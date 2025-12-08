// ignore_for_file: curly_braces_in_flow_control_structures, unused_local_variable

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class DatabaseService {
  static const String _dbName = 'pos_office.db';
  static const int _dbVersion = 9;

  late Database _db;
  late String _dbPath;

  Database get database => _db;
  String get databasePath => _dbPath;

  Future<void> initialize() async {
    // تهيئة قاعدة البيانات حسب المنصة
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // للمنصات المكتبية - استخدم sqflite_common_ffi
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('Desktop platform: Using sqflite_common_ffi');
    } else {
      // للمنصات المحمولة (Android/iOS) - استخدم sqflite العادي
      print('Mobile platform: Using default sqflite');
    }

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
        if (oldVersion < 7) {
          await _migrateToV7(db);
        }
        if (oldVersion < 8) {
          await _migrateToV8(db);
        }
        if (oldVersion < 9) {
          await _migrateToV9(db);
        }
        // Ensure no legacy triggers/views remain that reference old temp tables
        await _cleanupOrphanObjects(db);
        await _ensureCategorySchemaOn(db);
        await _createIndexes(db);
      },
    );
    // إعدادات أساسية فقط
    await _db.execute('PRAGMA foreign_keys = ON');
    await _createIndexes(_db);

    // فحص وإصلاح المستخدمين الافتراضيين فقط
    await checkAndFixDefaultUsers();
  }

  Future<void> reopen() async {
    await _db.close();
    _db = await openDatabase(_dbPath, version: _dbVersion);
    await _db.execute('PRAGMA foreign_keys = ON');
    await _createIndexes(_db);
    await _cleanupOrphanObjects(_db);
    await _ensureCategorySchemaOn(_db);
    await _ensureSaleItemsDiscountColumn(_db);
    await checkAndFixDefaultUsers();
    await cleanupSalesOldReferences();
  }

  /// Ensure discount_percent column exists on sale_items
  Future<void> _ensureSaleItemsDiscountColumn(DatabaseExecutor db) async {
    try {
      final cols = await db.rawQuery("PRAGMA table_info('sale_items')");
      final hasDiscount =
          cols.any((c) => (c['name']?.toString() ?? '') == 'discount_percent');
      if (!hasDiscount) {
        await db.execute(
            "ALTER TABLE sale_items ADD COLUMN discount_percent REAL NOT NULL DEFAULT 0");
      }
    } catch (e) {
      // ignore
    }
  }

  /// Force a complete cleanup of orphaned database objects
  /// This method can be called to resolve database corruption issues
  Future<void> forceCleanup() async {
    try {
      await _cleanupOrphanObjects(_db);
      await _createIndexes(_db);
      await _ensureCategorySchemaOn(_db);
    } catch (e) {
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
          // حفظ البيانات الموجودة
          final existingData = await _db.rawQuery('SELECT * FROM installments');

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
        } else {}
      } else {}

      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
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
          } catch (e) {
            // Continue with other objects even if one fails
          }
        }
      }

      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
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
      } catch (e) {
        debugPrint('Error cleaning up orphaned sale_items: $e');
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
              discount_percent REAL NOT NULL DEFAULT 0,
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
        // If even this fails, we might be in a bad state
        // Consider logging or notifying the user
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
          discount_percent REAL NOT NULL DEFAULT 0,
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

      // Re-enable foreign keys
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
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
          }
        }
      } catch (e) {
        // ignore
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

    // Expenses
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category)');
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
        role TEXT NOT NULL CHECK(role IN ('manager','supervisor','employee')),
        employee_code TEXT UNIQUE NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
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
        down_payment REAL DEFAULT 0,
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
        discount_percent REAL NOT NULL DEFAULT 0,
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
        category TEXT NOT NULL DEFAULT 'عام',
        description TEXT,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
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

    // التحقق من وجود العمود قبل إضافته
    try {
      final cols = await db.rawQuery("PRAGMA table_info('products')");
      final hasCategoryId =
          cols.any((c) => (c['name']?.toString() ?? '') == 'category_id');

      if (!hasCategoryId) {
        await db.execute('ALTER TABLE products ADD COLUMN category_id INTEGER');
        print('Added category_id column to products table');
      } else {
        print('category_id column already exists in products table');
      }
    } catch (e) {
      print('Error checking/adding category_id column: $e');
      // column already exists or other error
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

  Future<void> _migrateToV7(Database db) async {
    // تحديث جدول المستخدمين لدعم النظام الجديد
    try {
      debugPrint('بدء Migration V7...');

      // إعادة إنشاء جدول المستخدمين لدعم supervisor
      await db.execute('PRAGMA foreign_keys=off');

      // إنشاء جدول مؤقت
      await db.execute('''
        CREATE TABLE users_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          role TEXT NOT NULL CHECK(role IN ('manager','supervisor','employee')),
          employee_code TEXT UNIQUE NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');

      // نسخ البيانات الموجودة
      await db.execute('''
        INSERT INTO users_new (id, name, username, password, role, employee_code, active, created_at, updated_at)
        SELECT 
          id, 
          name, 
          username, 
          password, 
          role,
          COALESCE(employee_code, 'LEGACY' || id) as employee_code,
          active,
          COALESCE(created_at, datetime('now')) as created_at,
          datetime('now') as updated_at
        FROM users;
      ''');

      // حذف الجدول القديم
      await db.execute('DROP TABLE users');

      // إعادة تسمية الجدول الجديد
      await db.execute('ALTER TABLE users_new RENAME TO users');

      await db.execute('PRAGMA foreign_keys=on');
      debugPrint('تم إعادة إنشاء جدول المستخدمين بنجاح');

      // تحديث البيانات الموجودة
      final now = DateTime.now().toIso8601String();
      final existingUsers = await db.query('users');
      debugPrint('المستخدمون الموجودون: ${existingUsers.length}');

      for (final user in existingUsers) {
        await db.update(
            'users',
            {
              'employee_code': user['employee_code'] ?? 'LEGACY001',
              'created_at': user['created_at'] ?? now,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [user['id']]);
      }

      // إضافة المستخدمين الافتراضيين
      final defaultUsers = [
        {
          'name': 'المدير',
          'username': 'manager',
          'password': 'admin123',
          'role': 'manager',
          'employee_code': 'A1',
          'active': 1,
          'created_at': now,
          'updated_at': now,
        },
        {
          'name': 'المشرف',
          'username': 'supervisor',
          'password': 'super123',
          'role': 'supervisor',
          'employee_code': 'S1',
          'active': 1,
          'created_at': now,
          'updated_at': now,
        },
        {
          'name': 'الموظف',
          'username': 'employee',
          'password': 'emp123',
          'role': 'employee',
          'employee_code': 'C1',
          'active': 1,
          'created_at': now,
          'updated_at': now,
        },
      ];

      for (final user in defaultUsers) {
        final existing = await db.query('users',
            where: 'username = ?', whereArgs: [user['username']], limit: 1);

        if (existing.isEmpty) {
          await db.insert('users', user);
          debugPrint('تم إضافة مستخدم: ${user['username']}');
        } else {
          debugPrint('المستخدم موجود بالفعل: ${user['username']}');
        }
      }

      debugPrint('انتهى Migration V7 بنجاح');
    } catch (e) {
      debugPrint('خطأ في Migration V7: $e');
    }
  }

  Future<void> _migrateToV8(Database db) async {
    // إصلاح جدول المستخدمين لدعم supervisor
    try {
      debugPrint('بدء Migration V8 - إصلاح جدول المستخدمين...');

      // إعادة إنشاء جدول المستخدمين لدعم supervisor
      await db.execute('PRAGMA foreign_keys=off');

      // إنشاء جدول مؤقت
      await db.execute('''
        CREATE TABLE users_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          role TEXT NOT NULL CHECK(role IN ('manager','supervisor','employee')),
          employee_code TEXT UNIQUE NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');

      // نسخ البيانات الموجودة
      await db.execute('''
        INSERT INTO users_new (id, name, username, password, role, employee_code, active, created_at, updated_at)
        SELECT 
          id, 
          name, 
          username, 
          password, 
          role,
          COALESCE(employee_code, 'LEGACY' || id) as employee_code,
          active,
          COALESCE(created_at, datetime('now')) as created_at,
          datetime('now') as updated_at
        FROM users;
      ''');

      // حذف الجدول القديم
      await db.execute('DROP TABLE users');

      // إعادة تسمية الجدول الجديد
      await db.execute('ALTER TABLE users_new RENAME TO users');

      await db.execute('PRAGMA foreign_keys=on');
      debugPrint('تم إعادة إنشاء جدول المستخدمين بنجاح في V8');

      // إضافة المستخدمين الافتراضيين
      final now = DateTime.now().toIso8601String();
      final defaultUsers = [
        {
          'name': 'المدير',
          'username': 'manager',
          'password': 'admin123',
          'role': 'manager',
          'employee_code': 'A1',
          'active': 1,
          'created_at': now,
          'updated_at': now,
        },
        {
          'name': 'المشرف',
          'username': 'supervisor',
          'password': 'super123',
          'role': 'supervisor',
          'employee_code': 'S1',
          'active': 1,
          'created_at': now,
          'updated_at': now,
        },
        {
          'name': 'الموظف',
          'username': 'employee',
          'password': 'emp123',
          'role': 'employee',
          'employee_code': 'C1',
          'active': 1,
          'created_at': now,
          'updated_at': now,
        },
      ];

      for (final user in defaultUsers) {
        final existing = await db.query('users',
            where: 'username = ?', whereArgs: [user['username']], limit: 1);

        if (existing.isEmpty) {
          await db.insert('users', user);
          debugPrint('تم إضافة مستخدم في V8: ${user['username']}');
        } else {
          debugPrint('المستخدم موجود بالفعل في V8: ${user['username']}');
        }
      }

      debugPrint('انتهى Migration V8 بنجاح');
    } catch (e) {
      debugPrint('خطأ في Migration V8: $e');
    }
  }

  Future<void> _migrateToV9(Database db) async {
    // تحديث جدول المصروفات لإضافة حقول جديدة
    try {
      debugPrint('بدء Migration V9 - تحديث جدول المصروفات...');

      // التحقق من وجود الأعمدة الجديدة
      final cols = await db.rawQuery("PRAGMA table_info('expenses')");
      final columnNames = cols.map((c) => c['name']?.toString() ?? '').toList();

      // إضافة الأعمدة الجديدة إذا لم تكن موجودة
      if (!columnNames.contains('category')) {
        await db.execute(
            'ALTER TABLE expenses ADD COLUMN category TEXT NOT NULL DEFAULT \'عام\'');
        debugPrint('تم إضافة عمود category');
      }

      if (!columnNames.contains('description')) {
        await db.execute('ALTER TABLE expenses ADD COLUMN description TEXT');
        debugPrint('تم إضافة عمود description');
      }

      if (!columnNames.contains('expense_date')) {
        // إضافة عمود expense_date واستخدام created_at كقيمة افتراضية
        await db.execute('ALTER TABLE expenses ADD COLUMN expense_date TEXT');
        // نسخ created_at إلى expense_date للبيانات الموجودة
        await db.execute(
            'UPDATE expenses SET expense_date = created_at WHERE expense_date IS NULL');
        // جعل الحقل NOT NULL بعد نسخ البيانات
        await db.execute('''
          CREATE TABLE expenses_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL DEFAULT 'عام',
            description TEXT,
            expense_date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT
          );
        ''');
        await db.execute('''
          INSERT INTO expenses_new (id, title, amount, category, description, expense_date, created_at, updated_at)
          SELECT id, title, amount, COALESCE(category, 'عام'), description, COALESCE(expense_date, created_at), created_at, COALESCE(updated_at, created_at)
          FROM expenses;
        ''');
        await db.execute('DROP TABLE expenses');
        await db.execute('ALTER TABLE expenses_new RENAME TO expenses');
        // تحديث columnNames بعد إعادة إنشاء الجدول
        final newCols = await db.rawQuery("PRAGMA table_info('expenses')");
        final newColumnNames =
            newCols.map((c) => c['name']?.toString() ?? '').toList();
        columnNames.clear();
        columnNames.addAll(newColumnNames);
        debugPrint('تم إضافة عمود expense_date');
      }

      // التحقق مرة أخرى من updated_at بعد إعادة إنشاء الجدول
      if (!columnNames.contains('updated_at')) {
        try {
          await db.execute('ALTER TABLE expenses ADD COLUMN updated_at TEXT');
          debugPrint('تم إضافة عمود updated_at');
        } catch (e) {
          debugPrint('عمود updated_at موجود بالفعل أو خطأ: $e');
        }
      }

      debugPrint('انتهى Migration V9 بنجاح');
    } catch (e) {
      debugPrint('خطأ في Migration V9: $e');
    }
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now().toIso8601String();
    debugPrint('بدء إنشاء البيانات الافتراضية...');

    // إنشاء المستخدمين الافتراضيين
    final defaultUsers = [
      {
        'name': 'المدير',
        'username': 'manager',
        'password': _sha256Hex('admin123'),
        'role': 'manager',
        'employee_code': 'A1',
        'active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'name': 'المشرف',
        'username': 'supervisor',
        'password': _sha256Hex('super123'),
        'role': 'supervisor',
        'employee_code': 'S1',
        'active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'name': 'الموظف',
        'username': 'employee',
        'password': _sha256Hex('emp123'),
        'role': 'employee',
        'employee_code': 'C1',
        'active': 1,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final user in defaultUsers) {
      final existing = await db.query('users',
          where: 'username = ?', whereArgs: [user['username']], limit: 1);

      if (existing.isEmpty) {
        await db.insert('users', user);
        debugPrint('تم إنشاء مستخدم جديد: ${user['username']}');
      } else {
        await db.update('users', user,
            where: 'username = ?', whereArgs: [user['username']]);
        debugPrint('تم تحديث مستخدم موجود: ${user['username']}');
      }
    }

    // التأكد من وجود المستخدم الموحد للتوافق مع الإصدارات القديمة
    final existingAdmin = await db.query('users',
        where: 'username = ?', whereArgs: ['admin'], limit: 1);

    if (existingAdmin.isNotEmpty) {
      // حذف المستخدم القديم "admin" لأنه يسبب تضارب
      await db.delete('users', where: 'username = ?', whereArgs: ['admin']);
      debugPrint('تم حذف المستخدم القديم admin لتجنب التضارب');
    }
  }

  // Simple helpers for common queries used early in development
  Future<Map<String, Object?>?> findUserByCredentials(
      String username, String password) async {
    // جلب المستخدم بالاسم والتأكد من كونه فعّالاً
    final result = await _db.query(
      'users',
      where: 'username = ? AND active = 1',
      whereArgs: [username],
      limit: 1,
    );

    if (result.isEmpty) {
      debugPrint('لم يتم العثور على مستخدم فعّال بهذا الاسم');
      return null;
    }

    final user = result.first;
    final stored = (user['password'] ?? '').toString();

    // تحقق كلمة المرور: دعم نص صريح تاريخي أو SHA-256 سداسي حديث
    bool matches = false;
    try {
      // حساب SHA-256 للنص المدخل
      // ملاحظة: نستخدم crypto في طبقة أعلى لتجنّب استيراد هنا إذا لم يكن ضرورياً،
      // لكن لأجل الاكتفاء الذاتي سنحوّل هنا باستخدام صيغة بسيطة عبر دارت.
      // سنستخدم صيغة مقارنة ثنائية: إذا تخزين سداسي بطول 64 ويماثل هاش الإدخال.
      final hashed = _sha256Hex(password);
      final isHex64 =
          RegExp(r'^[a-f0-9]{64} ?$', caseSensitive: false).hasMatch(stored);
      if (stored == password) {
        matches = true; // توافق نص صريح قديم
      } else if (isHex64 && stored.toLowerCase() == hashed) {
        matches = true; // توافق كلمة مرور مهدّدة SHA-256
      } else {
        matches = false;
      }
    } catch (_) {
      matches = stored == password;
    }

    if (!matches) {
      debugPrint('بيانات الدخول غير صحيحة للمستخدم: $username');
      return null;
    }

    return user;
  }

  // حساب SHA-256 وإرجاعه كنص سداسي صغير الأحرف
  String _sha256Hex(String input) {
    // تجنّب إضافة تبعية مباشرة هنا: سنستدعي crypto عبر MethodChannel ليس مناسباً.
    // لذلك سنستخدم dart:convert و package:crypto في أعلى الملف إن كانت مستوردة.
    // لضمان العمل حتى إن لم تتوفر، نتحقق ديناميكياً عبر try/catch في الاستدعاء.
    // هنا نفترض تواجد crypto حسب pubspec.
    // ignore: avoid_print
    try {
      // سيستبدل Dart المحوّل عند البناء حسب الاستيراد أعلى الملف
      // نكتب الاستدعاءات بشكل منعزل لتجنب أخطاء إن لم تتوفر.
      // سيتم حقن الدوال فعلياً عبر imports الموجودة في الملف.
    } catch (_) {}
    // تنفيذ فعلي باستخدام crypto
    // سيتم حقنه عبر imports أعلى الملف: import 'dart:convert'; import 'package:crypto/crypto.dart';
    // نستخدم dynamic للسلامة في التحويل بدون إنكسار عند تحليل ثابت
    final dynamic utf8Dyn = utf8;
    final dynamic sha256Dyn = sha256;
    final bytes = utf8Dyn.encode(input) as List<int>;
    final digest = sha256Dyn.convert(bytes);
    return digest.toString();
  }

  // updateUserPassword removed: password changes are disabled

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
    // التحقق من صحة البيانات
    if (values['name'] == null ||
        (values['name'] as String?)?.trim().isEmpty == true) {
      throw Exception('اسم المنتج مطلوب');
    }
    final price = (values['price'] as num?)?.toDouble() ?? 0.0;
    if (values['price'] == null || price < 0) {
      throw Exception('السعر يجب أن يكون أكبر من أو يساوي صفر');
    }
    final quantity = (values['quantity'] as int?) ?? 0;
    if (values['quantity'] == null || quantity < 0) {
      throw Exception('الكمية يجب أن تكون أكبر من أو تساوي صفر');
    }

    // التحقق من الباركود إذا كان موجوداً
    if (values['barcode'] != null &&
        (values['barcode'] as String?)?.trim().isNotEmpty == true) {
      final barcode = (values['barcode'] as String).trim();
      if (await isBarcodeExists(barcode)) {
        throw Exception('الباركود موجود بالفعل');
      }
    }

    values['created_at'] = DateTime.now().toIso8601String();
    return _db.insert('products', values,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  /// التحقق من وجود باركود في قاعدة البيانات
  Future<bool> isBarcodeExists(String barcode) async {
    if (barcode.trim().isEmpty) return false;
    final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE barcode = ?',
        [barcode.trim()]);
    return (result.first['count'] as int) > 0;
  }

  Future<int> updateProduct(int id, Map<String, Object?> values) async {
    // التحقق من وجود المنتج
    final product =
        await _db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    if (product.isEmpty) {
      throw Exception('المنتج غير موجود');
    }

    // التحقق من صحة البيانات
    if (values['name'] != null &&
        (values['name'] as String?)?.trim().isEmpty == true) {
      throw Exception('اسم المنتج لا يمكن أن يكون فارغاً');
    }
    if (values['price'] != null) {
      final price = (values['price'] as num?)?.toDouble() ?? 0.0;
      if (price < 0) {
        throw Exception('السعر يجب أن يكون أكبر من أو يساوي صفر');
      }
    }
    if (values['quantity'] != null) {
      final quantity = (values['quantity'] as int?) ?? 0;
      if (quantity < 0) {
        throw Exception('الكمية يجب أن تكون أكبر من أو تساوي صفر');
      }
    }

    // التحقق من الباركود إذا كان موجوداً
    if (values['barcode'] != null &&
        (values['barcode'] as String?)?.trim().isNotEmpty == true) {
      final barcode = (values['barcode'] as String).trim();
      final existing = await _db.query('products',
          where: 'barcode = ? AND id != ?', whereArgs: [barcode, id], limit: 1);
      if (existing.isNotEmpty) {
        throw Exception('الباركود موجود بالفعل لمنتج آخر');
      }
    }

    values['updated_at'] = DateTime.now().toIso8601String();
    return _db.update('products', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    return _db.transaction<int>((txn) async {
      try {
        // التحقق من وجود المنتج
        final product = await txn.query('products',
            where: 'id = ?', whereArgs: [id], limit: 1);
        if (product.isEmpty) {
          return 0; // المنتج غير موجود
        }

        // First, get all sales that have items with this product
        final salesWithProduct = await txn.rawQuery('''
          SELECT DISTINCT s.id FROM sales s
          JOIN sale_items si ON s.id = si.sale_id
          WHERE si.product_id = ?
        ''', [id]);

        // Delete all sale_items that reference this product
        await txn
            .delete('sale_items', where: 'product_id = ?', whereArgs: [id]);

        // Delete installments for sales that only had this product
        for (final sale in salesWithProduct) {
          final saleId = sale['id'] as int;

          // Check if this sale has any remaining items
          final remainingItems = await txn.rawQuery('''
            SELECT COUNT(*) as count FROM sale_items WHERE sale_id = ?
          ''', [saleId]);

          final itemCount = remainingItems.first['count'] as int;

          // If no items remain, delete the sale and its installments
          if (itemCount == 0) {
            await txn.delete('installments',
                where: 'sale_id = ?', whereArgs: [saleId]);
            await txn.delete('sales', where: 'id = ?', whereArgs: [saleId]);
          }
        }

        // Then delete the product
        return await txn.delete('products', where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        rethrow;
      }
    });
  }

  /// Delete product with cascade option - removes related sale_items first
  Future<int> deleteProductWithCascade(int id) async {
    return _db.transaction<int>((txn) async {
      // First delete all sale_items that reference this product
      await txn.delete('sale_items', where: 'product_id = ?', whereArgs: [id]);

      // Then delete the product
      return txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Get count of sale_items that reference a product
  Future<int> getProductSaleItemsCount(int productId) async {
    final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM sale_items WHERE product_id = ?',
        [productId]);
    return result.first['count'] as int;
  }

  /// Clean up orphaned installments (installments without valid sales)
  Future<int> cleanupOrphanedInstallments() async {
    try {
      // Delete installments that reference non-existent sales
      final result = await _db.rawDelete('''
        DELETE FROM installments 
        WHERE sale_id NOT IN (SELECT id FROM sales)
      ''');

      return result;
    } catch (e) {
      return 0;
    }
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
    // التحقق من صحة البيانات
    if (values['name'] == null ||
        (values['name'] as String?)?.trim().isEmpty == true) {
      throw Exception('اسم العميل مطلوب');
    }

    // التحقق من total_debt إذا كان موجوداً
    if (values['total_debt'] != null) {
      final totalDebt = (values['total_debt'] as num?)?.toDouble() ?? 0.0;
      if (totalDebt < 0) {
        throw Exception('إجمالي الدين يجب أن يكون أكبر من أو يساوي صفر');
      }
    }

    if (id == null) {
      // إضافة عميل جديد
      return _db.insert('customers', values);
    } else {
      // تحديث عميل موجود - التحقق من وجوده
      final customer = await _db.query('customers',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (customer.isEmpty) {
        throw Exception('العميل غير موجود');
      }
      return _db.update('customers', values, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> deleteCustomer(int id) async {
    return _db.transaction<int>((txn) async {
      try {
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
              } catch (e) {
                // ignore
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
              } catch (e) {
                // ignore
              }
            }
          }

          await txn.execute('PRAGMA foreign_keys = ON');
        } catch (e) {
          await txn.execute('PRAGMA foreign_keys = ON');
        }

        // التحقق من وجود العميل أولاً
        final customerExists = await txn.query('customers',
            columns: ['id'], where: 'id = ?', whereArgs: [id]);
        if (customerExists.isEmpty) {
          return 0;
        }

        // أولاً، الحصول على معرفات المبيعات المرتبطة بالعميل
        final sales = await txn.query('sales',
            columns: ['id'], where: 'customer_id = ?', whereArgs: [id]);

        // حذف عناصر المبيعات المرتبطة
        for (final sale in sales) {
          await txn.delete('sale_items',
              where: 'sale_id = ?', whereArgs: [sale['id']]);
        }

        // حذف المدفوعات المرتبطة بالعميل
        await txn.delete('payments', where: 'customer_id = ?', whereArgs: [id]);

        // حذف الأقساط المرتبطة بالمبيعات
        for (final sale in sales) {
          try {
            await txn.delete('installments',
                where: 'sale_id = ?', whereArgs: [sale['id']]);
          } catch (e) {
            // محاولة بديلة - حذف مباشر
            try {
              await txn.execute(
                  'DELETE FROM installments WHERE sale_id = ?', [sale['id']]);
            } catch (directError) {
              // تجاهل الخطأ والمتابعة
            }
          }
        }

        // حذف المبيعات المرتبطة بالعميل
        await txn.delete('sales', where: 'customer_id = ?', whereArgs: [id]);

        // حذف العميل نفسه
        final deletedRows =
            await txn.delete('customers', where: 'id = ?', whereArgs: [id]);

        return deletedRows;
      } catch (e) {
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

  // Expenses - تم نقل الدوال إلى قسم "دوال إدارة المصروفات" أدناه
  // الدوال القديمة تم استبدالها بدوال محسنة مع دعم الفئات والوصف

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

  // Sales and installments (simplified version)
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
      try {
        // التحقق من أن قائمة العناصر ليست فارغة
        if (items.isEmpty) {
          throw Exception('لا يمكن إنشاء بيع بدون منتجات');
        }

        // التحقق من صحة البيانات والكميات المتاحة
        for (final it in items) {
          final productId = it['product_id'] as int?;
          if (productId == null) {
            throw Exception('معرف المنتج مطلوب');
          }

          // التحقق من وجود المنتج
          final product = await txn.query('products',
              where: 'id = ?', whereArgs: [productId], limit: 1);
          if (product.isEmpty) {
            throw Exception('المنتج غير موجود');
          }

          final quantity = (it['quantity'] as num?)?.toInt() ?? 0;
          if (quantity <= 0) {
            throw Exception('الكمية يجب أن تكون أكبر من صفر');
          }

          // التحقق من الكمية المتاحة إذا كان decrementStock مفعلاً
          if (decrementStock) {
            final availableQty = product.first['quantity'] as int? ?? 0;
            if (quantity > availableQty) {
              throw Exception(
                  'الكمية المطلوبة ($quantity) أكبر من الكمية المتاحة ($availableQty)');
            }
          }
        }

        // حساب الإجمالي والربح
        double total = 0;
        double profit = 0;
        for (final it in items) {
          final rawPrice = (it['price'] as num).toDouble();
          final discountPercent =
              ((it['discount_percent'] ?? 0) as num).toDouble();
          final price = rawPrice * (1 - (discountPercent.clamp(0, 100) / 100));
          final cost = (it['cost'] as num).toDouble();
          final quantity = (it['quantity'] as num).toDouble();

          if (price.isFinite && quantity.isFinite && quantity > 0) {
            final qty = quantity.toInt();
            total += price * qty;
            profit += (price - cost) * qty;
          }
        }

        // التحقق من أن الإجمالي أكبر من صفر
        if (total <= 0) {
          throw Exception('إجمالي البيع يجب أن يكون أكبر من صفر');
        }

        // إنشاء أو العثور على العميل
        int? ensuredCustomerId = customerId;
        if (ensuredCustomerId == null &&
            customerName?.trim().isNotEmpty == true) {
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

        // إنشاء البيع
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
          final rawPrice = (it['price'] as num).toDouble();
          final discountPercent =
              ((it['discount_percent'] ?? 0) as num).toDouble();
          final effectivePrice =
              rawPrice * (1 - (discountPercent.clamp(0, 100) / 100));
          final cost = (it['cost'] as num).toDouble();
          final quantity = (it['quantity'] as num).toDouble();

          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': it['product_id'],
            'price': effectivePrice,
            'cost': cost,
            'quantity': quantity.toInt(),
            'discount_percent': discountPercent,
          });

          if (decrementStock) {
            final qty = (it['quantity'] as num).toInt();
            final productId = it['product_id'] as int;
            // التحقق من أن الكمية لن تصبح سالبة
            final product = await txn.query('products',
                where: 'id = ?', whereArgs: [productId], limit: 1);
            if (product.isNotEmpty) {
              final currentQty = product.first['quantity'] as int? ?? 0;
              if (currentQty < qty) {
                throw Exception(
                    'الكمية المتاحة غير كافية للمنتج ${it['name'] ?? productId}');
              }
              await txn.rawUpdate(
                  'UPDATE products SET quantity = quantity - ? WHERE id = ?',
                  [qty, productId]);
            }
          }
        }

        // معالجة الديون والأقساط (مبسط)
        if (ensuredCustomerId != null) {
          if (type == 'credit') {
            // دين مباشر
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

            // إنشاء الأقساط
            DateTime currentDate = firstInstallmentDate ?? DateTime.now();
            for (int i = 0; i < installmentCount; i++) {
              await txn.insert('installments', {
                'sale_id': saleId,
                'due_date': currentDate.toIso8601String(),
                'amount': installmentAmount,
                'paid': 0,
                'paid_at': null,
              });
              currentDate = DateTime(
                  currentDate.year, currentDate.month + 1, currentDate.day);
            }
          }
        }

        return saleId;
      } catch (e) {
        debugPrint('خطأ في إنشاء البيع: $e');
        rethrow;
      }
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

  Future<List<Map<String, Object?>>> getOutOfStock() async {
    return _db.query(
      'products',
      where: 'quantity <= 0',
      orderBy: 'updated_at IS NULL DESC, updated_at ASC',
    );
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
    // استخدام expense_date بدلاً من created_at للمصروفات
    final expensesWhere = (from != null && to != null)
        ? 'WHERE expense_date BETWEEN ? AND ?'
        : '';
    final expensesArgs = (from != null && to != null)
        ? [from.toIso8601String(), to.toIso8601String()]
        : <Object?>[];
    final expenses = await _db.rawQuery(
        'SELECT IFNULL(SUM(amount),0) e FROM expenses $expensesWhere',
        expensesArgs);
    final totalSales = (sales.first['t'] as num?)?.toDouble() ?? 0.0;
    final totalProfit = (sales.first['p'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses = (expenses.first['e'] as num?)?.toDouble() ?? 0.0;
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

        if (sale.isEmpty) {
          debugPrint('البيع غير موجود: $saleId');
          return false;
        }

        // Get sale items to restore stock
        final saleItems = await txn.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [saleId],
        );

        // Restore stock for each item
        for (final item in saleItems) {
          try {
            await txn.rawUpdate(
              'UPDATE products SET quantity = quantity + ? WHERE id = ?',
              [item['quantity'], item['product_id']],
            );
          } catch (e) {
            debugPrint('خطأ في إرجاع المخزون للمنتج ${item['product_id']}: $e');
            // نتابع حتى لو فشل إرجاع المخزون
          }
        }

        // Delete sale items
        try {
          await txn
              .execute('DELETE FROM sale_items WHERE sale_id = ?', [saleId]);
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
          rethrow;
        }

        // Delete any related installments
        try {
          await txn
              .execute('DELETE FROM installments WHERE sale_id = ?', [saleId]);
        } catch (e) {
          debugPrint('خطأ في حذف installments: $e');
          // نتابع حتى لو فشل حذف الأقساط
        }

        // Delete the sale
        final deletedRows = await txn.rawDelete(
          'DELETE FROM sales WHERE id = ?',
          [saleId],
        );

        // Adjust customer debt if the deleted sale was credit
        if (deletedRows > 0 && sale.isNotEmpty) {
          final s = sale.first;
          if (s['type'] == 'credit' && s['customer_id'] != null) {
            try {
              await txn.rawUpdate(
                'UPDATE customers SET total_debt = MAX(IFNULL(total_debt,0) - ?, 0) WHERE id = ?',
                [(s['total'] as num).toDouble(), s['customer_id']],
              );
            } catch (e) {
              debugPrint('خطأ في تعديل دين العميل: $e');
              // لا نرمي الخطأ هنا لأن الحذف تم بنجاح
            }
          }
        }

        return deletedRows > 0;
      } catch (e) {
        debugPrint('خطأ في حذف البيع $saleId: $e');
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
        return;
      }

      final installmentCount = unpaidInstallments.length;
      final amountPerInstallment = paymentAmount / installmentCount;

      for (final installment in unpaidInstallments) {
        final installmentId = installment['id'] as int;
        final currentAmount = (installment['amount'] as num).toDouble();
        final newAmount =
            (currentAmount - amountPerInstallment).clamp(0.0, double.infinity);

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
        } else {
          // تقليل مبلغ القسط
          await txn.update(
            'installments',
            {'amount': newAmount},
            where: 'id = ?',
            whereArgs: [installmentId],
          );
        }
      }
    } catch (e) {
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
            debugPrint('Dropped main schema $type: $name');
          } catch (e) {
            debugPrint('Error dropping main schema $type $name: $e');
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
          } catch (e) {
            debugPrint('Error dropping temp schema $type $name: $e');
          }
        }
      }

      // إعادة تمكين المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');

      // إعادة إنشاء الفهارس
      await _createIndexes(_db);

      // التأكد من وجود الجداول الأساسية
      await _ensureCategorySchemaOn(_db);
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
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
              } catch (e) {
                debugPrint('Error dropping trigger $name: $e');
              }
            }
          }
        }
      } catch (e) {
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
                  break;
                case 'view':
                  await txn.execute('DROP VIEW IF EXISTS $name');
                  break;
                case 'index':
                  await txn.execute('DROP INDEX IF EXISTS $name');
                  break;
              }
            } catch (e) {
              debugPrint('Error dropping $type $name: $e');
            }
          }
        }

        // إعادة تفعيل المفاتيح الخارجية
        await txn.execute('PRAGMA foreign_keys = ON');
      } catch (e) {
        // التأكد من إعادة تفعيل المفاتيح الخارجية حتى لو فشل التنظيف
        try {
          await txn.execute('PRAGMA foreign_keys = ON');
        } catch (_) {}
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

  /// دالة شاملة لحذف جميع البيانات من قاعدة البيانات
  /// تحذف جميع الجداول عدا الجداول الأساسية (users, settings)
  Future<void> deleteAllData() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      // حذف جميع البيانات من الجداول بالترتيب الصحيح
      await _db.delete('payments');

      await _db.delete('installments');

      await _db.delete('sale_items');

      await _db.delete('sales');

      await _db.delete('expenses');

      await _db.delete('customers');

      await _db.delete('suppliers');

      await _db.delete('products');

      await _db.delete('categories');

      // إعادة تعيين AUTO_INCREMENT للجداول
      await _db.execute(
          'DELETE FROM sqlite_sequence WHERE name IN (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            'payments',
            'installments',
            'sale_items',
            'sales',
            'expenses',
            'customers',
            'suppliers',
            'products',
            'categories'
          ]);

      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
      rethrow;
    }
  }

  /// دالة للتحقق من وجود بيانات في قاعدة البيانات
  Future<Map<String, int>> checkDataExists() async {
    final result = <String, int>{};

    try {
      // فحص جدول المبيعات
      final salesCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM sales');
      result['المبيعات'] = salesCount.first['count'] as int;

      // فحص جدول المنتجات
      final productsCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM products');
      result['المنتجات'] = productsCount.first['count'] as int;

      // فحص جدول العملاء
      final customersCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM customers');
      result['العملاء'] = customersCount.first['count'] as int;

      // فحص جدول المصاريف
      final expensesCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM expenses');
      result['المصاريف'] = expensesCount.first['count'] as int;

      // فحص جدول الأقساط
      final installmentsCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM installments');
      result['الأقساط'] = installmentsCount.first['count'] as int;

      // فحص جدول المدفوعات
      final paymentsCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM payments');
      result['المدفوعات'] = paymentsCount.first['count'] as int;

      // فحص جدول عناصر المبيعات
      final saleItemsCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM sale_items');
      result['عناصر المبيعات'] = saleItemsCount.first['count'] as int;
    } catch (e) {
      debugPrint('Error checking data existence: $e');
    }

    return result;
  }

  /// دالة لإعادة تعيين جميع الديون في جدول العملاء
  Future<void> resetAllCustomerDebts() async {
    try {
      await _db.execute('UPDATE customers SET total_debt = 0');
    } catch (e) {
      rethrow;
    }
  }

  /// إنشاء نسخة احتياطية كاملة محسنة لقاعدة البيانات
  Future<String> createFullBackup(String backupPath) async {
    try {
      final timestamp = DateTime.now();
      final formattedDate =
          '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';
      final fileName = 'office_system_backup_$formattedDate.db';
      final backupFile = File(p.join(backupPath, fileName));

      // إنشاء مجلد النسخ الاحتياطي إذا لم يكن موجوداً
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // تنظيف النسخ القديمة (الاحتفاظ بآخر 10 نسخ فقط)
      await _cleanupOldBackups(backupPath);

      // التحقق من وجود مساحة كافية
      final dbSize = await File(_dbPath).length();
      final availableSpace = await _getAvailableDiskSpace(backupPath);
      if (availableSpace < dbSize * 1.5) {
        // نحتاج مساحة إضافية للتأكد
        throw Exception('مساحة القرص غير كافية لإنشاء النسخة الاحتياطية');
      }

      // إنشاء نسخة احتياطية من البيانات الحالية قبل الإغلاق
      await _db.execute('PRAGMA wal_checkpoint(FULL)');
      await _db.execute('PRAGMA optimize');

      // إغلاق قاعدة البيانات مؤقتاً لضمان النسخ الكامل
      await _db.close();

      try {
        // نسخ ملف قاعدة البيانات الرئيسي
        await File(_dbPath).copy(backupFile.path);

        // نسخ ملف WAL إذا كان موجوداً
        final walFile = File('$_dbPath-wal');
        if (await walFile.exists()) {
          final backupWalFile = File('${backupFile.path}-wal');
          await walFile.copy(backupWalFile.path);
        }

        // نسخ ملف SHM إذا كان موجوداً
        final shmFile = File('$_dbPath-shm');
        if (await shmFile.exists()) {
          final backupShmFile = File('${backupFile.path}-shm');
          await shmFile.copy(backupShmFile.path);
        }

        // التحقق من صحة النسخة الاحتياطية
        final backupDb = await openDatabase(backupFile.path, readOnly: true);
        await backupDb.rawQuery('SELECT COUNT(*) FROM sqlite_master');
        await backupDb.close();
      } catch (copyError) {
        // إذا فشل النسخ، حذف جميع الملفات المكسورة
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        final backupWalFile = File('${backupFile.path}-wal');
        if (await backupWalFile.exists()) {
          await backupWalFile.delete();
        }
        final backupShmFile = File('${backupFile.path}-shm');
        if (await backupShmFile.exists()) {
          await backupShmFile.delete();
        }
        rethrow;
      }

      // إعادة فتح قاعدة البيانات مع التحسينات
      _db = await openDatabase(_dbPath, version: _dbVersion);
      await _db.execute('PRAGMA foreign_keys = ON');
      await _createIndexes(_db);
      await _cleanupOrphanObjects(_db);
      await _ensureCategorySchemaOn(_db);

      return backupFile.path;
    } catch (e) {
      // محاولة إعادة فتح قاعدة البيانات في حالة الخطأ
      try {
        _db = await openDatabase(_dbPath, version: _dbVersion);
        await _db.execute('PRAGMA foreign_keys = ON');
        await _createIndexes(_db);
      } catch (_) {}
      rethrow;
    }
  }

  /// الحصول على المساحة المتاحة في القرص
  Future<int> _getAvailableDiskSpace(String path) async {
    try {
      // هذا تنفيذ مبسط - في التطبيقات الحقيقية قد تحتاج مكتبة خارجية
      final directory = Directory(path);
      if (await directory.exists()) {
        return 1024 * 1024 * 1024; // 1GB افتراضي
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// استعادة نسخة احتياطية كاملة محسنة
  Future<void> restoreFullBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw Exception('ملف النسخة الاحتياطية غير موجود');
      }

      // التحقق من صحة ملف النسخة الاحتياطية
      final testDb = await openDatabase(backupFilePath, readOnly: true);
      try {
        await testDb.rawQuery('SELECT COUNT(*) FROM sqlite_master');
        // التحقق من وجود الجداول الأساسية
        final tables = await testDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
        if (tables.isEmpty) {
          throw Exception('ملف النسخة الاحتياطية لا يحتوي على جداول صالحة');
        }
      } finally {
        await testDb.close();
      }

      // إنشاء نسخة احتياطية من البيانات الحالية قبل الاستعادة
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final currentBackupPath = '${_dbPath}_pre_restore_$timestamp.db';

      // إغلاق قاعدة البيانات الحالية وإجراء تنظيف
      await _db.execute('PRAGMA wal_checkpoint(FULL)');
      await _db.close();

      // نسخ البيانات الحالية كنسخة احتياطية احتياطية
      await File(_dbPath).copy(currentBackupPath);

      // نسخ ملفات WAL و SHM الحالية إذا كانت موجودة
      final currentWalFile = File('$_dbPath-wal');
      if (await currentWalFile.exists()) {
        await currentWalFile.copy('$currentBackupPath-wal');
      }

      final currentShmFile = File('$_dbPath-shm');
      if (await currentShmFile.exists()) {
        await currentShmFile.copy('$currentBackupPath-shm');
      }

      try {
        // استعادة النسخة الاحتياطية الرئيسية
        await backupFile.copy(_dbPath);

        // استعادة ملف WAL إذا كان موجوداً
        final backupWalFile = File('$backupFilePath-wal');
        if (await backupWalFile.exists()) {
          final walFile = File('$_dbPath-wal');
          await backupWalFile.copy(walFile.path);
        }

        // استعادة ملف SHM إذا كان موجوداً
        final backupShmFile = File('$backupFilePath-shm');
        if (await backupShmFile.exists()) {
          final shmFile = File('$_dbPath-shm');
          await backupShmFile.copy(shmFile.path);
        }

        // إعادة فتح قاعدة البيانات والتحقق من صحتها
        _db = await openDatabase(_dbPath, version: _dbVersion);
        await _db.execute('PRAGMA foreign_keys = ON');

        // التحقق من صحة البيانات المستعادة
        await _db.rawQuery('PRAGMA integrity_check');

        // إعادة بناء الفهارس والتنظيف
        await _createIndexes(_db);
        await _cleanupOrphanObjects(_db);
        await _ensureCategorySchemaOn(_db);

        // تحسين قاعدة البيانات بعد الاستعادة
        await _db.execute('PRAGMA optimize');
      } catch (restoreError) {
        // في حالة فشل الاستعادة، استعادة البيانات الأصلية
        try {
          await _db.close();
          await File(currentBackupPath).copy(_dbPath);

          // استعادة ملفات WAL و SHM الأصلية
          final backupWalFile = File('$currentBackupPath-wal');
          if (await backupWalFile.exists()) {
            await backupWalFile.copy('$_dbPath-wal');
          }

          final backupShmFile = File('$currentBackupPath-shm');
          if (await backupShmFile.exists()) {
            await backupShmFile.copy('$_dbPath-shm');
          }

          _db = await openDatabase(_dbPath, version: _dbVersion);
          await _db.execute('PRAGMA foreign_keys = ON');
          await _createIndexes(_db);
        } catch (_) {}

        // حذف النسخة الاحتياطية المؤقتة وجميع ملفاتها
        try {
          await File(currentBackupPath).delete();
          await File('$currentBackupPath-wal').delete();
          await File('$currentBackupPath-shm').delete();
        } catch (_) {}

        throw Exception(
            'فشل في استعادة النسخة الاحتياطية: ${restoreError.toString()}');
      }

      // حذف النسخة الاحتياطية المؤقتة وجميع ملفاتها بعد نجاح الاستعادة
      try {
        await File(currentBackupPath).delete();
        await File('$currentBackupPath-wal').delete();
        await File('$currentBackupPath-shm').delete();
      } catch (_) {}
    } catch (e) {
      // محاولة إعادة فتح قاعدة البيانات في حالة الخطأ
      try {
        _db = await openDatabase(_dbPath, version: _dbVersion);
        await _db.execute('PRAGMA foreign_keys = ON');
        await _createIndexes(_db);
      } catch (_) {}
      rethrow;
    }
  }

  /// الحصول على حجم قاعدة البيانات
  Future<String> getDatabaseSize() async {
    try {
      final file = File(_dbPath);
      if (await file.exists()) {
        final size = await file.length();
        if (size < 1024) {
          return '$size B';
        } else if (size < 1024 * 1024) {
          return '${(size / 1024).toStringAsFixed(1)} KB';
        } else {
          return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      }
      return 'غير متاح';
    } catch (e) {
      return 'خطأ في الحساب';
    }
  }

  /// الحصول على إحصائيات قاعدة البيانات
  /// تنظيف النسخ الاحتياطية القديمة (الاحتفاظ بآخر 10 نسخ فقط)
  Future<void> _cleanupOldBackups(String backupPath) async {
    try {
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) return;

      final backupFiles = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.db'))
          .cast<File>()
          .toList();

      // ترتيب الملفات حسب تاريخ التعديل (الأحدث أولاً)
      backupFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // حذف الملفات الزائدة (الاحتفاظ بآخر 10 نسخ فقط)
      if (backupFiles.length > 10) {
        for (int i = 10; i < backupFiles.length; i++) {
          try {
            await backupFiles[i].delete();
          } catch (e) {
            // تجاهل الأخطاء في الحذف
          }
        }
      }
    } catch (e) {
      // تجاهل الأخطاء في التنظيف
    }
  }

  /// التحقق من سلامة النسخة الاحتياطية
  Future<bool> verifyBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) return false;

      // فتح قاعدة البيانات للتحقق
      final testDb = await openDatabase(backupFilePath, readOnly: true);
      try {
        // التحقق من وجود الجداول الأساسية
        final tables = await testDb
            .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final tableNames = tables.map((t) => t['name'] as String).toList();

        final requiredTables = [
          'users',
          'products',
          'categories',
          'customers',
          'sales',
          'sale_items'
        ];
        for (final table in requiredTables) {
          if (!tableNames.contains(table)) return false;
        }

        // التحقق من سلامة البيانات
        await testDb.rawQuery('PRAGMA integrity_check');

        return true;
      } finally {
        await testDb.close();
      }
    } catch (e) {
      return false;
    }
  }

  /// الحصول على قائمة النسخ الاحتياطية المتاحة
  Future<List<Map<String, dynamic>>> getAvailableBackups(
      String backupPath) async {
    try {
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) return [];

      final backupFiles = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.db'))
          .cast<File>()
          .toList();

      final backups = <Map<String, dynamic>>[];
      for (final file in backupFiles) {
        final stat = await file.stat();
        final size = await file.length();
        final isValid = await verifyBackup(file.path);

        backups.add({
          'path': file.path,
          'name': p.basename(file.path),
          'size': size,
          'date': stat.modified,
          'isValid': isValid,
        });
      }

      // ترتيب حسب التاريخ (الأحدث أولاً)
      backups.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      return backups;
    } catch (e) {
      return [];
    }
  }

  /// تشغيل النسخ الاحتياطي التلقائي
  Future<void> runAutoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
      final autoBackupFrequency =
          prefs.getString('auto_backup_frequency') ?? 'weekly';
      final backupPath = prefs.getString('backup_path') ?? '';

      if (!autoBackupEnabled || backupPath.isEmpty) return;

      // التحقق من موعد آخر نسخة احتياطية
      final lastBackupTime = prefs.getInt('last_auto_backup_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastBackup = now - lastBackupTime;

      bool shouldBackup = false;
      switch (autoBackupFrequency) {
        case 'daily':
          shouldBackup = timeSinceLastBackup >= 24 * 60 * 60 * 1000; // 24 ساعة
          break;
        case 'weekly':
          shouldBackup =
              timeSinceLastBackup >= 7 * 24 * 60 * 60 * 1000; // 7 أيام
          break;
        case 'monthly':
          shouldBackup =
              timeSinceLastBackup >= 30 * 24 * 60 * 60 * 1000; // 30 يوم
          break;
      }

      if (shouldBackup) {
        await createFullBackup(backupPath);
        await prefs.setInt('last_auto_backup_time', now);
      }
    } catch (e) {
      // تسجيل الخطأ (يمكن إضافة نظام logging لاحقاً)
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final stats = <String, int>{};

      // عدد المنتجات
      final productsResult =
          await _db.rawQuery('SELECT COUNT(*) as count FROM products');
      final productsCount = productsResult.first['count'] as int? ?? 0;
      stats['products'] = productsCount;

      // عدد العملاء
      final customersResult =
          await _db.rawQuery('SELECT COUNT(*) as count FROM customers');
      final customersCount = customersResult.first['count'] as int? ?? 0;
      stats['customers'] = customersCount;

      // عدد المبيعات
      final salesResult =
          await _db.rawQuery('SELECT COUNT(*) as count FROM sales');
      final salesCount = salesResult.first['count'] as int? ?? 0;
      stats['sales'] = salesCount;

      // عدد الأقسام
      final categoriesResult =
          await _db.rawQuery('SELECT COUNT(*) as count FROM categories');
      final categoriesCount = categoriesResult.first['count'] as int? ?? 0;
      stats['categories'] = categoriesCount;

      return stats;
    } catch (e) {
      return {};
    }
  }

  // ==================== التقارير المالية الشاملة ====================

  /// قائمة الدخل الشهرية
  Future<Map<String, dynamic>> getIncomeStatement(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // الإيرادات
      final revenueResult = await _db.rawQuery('''
        SELECT 
          COALESCE(SUM(total), 0) as total_revenue,
          COALESCE(SUM(profit), 0) as gross_profit
        FROM sales 
        WHERE created_at >= ? AND created_at <= ?
      ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

      // تكلفة البضائع المباعة
      final cogsResult = await _db.rawQuery('''
        SELECT COALESCE(SUM(si.cost * si.quantity), 0) as cogs
        FROM sale_items si
        JOIN sales s ON si.sale_id = s.id
        WHERE s.created_at >= ? AND s.created_at <= ?
      ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

      // المصروفات
      final expensesResult = await _db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total_expenses
        FROM expenses 
        WHERE created_at >= ? AND created_at <= ?
      ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

      final expenses =
          (expensesResult.first['total_expenses'] as num?)?.toDouble() ?? 0.0;

      final revenue =
          (revenueResult.first['total_revenue'] as num?)?.toDouble() ?? 0.0;
      final grossProfit =
          (revenueResult.first['gross_profit'] as num?)?.toDouble() ?? 0.0;
      final cogs = (cogsResult.first['cogs'] as num?)?.toDouble() ?? 0.0;
      final netProfit = grossProfit - expenses;

      return {
        'revenue': revenue,
        'cogs': cogs,
        'gross_profit': grossProfit,
        'expenses': expenses,
        'net_profit': netProfit,
        'month': month.month,
        'year': month.year,
      };
    } catch (e) {
      return {};
    }
  }

  /// الميزانية العمومية
  Future<Map<String, dynamic>> getBalanceSheet(DateTime date) async {
    try {
      // الأصول
      final assetsResult = await _db.rawQuery('''
        SELECT COALESCE(SUM(price * quantity), 0) as inventory_value
        FROM products
      ''');

      // الخصوم (الديون المستحقة)
      final liabilitiesResult = await _db.rawQuery('''
        SELECT COALESCE(SUM(amount - paid), 0) as total_debts
        FROM installments
        WHERE paid < amount
      ''');

      // حقوق الملكية (الأرباح المحتجزة)
      final equityResult = await _db.rawQuery('''
        SELECT COALESCE(SUM(profit), 0) as retained_earnings
        FROM sales
        WHERE created_at <= ?
      ''', [date.toIso8601String()]);

      final assets =
          (assetsResult.first['inventory_value'] as num?)?.toDouble() ?? 0.0;
      final liabilities =
          (liabilitiesResult.first['total_debts'] as num?)?.toDouble() ?? 0.0;
      final equity =
          (equityResult.first['retained_earnings'] as num?)?.toDouble() ?? 0.0;

      return {
        'assets': assets,
        'liabilities': liabilities,
        'equity': equity,
        'date': date.toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }

  /// تحليل الاتجاهات والتنبؤات
  Future<Map<String, dynamic>> getTrendAnalysis(int months) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - months, 1);

      // بيانات المبيعات الشهرية
      final monthlySales = await _db.rawQuery('''
        SELECT 
          strftime('%Y-%m', created_at) as month,
          COUNT(*) as sales_count,
          SUM(total) as total_revenue,
          SUM(profit) as total_profit,
          AVG(total) as avg_sale_amount
        FROM sales
        WHERE created_at >= ? AND created_at <= ?
        GROUP BY strftime('%Y-%m', created_at)
        ORDER BY month
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      // حساب معدل النمو
      List<double> revenues = [];
      for (final row in monthlySales) {
        revenues.add((row['total_revenue'] as num?)?.toDouble() ?? 0.0);
      }

      double growthRate = 0.0;
      if (revenues.length >= 2) {
        final currentRevenue = revenues.last;
        final previousRevenue = revenues[revenues.length - 2];
        if (previousRevenue > 0) {
          growthRate =
              ((currentRevenue - previousRevenue) / previousRevenue) * 100;
        }
      }

      // التنبؤ بالشهر القادم
      double predictedRevenue = 0.0;
      if (revenues.isNotEmpty) {
        final avgRevenue = revenues.reduce((a, b) => a + b) / revenues.length;
        predictedRevenue = avgRevenue * (1 + (growthRate / 100));
      }

      return {
        'monthly_data': monthlySales,
        'growth_rate': growthRate,
        'predicted_revenue': predictedRevenue,
        'trend_direction': growthRate > 0
            ? 'up'
            : growthRate < 0
                ? 'down'
                : 'stable',
      };
    } catch (e) {
      return {};
    }
  }

  /// مؤشرات الأداء الرئيسية (KPI)
  Future<Map<String, dynamic>> getKPIs(DateTime date) async {
    try {
      final startOfMonth = DateTime(date.year, date.month, 1);
      // Use half-open [start, nextMonthStart) to be consistent
      final nextMonthStart = DateTime(date.year, date.month + 1, 1);

      // إجمالي المبيعات الشهرية
      final monthlySalesResult = await _db.rawQuery('''
        SELECT 
          COUNT(*) as sales_count,
          SUM(total) as total_revenue,
          SUM(profit) as total_profit,
          AVG(total) as avg_sale_amount
        FROM sales
        WHERE created_at >= ? AND created_at < ?
      ''', [startOfMonth.toIso8601String(), nextMonthStart.toIso8601String()]);

      // عدد العملاء الجدد
      int newCustomersCount = 0;
      try {
        final newCustomersResult = await _db.rawQuery('''
          SELECT COUNT(*) as new_customers
          FROM customers
          WHERE created_at >= ? AND created_at < ?
        ''',
            [startOfMonth.toIso8601String(), nextMonthStart.toIso8601String()]);
        newCustomersCount =
            (newCustomersResult.first['new_customers'] as num?)?.toInt() ?? 0;
      } catch (_) {
        // Fallback if customers.created_at doesn't exist: distinct customers from sales this month
        final fallback = await _db.rawQuery('''
          SELECT COUNT(DISTINCT customer_id) as cnt
          FROM sales
          WHERE customer_id IS NOT NULL AND created_at >= ? AND created_at < ?
        ''',
            [startOfMonth.toIso8601String(), nextMonthStart.toIso8601String()]);
        newCustomersCount = (fallback.first['cnt'] as num?)?.toInt() ?? 0;
      }

      // معدل التحويل (العملاء الذين اشتروا)
      final totalCustomersResult = await _db.rawQuery('''
        SELECT COUNT(*) as total_customers
        FROM customers
      ''');

      final customersWithSalesResult = await _db.rawQuery('''
        SELECT COUNT(DISTINCT customer_id) as customers_with_sales
        FROM sales
        WHERE created_at >= ? AND created_at < ? AND customer_id IS NOT NULL
      ''', [startOfMonth.toIso8601String(), nextMonthStart.toIso8601String()]);

      // هامش الربح
      final totalRevenue =
          (monthlySalesResult.first['total_revenue'] as num?)?.toDouble() ??
              0.0;
      final totalProfit =
          (monthlySalesResult.first['total_profit'] as num?)?.toDouble() ?? 0.0;
      final profitMargin =
          totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;

      // معدل التحويل
      final totalCustomers =
          totalCustomersResult.first['total_customers'] as int? ?? 0;
      final customersWithSales =
          customersWithSalesResult.first['customers_with_sales'] as int? ?? 0;
      final conversionRate = totalCustomers > 0
          ? (customersWithSales / totalCustomers) * 100
          : 0.0;

      return {
        'monthly_revenue': totalRevenue,
        'monthly_profit': totalProfit,
        'sales_count': monthlySalesResult.first['sales_count'] as int? ?? 0,
        'avg_sale_amount':
            (monthlySalesResult.first['avg_sale_amount'] as num?)?.toDouble() ??
                0.0,
        'new_customers': newCustomersCount,
        'profit_margin': profitMargin,
        'conversion_rate': conversionRate,
        'month': date.month,
        'year': date.year,
      };
    } catch (e) {
      return {};
    }
  }

  /// تقرير الضرائب
  Future<Map<String, dynamic>> getTaxReport(
      DateTime startDate, DateTime endDate) async {
    try {
      // المبيعات الخاضعة للضريبة
      final taxableSalesResult = await _db.rawQuery('''
        SELECT 
          COUNT(*) as sales_count,
          SUM(total) as total_amount,
          SUM(profit) as total_profit
        FROM sales
        WHERE created_at >= ? AND created_at <= ?
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      // تفاصيل المبيعات للفاتورة الضريبية
      final salesDetails = await _db.rawQuery('''
        SELECT 
          s.id,
          s.created_at,
          s.total,
          s.profit,
          s.type,
          c.name as customer_name,
          c.phone as customer_phone
        FROM sales s
        LEFT JOIN customers c ON s.customer_id = c.id
        WHERE s.created_at >= ? AND s.created_at <= ?
        ORDER BY s.created_at DESC
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      final totalAmount =
          (taxableSalesResult.first['total_amount'] as num?)?.toDouble() ?? 0.0;
      final totalProfit =
          (taxableSalesResult.first['total_profit'] as num?)?.toDouble() ?? 0.0;

      // لا توجد ضرائب - المبلغ الصافي = إجمالي المبيعات
      const taxRate = 0.0;
      final taxAmount = 0.0;
      final netAmount = totalAmount;

      return {
        'period_start': startDate.toIso8601String(),
        'period_end': endDate.toIso8601String(),
        'total_sales': totalAmount,
        'total_profit': totalProfit,
        'tax_rate': taxRate * 100,
        'tax_amount': taxAmount,
        'net_amount': netAmount,
        'sales_count': taxableSalesResult.first['sales_count'] as int? ?? 0,
        'sales_details': salesDetails,
      };
    } catch (e) {
      return {};
    }
  }

  /// تقرير الجرد الشامل
  Future<Map<String, dynamic>> getInventoryReport() async {
    try {
      // إجمالي المخزون
      final totalInventoryResult = await _db.rawQuery('''
        SELECT 
          COUNT(*) as total_products,
          SUM(quantity) as total_quantity,
          SUM(price * quantity) as total_value,
          SUM(cost * quantity) as total_cost
        FROM products
      ''');

      // المنتجات منخفضة الكمية
      final lowStockResult = await _db.rawQuery('''
        SELECT COUNT(*) as low_stock_count
        FROM products
        WHERE quantity <= 10
      ''');

      // المنتجات نفدت
      final outOfStockResult = await _db.rawQuery('''
        SELECT COUNT(*) as out_of_stock_count
        FROM products
        WHERE quantity = 0
      ''');

      // المنتجات الأكثر مبيعاً
      final topSellingResult = await _db.rawQuery('''
        SELECT 
          p.name,
          p.barcode,
          SUM(si.quantity) as total_sold,
          SUM(si.price * si.quantity) as total_revenue
        FROM products p
        JOIN sale_items si ON p.id = si.product_id
        JOIN sales s ON si.sale_id = s.id
        WHERE s.created_at >= date('now', '-30 days')
        GROUP BY p.id, p.name, p.barcode
        ORDER BY total_sold DESC
        LIMIT 10
      ''');

      // المنتجات بطيئة الحركة
      final slowMovingResult = await _db.rawQuery('''
        SELECT 
          p.name,
          p.barcode,
          p.quantity,
          p.price,
          p.cost
        FROM products p
        LEFT JOIN sale_items si ON p.id = si.product_id
        LEFT JOIN sales s ON si.sale_id = s.id AND s.created_at >= date('now', '-90 days')
        GROUP BY p.id, p.name, p.barcode, p.quantity, p.price, p.cost
        HAVING COUNT(si.id) = 0 OR COUNT(si.id) < 3
        ORDER BY p.quantity DESC
        LIMIT 10
      ''');

      final totalValue =
          totalInventoryResult.first['total_value'] as double? ?? 0.0;
      final totalCost =
          totalInventoryResult.first['total_cost'] as double? ?? 0.0;
      final inventoryTurnover = totalCost > 0 ? (totalValue / totalCost) : 0.0;
      final profitMargin =
          totalValue > 0 ? ((totalValue - totalCost) / totalValue) * 100 : 0.0;

      return {
        'total_products':
            totalInventoryResult.first['total_products'] as int? ?? 0,
        'total_quantity':
            totalInventoryResult.first['total_quantity'] as int? ?? 0,
        'total_value': totalValue,
        'total_cost': totalCost,
        'inventory_turnover': inventoryTurnover,
        'profit_margin': profitMargin,
        'low_stock_count': lowStockResult.first['low_stock_count'] as int? ?? 0,
        'out_of_stock_count':
            outOfStockResult.first['out_of_stock_count'] as int? ?? 0,
        'top_selling_products': topSellingResult,
        'slow_moving_products': slowMovingResult,
        'report_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }

  /// حذف جميع البيانات من قاعدة البيانات (نسخة محدثة)
  Future<void> deleteAllDataNew() async {
    try {
      // تعطيل المفاتيح الخارجية خارج transaction
      await _db.execute('PRAGMA foreign_keys = OFF');

      // نفّذ الحذف داخل معاملة واحدة
      await _db.transaction((txn) async {
        // حذف الجداول بالترتيب الصحيح لتجنب مشاكل المفاتيح الخارجية
        // أولاً: حذف الجداول الفرعية
        try {
          await txn.execute('DELETE FROM installments');
        } catch (e) {
          debugPrint('خطأ في حذف installments: $e');
        }

        try {
          await txn.execute('DELETE FROM sale_items');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
        }

        try {
          await txn.execute('DELETE FROM payments');
        } catch (e) {
          debugPrint('خطأ في حذف payments: $e');
        }

        try {
          await txn.execute('DELETE FROM expenses');
        } catch (e) {
          debugPrint('خطأ في حذف expenses: $e');
        }

        // ثانياً: حذف الجداول الرئيسية
        try {
          await txn.execute('DELETE FROM sales');
        } catch (e) {
          debugPrint('خطأ في حذف sales: $e');
        }

        try {
          await txn.execute('DELETE FROM products');
        } catch (e) {
          debugPrint('خطأ في حذف products: $e');
        }

        try {
          await txn.execute('DELETE FROM categories');
        } catch (e) {
          debugPrint('خطأ في حذف categories: $e');
        }

        try {
          await txn.execute('DELETE FROM customers');
        } catch (e) {
          debugPrint('خطأ في حذف customers: $e');
        }

        try {
          await txn.execute('DELETE FROM suppliers');
        } catch (e) {
          debugPrint('خطأ في حذف suppliers: $e');
        }

        // ثالثاً: حذف المستخدمين عدا المدير
        try {
          await txn.execute('DELETE FROM users WHERE username != ?', ['admin']);
        } catch (e) {
          debugPrint('خطأ في حذف users: $e');
        }

        // إعادة تعيين AUTO_INCREMENT
        try {
          await txn.execute('DELETE FROM sqlite_sequence');
        } catch (e) {
          debugPrint('خطأ في حذف sqlite_sequence: $e');
        }
      });

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');

      // إعادة إنشاء البيانات الأساسية
      try {
        await _seedData(_db);
      } catch (e) {
        debugPrint('خطأ في إعادة إنشاء البيانات الأساسية: $e');
        // لا نرمي الخطأ هنا لأن الحذف تم بنجاح
      }
    } catch (e) {
      // إعادة تفعيل المفاتيح الخارجية في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}

      debugPrint('خطأ في حذف جميع البيانات: $e');
      throw Exception('خطأ في حذف جميع البيانات: $e');
    }
  }

  /// حذف المنتجات والأقسام فقط
  Future<void> deleteProductsAndCategories() async {
    try {
      // تعطيل المفاتيح الخارجية خارج transaction
      await _db.execute('PRAGMA foreign_keys = OFF');

      // نفّذ الحذف داخل معاملة واحدة
      await _db.transaction((txn) async {
        // حذف sale_items أولاً (لأنها مرتبطة بالمنتجات)
        try {
          await txn.execute('DELETE FROM sale_items');
          debugPrint('تم حذف sale_items بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
          // نتابع حتى لو فشل حذف sale_items
        }

        // حذف المنتجات
        try {
          await txn.execute('DELETE FROM products');
          debugPrint('تم حذف products بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف products: $e');
          rethrow; // نرمي الخطأ هنا لأن حذف المنتجات مهم
        }

        // حذف الأقسام
        try {
          await txn.execute('DELETE FROM categories');
          debugPrint('تم حذف categories بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف categories: $e');
          // نتابع حتى لو فشل حذف categories
        }

        // إعادة تعيين AUTO_INCREMENT للمنتجات والأقسام
        try {
          await txn.execute(
              'DELETE FROM sqlite_sequence WHERE name IN ("products", "categories", "sale_items")');
          debugPrint('تم إعادة تعيين sqlite_sequence بنجاح');
        } catch (e) {
          debugPrint('خطأ في إعادة تعيين sqlite_sequence: $e');
          // لا نرمي الخطأ هنا لأن هذا ليس حرجاً
        }
      });

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // التأكد من إعادة تفعيل المفاتيح الخارجية حتى في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      debugPrint('خطأ في حذف المنتجات والأقسام: $e');
      throw Exception('خطأ في حذف المنتجات والأقسام: $e');
    }
  }

  /// حذف الإحصائيات والتقارير
  Future<void> deleteReportsAndStatistics() async {
    try {
      await _db.transaction((txn) async {
        // حذف سجلات الأداء إذا كانت موجودة
        try {
          await txn.execute('DELETE FROM performance_logs');
        } catch (e) {
          // الجدول قد لا يكون موجوداً
        }

        // حذف التقارير المؤقتة إذا كانت موجودة
        try {
          await txn.execute('DELETE FROM temp_reports');
        } catch (e) {
          // الجدول قد لا يكون موجوداً
        }

        // حذف سجلات النسخ الاحتياطي إذا كانت موجودة
        try {
          await txn.execute('DELETE FROM backup_logs');
        } catch (e) {
          // الجدول قد لا يكون موجوداً
        }

        // حذف البيانات الإحصائية من الجداول الموجودة
        // حذف سجلات المدفوعات (إحصائيات مالية)
        await txn.delete('payments');

        // حذف سجلات المصروفات (إحصائيات مالية)
        await txn.delete('expenses');

        // حذف الأقساط (إحصائيات مالية)
        await txn.delete('installments');

        // إعادة تعيين AUTO_INCREMENT للجداول المحذوفة
        await txn.execute(
            'DELETE FROM sqlite_sequence WHERE name IN ("payments", "expenses", "installments")');

        // تنظيف أي جداول مؤقتة أخرى
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name LIKE "%temp%"');
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name LIKE "%log%"');
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name LIKE "%report%"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف الإحصائيات والتقارير: $e');
    }
  }

  /// حذف المبيعات فقط
  Future<void> deleteSalesOnly() async {
    try {
      // تعطيل المفاتيح الخارجية خارج transaction
      await _db.execute('PRAGMA foreign_keys = OFF');

      // نفّذ الحذف داخل معاملة واحدة
      await _db.transaction((txn) async {
        // حذف الأقساط أولاً (لأنها مرتبطة بالمبيعات)
        try {
          await txn.execute('DELETE FROM installments');
          debugPrint('تم حذف installments بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف installments: $e');
        }

        // حذف سجلات المبيعات
        try {
          await txn.execute('DELETE FROM sale_items');
          debugPrint('تم حذف sale_items بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
        }

        // حذف المبيعات
        try {
          await txn.execute('DELETE FROM sales');
          debugPrint('تم حذف sales بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف sales: $e');
          rethrow; // نرمي الخطأ هنا لأن حذف المبيعات مهم
        }

        // إعادة تعيين AUTO_INCREMENT
        try {
          await txn.execute(
              'DELETE FROM sqlite_sequence WHERE name IN ("sales", "sale_items", "installments")');
          debugPrint('تم إعادة تعيين sqlite_sequence بنجاح');
        } catch (e) {
          debugPrint('خطأ في إعادة تعيين sqlite_sequence: $e');
          // لا نرمي الخطأ هنا لأن هذا ليس حرجاً
        }
      });

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // التأكد من إعادة تفعيل المفاتيح الخارجية حتى في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      debugPrint('خطأ في حذف المبيعات: $e');
      throw Exception('خطأ في حذف المبيعات: $e');
    }
  }

  /// حذف العملاء فقط
  Future<void> deleteCustomersOnly() async {
    try {
      await _db.transaction((txn) async {
        // حذف المدفوعات المرتبطة بالعملاء
        await txn.delete('payments');

        // حذف العملاء
        await txn.delete('customers');

        // إعادة تعيين AUTO_INCREMENT
        await txn.execute(
            'DELETE FROM sqlite_sequence WHERE name IN ("customers", "payments")');
      });
    } catch (e) {
      throw Exception('خطأ في حذف العملاء: $e');
    }
  }

  /// حذف المدفوعات فقط
  Future<void> deletePaymentsOnly() async {
    try {
      await _db.transaction((txn) async {
        // حذف المدفوعات
        await txn.delete('payments');

        // إعادة تعيين AUTO_INCREMENT
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "payments"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف المدفوعات: $e');
    }
  }

  /// حذف المصروفات فقط
  Future<void> deleteExpensesOnly() async {
    try {
      await _db.transaction((txn) async {
        // حذف المصروفات
        await txn.delete('expenses');

        // إعادة تعيين AUTO_INCREMENT
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "expenses"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف المصروفات: $e');
    }
  }

  /// حذف الأقساط فقط
  Future<void> deleteInstallmentsOnly() async {
    try {
      await _db.transaction((txn) async {
        // حذف الأقساط
        await txn.delete('installments');

        // إعادة تعيين AUTO_INCREMENT
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "installments"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف الأقساط: $e');
    }
  }

  /// حذف المستخدمين فقط
  Future<void> deleteUsersOnly() async {
    try {
      await _db.transaction((txn) async {
        // تعطيل المفاتيح الخارجية مؤقتًا لتجنب تعارضات العلاقات
        await txn.execute('PRAGMA foreign_keys = OFF');
        // حذف المستخدمين
        await txn.delete('users');

        // إعادة تعيين AUTO_INCREMENT
        await txn.execute('DELETE FROM sqlite_sequence WHERE name = "users"');

        // تأكد من وجود عمود الصلاحيات قبل الإدراج (لتوافق قواعد بيانات قديمة)
        final usersColumns = await txn.rawQuery('PRAGMA table_info(users)');
        final hasPermissionsColumn = usersColumns.any((col) {
          final dynamic name = col['name'];
          return name is String && name.toLowerCase() == 'permissions';
        });
        if (!hasPermissionsColumn) {
          await txn.execute('ALTER TABLE users ADD COLUMN permissions TEXT');
        }

        // تشفير كلمة المرور الافتراضية
        final hashedPassword =
            sha256.convert(utf8.encode('Manager@2025')).toString();

        // إعادة إنشاء المستخدم الافتراضي مع كلمة مرور مشفرة
        await txn.insert('users', {
          'name': 'مدير النظام',
          'username': 'manager',
          'password': hashedPassword,
          'role': 'manager',
          'employee_code': 'ADMIN001',
          'permissions': 'all',
          'active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        // إعادة تفعيل المفاتيح الخارجية بعد الانتهاء
        await txn.execute('PRAGMA foreign_keys = ON');
      });
    } catch (e) {
      throw Exception('خطأ في حذف المستخدمين: $e');
    }
  }

  /// حذف الموردين فقط
  Future<void> deleteSuppliersOnly() async {
    try {
      await _db.transaction((txn) async {
        // حذف الموردين
        await txn.delete('suppliers');

        // إعادة تعيين AUTO_INCREMENT
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "suppliers"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف الموردين: $e');
    }
  }

  /// حذف المنتجات فقط (مع حذف سجلات sale_items المرتبطة)
  Future<void> deleteProductsOnly() async {
    try {
      // تعطيل المفاتيح الخارجية خارج transaction
      await _db.execute('PRAGMA foreign_keys = OFF');

      // نفّذ الحذف داخل معاملة واحدة
      await _db.transaction((txn) async {
        // حذف عناصر المبيعات المرتبطة بالمنتجات
        try {
          await txn.execute('DELETE FROM sale_items');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
        }

        // حذف المنتجات فقط
        try {
          await txn.execute('DELETE FROM products');
        } catch (e) {
          debugPrint('خطأ في حذف products: $e');
          rethrow;
        }

        // إعادة تعيين AUTO_INCREMENT
        try {
          await txn.execute(
              'DELETE FROM sqlite_sequence WHERE name IN ("products", "sale_items")');
        } catch (e) {
          debugPrint('خطأ في إعادة تعيين sqlite_sequence: $e');
        }
      });

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // التأكد من إعادة تفعيل المفاتيح الخارجية حتى في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      debugPrint('خطأ في حذف المنتجات: $e');
      throw Exception('خطأ في حذف المنتجات: $e');
    }
  }

  /// حذف الأقسام الفارغة فقط (التي لا تحتوي على منتجات)
  Future<int> deleteEmptyCategories() async {
    try {
      return await _db.transaction<int>((txn) async {
        final deleted = await txn.rawDelete('''
          DELETE FROM categories
          WHERE id NOT IN (
            SELECT DISTINCT IFNULL(category_id, -1) FROM products
          )
        ''');
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "categories"');
        return deleted;
      });
    } catch (e) {
      throw Exception('خطأ في حذف الأقسام الفارغة: $e');
    }
  }

  /// حذف العملاء الذين ليس لديهم أي مبيعات (مع حذف مدفوعاتهم)
  Future<void> deleteCustomersWithoutSales() async {
    try {
      await _db.transaction((txn) async {
        // حذف المدفوعات للعملاء الذين لا يملكون مبيعات
        await txn.execute('''
          DELETE FROM payments
          WHERE customer_id IN (
            SELECT c.id FROM customers c
            LEFT JOIN sales s ON s.customer_id = c.id
            WHERE s.id IS NULL
          )
        ''');

        // حذف العملاء الذين لا يملكون مبيعات
        await txn.execute('''
          DELETE FROM customers
          WHERE id IN (
            SELECT c.id FROM customers c
            LEFT JOIN sales s ON s.customer_id = c.id
            WHERE s.id IS NULL
          )
        ''');

        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "customers"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف العملاء بدون مبيعات: $e');
    }
  }

  /// حذف المبيعات الأقدم من تاريخ محدد (مع العناصر والأقساط)
  Future<void> deleteSalesBefore(DateTime cutoff) async {
    try {
      final cutoffIso = cutoff.toIso8601String();

      // تعطيل المفاتيح الخارجية خارج transaction
      await _db.execute('PRAGMA foreign_keys = OFF');

      // نفّذ الحذف داخل معاملة واحدة
      await _db.transaction((txn) async {
        // حذف الأقساط المرتبطة بمبيعات قديمة
        try {
          await txn.execute('''
            DELETE FROM installments
            WHERE sale_id IN (
              SELECT id FROM sales WHERE created_at < ?
            )
          ''', [cutoffIso]);
          debugPrint('تم حذف installments القديمة بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف installments: $e');
        }

        // حذف عناصر المبيعات للمبيعات القديمة
        try {
          await txn.execute('''
            DELETE FROM sale_items
            WHERE sale_id IN (
              SELECT id FROM sales WHERE created_at < ?
            )
          ''', [cutoffIso]);
          debugPrint('تم حذف sale_items القديمة بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
        }

        // حذف المبيعات القديمة
        try {
          await txn
              .execute('DELETE FROM sales WHERE created_at < ?', [cutoffIso]);
          debugPrint('تم حذف sales القديمة بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف sales: $e');
          rethrow; // نرمي الخطأ هنا لأن حذف المبيعات مهم
        }

        // إعادة تعيين AUTO_INCREMENT
        try {
          await txn.execute(
              'DELETE FROM sqlite_sequence WHERE name IN ("sales", "sale_items", "installments")');
          debugPrint('تم إعادة تعيين sqlite_sequence بنجاح');
        } catch (e) {
          debugPrint('خطأ في إعادة تعيين sqlite_sequence: $e');
          // لا نرمي الخطأ هنا لأن هذا ليس حرجاً
        }
      });

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // التأكد من إعادة تفعيل المفاتيح الخارجية حتى في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      debugPrint('خطأ في حذف المبيعات القديمة: $e');
      throw Exception('خطأ في حذف المبيعات القديمة: $e');
    }
  }

  /// إعادة تعيين كميات المخزون إلى صفر لجميع المنتجات
  Future<void> resetInventoryToZero() async {
    try {
      await _db.transaction((txn) async {
        await txn.execute('UPDATE products SET quantity = 0');
      });
    } catch (e) {
      throw Exception('خطأ في إعادة تعيين كميات المخزون: $e');
    }
  }

  /// ضغط قاعدة البيانات لتقليل الحجم بعد عمليات الحذف الكبيرة
  Future<void> vacuumDatabase() async {
    try {
      await _db.execute('VACUUM');
    } catch (e) {
      throw Exception('خطأ في ضغط قاعدة البيانات: $e');
    }
  }

  // ==================== دوال إدارة المصروفات ====================

  /// إضافة مصروف جديد
  Future<int> createExpense({
    required String title,
    required double amount,
    required String category,
    String? description,
    DateTime? expenseDate,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final expenseDateStr = (expenseDate ?? DateTime.now()).toIso8601String();

      final id = await _db.insert('expenses', {
        'title': title,
        'amount': amount,
        'category': category,
        'description': description,
        'expense_date': expenseDateStr,
        'created_at': now,
        'updated_at': now,
      });

      return id;
    } catch (e) {
      throw Exception('خطأ في إضافة المصروف: $e');
    }
  }

  /// تحديث مصروف موجود
  Future<void> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String category,
    String? description,
    DateTime? expenseDate,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final expenseDateStr = (expenseDate ?? DateTime.now()).toIso8601String();

      await _db.update(
        'expenses',
        {
          'title': title,
          'amount': amount,
          'category': category,
          'description': description,
          'expense_date': expenseDateStr,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('خطأ في تحديث المصروف: $e');
    }
  }

  /// حذف مصروف
  Future<void> deleteExpense(int id) async {
    try {
      await _db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('خطأ في حذف المصروف: $e');
    }
  }

  /// الحصول على جميع المصروفات
  Future<List<Map<String, dynamic>>> getExpenses({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    try {
      final where = <String>[];
      final whereArgs = <Object?>[];

      if (from != null) {
        where.add('expense_date >= ?');
        whereArgs.add(from.toIso8601String());
      }

      if (to != null) {
        where.add('expense_date <= ?');
        whereArgs.add(to.toIso8601String());
      }

      if (category != null && category.isNotEmpty) {
        where.add('category = ?');
        whereArgs.add(category);
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      return await _db.rawQuery('''
        SELECT * FROM expenses
        $whereClause
        ORDER BY expense_date DESC, created_at DESC
      ''', whereArgs);
    } catch (e) {
      throw Exception('خطأ في جلب المصروفات: $e');
    }
  }

  /// الحصول على مصروف واحد
  Future<Map<String, dynamic>?> getExpense(int id) async {
    try {
      final result = await _db.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return result.isEmpty ? null : result.first;
    } catch (e) {
      throw Exception('خطأ في جلب المصروف: $e');
    }
  }

  /// الحصول على إجمالي المصروفات
  Future<double> getTotalExpenses({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    try {
      final where = <String>[];
      final whereArgs = <Object?>[];

      if (from != null) {
        where.add('expense_date >= ?');
        whereArgs.add(from.toIso8601String());
      }

      if (to != null) {
        where.add('expense_date <= ?');
        whereArgs.add(to.toIso8601String());
      }

      if (category != null && category.isNotEmpty) {
        where.add('category = ?');
        whereArgs.add(category);
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      final result = await _db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total FROM expenses
        $whereClause
      ''', whereArgs);

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('خطأ في حساب إجمالي المصروفات: $e');
    }
  }

  /// الحصول على قائمة أنواع المصروفات
  Future<List<String>> getExpenseCategories() async {
    try {
      final result = await _db.rawQuery('''
        SELECT DISTINCT category FROM expenses
        WHERE category IS NOT NULL AND category != ''
        ORDER BY category
      ''');

      return result.map((row) => row['category']?.toString() ?? '').toList();
    } catch (e) {
      return [];
    }
  }

  /// حذف نوع مصروف (تحديث جميع المصروفات التي تستخدمه إلى "عام")
  Future<int> deleteExpenseCategory(String category) async {
    try {
      if (category == 'عام') {
        throw Exception('لا يمكن حذف النوع الافتراضي "عام"');
      }

      // التحقق من وجود مصروفات تستخدم هذا النوع
      final countResult = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM expenses
        WHERE category = ?
      ''', [category]);

      final count = (countResult.first['count'] as num?)?.toInt() ?? 0;

      if (count > 0) {
        // تحديث جميع المصروفات التي تستخدم هذا النوع إلى "عام"
        final updated = await _db.update(
          'expenses',
          {
            'category': 'عام',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'category = ?',
          whereArgs: [category],
        );
        return updated;
      }

      return 0;
    } catch (e) {
      throw Exception('خطأ في حذف نوع المصروف: $e');
    }
  }

  /// الحصول على عدد المصروفات لنوع معين
  Future<int> getExpenseCountByCategory(String category) async {
    try {
      final result = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM expenses
        WHERE category = ?
      ''', [category]);

      return (result.first['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// الحصول على جميع المعاملات المالية (مبيعات، مصروفات، مدفوعات)
  Future<List<Map<String, dynamic>>> getAllFinancialTransactions({
    DateTime? from,
    DateTime? to,
    String? transactionType,
  }) async {
    try {
      final transactions = <Map<String, dynamic>>[];

      // إضافة المبيعات
      if (transactionType == null || transactionType == 'sales') {
        final where = <String>[];
        final args = <Object?>[];

        if (from != null && to != null) {
          where.add('s.created_at BETWEEN ? AND ?');
          args.addAll([from.toIso8601String(), to.toIso8601String()]);
        }

        final sales = await _db.rawQuery('''
          SELECT 
            s.id,
            s.created_at as transaction_date,
            s.total as amount,
            s.profit,
            s.type,
            c.name as customer_name,
            'sale' as transaction_type,
            'مبيعات' as transaction_type_label,
            CASE 
              WHEN s.type = 'cash' THEN 'نقدي'
              WHEN s.type = 'credit' THEN 'آجل'
              WHEN s.type = 'installment' THEN 'أقساط'
              ELSE s.type
            END as type_label
          FROM sales s
          LEFT JOIN customers c ON c.id = s.customer_id
          ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
          ORDER BY s.created_at DESC
        ''', args);

        transactions.addAll(sales.map((s) => {
              ...s,
              'amount': (s['amount'] as num?)?.toDouble() ?? 0.0,
              'profit': (s['profit'] as num?)?.toDouble() ?? 0.0,
            }));
      }

      // إضافة المصروفات
      if (transactionType == null || transactionType == 'expenses') {
        final where = <String>[];
        final args = <Object?>[];

        if (from != null && to != null) {
          where.add('e.expense_date BETWEEN ? AND ?');
          args.addAll([from.toIso8601String(), to.toIso8601String()]);
        }

        final expenses = await _db.rawQuery('''
          SELECT 
            e.id,
            e.expense_date as transaction_date,
            e.amount,
            e.title,
            e.category,
            e.description,
            NULL as profit,
            'expense' as transaction_type,
            'مصروفات' as transaction_type_label,
            e.category as type_label
          FROM expenses e
          ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
          ORDER BY e.expense_date DESC
        ''', args);

        transactions.addAll(expenses.map((e) => {
              ...e,
              'amount': (e['amount'] as num?)?.toDouble() ?? 0.0,
            }));
      }

      // إضافة المدفوعات
      if (transactionType == null || transactionType == 'payments') {
        final where = <String>[];
        final args = <Object?>[];

        if (from != null && to != null) {
          where.add('p.payment_date BETWEEN ? AND ?');
          args.addAll([from.toIso8601String(), to.toIso8601String()]);
        }

        final payments = await _db.rawQuery('''
          SELECT 
            p.id,
            p.payment_date as transaction_date,
            p.amount,
            p.notes as description,
            c.name as customer_name,
            NULL as profit,
            'payment' as transaction_type,
            'مدفوعات' as transaction_type_label,
            'دفعة' as type_label
          FROM payments p
          JOIN customers c ON c.id = p.customer_id
          ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
          ORDER BY p.payment_date DESC
        ''', args);

        transactions.addAll(payments.map((p) => {
              ...p,
              'amount': (p['amount'] as num?)?.toDouble() ?? 0.0,
            }));
      }

      // ترتيب جميع المعاملات حسب التاريخ
      transactions.sort((a, b) {
        final dateA = a['transaction_date']?.toString() ?? '';
        final dateB = b['transaction_date']?.toString() ?? '';
        return dateB.compareTo(dateA); // الأحدث أولاً
      });

      return transactions;
    } catch (e) {
      throw Exception('خطأ في جلب المعاملات المالية: $e');
    }
  }

  /// الحصول على إحصائيات المصروفات حسب النوع
  Future<Map<String, double>> getExpensesByCategory({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final where = <String>[];
      final whereArgs = <Object?>[];

      if (from != null) {
        where.add('expense_date >= ?');
        whereArgs.add(from.toIso8601String());
      }

      if (to != null) {
        where.add('expense_date <= ?');
        whereArgs.add(to.toIso8601String());
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      final result = await _db.rawQuery('''
        SELECT category, SUM(amount) as total
        FROM expenses
        $whereClause
        GROUP BY category
        ORDER BY total DESC
      ''', whereArgs);

      final map = <String, double>{};
      for (final row in result) {
        final category = row['category']?.toString() ?? 'عام';
        final total = (row['total'] as num?)?.toDouble() ?? 0.0;
        map[category] = total;
      }

      return map;
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات المصروفات: $e');
    }
  }

  /// فحص وإصلاح المستخدمين الافتراضيين
  Future<void> checkAndFixDefaultUsers() async {
    try {
      debugPrint('بدء فحص المستخدمين الافتراضيين...');

      // التحقق من وجود جدول المستخدمين
      final tables = await _db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='users'");

      if (tables.isEmpty) {
        debugPrint('جدول المستخدمين غير موجود، سيتم إنشاؤه...');
        await _createSchema(_db);
        return;
      }

      // حذف المستخدمين المؤقتين (الذين لديهم _conflict_ في اسم المستخدم)
      try {
        final conflictUsers = await _db.query(
          'users',
          where: 'username LIKE ?',
          whereArgs: ['%_conflict_%'],
        );
        if (conflictUsers.isNotEmpty) {
          await _db.delete(
            'users',
            where: 'username LIKE ?',
            whereArgs: ['%_conflict_%'],
          );
          debugPrint('تم حذف ${conflictUsers.length} مستخدم مؤقت');
        }
      } catch (e) {
        debugPrint('خطأ في حذف المستخدمين المؤقتين: $e');
      }

      // إنشاء المستخدمين الافتراضيين ببساطة
      final nowIso = DateTime.now().toIso8601String();
      final defaultUsers = [
        {
          'name': 'المدير',
          'username': 'manager',
          'password': _sha256Hex('admin123'),
          'role': 'manager',
          'employee_code': 'A1',
          'active': 1,
          'created_at': nowIso,
          'updated_at': nowIso,
        },
        {
          'name': 'المشرف',
          'username': 'supervisor',
          'password': _sha256Hex('super123'),
          'role': 'supervisor',
          'employee_code': 'S1',
          'active': 1,
          'created_at': nowIso,
          'updated_at': nowIso,
        },
        {
          'name': 'الموظف',
          'username': 'employee',
          'password': _sha256Hex('emp123'),
          'role': 'employee',
          'employee_code': 'C1',
          'active': 1,
          'created_at': nowIso,
          'updated_at': nowIso,
        },
      ];

      for (final user in defaultUsers) {
        try {
          // محاولة إدراج أو تحديث المستخدم
          await _db.insert('users', user);
          debugPrint('تم إضافة مستخدم: ${user['username']}');
        } catch (e) {
          // إذا فشل الإدراج، جرب التحديث
          try {
            // التحقق من المستخدم الحالي أولاً
            final existing = await _db.query(
              'users',
              where: 'username = ?',
              whereArgs: [user['username']],
              limit: 1,
            );

            if (existing.isNotEmpty) {
              final currentEmployeeCode =
                  existing.first['employee_code']?.toString();
              final desiredEmployeeCode = user['employee_code']?.toString();

              // التحقق من وجود تضارب في employee_code
              bool hasConflict = false;
              if (currentEmployeeCode != desiredEmployeeCode) {
                final conflict = await _db.query(
                  'users',
                  where: 'employee_code = ? AND username != ?',
                  whereArgs: [desiredEmployeeCode, user['username']],
                  limit: 1,
                );
                hasConflict = conflict.isNotEmpty;
              }

              // تحديث الحقول الآمنة فقط (لا employee_code إذا كان هناك تضارب)
              final updateData = <String, dynamic>{
                'name': user['name'],
                'password': user['password'],
                'role': user['role'],
                'active': 1,
                'updated_at': nowIso,
              };

              // تحديث employee_code فقط إذا لم يكن هناك تضارب
              if (!hasConflict && currentEmployeeCode != desiredEmployeeCode) {
                updateData['employee_code'] = user['employee_code'];
              }

              await _db.update(
                'users',
                updateData,
                where: 'username = ?',
                whereArgs: [user['username']],
              );
              debugPrint('تم تحديث مستخدم: ${user['username']}');
            }
          } catch (updateError) {
            debugPrint(
                'فشل في تحديث المستخدم ${user['username']}: $updateError');
          }
        }
      }

      debugPrint('انتهى فحص وإصلاح المستخدمين الافتراضيين');
    } catch (e) {
      debugPrint('خطأ في فحص وإصلاح المستخدمين الافتراضيين: $e');
      // لا نرمي الاستثناء هنا لتجنب تعليق التطبيق
    }
  }
}
