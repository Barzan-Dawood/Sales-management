import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static const String _dbName = 'pos_office.db';
  static const int _dbVersion = 6;

  late Database _db;
  late String _dbPath;

  Database get database => _db;
  String get databasePath => _dbPath;

  Future<void> initialize() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(appDir.path, _dbName);
    _dbPath = dbPath;
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedData(db);
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Add migrations here as schema evolves
        if (oldVersion < 2) {
          await _migrateToV2(db);
        }
        if (oldVersion < 3) {
          await _migrateToV3(db);
        }
        if (oldVersion < 4) {
          await _migrateToV4(db);
        }
        if (oldVersion < 5) {
          await _migrateToV5(db);
        }
        if (oldVersion < 6) {
          await _migrateToV6(db);
        }
        // Ensure no legacy triggers/views remain that reference old temp tables
        await _cleanupOrphanObjects(db);
        await _ensureCategorySchemaOn(db);
        await _createIndexes(db);
      },
    );
    // Enforce foreign keys and ensure indexes on every open
    await _db.execute('PRAGMA foreign_keys = ON');
    await _createIndexes(_db);
    await _cleanupOrphanObjects(_db);
    await _ensureAdminPlainCredentials();
    // Ensure new tables/columns exist even if version didn't change
    await _ensureCategorySchemaOn(_db);
    // Clean up any sales_old references
    await cleanupSalesOldReferences();

    // إصلاح جدول installments إذا كان يحتوي على مراجع خاطئة
    await fixInstallmentsTable();
  }

  Future<void> reopen() async {
    await _db.close();
    _db = await openDatabase(_dbPath, version: _dbVersion);
    await _db.execute('PRAGMA foreign_keys = ON');
    await _createIndexes(_db);
    await _cleanupOrphanObjects(_db);
    await _ensureCategorySchemaOn(_db);
    await cleanupSalesOldReferences();
  }

  /// Force a complete cleanup of orphaned database objects
  /// This method can be called to resolve database corruption issues
  Future<void> forceCleanup() async {
    try {
      await _cleanupOrphanObjects(_db);
      await _createIndexes(_db);
      await _ensureCategorySchemaOn(_db);
    } catch (e) {
      print('Error during force cleanup: $e');
      rethrow;
    }
  }

  /// إصلاح جدول installments إذا كان يحتوي على مراجع خاطئة
  Future<void> fixInstallmentsTable() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      final installmentsSchema = await _db.rawQuery(
          "SELECT sql FROM sqlite_master WHERE type='table' AND name='installments'");
      if (installmentsSchema.isNotEmpty) {
        final schema = installmentsSchema.first['sql']?.toString() ?? '';
        if (schema.contains('sales_old')) {
          print('إصلاح جدول installments - يحتوي على مراجع خاطئة...');

          // حفظ البيانات الموجودة
          final existingData = await _db.rawQuery('SELECT * FROM installments');
          print('تم العثور على ${existingData.length} قسط موجود');

          // حذف الجدول القديم
          await _db.execute('DROP TABLE installments');

          // إنشاء الجدول الجديد
          await _db.execute('''
            CREATE TABLE installments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sale_id INTEGER NOT NULL,
              due_date TEXT NOT NULL,
              amount REAL NOT NULL,
              paid INTEGER NOT NULL DEFAULT 0,
              paid_at TEXT,
              FOREIGN KEY(sale_id) REFERENCES sales(id)
            );
          ''');

          // استعادة البيانات
          for (final row in existingData) {
            await _db.insert('installments', {
              'id': row['id'],
              'sale_id': row['sale_id'],
              'due_date': row['due_date'],
              'amount': row['amount'],
              'paid': row['paid'],
              'paid_at': row['paid_at'],
            });
          }

          print(
              'تم إصلاح جدول installments بنجاح - تم استعادة ${existingData.length} قسط');
        } else {
          print('جدول installments لا يحتوي على مراجع خاطئة');
        }
      } else {
        print('جدول installments غير موجود');
      }

      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
      print('خطأ في إصلاح جدول installments: $e');
      rethrow;
    }
  }

  /// Clean up sales_old references specifically
  Future<void> cleanupSalesOldReferences() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      // Drop sales_old table if exists
      await _db.execute('DROP TABLE IF EXISTS sales_old');

      // Find and drop all objects referencing sales_old
      final orphanObjects = await _db.rawQuery('''
        SELECT type, name FROM sqlite_master 
        WHERE type IN ('trigger', 'view', 'index') 
        AND (IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%')
      ''');

      for (final row in orphanObjects) {
        final type = row['type']?.toString();
        final name = row['name']?.toString();
        if (type != null && name != null && name.isNotEmpty) {
          try {
            String dropCommand;
            switch (type) {
              case 'view':
                dropCommand = 'DROP VIEW IF EXISTS $name';
                break;
              case 'index':
                dropCommand = 'DROP INDEX IF EXISTS $name';
                break;
              case 'trigger':
                dropCommand = 'DROP TRIGGER IF EXISTS $name';
                break;
              default:
                continue;
            }
            await _db.execute(dropCommand);
            print('Cleaned up orphaned $type: $name');
          } catch (e) {
            print('Error cleaning up $type $name: $e');
            // Continue with other objects even if one fails
          }
        }
      }

      await _db.execute('PRAGMA foreign_keys = ON');
      print('Sales_old cleanup completed');
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
      print('Error during sales_old cleanup: $e');
      rethrow;
    }
  }

  /// Debug function to check customer deletion status
  Future<Map<String, dynamic>> debugCustomerDeletion(int customerId) async {
    final result = <String, dynamic>{};

    try {
      // Check if customer exists
      final customer = await _db
          .query('customers', where: 'id = ?', whereArgs: [customerId]);
      result['customer_exists'] = customer.isNotEmpty;

      if (customer.isNotEmpty) {
        result['customer_data'] = customer.first;
      }

      // Check related sales
      final sales = await _db
          .query('sales', where: 'customer_id = ?', whereArgs: [customerId]);
      result['sales_count'] = sales.length;
      result['sales_data'] = sales;

      // Check related payments
      final payments = await _db
          .query('payments', where: 'customer_id = ?', whereArgs: [customerId]);
      result['payments_count'] = payments.length;
      result['payments_data'] = payments;

      // Check related installments
      final installments = await _db.rawQuery('''
        SELECT i.* FROM installments i
        JOIN sales s ON s.id = i.sale_id
        WHERE s.customer_id = ?
      ''', [customerId]);
      result['installments_count'] = installments.length;
      result['installments_data'] = installments;

      // Check related sale_items
      final saleItems = await _db.rawQuery('''
        SELECT si.* FROM sale_items si
        JOIN sales s ON s.id = si.sale_id
        WHERE s.customer_id = ?
      ''', [customerId]);
      result['sale_items_count'] = saleItems.length;
      result['sale_items_data'] = saleItems;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Aggressive cleanup that rebuilds sale_items table if necessary
  Future<void> aggressiveCleanup() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      // First, try the normal cleanup
      await _cleanupOrphanObjects(_db);

      // Clean up orphaned records in sale_items
      try {
        await _db.execute('''
          DELETE FROM sale_items 
          WHERE sale_id NOT IN (SELECT id FROM sales)
          OR product_id NOT IN (SELECT id FROM products)
        ''');
        print('Cleaned up orphaned sale_items records');
      } catch (e) {
        print('Error cleaning orphaned sale_items: $e');
      }

      // If that doesn't work, completely rebuild sale_items
      try {
        // Check if sale_items exists and is corrupted
        final saleItemsCheck = await _db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='sale_items'");

        if (saleItemsCheck.isNotEmpty) {
          // Backup existing data
          final existingData = await _db.rawQuery('SELECT * FROM sale_items');

          // Drop and recreate the table
          await _db.execute('DROP TABLE sale_items');

          // Recreate with proper structure
          await _db.execute('''
            CREATE TABLE sale_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sale_id INTEGER NOT NULL,
              product_id INTEGER NOT NULL,
              price REAL NOT NULL,
              cost REAL NOT NULL,
              quantity INTEGER NOT NULL,
              FOREIGN KEY(sale_id) REFERENCES sales(id),
              FOREIGN KEY(product_id) REFERENCES products(id)
            );
          ''');

          // Restore data if any
          if (existingData.isNotEmpty) {
            for (final row in existingData) {
              await _db.insert('sale_items', {
                'sale_id': row['sale_id'],
                'product_id': row['product_id'],
                'price': row['price'],
                'cost': row['cost'],
                'quantity': row['quantity'],
              });
            }
          }
        }
      } catch (e) {
        print('Error rebuilding sale_items: $e');
      }

      // Ensure all core tables exist
      await _db.execute('''
        CREATE TABLE IF NOT EXISTS sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER,
          total REAL NOT NULL,
          profit REAL NOT NULL DEFAULT 0,
          type TEXT NOT NULL CHECK(type IN ('cash','installment','credit')),
          created_at TEXT NOT NULL,
          due_date TEXT,
          down_payment REAL DEFAULT 0,
          FOREIGN KEY(customer_id) REFERENCES customers(id)
        );
      ''');

      await _db.execute('''
        CREATE TABLE IF NOT EXISTS sale_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          price REAL NOT NULL,
          cost REAL NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY(sale_id) REFERENCES sales(id),
          FOREIGN KEY(product_id) REFERENCES products(id)
        );
      ''');

      // Recreate indexes
      await _createIndexes(_db);
      await _ensureCategorySchemaOn(_db);

      // Re-enable foreign keys
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // Ensure foreign keys are re-enabled
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      print('Error during aggressive cleanup: $e');
      rethrow;
    }
  }

  /// Check database integrity and return any issues found
  Future<List<String>> checkDatabaseIntegrity() async {
    final issues = <String>[];

    try {
      // Check for sales_old table
      final salesOldCheck = await _db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='sales_old'");
      if (salesOldCheck.isNotEmpty) {
        issues.add('Found orphaned sales_old table');
      }

      // Check for objects referencing sales_old in main schema
      final salesOldRefs = await _db.rawQuery('''
        SELECT type, name FROM sqlite_master 
        WHERE type IN ('trigger', 'view', 'index') 
        AND IFNULL(sql,'') LIKE '%sales_old%'
      ''');
      if (salesOldRefs.isNotEmpty) {
        issues.add(
            'Found ${salesOldRefs.length} objects referencing sales_old in main schema');
      }

      // Check for objects referencing sales_old in temp schema
      final tempSalesOldRefs = await _db.rawQuery('''
        SELECT type, name FROM sqlite_temp_master 
        WHERE type IN ('trigger', 'view', 'index') 
        AND IFNULL(sql,'') LIKE '%sales_old%'
      ''');
      if (tempSalesOldRefs.isNotEmpty) {
        issues.add(
            'Found ${tempSalesOldRefs.length} objects referencing sales_old in temp schema');
      }

      // Check if sale_items is a view instead of table
      final saleItemsType = await _db.rawQuery(
          "SELECT type FROM sqlite_master WHERE name='sale_items' LIMIT 1");
      if (saleItemsType.isNotEmpty && saleItemsType.first['type'] == 'view') {
        issues.add('sale_items is a view instead of a table');
      }

      // Check if sale_items table exists
      final saleItemsExists = await _db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='sale_items'");
      if (saleItemsExists.isEmpty) {
        issues.add('sale_items table is missing');
      }

      // Check foreign key constraints
      final fkCheck = await _db.rawQuery('PRAGMA foreign_key_check');
      if (fkCheck.isNotEmpty) {
        issues.add('Found ${fkCheck.length} foreign key constraint violations');
      }

      // Check for orphaned records in sale_items
      final orphanedSaleItems = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM sale_items si
        LEFT JOIN sales s ON si.sale_id = s.id
        WHERE s.id IS NULL
      ''');
      final orphanedCount = orphanedSaleItems.first['count'] as int;
      if (orphanedCount > 0) {
        issues.add('Found $orphanedCount orphaned sale_items records');
      }

      // Check for orphaned records in sale_items with products
      final orphanedProductItems = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM sale_items si
        LEFT JOIN products p ON si.product_id = p.id
        WHERE p.id IS NULL
      ''');
      final orphanedProductCount = orphanedProductItems.first['count'] as int;
      if (orphanedProductCount > 0) {
        issues.add(
            'Found $orphanedProductCount sale_items with missing products');
      }
    } catch (e) {
      issues.add('Error checking database integrity: $e');
    }

    return issues;
  }

  /// Debug method to find all references to sales_old
  Future<Map<String, dynamic>> debugSalesOldReferences() async {
    final result = <String, dynamic>{};

    try {
      // Get all objects in main schema
      final mainObjects = await _db.rawQuery('''
        SELECT type, name, sql FROM sqlite_master 
        WHERE IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%'
        ORDER BY type, name
      ''');
      result['main_schema'] = mainObjects;

      // Get all objects in temp schema
      final tempObjects = await _db.rawQuery('''
        SELECT type, name, sql FROM sqlite_temp_master 
        WHERE IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%'
        ORDER BY type, name
      ''');
      result['temp_schema'] = tempObjects;

      // Get all triggers
      final allTriggers = await _db.rawQuery('''
        SELECT name, sql FROM sqlite_master WHERE type='trigger'
        UNION ALL
        SELECT name, sql FROM sqlite_temp_master WHERE type='trigger'
      ''');
      result['all_triggers'] = allTriggers;

      // Get table info for sale_items
      final saleItemsInfo = await _db.rawQuery('''
        SELECT * FROM sqlite_master WHERE name='sale_items'
      ''');
      result['sale_items_info'] = saleItemsInfo;

      // Get foreign key info
      final fkInfo = await _db.rawQuery('PRAGMA foreign_key_list(sale_items)');
      result['sale_items_fk'] = fkInfo;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Emergency method to completely reset sale_items table
  /// Use this only if all other cleanup methods fail
  Future<void> emergencyResetSaleItems() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      // Get all existing data
      final existingData = await _db.rawQuery('SELECT * FROM sale_items');
      print('Backing up ${existingData.length} sale_items records');

      // Drop the table completely
      await _db.execute('DROP TABLE IF EXISTS sale_items');

      // Recreate with clean structure
      await _db.execute('''
        CREATE TABLE sale_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          price REAL NOT NULL,
          cost REAL NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY(sale_id) REFERENCES sales(id),
          FOREIGN KEY(product_id) REFERENCES products(id)
        );
      ''');

      // Restore data
      for (final row in existingData) {
        await _db.insert('sale_items', {
          'sale_id': row['sale_id'],
          'product_id': row['product_id'],
          'price': row['price'],
          'cost': row['cost'],
          'quantity': row['quantity'],
        });
      }

      print('Restored ${existingData.length} sale_items records');

      // Re-enable foreign keys
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      print('Error during emergency reset: $e');
      rethrow;
    }
  }

  Future<void> _migrateToV2(Database db) async {
    // SQLite cannot directly alter CHECK constraints. Recreate sales table.
    await db.execute('PRAGMA foreign_keys=off');
    await db.execute('ALTER TABLE sales RENAME TO sales_old');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        total REAL NOT NULL,
        profit REAL NOT NULL DEFAULT 0,
        type TEXT NOT NULL CHECK(type IN ('cash','installment','credit')),
        created_at TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      );
    ''');
    await db.execute('''
      INSERT INTO sales (id, customer_id, total, profit, type, created_at)
      SELECT id, customer_id, total, profit, type, created_at FROM sales_old;
    ''');
    await db.execute('DROP TABLE sales_old');
    await db.execute('PRAGMA foreign_keys=on');
  }

  Future<void> _cleanupOrphanObjects(Database db) async {
    try {
      // Disable foreign keys temporarily for cleanup
      await db.execute('PRAGMA foreign_keys = OFF');

      // Drop leftover temporary renamed table if present
      try {
        await db.execute('DROP TABLE IF EXISTS sales_old');
      } catch (_) {}

      // إصلاح جدول installments إذا كان يحتوي على مراجع خاطئة
      try {
        final installmentsSchema = await db.rawQuery(
            "SELECT sql FROM sqlite_master WHERE type='table' AND name='installments'");
        if (installmentsSchema.isNotEmpty) {
          final schema = installmentsSchema.first['sql']?.toString() ?? '';
          if (schema.contains('sales_old')) {
            print('إصلاح جدول installments في _cleanupOrphanObjects...');

            // حفظ البيانات الموجودة
            final existingData =
                await db.rawQuery('SELECT * FROM installments');

            // حذف الجدول القديم
            await db.execute('DROP TABLE installments');

            // إنشاء الجدول الجديد
            await db.execute('''
              CREATE TABLE installments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sale_id INTEGER NOT NULL,
                due_date TEXT NOT NULL,
                amount REAL NOT NULL,
                paid INTEGER NOT NULL DEFAULT 0,
                paid_at TEXT,
                FOREIGN KEY(sale_id) REFERENCES sales(id)
              );
            ''');

            // استعادة البيانات
            for (final row in existingData) {
              await db.insert('installments', {
                'id': row['id'],
                'sale_id': row['sale_id'],
                'due_date': row['due_date'],
                'amount': row['amount'],
                'paid': row['paid'],
                'paid_at': row['paid_at'],
              });
            }

            print('تم إصلاح جدول installments في _cleanupOrphanObjects بنجاح');
          }
        }
      } catch (e) {
        print('خطأ في إصلاح جدول installments في _cleanupOrphanObjects: $e');
      }

      // Get all database objects that might reference sales_old
      final allObjects = await db.rawQuery('''
        SELECT type, name, sql FROM sqlite_master 
        WHERE type IN ('trigger', 'view', 'index', 'table') 
        AND (IFNULL(sql,'') LIKE '%sales_old%' OR name = 'sales_old')
        UNION ALL
        SELECT type, name, sql FROM sqlite_temp_master 
        WHERE type IN ('trigger', 'view', 'index', 'table') 
        AND (IFNULL(sql,'') LIKE '%sales_old%' OR name = 'sales_old')
      ''');

      for (final row in allObjects) {
        final type = row['type']?.toString();
        final name = row['name']?.toString();
        if (type != null && name != null && name.isNotEmpty) {
          try {
            String dropCommand;
            switch (type) {
              case 'view':
                dropCommand = 'DROP VIEW IF EXISTS $name';
                break;
              case 'index':
                dropCommand = 'DROP INDEX IF EXISTS $name';
                break;
              case 'trigger':
                dropCommand = 'DROP TRIGGER IF EXISTS $name';
                break;
              case 'table':
                if (name == 'sales_old') {
                  dropCommand = 'DROP TABLE IF EXISTS $name';
                } else {
                  continue; // Skip other tables
                }
                break;
              default:
                continue;
            }
            await db.execute(dropCommand);
          } catch (_) {}
        }
      }

      // Drop any triggers on sale_items (we don't use triggers in current schema)
      final saleItemsTriggers = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='trigger' AND tbl_name='sale_items'");
      for (final row in saleItemsTriggers) {
        final name = row['name']?.toString();
        if (name != null && name.isNotEmpty) {
          try {
            await db.execute('DROP TRIGGER IF EXISTS $name');
          } catch (_) {}
        }
      }

      // Ensure sale_items is a real table (not a leftover view)
      final saleItemsObj = await db.rawQuery(
          "SELECT type FROM sqlite_master WHERE name='sale_items' LIMIT 1");
      if (saleItemsObj.isNotEmpty && saleItemsObj.first['type'] == 'view') {
        try {
          await db.execute('DROP VIEW IF EXISTS sale_items');
        } catch (_) {}
      }

      // Re-ensure core tables exist with proper structure
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER,
          total REAL NOT NULL,
          profit REAL NOT NULL DEFAULT 0,
          type TEXT NOT NULL CHECK(type IN ('cash','installment','credit')),
          created_at TEXT NOT NULL,
          due_date TEXT,
          down_payment REAL DEFAULT 0,
          FOREIGN KEY(customer_id) REFERENCES customers(id)
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          price REAL NOT NULL,
          cost REAL NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY(sale_id) REFERENCES sales(id),
          FOREIGN KEY(product_id) REFERENCES products(id)
        );
      ''');

      // Re-enable foreign keys
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // Ensure foreign keys are re-enabled even if cleanup fails
      try {
        await db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      // best-effort cleanup
    }
  }

  Future<void> _ensureAdminPlainCredentials() async {
    try {
      final users = await _db.query('users',
          where: 'username = ?', whereArgs: ['admin'], limit: 1);
      const desired = 'admin123';
      if (users.isEmpty) {
        await _db.insert('users', {
          'name': 'Administrator',
          'username': 'admin',
          'password': desired,
          'role': 'manager',
          'active': 1,
        });
        return;
      }
      final current = (users.first['password'] ?? '').toString();
      if (current != desired) {
        await _db.update('users', {'password': desired},
            where: 'id = ?', whereArgs: [users.first['id']]);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _createIndexes(Database db) async {
    // Products
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id)');

    // Sales
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id)');
    await db
        .execute('CREATE INDEX IF NOT EXISTS idx_sales_type ON sales(type)');

    // Sale items
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id)');

    // Customers
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)');

    // Payments
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date)');
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon INTEGER,
        color INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('manager','employee')),
        active INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE,
        price REAL NOT NULL,
        cost REAL NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 0,
        min_quantity INTEGER NOT NULL DEFAULT 1,
        category_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        total_debt REAL NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        total_payable REAL NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        total REAL NOT NULL,
        profit REAL NOT NULL DEFAULT 0,
        type TEXT NOT NULL CHECK(type IN ('cash','installment','credit')),
        created_at TEXT NOT NULL,
        due_date TEXT,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        price REAL NOT NULL,
        cost REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY(sale_id) REFERENCES sales(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        due_date TEXT NOT NULL,
        amount REAL NOT NULL,
        paid INTEGER NOT NULL DEFAULT 0,
        paid_at TEXT,
        FOREIGN KEY(sale_id) REFERENCES sales(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT,
        phone TEXT,
        address TEXT,
        logo_path TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      );
    ''');
  }

  Future<void> _ensureCategorySchemaOn(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon INTEGER,
        color INTEGER
      );
    ''');
    try {
      await db.execute('ALTER TABLE products ADD COLUMN category_id INTEGER');
    } catch (_) {
      // column already exists
    }
  }

  Future<void> _migrateToV3(Database db) async {
    // Add due_date to sales for credit tracking
    try {
      await db.execute('ALTER TABLE sales ADD COLUMN due_date TEXT');
    } catch (_) {}
  }

  Future<void> _migrateToV4(Database db) async {
    // Add payments table for debt collection
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      );
    ''');
  }

  Future<void> _migrateToV5(Database db) async {
    // Add address field to settings table
    try {
      await db.execute('ALTER TABLE settings ADD COLUMN address TEXT');
    } catch (_) {
      // column already exists
    }
  }

  Future<void> _migrateToV6(Database db) async {
    // Add down_payment field to sales table for installments
    try {
      await db
          .execute('ALTER TABLE sales ADD COLUMN down_payment REAL DEFAULT 0');
    } catch (_) {
      // column already exists
    }
  }

  Future<void> _seedData(Database db) async {
    // Ensure an admin user exists with a plain password as requested
    final existing = await db.query('users',
        where: 'username = ?', whereArgs: ['admin'], limit: 1);
    const plain = 'admin123';
    if (existing.isEmpty) {
      await db.insert('users', {
        'name': 'Administrator',
        'username': 'admin',
        'password': plain,
        'role': 'manager',
        'active': 1,
      });
    } else {
      await db.update(
          'users',
          {
            'name': existing.first['name'] ?? 'Administrator',
            'password': plain,
            'role': 'manager',
            'active': 1,
          },
          where: 'username = ?',
          whereArgs: ['admin']);
    }
  }

  // Simple helpers for common queries used early in development
  Future<Map<String, Object?>?> findUserByCredentials(
      String username, String password) async {
    final result = await _db.query(
      'users',
      where: 'username = ? AND password = ? AND active = 1',
      whereArgs: [username, password],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<List<Map<String, Object?>>> getAllProducts(
      {String? query, int? categoryId}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      where.add('(name LIKE ? OR barcode LIKE ?)');
      args.addAll([like, like]);
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    return _db.query('products',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: where.isEmpty ? null : args,
        orderBy: 'id DESC');
  }

  Future<int> insertProduct(Map<String, Object?> values) async {
    values['created_at'] = DateTime.now().toIso8601String();
    return _db.insert('products', values,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updateProduct(int id, Map<String, Object?> values) async {
    values['updated_at'] = DateTime.now().toIso8601String();
    return _db.update('products', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    return _db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Categories
  Future<List<Map<String, Object?>>> getCategories({String? query}) async {
    if (query == null || query.trim().isEmpty) {
      return _db.query('categories', orderBy: 'name ASC');
    }
    final like = '%${query.trim()}%';
    return _db.query('categories',
        where: 'name LIKE ?', whereArgs: [like], orderBy: 'name ASC');
  }

  Future<int> upsertCategory(Map<String, Object?> values, {int? id}) async {
    if (id == null) return _db.insert('categories', values);
    return _db.update('categories', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    return _db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Customers
  Future<List<Map<String, Object?>>> getCustomers({String? query}) async {
    if (query == null || query.trim().isEmpty)
      return _db.query('customers', orderBy: 'id DESC');
    final like = '%${query.trim()}%';
    return _db.query('customers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: [like, like],
        orderBy: 'id DESC');
  }

  Future<int> upsertCustomer(Map<String, Object?> values, {int? id}) async {
    if (id == null) return _db.insert('customers', values);
    return _db.update('customers', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCustomer(int id) async {
    return _db.transaction<int>((txn) async {
      try {
        print('Starting deletion of customer ID: $id');

        // تنظيف المراجع القديمة قبل البدء
        try {
          await txn.execute('PRAGMA foreign_keys = OFF');
          await txn.execute('DROP TABLE IF EXISTS sales_old');

          // حذف أي triggers أو views تشير إلى sales_old من المخطط الرئيسي
          final orphanObjects = await txn.rawQuery('''
            SELECT type, name FROM sqlite_master 
            WHERE type IN ('trigger', 'view', 'index') 
            AND (IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%')
          ''');

          for (final row in orphanObjects) {
            final type = row['type']?.toString();
            final name = row['name']?.toString();
            if (type != null && name != null && name.isNotEmpty) {
              try {
                String dropCommand;
                switch (type) {
                  case 'view':
                    dropCommand = 'DROP VIEW IF EXISTS $name';
                    break;
                  case 'index':
                    dropCommand = 'DROP INDEX IF EXISTS $name';
                    break;
                  case 'trigger':
                    dropCommand = 'DROP TRIGGER IF EXISTS $name';
                    break;
                  default:
                    continue;
                }
                await txn.execute(dropCommand);
                print('Dropped orphaned $type: $name');
              } catch (e) {
                print('Error dropping $type $name: $e');
              }
            }
          }

          // حذف أي triggers أو views تشير إلى sales_old من المخطط المؤقت
          final tempOrphanObjects = await txn.rawQuery('''
            SELECT type, name FROM sqlite_temp_master 
            WHERE type IN ('trigger', 'view', 'index') 
            AND (IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%')
          ''');

          for (final row in tempOrphanObjects) {
            final type = row['type']?.toString();
            final name = row['name']?.toString();
            if (type != null && name != null && name.isNotEmpty) {
              try {
                String dropCommand;
                switch (type) {
                  case 'view':
                    dropCommand = 'DROP VIEW IF EXISTS $name';
                    break;
                  case 'index':
                    dropCommand = 'DROP INDEX IF EXISTS $name';
                    break;
                  case 'trigger':
                    dropCommand = 'DROP TRIGGER IF EXISTS $name';
                    break;
                  default:
                    continue;
                }
                await txn.execute(dropCommand);
                print('Dropped temp orphaned $type: $name');
              } catch (e) {
                print('Error dropping temp $type $name: $e');
              }
            }
          }

          await txn.execute('PRAGMA foreign_keys = ON');
        } catch (e) {
          print('Error during cleanup: $e');
          await txn.execute('PRAGMA foreign_keys = ON');
        }

        // التحقق من وجود العميل أولاً
        final customerExists = await txn.query('customers',
            columns: ['id'], where: 'id = ?', whereArgs: [id]);
        if (customerExists.isEmpty) {
          print('Customer with ID $id does not exist');
          return 0;
        }

        // أولاً، الحصول على معرفات المبيعات المرتبطة بالعميل
        final sales = await txn.query('sales',
            columns: ['id'], where: 'customer_id = ?', whereArgs: [id]);
        print('Found ${sales.length} sales for customer $id');

        // حذف عناصر المبيعات المرتبطة
        for (final sale in sales) {
          final deletedItems = await txn.delete('sale_items',
              where: 'sale_id = ?', whereArgs: [sale['id']]);
          print('Deleted $deletedItems sale_items for sale ${sale['id']}');
        }

        // حذف المدفوعات المرتبطة بالعميل
        final deletedPayments = await txn
            .delete('payments', where: 'customer_id = ?', whereArgs: [id]);
        print('Deleted $deletedPayments payments for customer $id');

        // حذف الأقساط المرتبطة بالمبيعات
        for (final sale in sales) {
          try {
            final deletedInstallments = await txn.delete('installments',
                where: 'sale_id = ?', whereArgs: [sale['id']]);
            print(
                'Deleted $deletedInstallments installments for sale ${sale['id']}');
          } catch (e) {
            print('Error deleting installments for sale ${sale['id']}: $e');
            // محاولة بديلة - حذف مباشر
            try {
              await txn.execute(
                  'DELETE FROM installments WHERE sale_id = ?', [sale['id']]);
              print('Successfully deleted installments using direct SQL');
            } catch (directError) {
              print('Direct SQL deletion also failed: $directError');
              // تجاهل الخطأ والمتابعة
            }
          }
        }

        // حذف المبيعات المرتبطة بالعميل
        final deletedSales = await txn
            .delete('sales', where: 'customer_id = ?', whereArgs: [id]);
        print('Deleted $deletedSales sales for customer $id');

        // حذف العميل نفسه
        final deletedRows =
            await txn.delete('customers', where: 'id = ?', whereArgs: [id]);
        print('Deleted $deletedRows customers with ID $id');

        return deletedRows;
      } catch (e) {
        print('Error deleting customer: $e');
        rethrow;
      }
    });
  }

  // Suppliers
  Future<List<Map<String, Object?>>> getSuppliers({String? query}) async {
    if (query == null || query.trim().isEmpty)
      return _db.query('suppliers', orderBy: 'id DESC');
    final like = '%${query.trim()}%';
    return _db.query('suppliers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: [like, like],
        orderBy: 'id DESC');
  }

  Future<int> upsertSupplier(Map<String, Object?> values, {int? id}) async {
    if (id == null) return _db.insert('suppliers', values);
    return _db.update('suppliers', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSupplier(int id) =>
      _db.delete('suppliers', where: 'id = ?', whereArgs: [id]);

  // Expenses
  Future<List<Map<String, Object?>>> getExpenses(
      {DateTime? from, DateTime? to}) async {
    if (from == null || to == null)
      return _db.query('expenses', orderBy: 'created_at DESC');
    return _db.query('expenses',
        where: 'created_at BETWEEN ? AND ?',
        whereArgs: [from.toIso8601String(), to.toIso8601String()],
        orderBy: 'created_at DESC');
  }

  Future<int> addExpense(String title, double amount) async {
    return _db.insert('expenses', {
      'title': title,
      'amount': amount,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> deleteExpense(int id) =>
      _db.delete('expenses', where: 'id = ?', whereArgs: [id]);

  // إدارة الأقساط
  Future<List<Map<String, Object?>>> getInstallments({
    int? customerId,
    int? saleId,
    bool overdueOnly = false,
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (customerId != null) {
      where.add('s.customer_id = ?');
      args.add(customerId);
    }

    if (saleId != null) {
      where.add('i.sale_id = ?');
      args.add(saleId);
    }

    if (overdueOnly) {
      where.add('i.due_date < ? AND i.paid = 0');
      args.add(DateTime.now().toIso8601String());
    }

    final sql = '''
      SELECT 
        i.*,
        s.customer_id,
        c.name as customer_name,
        c.phone as customer_phone,
        s.total as sale_total,
        s.type as sale_type
      FROM installments i
      JOIN sales s ON s.id = i.sale_id
      JOIN customers c ON c.id = s.customer_id
      ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
      ORDER BY i.due_date ASC
    ''';

    return _db.rawQuery(sql, args);
  }

  Future<int> payInstallment(int installmentId, double amount,
      {String? notes}) async {
    return _db.transaction<int>((txn) async {
      // الحصول على بيانات القسط
      final installment = await txn.query(
        'installments',
        where: 'id = ?',
        whereArgs: [installmentId],
      );

      if (installment.isEmpty) {
        throw Exception('القسط غير موجود');
      }

      final installmentData = installment.first;
      final saleId = installmentData['sale_id'] as int;
      final customerId = await txn.query(
        'sales',
        columns: ['customer_id'],
        where: 'id = ?',
        whereArgs: [saleId],
      );

      if (customerId.isEmpty) {
        throw Exception('البيع غير موجود');
      }

      final customerIdValue = customerId.first['customer_id'] as int;

      // تحديث حالة القسط
      await txn.update(
        'installments',
        {
          'paid': 1,
          'paid_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [installmentId],
      );

      // إضافة سجل الدفع
      final paymentId = await txn.insert('payments', {
        'customer_id': customerIdValue,
        'amount': amount,
        'payment_date': DateTime.now().toIso8601String(),
        'notes': notes ?? 'دفع قسط',
        'created_at': DateTime.now().toIso8601String(),
      });

      // تقليل دين العميل
      await txn.rawUpdate(
        'UPDATE customers SET total_debt = MAX(IFNULL(total_debt, 0) - ?, 0) WHERE id = ?',
        [amount, customerIdValue],
      );

      return paymentId;
    });
  }

  Future<Map<String, dynamic>> getInstallmentSummary(int customerId) async {
    final installments = await getInstallments(customerId: customerId);

    double totalInstallments = 0;
    double paidInstallments = 0;
    double overdueAmount = 0;
    int overdueCount = 0;
    int totalCount = 0;
    int paidCount = 0;

    for (final installment in installments) {
      final amount = (installment['amount'] as num).toDouble();
      final paid = (installment['paid'] as int) == 1;
      final dueDate = DateTime.parse(installment['due_date'] as String);

      totalInstallments += amount;
      totalCount++;

      if (paid) {
        paidInstallments += amount;
        paidCount++;
      } else if (dueDate.isBefore(DateTime.now())) {
        overdueAmount += amount;
        overdueCount++;
      }
    }

    return {
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'remainingInstallments': totalInstallments - paidInstallments,
      'overdueAmount': overdueAmount,
      'overdueCount': overdueCount,
      'totalCount': totalCount,
      'paidCount': paidCount,
      'remainingCount': totalCount - paidCount,
    };
  }

  /// الحصول على تفاصيل الأقساط مع المبالغ المحدثة
  Future<List<Map<String, dynamic>>> getInstallmentDetails(
      int customerId) async {
    final installments = await _db.rawQuery('''
      SELECT 
        i.id,
        i.sale_id,
        i.due_date,
        i.amount,
        i.paid,
        i.paid_at,
        s.created_at as sale_date,
        s.total as sale_total,
        s.type as sale_type
      FROM installments i
      JOIN sales s ON s.id = i.sale_id
      WHERE s.customer_id = ?
      ORDER BY i.due_date ASC
    ''', [customerId]);

    return installments.map((installment) {
      final dueDate = DateTime.parse(installment['due_date'] as String);
      final isOverdue = !(installment['paid'] as int == 1) &&
          dueDate.isBefore(DateTime.now());

      return {
        ...installment,
        'is_overdue': isOverdue,
        'days_overdue':
            isOverdue ? DateTime.now().difference(dueDate).inDays : 0,
      };
    }).toList();
  }

  // Sales and installments (integrated system)
  Future<int> createSale(
      {int? customerId,
      String? customerName,
      String? customerPhone,
      String? customerAddress,
      DateTime? dueDate,
      required String type,
      required List<Map<String, Object?>> items,
      bool decrementStock = true,
      // إضافة معاملات الأقساط
      int? installmentCount,
      double? downPayment,
      DateTime? firstInstallmentDate}) async {
    return _db.transaction<int>((txn) async {
      // Defensive cleanup to neutralize legacy objects referencing sales_old
      try {
        // Disable foreign keys temporarily for cleanup
        await txn.execute('PRAGMA foreign_keys = OFF');

        // Drop the sales_old table if it exists
        await txn.execute('DROP TABLE IF EXISTS sales_old');

        // إصلاح إضافي: التأكد من أن جدول sales موجود
        final salesTableCheck = await txn.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='sales'");
        if (salesTableCheck.isEmpty) {
          print('خطأ: جدول sales غير موجود! إنشاء الجدول...');
          // إنشاء جدول sales إذا لم يكن موجوداً
          await txn.execute('''
            CREATE TABLE IF NOT EXISTS sales (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              customer_id INTEGER,
              total REAL NOT NULL,
              profit REAL NOT NULL DEFAULT 0,
              type TEXT NOT NULL DEFAULT 'cash',
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              down_payment REAL DEFAULT 0,
              FOREIGN KEY(customer_id) REFERENCES customers(id)
            );
          ''');
        }

        // إصلاح جدول installments إذا كان يحتوي على مراجع خاطئة
        try {
          final installmentsSchema = await txn.rawQuery(
              "SELECT sql FROM sqlite_master WHERE type='table' AND name='installments'");
          if (installmentsSchema.isNotEmpty) {
            final schema = installmentsSchema.first['sql']?.toString() ?? '';
            if (schema.contains('sales_old')) {
              print('جدول installments يحتوي على مراجع خاطئة، إعادة إنشاؤه...');

              // حفظ البيانات الموجودة
              final existingData =
                  await txn.rawQuery('SELECT * FROM installments');

              // حذف الجدول القديم
              await txn.execute('DROP TABLE installments');

              // إنشاء الجدول الجديد
              await txn.execute('''
                CREATE TABLE installments (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  sale_id INTEGER NOT NULL,
                  due_date TEXT NOT NULL,
                  amount REAL NOT NULL,
                  paid INTEGER NOT NULL DEFAULT 0,
                  paid_at TEXT,
                  FOREIGN KEY(sale_id) REFERENCES sales(id)
                );
              ''');

              // استعادة البيانات
              for (final row in existingData) {
                await txn.insert('installments', {
                  'id': row['id'],
                  'sale_id': row['sale_id'],
                  'due_date': row['due_date'],
                  'amount': row['amount'],
                  'paid': row['paid'],
                  'paid_at': row['paid_at'],
                });
              }

              print('تم إصلاح جدول installments بنجاح');
            }
          }
        } catch (e) {
          print('خطأ في فحص/إصلاح جدول installments: $e');
        }

        // Get all objects that reference sales_old from both main and temp schemas
        final allObjects = await txn.rawQuery('''
          SELECT type, name FROM sqlite_master 
          WHERE type IN ('trigger', 'view', 'index') 
          AND (IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%')
          UNION ALL
          SELECT type, name FROM sqlite_temp_master 
          WHERE type IN ('trigger', 'view', 'index') 
          AND (IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%')
        ''');

        for (final row in allObjects) {
          final type = row['type']?.toString();
          final name = row['name']?.toString();
          if (type != null && name != null && name.isNotEmpty) {
            try {
              String dropCommand;
              switch (type) {
                case 'view':
                  dropCommand = 'DROP VIEW IF EXISTS $name';
                  break;
                case 'index':
                  dropCommand = 'DROP INDEX IF EXISTS $name';
                  break;
                case 'trigger':
                  dropCommand = 'DROP TRIGGER IF EXISTS $name';
                  break;
                default:
                  continue;
              }
              await txn.execute(dropCommand);
            } catch (_) {}
          }
        }

        // Drop any triggers on sale_items that might reference old tables
        final siTriggers = await txn.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='trigger' AND tbl_name='sale_items'");
        for (final row in siTriggers) {
          final name = row['name']?.toString();
          if (name != null && name.isNotEmpty) {
            try {
              await txn.execute('DROP TRIGGER IF EXISTS $name');
            } catch (_) {}
          }
        }

        // Ensure sale_items is not a VIEW
        final siType = await txn.rawQuery(
            "SELECT type FROM sqlite_master WHERE name='sale_items' LIMIT 1");
        if (siType.isNotEmpty && (siType.first['type']?.toString() == 'view')) {
          try {
            await txn.execute('DROP VIEW IF EXISTS sale_items');
          } catch (_) {}
        }

        // Re-ensure core tables exist
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER,
            total REAL NOT NULL,
            profit REAL NOT NULL DEFAULT 0,
            type TEXT NOT NULL CHECK(type IN ('cash','installment','credit')),
            created_at TEXT NOT NULL,
            due_date TEXT,
            down_payment REAL DEFAULT 0,
            FOREIGN KEY(customer_id) REFERENCES customers(id)
          );
        ''');
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            price REAL NOT NULL,
            cost REAL NOT NULL,
            quantity INTEGER NOT NULL,
            FOREIGN KEY(sale_id) REFERENCES sales(id),
            FOREIGN KEY(product_id) REFERENCES products(id)
          );
        ''');

        // Re-enable foreign keys
        await txn.execute('PRAGMA foreign_keys = ON');
      } catch (e) {
        // Ensure foreign keys are re-enabled even if cleanup fails
        try {
          await txn.execute('PRAGMA foreign_keys = ON');
        } catch (_) {}
      }

      // تنظيف إضافي للتأكد من عدم وجود مراجع لـ sales_old
      try {
        // البحث عن أي triggers أو views تحتوي على sales_old
        final problematicObjects = await txn.rawQuery('''
          SELECT name, type, sql FROM sqlite_master 
          WHERE (sql LIKE '%sales_old%' OR name LIKE '%sales_old%')
          AND type IN ('trigger', 'view', 'index')
        ''');

        for (final obj in problematicObjects) {
          final name = obj['name']?.toString();
          final type = obj['type']?.toString();
          if (name != null && name.isNotEmpty) {
            try {
              switch (type) {
                case 'trigger':
                  await txn.execute('DROP TRIGGER IF EXISTS $name');
                  print('Dropped problematic trigger in createSale: $name');
                  break;
                case 'view':
                  await txn.execute('DROP VIEW IF EXISTS $name');
                  print('Dropped problematic view in createSale: $name');
                  break;
                case 'index':
                  await txn.execute('DROP INDEX IF EXISTS $name');
                  print('Dropped problematic index in createSale: $name');
                  break;
              }
            } catch (e) {
              print('Error dropping $type $name in createSale: $e');
            }
          }
        }
      } catch (e) {
        print('Error during sales_old cleanup in createSale: $e');
      }

      double total = 0;
      double profit = 0;
      for (final it in items) {
        final price = (it['price'] as num).toDouble();
        final cost = (it['cost'] as num).toDouble();
        final quantity = (it['quantity'] as num).toDouble();

        // فحص القيم للتأكد من أنها صحيحة
        if (price.isNaN ||
            price.isInfinite ||
            quantity.isNaN ||
            quantity.isInfinite) {
          print(
              'تحذير: قيمة غير صحيحة في قاعدة البيانات - السعر: $price, الكمية: $quantity');
          continue;
        }

        final qty = quantity.toInt();
        total += price * qty;
        profit += (price - cost) * qty;
      }
      int? ensuredCustomerId = customerId;

      // إنشاء عميل لجميع أنواع المبيعات إذا تم إدخال اسم العميل
      if (ensuredCustomerId == null &&
          (customerName?.trim().isNotEmpty == true)) {
        // Try to find by name/phone; if not found, create
        final existing = await txn.query('customers',
            where: 'name = ? AND IFNULL(phone, "") = IFNULL(?, "")',
            whereArgs: [customerName!.trim(), customerPhone?.trim()]);
        if (existing.isNotEmpty) {
          ensuredCustomerId = existing.first['id'] as int;
        } else {
          ensuredCustomerId = await txn.insert('customers', {
            'name': customerName.trim(),
            'phone': customerPhone?.trim(),
            'address': customerAddress?.trim(),
            'total_debt': 0,
          });
        }
      }

      final saleId = await txn.insert('sales', {
        'customer_id': ensuredCustomerId,
        'total': total,
        'profit': profit,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'down_payment': downPayment ?? 0.0,
      });

      // إضافة عناصر البيع
      for (final it in items) {
        try {
          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': it['product_id'],
            'price': it['price'],
            'cost': it['cost'],
            'quantity': it['quantity'],
          });
          if (decrementStock) {
            await txn.rawUpdate(
                'UPDATE products SET quantity = quantity - ? WHERE id = ?',
                [it['quantity'], it['product_id']]);
          }
        } catch (e) {
          print('Error inserting sale item: $e');
          print('Sale ID: $saleId, Product ID: ${it['product_id']}');
          rethrow;
        }
      }

      // معالجة الديون والأقساط
      if (ensuredCustomerId != null) {
        if (type == 'credit') {
          // دين مباشر - إضافة المبلغ كاملاً للديون
          await txn.rawUpdate(
              'UPDATE customers SET total_debt = IFNULL(total_debt,0) + ? WHERE id = ?',
              [total, ensuredCustomerId]);
        } else if (type == 'installment' &&
            installmentCount != null &&
            installmentCount > 0) {
          // بيع بالأقساط
          final downPaymentAmount = downPayment ?? 0.0;
          final remainingAmount = total - downPaymentAmount;
          final installmentAmount = remainingAmount / installmentCount;

          // إضافة المبلغ المتبقي للديون
          await txn.rawUpdate(
              'UPDATE customers SET total_debt = IFNULL(total_debt,0) + ? WHERE id = ?',
              [remainingAmount, ensuredCustomerId]);

          // تنظيف إضافي قبل إنشاء الأقساط
          try {
            // البحث عن أي triggers تحتوي على sales_old
            final problematicTriggers = await txn.rawQuery('''
              SELECT name FROM sqlite_master 
              WHERE type = 'trigger' 
              AND (sql LIKE '%sales_old%' OR name LIKE '%sales_old%')
            ''');

            for (final trigger in problematicTriggers) {
              final name = trigger['name']?.toString();
              if (name != null && name.isNotEmpty) {
                try {
                  await txn.execute('DROP TRIGGER IF EXISTS $name');
                  print('Dropped problematic trigger: $name');
                } catch (e) {
                  print('Error dropping trigger $name: $e');
                }
              }
            }
          } catch (e) {
            print('Error during trigger cleanup: $e');
          }

          // إنشاء الأقساط
          DateTime currentDate = firstInstallmentDate ?? DateTime.now();
          for (int i = 0; i < installmentCount; i++) {
            try {
              await txn.insert('installments', {
                'sale_id': saleId,
                'due_date': currentDate.toIso8601String(),
                'amount': installmentAmount,
                'paid': 0,
                'paid_at': null,
              });
              print('تم إنشاء قسط ${i + 1} للمبيعة $saleId');
            } catch (e) {
              print('خطأ في إنشاء القسط ${i + 1}: $e');
              // محاولة إصلاح المشكلة
              try {
                // التأكد من أن جدول sales موجود
                final salesCheck = await txn.rawQuery(
                    "SELECT name FROM sqlite_master WHERE type='table' AND name='sales'");
                if (salesCheck.isEmpty) {
                  print('خطأ: جدول sales غير موجود!');
                  throw Exception('جدول sales غير موجود');
                }

                // التأكد من أن المبيعة موجودة
                final saleCheck = await txn
                    .rawQuery('SELECT id FROM sales WHERE id = ?', [saleId]);
                if (saleCheck.isEmpty) {
                  print('خطأ: المبيعة $saleId غير موجودة!');
                  throw Exception('المبيعة غير موجودة');
                }

                // إعادة المحاولة
                await txn.insert('installments', {
                  'sale_id': saleId,
                  'due_date': currentDate.toIso8601String(),
                  'amount': installmentAmount,
                  'paid': 0,
                  'paid_at': null,
                });
                print('تم إنشاء القسط ${i + 1} بنجاح بعد الإصلاح');
              } catch (retryError) {
                print('فشل في إصلاح المشكلة: $retryError');
                rethrow;
              }
            }
            // إضافة شهر للأقساط الشهرية
            currentDate = DateTime(
                currentDate.year, currentDate.month + 1, currentDate.day);
          }
        }
      }

      return saleId;
    });
  }

  Future<void> adjustProductQuantity(int productId, int delta) async {
    await _db.rawUpdate(
        'UPDATE products SET quantity = quantity + ? WHERE id = ?',
        [delta, productId]);
  }

  Future<List<Map<String, Object?>>> getLowStock() async {
    return _db.query('products',
        where: 'quantity <= min_quantity', orderBy: 'quantity ASC');
  }

  Future<List<Map<String, Object?>>> slowMovingProducts({int days = 30}) async {
    // products with no sales in X days
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return _db.rawQuery('''
      SELECT p.* FROM products p
      LEFT JOIN sale_items si ON si.product_id = p.id
      LEFT JOIN sales s ON s.id = si.sale_id AND s.created_at >= ?
      GROUP BY p.id
      HAVING COUNT(s.id) = 0
      ORDER BY p.updated_at IS NULL DESC, p.updated_at ASC
    ''', [since]);
  }

  Future<Map<String, double>> profitAndLoss(
      {DateTime? from, DateTime? to}) async {
    final String where = (from != null && to != null)
        ? "WHERE s.created_at BETWEEN ? AND ?"
        : '';
    final args = (from != null && to != null)
        ? [from.toIso8601String(), to.toIso8601String()]
        : <Object?>[];
    final sales = await _db.rawQuery(
        'SELECT IFNULL(SUM(total),0) t, IFNULL(SUM(profit),0) p FROM sales s $where',
        args);
    final expenses = await _db.rawQuery(
        'SELECT IFNULL(SUM(amount),0) e FROM expenses ${where.isEmpty ? '' : 'WHERE created_at BETWEEN ? AND ?'}',
        args);
    final totalSales = (sales.first['t'] as num).toDouble();
    final totalProfit = (sales.first['p'] as num).toDouble();
    final totalExpenses = (expenses.first['e'] as num).toDouble();
    return {
      'sales': totalSales,
      'profit': totalProfit,
      'expenses': totalExpenses,
      'net': totalProfit - totalExpenses,
    };
  }

  // Sales History
  Future<List<Map<String, Object?>>> getSalesHistory({
    DateTime? from,
    DateTime? to,
    String? type,
    String? query,
    bool sortDescending = true,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (from != null && to != null) {
      whereClause += 's.created_at BETWEEN ? AND ?';
      whereArgs.addAll([from.toIso8601String(), to.toIso8601String()]);
    }

    if (type != null && type.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 's.type = ?';
      whereArgs.add(type);
    }

    if (query != null && query.trim().isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(c.name LIKE ? OR p.name LIKE ? OR s.id LIKE ?)';
      final likeQuery = '%${query.trim()}%';
      whereArgs.addAll([likeQuery, likeQuery, likeQuery]);
    }

    final sales = await _db.rawQuery('''
      SELECT 
        s.*,
        c.name as customer_name,
        c.phone as customer_phone,
        GROUP_CONCAT(p.name || ' (' || si.quantity || 'x' || si.price || ')') as items_summary
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      LEFT JOIN sale_items si ON s.id = si.sale_id
      LEFT JOIN products p ON si.product_id = p.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      GROUP BY s.id
      ORDER BY s.id ${sortDescending ? 'DESC' : 'ASC'}
    ''', whereArgs);

    return sales;
  }

  Future<List<Map<String, Object?>>> getSaleItems(int saleId) async {
    return await _db.rawQuery('''
      SELECT 
        si.*,
        p.name as product_name,
        p.barcode
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      WHERE si.sale_id = ?
      ORDER BY si.id
    ''', [saleId]);
  }

  Future<Map<String, Object?>?> getSaleDetails(int saleId) async {
    final result = await _db.rawQuery('''
      SELECT 
        s.*,
        c.name as customer_name,
        c.phone as customer_phone,
        c.address as customer_address
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.id = ?
    ''', [saleId]);

    return result.isNotEmpty ? result.first : null;
  }

  Future<bool> deleteSale(int saleId) async {
    return await _db.transaction<bool>((txn) async {
      try {
        // Get sale to adjust debts if needed
        final sale = await txn.query('sales',
            where: 'id = ?', whereArgs: [saleId], limit: 1);
        // Get sale items to restore stock
        final saleItems = await txn.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [saleId],
        );

        // Restore stock for each item
        for (final item in saleItems) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [item['quantity'], item['product_id']],
          );
        }

        // Delete sale items
        await txn.delete(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [saleId],
        );

        // Delete any related installments
        await txn.delete(
          'installments',
          where: 'sale_id = ?',
          whereArgs: [saleId],
        );

        // Delete the sale
        final deletedRows = await txn.delete(
          'sales',
          where: 'id = ?',
          whereArgs: [saleId],
        );

        // Adjust customer debt if the deleted sale was credit
        if (deletedRows > 0 && sale.isNotEmpty) {
          final s = sale.first;
          if (s['type'] == 'credit' && s['customer_id'] != null) {
            await txn.rawUpdate(
              'UPDATE customers SET total_debt = MAX(IFNULL(total_debt,0) - ?, 0) WHERE id = ?',
              [(s['total'] as num).toDouble(), s['customer_id']],
            );
          }
        }

        return deletedRows > 0;
      } catch (e) {
        return false;
      }
    });
  }

  // Receivables and credit tracking (includes installments)
  Future<List<Map<String, Object?>>> receivablesByCustomer(
      {String? query}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      where.add('(c.name LIKE ? OR c.phone LIKE ?)');
      args.addAll([like, like]);
    }
    final sql = '''
      SELECT 
        c.id,
        c.name,
        c.phone,
        IFNULL(c.total_debt, 0) AS total_debt,
        IFNULL((
          SELECT SUM(s.total) FROM sales s 
          WHERE s.customer_id = c.id AND s.type = 'credit'
        ), 0) AS credit_debt,
        IFNULL((
          SELECT SUM(s.total - COALESCE(s.down_payment, 0)) FROM sales s 
          WHERE s.customer_id = c.id AND s.type = 'installment'
        ), 0) AS installment_debt,
        (
          SELECT MIN(s2.due_date) FROM sales s2 
          WHERE s2.customer_id = c.id AND s2.type = 'credit' AND s2.due_date IS NOT NULL
        ) AS next_credit_due_date,
        (
          SELECT MIN(i.due_date) FROM installments i
          JOIN sales s ON s.id = i.sale_id
          WHERE s.customer_id = c.id AND i.paid = 0
        ) AS next_installment_due_date,
        (
          SELECT COUNT(*) FROM installments i
          JOIN sales s ON s.id = i.sale_id
          WHERE s.customer_id = c.id AND i.paid = 0 AND i.due_date < ?
        ) AS overdue_installments_count
      FROM customers c
      WHERE IFNULL(c.total_debt, 0) > 0
      ${where.isNotEmpty ? 'AND ${where.join(' AND ')}' : ''}
      ORDER BY 
        (CASE WHEN next_credit_due_date IS NULL AND next_installment_due_date IS NULL THEN 1 ELSE 0 END),
        COALESCE(next_credit_due_date, next_installment_due_date) ASC,
        c.name ASC
    ''';
    args.insert(0, DateTime.now().toIso8601String());
    return _db.rawQuery(sql, args);
  }

  Future<List<Map<String, Object?>>> creditSales(
      {bool overdueOnly = false,
      int? customerId,
      DateTime? from,
      DateTime? to}) async {
    final where = <String>['s.type = "credit"'];
    final args = <Object?>[];
    if (customerId != null) {
      where.add('s.customer_id = ?');
      args.add(customerId);
    }
    if (from != null && to != null) {
      where.add('s.created_at BETWEEN ? AND ?');
      args.addAll([from.toIso8601String(), to.toIso8601String()]);
    }
    if (overdueOnly) {
      where.add('s.due_date IS NOT NULL AND s.due_date < ?');
      args.add(DateTime.now().toIso8601String());
    }
    final sql = '''
      SELECT s.*, c.name AS customer_name, c.phone AS customer_phone
      FROM sales s
      LEFT JOIN customers c ON c.id = s.customer_id
      WHERE ${where.join(' AND ')}
      ORDER BY (CASE WHEN s.due_date IS NULL THEN 1 ELSE 0 END), s.due_date ASC, s.created_at DESC
    ''';
    return _db.rawQuery(sql, args);
  }

  // Payment collection system
  Future<int> addPayment({
    required int customerId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  }) async {
    return _db.transaction<int>((txn) async {
      // Insert payment record
      final paymentId = await txn.insert('payments', {
        'customer_id': customerId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Reduce customer debt
      await txn.rawUpdate(
        'UPDATE customers SET total_debt = MAX(IFNULL(total_debt, 0) - ?, 0) WHERE id = ?',
        [amount, customerId],
      );

      // تقليل الأقساط المتبقية
      await _reduceInstallmentsFromPayment(txn, customerId, amount);

      return paymentId;
    });
  }

  /// تقليل الأقساط المتبقية عند الدفع الإضافي بالتساوي
  Future<void> _reduceInstallmentsFromPayment(
      DatabaseExecutor txn, int customerId, double paymentAmount) async {
    try {
      // الحصول على الأقساط المتبقية للعميل
      final unpaidInstallments = await txn.rawQuery('''
        SELECT i.* FROM installments i
        JOIN sales s ON s.id = i.sale_id
        WHERE s.customer_id = ? AND i.paid = 0 AND i.amount > 0
        ORDER BY i.due_date ASC
      ''', [customerId]);

      if (unpaidInstallments.isEmpty) {
        print('لا توجد أقساط متبقية للعميل $customerId');
        return;
      }

      final installmentCount = unpaidInstallments.length;
      final amountPerInstallment = paymentAmount / installmentCount;

      print('بدء تقليل الأقساط بالتساوي:');
      print('- عدد الأقساط المتبقية: $installmentCount');
      print('- المبلغ الإجمالي: $paymentAmount');
      print('- المبلغ لكل قسط: $amountPerInstallment');

      for (final installment in unpaidInstallments) {
        final installmentId = installment['id'] as int;
        final currentAmount = (installment['amount'] as num).toDouble();
        final newAmount =
            (currentAmount - amountPerInstallment).clamp(0.0, double.infinity);

        print('القسط $installmentId: $currentAmount → $newAmount');

        if (newAmount <= 0) {
          // القسط مدفوع بالكامل
          await txn.update(
            'installments',
            {
              'amount': 0.0,
              'paid': 1,
              'paid_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [installmentId],
          );
          print('تم دفع القسط $installmentId بالكامل');
        } else {
          // تقليل مبلغ القسط
          await txn.update(
            'installments',
            {'amount': newAmount},
            where: 'id = ?',
            whereArgs: [installmentId],
          );
          print('تم تقليل القسط $installmentId إلى $newAmount');
        }
      }

      print('انتهاء تقليل الأقساط بالتساوي');
    } catch (e) {
      print('خطأ في تقليل الأقساط: $e');
      // لا نريد إيقاف العملية إذا فشل تقليل الأقساط
    }
  }

  Future<List<Map<String, Object?>>> getCustomerPayments({
    int? customerId,
    DateTime? from,
    DateTime? to,
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (customerId != null) {
      where.add('p.customer_id = ?');
      args.add(customerId);
    }

    if (from != null && to != null) {
      where.add('p.payment_date BETWEEN ? AND ?');
      args.addAll([from.toIso8601String(), to.toIso8601String()]);
    }

    final sql = '''
      SELECT 
        p.*,
        c.name as customer_name,
        c.phone as customer_phone
      FROM payments p
      JOIN customers c ON c.id = p.customer_id
      ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
      ORDER BY p.payment_date DESC, p.created_at DESC
    ''';

    return _db.rawQuery(sql, args);
  }

  // Debt statistics and analytics
  Future<Map<String, double>> getDebtStatistics() async {
    final totalDebt = await _db.rawQuery('''
      SELECT IFNULL(SUM(total_debt), 0) as total FROM customers
    ''');

    final overdueDebt = await _db.rawQuery('''
      SELECT IFNULL(SUM(s.total), 0) as overdue
      FROM sales s
      WHERE s.type = 'credit' 
        AND s.due_date IS NOT NULL 
        AND s.due_date < ?
    ''', [DateTime.now().toIso8601String()]);

    final totalPayments = await _db.rawQuery('''
      SELECT IFNULL(SUM(amount), 0) as total FROM payments
    ''');

    final customersWithDebt = await _db.rawQuery('''
      SELECT COUNT(*) as count FROM customers WHERE total_debt > 0
    ''');

    return {
      'total_debt': (totalDebt.first['total'] as num).toDouble(),
      'overdue_debt': (overdueDebt.first['overdue'] as num).toDouble(),
      'total_payments': (totalPayments.first['total'] as num).toDouble(),
      'customers_with_debt':
          (customersWithDebt.first['count'] as num).toDouble(),
    };
  }

  // Debt aging report
  Future<List<Map<String, Object?>>> getDebtAgingReport() async {
    return _db.rawQuery('''
      SELECT 
        c.id,
        c.name,
        c.phone,
        c.total_debt,
        COUNT(CASE 
          WHEN s.due_date IS NULL THEN 1 
          WHEN s.due_date >= ? THEN 1 
          ELSE NULL 
        END) as current_count,
        COUNT(CASE 
          WHEN s.due_date < ? AND s.due_date >= ? THEN 1 
          ELSE NULL 
        END) as overdue_30_count,
        COUNT(CASE 
          WHEN s.due_date < ? AND s.due_date >= ? THEN 1 
          ELSE NULL 
        END) as overdue_60_count,
        COUNT(CASE 
          WHEN s.due_date < ? THEN 1 
          ELSE NULL 
        END) as overdue_90_count,
        SUM(CASE 
          WHEN s.due_date IS NULL THEN s.total 
          WHEN s.due_date >= ? THEN s.total 
          ELSE 0 
        END) as current_amount,
        SUM(CASE 
          WHEN s.due_date < ? AND s.due_date >= ? THEN s.total 
          ELSE 0 
        END) as overdue_30_amount,
        SUM(CASE 
          WHEN s.due_date < ? AND s.due_date >= ? THEN s.total 
          ELSE 0 
        END) as overdue_60_amount,
        SUM(CASE 
          WHEN s.due_date < ? THEN s.total 
          ELSE 0 
        END) as overdue_90_amount
      FROM customers c
      LEFT JOIN sales s ON s.customer_id = c.id AND s.type = 'credit'
      WHERE c.total_debt > 0
      GROUP BY c.id, c.name, c.phone, c.total_debt
      ORDER BY c.total_debt DESC
    ''', [
      DateTime.now().toIso8601String(), // current
      DateTime.now().toIso8601String(), // overdue_30
      DateTime.now()
          .subtract(Duration(days: 30))
          .toIso8601String(), // overdue_30
      DateTime.now()
          .subtract(Duration(days: 30))
          .toIso8601String(), // overdue_60
      DateTime.now()
          .subtract(Duration(days: 60))
          .toIso8601String(), // overdue_60
      DateTime.now()
          .subtract(Duration(days: 60))
          .toIso8601String(), // overdue_90
      DateTime.now().toIso8601String(), // current_amount
      DateTime.now().toIso8601String(), // overdue_30_amount
      DateTime.now()
          .subtract(Duration(days: 30))
          .toIso8601String(), // overdue_30_amount
      DateTime.now()
          .subtract(Duration(days: 30))
          .toIso8601String(), // overdue_60_amount
      DateTime.now()
          .subtract(Duration(days: 60))
          .toIso8601String(), // overdue_60_amount
      DateTime.now()
          .subtract(Duration(days: 60))
          .toIso8601String(), // overdue_90_amount
    ]);
  }

  // Overdue debt alerts
  Future<List<Map<String, Object?>>> getOverdueDebts(
      {int daysOverdue = 0}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOverdue));
    return _db.rawQuery('''
      SELECT 
        s.*,
        c.name as customer_name,
        c.phone as customer_phone,
        c.address as customer_address,
        julianday('now') - julianday(s.due_date) as days_overdue
      FROM sales s
      JOIN customers c ON c.id = s.customer_id
      WHERE s.type = 'credit' 
        AND s.due_date IS NOT NULL 
        AND s.due_date < ?
      ORDER BY s.due_date ASC
    ''', [cutoffDate.toIso8601String()]);
  }

  // Delete payment
  Future<bool> deletePayment(int paymentId) async {
    return _db.transaction<bool>((txn) async {
      try {
        // Get payment details
        final payment = await txn.query('payments',
            where: 'id = ?', whereArgs: [paymentId], limit: 1);

        if (payment.isEmpty) return false;

        final p = payment.first;
        final customerId = p['customer_id'] as int;
        final amount = (p['amount'] as num).toDouble();

        // Delete payment
        final deletedRows = await txn
            .delete('payments', where: 'id = ?', whereArgs: [paymentId]);

        if (deletedRows > 0) {
          // Restore customer debt
          await txn.rawUpdate(
            'UPDATE customers SET total_debt = IFNULL(total_debt, 0) + ? WHERE id = ?',
            [amount, customerId],
          );
        }

        return deletedRows > 0;
      } catch (e) {
        return false;
      }
    });
  }

  /// دالة شاملة لتنظيف قاعدة البيانات من المراجع القديمة
  Future<void> comprehensiveCleanup() async {
    try {
      print('Starting comprehensive database cleanup...');

      await _db.execute('PRAGMA foreign_keys = OFF');

      // حذف جدول sales_old إذا كان موجوداً
      await _db.execute('DROP TABLE IF EXISTS sales_old');

      // البحث عن جميع الكائنات التي تشير إلى sales_old في المخطط الرئيسي
      final mainObjects = await _db.rawQuery('''
        SELECT type, name, sql FROM sqlite_master 
        WHERE type IN ('trigger', 'view', 'index', 'table') 
        AND (IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%')
        ORDER BY type, name
      ''');

      print(
          'Found ${mainObjects.length} objects in main schema referencing sales_old');

      for (final row in mainObjects) {
        final type = row['type']?.toString();
        final name = row['name']?.toString();
        if (type != null && name != null && name.isNotEmpty) {
          try {
            String dropCommand;
            switch (type) {
              case 'view':
                dropCommand = 'DROP VIEW IF EXISTS $name';
                break;
              case 'index':
                dropCommand = 'DROP INDEX IF EXISTS $name';
                break;
              case 'trigger':
                dropCommand = 'DROP TRIGGER IF EXISTS $name';
                break;
              case 'table':
                if (name == 'sales_old') {
                  dropCommand = 'DROP TABLE IF EXISTS $name';
                } else {
                  continue; // Skip other tables
                }
                break;
              default:
                continue;
            }
            await _db.execute(dropCommand);
            print('Dropped main schema $type: $name');
          } catch (e) {
            print('Error dropping main schema $type $name: $e');
          }
        }
      }

      // البحث عن جميع الكائنات التي تشير إلى sales_old في المخطط المؤقت
      final tempObjects = await _db.rawQuery('''
        SELECT type, name, sql FROM sqlite_temp_master 
        WHERE type IN ('trigger', 'view', 'index', 'table') 
        AND (IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%')
        ORDER BY type, name
      ''');

      print(
          'Found ${tempObjects.length} objects in temp schema referencing sales_old');

      for (final row in tempObjects) {
        final type = row['type']?.toString();
        final name = row['name']?.toString();
        if (type != null && name != null && name.isNotEmpty) {
          try {
            String dropCommand;
            switch (type) {
              case 'view':
                dropCommand = 'DROP VIEW IF EXISTS $name';
                break;
              case 'index':
                dropCommand = 'DROP INDEX IF EXISTS $name';
                break;
              case 'trigger':
                dropCommand = 'DROP TRIGGER IF EXISTS $name';
                break;
              case 'table':
                if (name == 'sales_old') {
                  dropCommand = 'DROP TABLE IF EXISTS $name';
                } else {
                  continue; // Skip other tables
                }
                break;
              default:
                continue;
            }
            await _db.execute(dropCommand);
            print('Dropped temp schema $type: $name');
          } catch (e) {
            print('Error dropping temp schema $type $name: $e');
          }
        }
      }

      // إعادة تمكين المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');

      // إعادة إنشاء الفهارس
      await _createIndexes(_db);

      // التأكد من وجود الجداول الأساسية
      await _ensureCategorySchemaOn(_db);

      print('Comprehensive cleanup completed successfully');
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
      print('Error during comprehensive cleanup: $e');
      rethrow;
    }
  }

  // دالة تعديل القسط
  Future<void> updateInstallment(
      int installmentId, double newAmount, DateTime newDueDate) async {
    await _db.update(
      'installments',
      {
        'amount': newAmount,
        'due_date': newDueDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [installmentId],
    );
  }

  // دالة حذف القسط
  Future<void> deleteInstallment(int installmentId) async {
    await _db.transaction((txn) async {
      // الحصول على بيانات القسط
      final installment = await txn.query(
        'installments',
        where: 'id = ?',
        whereArgs: [installmentId],
      );

      if (installment.isNotEmpty) {
        final saleId = installment.first['sale_id'] as int;
        final amount = (installment.first['amount'] as num).toDouble();

        // الحصول على بيانات البيع
        final sale = await txn.query(
          'sales',
          where: 'id = ?',
          whereArgs: [saleId],
        );

        if (sale.isNotEmpty) {
          final customerId = sale.first['customer_id'] as int;

          // إضافة المبلغ إلى دين العميل
          await txn.rawUpdate(
            'UPDATE customers SET total_debt = IFNULL(total_debt, 0) + ? WHERE id = ?',
            [amount, customerId],
          );
        }
      }

      // حذف القسط
      await txn.delete(
        'installments',
        where: 'id = ?',
        whereArgs: [installmentId],
      );
    });
  }

  // دالة الحصول على الأقساط المتأخرة
  Future<List<Map<String, dynamic>>> getOverdueInstallments() async {
    final now = DateTime.now().toIso8601String();
    return _db.rawQuery('''
      SELECT 
        i.*,
        s.customer_id,
        c.name as customer_name,
        c.phone as customer_phone,
        c.address as customer_address,
        julianday('now') - julianday(i.due_date) as days_overdue
      FROM installments i
      JOIN sales s ON i.sale_id = s.id
      JOIN customers c ON s.customer_id = c.id
      WHERE i.paid = 0 
      AND i.due_date < ?
      ORDER BY i.due_date ASC
    ''', [now]);
  }

  // دالة الحصول على الأقساط المستحقة هذا الشهر
  Future<List<Map<String, dynamic>>> getCurrentMonthInstallments() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth = DateTime(now.year, now.month + 1, 0).toIso8601String();

    return _db.rawQuery('''
      SELECT 
        i.*,
        s.customer_id,
        c.name as customer_name,
        c.phone as customer_phone,
        c.address as customer_address
      FROM installments i
      JOIN sales s ON i.sale_id = s.id
      JOIN customers c ON s.customer_id = c.id
      WHERE i.paid = 0 
      AND i.due_date >= ? 
      AND i.due_date <= ?
      ORDER BY i.due_date ASC
    ''', [startOfMonth, endOfMonth]);
  }

  // دالة تنظيف شاملة لجميع triggers
  Future<void> cleanupAllTriggers() async {
    await _db.transaction((txn) async {
      try {
        // البحث عن جميع triggers
        final allTriggers = await txn.rawQuery('''
          SELECT name, sql FROM sqlite_master 
          WHERE type = 'trigger'
        ''');

        for (final trigger in allTriggers) {
          final name = trigger['name']?.toString();
          final sql = trigger['sql']?.toString();

          if (name != null && sql != null) {
            // حذف triggers التي تحتوي على sales_old أو أي مراجع مشكلة
            if (sql.contains('sales_old') ||
                sql.contains('main.sales_old') ||
                name.contains('sales_old')) {
              try {
                await txn.execute('DROP TRIGGER IF EXISTS $name');
                print('Dropped problematic trigger: $name');
              } catch (e) {
                print('Error dropping trigger $name: $e');
              }
            }
          }
        }

        print('Trigger cleanup completed');
      } catch (e) {
        print('Error during trigger cleanup: $e');
        rethrow;
      }
    });
  }

  // دالة تنظيف شاملة لجميع مراجع sales_old
  Future<void> comprehensiveSalesOldCleanup() async {
    await _db.transaction((txn) async {
      try {
        // تعطيل المفاتيح الخارجية مؤقتاً
        await txn.execute('PRAGMA foreign_keys = OFF');

        // حذف جدول sales_old إذا كان موجوداً
        await txn.execute('DROP TABLE IF EXISTS sales_old');

        // البحث عن جميع الكائنات التي تحتوي على مراجع لـ sales_old
        final allObjects = await txn.rawQuery('''
          SELECT name, type, sql FROM sqlite_master 
          WHERE (sql LIKE '%sales_old%' OR name LIKE '%sales_old%')
          AND type IN ('trigger', 'view', 'index')
          UNION ALL
          SELECT name, type, sql FROM sqlite_temp_master 
          WHERE (sql LIKE '%sales_old%' OR name LIKE '%sales_old%')
          AND type IN ('trigger', 'view', 'index')
        ''');

        for (final obj in allObjects) {
          final name = obj['name']?.toString();
          final type = obj['type']?.toString();
          if (name != null && name.isNotEmpty) {
            try {
              switch (type) {
                case 'trigger':
                  await txn.execute('DROP TRIGGER IF EXISTS $name');
                  print('Dropped trigger: $name');
                  break;
                case 'view':
                  await txn.execute('DROP VIEW IF EXISTS $name');
                  print('Dropped view: $name');
                  break;
                case 'index':
                  await txn.execute('DROP INDEX IF EXISTS $name');
                  print('Dropped index: $name');
                  break;
              }
            } catch (e) {
              print('Error dropping $type $name: $e');
            }
          }
        }

        // إعادة تفعيل المفاتيح الخارجية
        await txn.execute('PRAGMA foreign_keys = ON');

        print('Comprehensive sales_old cleanup completed');
      } catch (e) {
        // التأكد من إعادة تفعيل المفاتيح الخارجية حتى لو فشل التنظيف
        try {
          await txn.execute('PRAGMA foreign_keys = ON');
        } catch (_) {}
        print('Error during comprehensive sales_old cleanup: $e');
        rethrow;
      }
    });
  }

  // دالة الحصول على إحصائيات الأقساط
  Future<Map<String, dynamic>> getInstallmentStatistics() async {
    final now = DateTime.now().toIso8601String();

    final totalInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
    ''');

    final paidInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE paid = 1
    ''');

    final unpaidInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE paid = 0
    ''');

    final overdueInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE paid = 0 AND due_date < ?
    ''', [now]);

    return {
      'total_count': (totalInstallments.first['count'] as int),
      'total_amount':
          (totalInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'paid_count': (paidInstallments.first['count'] as int),
      'paid_amount':
          (paidInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'unpaid_count': (unpaidInstallments.first['count'] as int),
      'unpaid_amount':
          (unpaidInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'overdue_count': (overdueInstallments.first['count'] as int),
      'overdue_amount':
          (overdueInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // دالة الحصول على ملخص أقساط فاتورة محددة
  Future<Map<String, dynamic>> getSaleInstallmentSummary(int saleId) async {
    final now = DateTime.now().toIso8601String();

    final totalInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE sale_id = ?
    ''', [saleId]);

    final paidInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE sale_id = ? AND paid = 1
    ''', [saleId]);

    final unpaidInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE sale_id = ? AND paid = 0
    ''', [saleId]);

    final overdueInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE sale_id = ? AND paid = 0 AND due_date < ?
    ''', [saleId, now]);

    return {
      'totalDebt':
          (totalInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'totalPaid': (paidInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'remainingDebt':
          (unpaidInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'overdueAmount':
          (overdueInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'totalCount': (totalInstallments.first['count'] as int),
      'paidCount': (paidInstallments.first['count'] as int),
      'unpaidCount': (unpaidInstallments.first['count'] as int),
      'overdueCount': (overdueInstallments.first['count'] as int),
    };
  }
}
