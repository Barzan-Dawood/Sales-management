// هذا الملف يحتوي على أوامر لتحديث جميع الشاشات المتبقية للوضع الليلي
// يمكن تشغيل هذا الملف لتحديث جميع الشاشات دفعة واحدة

import 'dart:io';

void main() async {
  print('بدء تحديث جميع الشاشات للوضع الليلي...');

  // قائمة الشاشات المتبقية للتحديث
  final screensToUpdate = [
    'lib/src/screens/dashboard_screen.dart',
    'lib/src/screens/customers_screen.dart',
    'lib/src/screens/suppliers_screen.dart',
    'lib/src/screens/accounting_screen.dart',
    'lib/src/screens/reports_screen.dart',
    'lib/src/screens/debts_screen.dart',
    'lib/src/screens/sales_history_screen.dart',
    'lib/src/screens/advanced_reports_screen.dart',
    'lib/src/screens/tests_screen.dart',
    'lib/src/screens/inventory_screen.dart',
  ];

  for (final screenPath in screensToUpdate) {
    await updateScreenForDarkMode(screenPath);
  }

  print('تم تحديث جميع الشاشات بنجاح!');
}

Future<void> updateScreenForDarkMode(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      print('الملف غير موجود: $filePath');
      return;
    }

    String content = await file.readAsString();

    // إضافة import للـ dark_mode_utils
    if (!content.contains('dark_mode_utils.dart')) {
      content = content.replaceFirst(
        RegExp(r"import '\.\./utils/[^']*';"),
        "import '../utils/dark_mode_utils.dart';\nimport '../utils/screen_updater.dart';",
      );
    }

    // تحديث الألوان الثابتة
    content = updateHardcodedColors(content);

    // كتابة الملف المحدث
    await file.writeAsString(content);
    print('تم تحديث: $filePath');
  } catch (e) {
    print('خطأ في تحديث $filePath: $e');
  }
}

String updateHardcodedColors(String content) {
  // تحديث الألوان الثابتة الشائعة
  final colorReplacements = {
    'Colors.white': 'DarkModeUtils.getCardColor(context)',
    'Colors.grey.shade300': 'DarkModeUtils.getBorderColor(context)',
    'Colors.grey.shade100':
        'DarkModeUtils.getSurfaceColor(context).withOpacity(0.5)',
    'Colors.grey.shade50': 'DarkModeUtils.getBackgroundColor(context)',
    'Colors.grey.shade600': 'DarkModeUtils.getSecondaryTextColor(context)',
    'Colors.grey.shade700': 'DarkModeUtils.getTextColor(context)',
    'Colors.grey.shade400': 'DarkModeUtils.getSecondaryTextColor(context)',
    'Colors.black87': 'DarkModeUtils.getTextColor(context)',
    'Colors.black54': 'DarkModeUtils.getSecondaryTextColor(context)',
    'Colors.red': 'DarkModeUtils.getErrorColor(context)',
    'Colors.green': 'DarkModeUtils.getSuccessColor(context)',
    'Colors.orange': 'DarkModeUtils.getWarningColor(context)',
    'Colors.blue': 'DarkModeUtils.getInfoColor(context)',
  };

  for (final entry in colorReplacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  // تحديث BoxDecoration الشائعة
  content = content.replaceAll(
    RegExp(r'BoxDecoration\(\s*color: Colors\.white,'),
    'BoxDecoration(\n        color: DarkModeUtils.getCardColor(context),',
  );

  // تحديث Container decorations
  content = content.replaceAll(
    RegExp(r'Container\(\s*decoration: BoxDecoration\('),
    'Container(\n        decoration: DarkModeUtils.createContainerDecoration(context).copyWith(',
  );

  return content;
}
