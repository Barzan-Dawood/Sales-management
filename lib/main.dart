import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'src/app_shell.dart';
import 'src/services/db/database_service.dart';
import 'src/services/auth/auth_provider.dart';
import 'src/services/store_config.dart';
import 'src/services/theme_provider.dart';
import 'src/services/license/license_provider.dart';
import 'src/services/dashboard_view_model.dart';
import 'src/services/sales_history_view_model.dart';
import 'src/services/auto_backup_service.dart';
import 'src/utils/app_themes.dart';

/// نقطة الدخول للتطبيق
/// - تهيئة البيئة العامة وبيانات اللغة العربية
/// - اختيار محرك قاعدة البيانات حسب المنصة (مكتبي/محمول)
/// - تهيئة قاعدة البيانات مع محاولات تنظيف تلقائية عند وجود مشاكل
/// - إعداد مزودي الحالة (Providers) وتشغيل التطبيق
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة بيانات اللغة العربية
  await initializeDateFormatting('ar_IQ', null);
  // نقطة مركزية لالتقاط أخطاء Flutter
  // في وضع التطوير تطبع الأخطاء، ويمكن لاحقًا ربطها بخدمة تتبع (Sentry مثلًا)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    assert(() {
      // يسجّل التتبع في وضع التطوير فقط
      debugPrint(details.toStringShort());
      return true;
    }());
  };
  // تهيئة قاعدة البيانات حسب المنصة
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // للمنصات المكتبية: استخدام محرك FFI للتوافق والأداء
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    // للمنصات المحمولة (Android/iOS): استخدام المحرك الافتراضي
  }

  final databaseService = DatabaseService();

  try {
    await databaseService.initialize();
  } catch (e) {
    // محاولة تنظيف بسيط فقط
    try {
      await databaseService.forceCleanup();
      await databaseService.initialize();
    } catch (cleanupError) {
      rethrow;
    }
  }

  final storeConfig = StoreConfig();
  await storeConfig.initialize();

  // تهيئة خدمة النسخ الاحتياطي التلقائي
  final autoBackupService = AutoBackupService();
  await autoBackupService.initialize(databaseService);

  // إعداد مزودي الحالة وتشغيل التطبيق
  runApp(MultiProvider(
    providers: [
      Provider<DatabaseService>.value(value: databaseService),
      ChangeNotifierProvider(create: (_) => AuthProvider(databaseService)),
      ChangeNotifierProvider.value(value: storeConfig),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LicenseProvider()),
      ChangeNotifierProvider(
          create: (_) => DashboardViewModel(databaseService)),
      ChangeNotifierProvider(
          create: (_) => SalesHistoryViewModel(databaseService)),
    ],
    child: const MyApp(),
  ));
}

/// الجذر الأساسي للتطبيق، يطبّق السمات والاتجاه ويحقن `AppShell`
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StoreConfig, ThemeProvider>(
      builder: (context, storeConfig, themeProvider, child) {
        return MaterialApp(
          title: storeConfig.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          // فرض اتجاه من اليمين لليسار لجميع الواجهات العربية
          home: const Directionality(
              textDirection: TextDirection.rtl, child: AppShell()),
        );
      },
    );
  }
}
