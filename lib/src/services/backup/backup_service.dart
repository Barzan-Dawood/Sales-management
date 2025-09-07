import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

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
}
