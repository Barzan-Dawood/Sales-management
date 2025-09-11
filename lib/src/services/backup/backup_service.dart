import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../db/database_service.dart';

class BackupService {
  BackupService(this._db);
  final DatabaseService _db;

  Future<String?> backupDatabase() async {
    final dbPath = _db.databasePath;
    final defaultName = 'backup_${DateTime.now().millisecondsSinceEpoch}.db';
    final output = await FilePicker.platform.saveFile(
      dialogTitle: 'Select backup destination',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (output == null) return null;
    await File(dbPath).copy(output);
    return output;
  }

  /// إنشاء نسخة احتياطية مباشرة داخل مجلد محدد بدون حوار
  Future<String> backupToDirectory(String directoryPath) async {
    final dbPath = _db.databasePath;
    final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.db';
    final output = p.join(directoryPath, fileName);
    await File(output).parent.create(recursive: true);
    await File(dbPath).copy(output);
    return output;
  }

  Future<String?> restoreDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (result == null || result.files.single.path == null) return null;
    final source = result.files.single.path!;
    final dest = _db.databasePath;
    await _db.database.close();
    await File(source).copy(dest);
    await _db.reopen();
    return p.basename(source);
  }

  /// نسخ احتياطي للمنتجات والأقسام فقط
  Future<String?> backupProductsAndCategories() async {
    final defaultName =
        'products_categories_backup_${DateTime.now().millisecondsSinceEpoch}.db';
    final output = await FilePicker.platform.saveFile(
      dialogTitle: 'اختيار مكان حفظ نسخة المنتجات والأقسام',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (output == null) return null;

    try {
      // إنشاء قاعدة بيانات مؤقتة للنسخ الاحتياطي
      final tempDb = await openDatabase(output, version: 1);

      // إنشاء جداول المنتجات والأقسام
      await tempDb.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          description TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
      ''');

      await tempDb.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          price REAL NOT NULL,
          cost REAL NOT NULL,
          stock INTEGER NOT NULL DEFAULT 0,
          category_id INTEGER,
          barcode TEXT,
          image_path TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY(category_id) REFERENCES categories(id)
        );
      ''');

      // نسخ البيانات من قاعدة البيانات الرئيسية
      final categories =
          await _db.database.rawQuery('SELECT * FROM categories');
      for (final category in categories) {
        await tempDb.insert('categories', category);
      }

      final products = await _db.database.rawQuery('SELECT * FROM products');
      for (final product in products) {
        await tempDb.insert('products', product);
      }

      await tempDb.close();
      return output;
    } catch (e) {
      print('خطأ في نسخ المنتجات والأقسام: $e');
      return null;
    }
  }

  /// استعادة المنتجات والأقسام من نسخة احتياطية
  Future<String?> restoreProductsAndCategories() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (result == null || result.files.single.path == null) return null;

    final source = result.files.single.path!;

    try {
      // فتح قاعدة البيانات المصدر
      final sourceDb = await openDatabase(source, version: 1);

      // التحقق من وجود الجداول المطلوبة
      final categoriesCheck = await sourceDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='categories'");
      final productsCheck = await sourceDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='products'");

      if (categoriesCheck.isEmpty || productsCheck.isEmpty) {
        await sourceDb.close();
        throw Exception('الملف لا يحتوي على جداول المنتجات والأقسام المطلوبة');
      }

      // بدء المعاملة
      await _db.database.transaction((txn) async {
        // حذف البيانات الموجودة
        await txn.execute('DELETE FROM products');
        await txn.execute('DELETE FROM categories');

        // استعادة الأقسام
        final categories = await sourceDb.rawQuery('SELECT * FROM categories');
        for (final category in categories) {
          await txn.insert('categories', category);
        }

        // استعادة المنتجات
        final products = await sourceDb.rawQuery('SELECT * FROM products');
        for (final product in products) {
          await txn.insert('products', product);
        }
      });

      await sourceDb.close();
      return p.basename(source);
    } catch (e) {
      print('خطأ في استعادة المنتجات والأقسام: $e');
      return null;
    }
  }
}
