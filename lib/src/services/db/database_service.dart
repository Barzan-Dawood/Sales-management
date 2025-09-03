import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static const String _dbName = 'pos_office.db';
  static const int _dbVersion = 1;

  late final Database _db;
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Add migrations here as schema evolves
        await _ensureCategorySchemaOn(db);
      },
    );
    // Ensure new tables/columns exist even if version didn't change
    await _ensureCategorySchemaOn(_db);
  }

  Future<void> reopen() async {
    await _db.close();
    _db = await openDatabase(_dbPath, version: _dbVersion);
    await _ensureCategorySchemaOn(_db);
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
        type TEXT NOT NULL CHECK(type IN ('cash','installment')),
        created_at TEXT NOT NULL,
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
        logo_path TEXT
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

  Future<void> _seedData(Database db) async {
    await db.insert('users', {
      'name': 'Administrator',
      'username': 'admin',
      'password': 'admin', // For demo; replace with hash in production
      'role': 'manager',
      'active': 1,
    });
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

  Future<int> deleteCustomer(int id) =>
      _db.delete('customers', where: 'id = ?', whereArgs: [id]);

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

  // Sales and installments (simplified)
  Future<int> createSale(
      {int? customerId,
      required String type,
      required List<Map<String, Object?>> items,
      bool decrementStock = true}) async {
    return _db.transaction<int>((txn) async {
      double total = 0;
      double profit = 0;
      for (final it in items) {
        final price = (it['price'] as num).toDouble();
        final cost = (it['cost'] as num).toDouble();
        final qty = (it['quantity'] as num).toInt();
        total += price * qty;
        profit += (price - cost) * qty;
      }
      final saleId = await txn.insert('sales', {
        'customer_id': customerId,
        'total': total,
        'profit': profit,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      });
      for (final it in items) {
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
}
