import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:file_picker/file_picker.dart';

class DatabaseMigrationService {
  static const String _databaseName = 'office_management.db';
  static const int _currentVersion = 1;

  // إصدارات قاعدة البيانات
  static const Map<int, String> _versionHistory = {
    1: 'الإصدار الأولي - نظام إدارة المكتب الأساسي',
    2: 'إضافة دعم النسخ الاحتياطي السحابي',
    3: 'تحسينات الأداء والاستقرار',
  };

  /// الحصول على معلومات قاعدة البيانات الحالية
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final db = await _getDatabase();
      final version = await db.getVersion();
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");

      return {
        'version': version,
        'versionDescription': _versionHistory[version] ?? 'إصدار غير معروف',
        'tablesCount': tables.length,
        'tables': tables.map((table) => table['name']).toList(),
        'databasePath': db.path,
        'databaseSize': await _getDatabaseSize(db.path),
      };
    } catch (e) {
      throw Exception('خطأ في الحصول على معلومات قاعدة البيانات: $e');
    }
  }

  /// إنشاء نسخة احتياطية من قاعدة البيانات
  static Future<String> createBackup() async {
    try {
      final db = await _getDatabase();
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(documentsDir.path, 'backups'));

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath =
          path.join(backupDir.path, 'office_management_backup_$timestamp.db');

      // نسخ قاعدة البيانات
      await File(db.path).copy(backupPath);

      return backupPath;
    } catch (e) {
      throw Exception('خطأ في إنشاء النسخة الاحتياطية: $e');
    }
  }

  /// استعادة قاعدة البيانات من ملف
  static Future<void> restoreFromFile() async {
    try {
      // اختيار ملف النسخة الاحتياطية
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final backupPath = result.files.single.path!;
        final db = await _getDatabase();

        // إغلاق قاعدة البيانات الحالية
        await db.close();

        // نسخ النسخة الاحتياطية إلى قاعدة البيانات الحالية
        await File(backupPath).copy(db.path);

        // إعادة فتح قاعدة البيانات
        await _getDatabase();
      }
    } catch (e) {
      throw Exception('خطأ في استعادة قاعدة البيانات: $e');
    }
  }

  /// ترحيل قاعدة البيانات إلى إصدار أحدث
  static Future<void> migrateToNewVersion() async {
    try {
      final db = await _getDatabase();
      final currentVersion = await db.getVersion();

      if (currentVersion < _currentVersion) {
        await _performMigration(db, currentVersion, _currentVersion);
      }
    } catch (e) {
      throw Exception('خطأ في ترحيل قاعدة البيانات: $e');
    }
  }

  /// تصدير قاعدة البيانات
  static Future<String> exportDatabase() async {
    try {
      final db = await _getDatabase();
      final documentsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(path.join(documentsDir.path, 'exports'));

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportPath =
          path.join(exportDir.path, 'office_management_export_$timestamp.db');

      await File(db.path).copy(exportPath);

      return exportPath;
    } catch (e) {
      throw Exception('خطأ في تصدير قاعدة البيانات: $e');
    }
  }

  /// استيراد قاعدة البيانات
  static Future<void> importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final importPath = result.files.single.path!;
        final db = await _getDatabase();

        // إغلاق قاعدة البيانات الحالية
        await db.close();

        // نسخ قاعدة البيانات المستوردة
        await File(importPath).copy(db.path);

        // إعادة فتح قاعدة البيانات
        await _getDatabase();
      }
    } catch (e) {
      throw Exception('خطأ في استيراد قاعدة البيانات: $e');
    }
  }

  /// الحصول على قائمة النسخ الاحتياطية
  static Future<List<Map<String, dynamic>>> getBackupList() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(documentsDir.path, 'backups'));

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir.list().toList();
      final backups = <Map<String, dynamic>>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.db')) {
          final stat = await file.stat();
          backups.add({
            'path': file.path,
            'name': path.basename(file.path),
            'size': stat.size,
            'created': stat.modified,
          });
        }
      }

      // ترتيب حسب تاريخ الإنشاء (الأحدث أولاً)
      backups.sort((a, b) =>
          (b['created'] as DateTime).compareTo(a['created'] as DateTime));

      return backups;
    } catch (e) {
      throw Exception('خطأ في الحصول على قائمة النسخ الاحتياطية: $e');
    }
  }

  /// حذف نسخة احتياطية
  static Future<void> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('خطأ في حذف النسخة الاحتياطية: $e');
    }
  }

  // الوظائف المساعدة
  static Future<Database> _getDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDir.path, _databaseName);

    return await openDatabase(
      dbPath,
      version: _currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // إنشاء الجداول الأساسية
    await _createTables(db);
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    await _performMigration(db, oldVersion, newVersion);
  }

  static Future<void> _performMigration(
      Database db, int fromVersion, int toVersion) async {
    for (int version = fromVersion + 1; version <= toVersion; version++) {
      switch (version) {
        case 2:
          await _migrateToVersion2(db);
          break;
        case 3:
          await _migrateToVersion3(db);
          break;
        // إضافة المزيد من الإصدارات هنا
      }
    }
  }

  static Future<void> _migrateToVersion2(Database db) async {
    // إضافة جداول جديدة أو تعديل الجداول الموجودة
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cloud_backups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        backup_name TEXT NOT NULL,
        cloud_path TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        size INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> _migrateToVersion3(Database db) async {
    // تحسينات الأداء
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(created_at)
    ''');
  }

  static Future<void> _createTables(Database db) async {
    // إنشاء الجداول الأساسية
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER DEFAULT 0,
        category TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT,
        total REAL NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  static Future<int> _getDatabaseSize(String dbPath) async {
    try {
      final file = File(dbPath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
