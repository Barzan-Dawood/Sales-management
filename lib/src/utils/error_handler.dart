import 'package:flutter/material.dart';

/// معالج الأخطاء المحسن
class ErrorHandler {
  /// معالجة الأخطاء مع عرض رسائل واضحة
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    bool showSnackBar = true,
    bool showDialog = false,
  }) {
    String message = customMessage ?? _getErrorMessage(error);

    if (showSnackBar) {
      _showErrorSnackBar(context, message);
    }

    if (showDialog) {
      _showErrorDialog(context, message);
    }

    // تسجيل الخطأ للتشخيص
    debugPrint('خطأ في التطبيق: $error');
  }

  /// الحصول على رسالة خطأ واضحة
  static String _getErrorMessage(dynamic error) {
    if (error == null) return 'حدث خطأ غير معروف';

    final errorString = error.toString().toLowerCase();

    // رسائل خطأ باللغة العربية
    if (errorString.contains('network')) {
      return 'خطأ في الاتصال بالشبكة';
    } else if (errorString.contains('database')) {
      return 'خطأ في قاعدة البيانات';
    } else if (errorString.contains('permission')) {
      return 'ليس لديك صلاحية لهذا الإجراء';
    } else if (errorString.contains('not found')) {
      return 'العنصر المطلوب غير موجود';
    } else if (errorString.contains('duplicate')) {
      return 'العنصر موجود بالفعل';
    } else if (errorString.contains('constraint')) {
      return 'خطأ في البيانات المدخلة';
    } else if (errorString.contains('timeout')) {
      return 'انتهت مهلة العملية';
    } else {
      return 'حدث خطأ: ${error.toString()}';
    }
  }

  /// عرض رسالة خطأ في SnackBar
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// عرض رسالة خطأ في Dialog
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// معالجة الأخطاء مع إعادة المحاولة
  static Future<T?> handleWithRetry<T>(
    BuildContext context,
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (error) {
        if (i == maxRetries - 1) {
          handleError(context, error);
          return null;
        }

        // انتظار قبل إعادة المحاولة
        await Future.delayed(delay);
      }
    }
    return null;
  }

  /// معالجة الأخطاء مع عرض مؤشر تحميل
  static Future<T?> handleWithLoading<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String loadingMessage = 'جاري المعالجة...',
  }) async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(loadingMessage),
          ],
        ),
      ),
    );

    try {
      final result = await operation();
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل
      return result;
    } catch (error) {
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل
      handleError(context, error);
      return null;
    }
  }
}
