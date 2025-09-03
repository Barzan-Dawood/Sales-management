import 'dart:io';

import 'package:file_picker/file_picker.dart';

class CsvExporter {
  static Future<String?> exportRows(
      String filename, List<List<String>> rows) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ ملف CSV',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (path == null) return null;
    final csv = rows.map((r) => r.map(_escape).join(',')).join('\n');
    await File(path).writeAsString(csv);
    return path;
  }

  static String _escape(String input) {
    final needsQuotes =
        input.contains(',') || input.contains('"') || input.contains('\n');
    final escaped = input.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }
}
