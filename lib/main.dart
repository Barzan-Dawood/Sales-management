// ignore_for_file: unused_local_variable

import 'dart:io';
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
    print('Main: Desktop platform - Using sqflite_common_ffi');
  } else {
    // للمنصات المحمولة (Android/iOS): استخدام المحرك الافتراضي
    print('Main: Mobile platform - Using default sqflite');
  }

  final databaseService = DatabaseService();

  try {
    await databaseService.initialize();

    // تنظيف إضافي لضمان إزالة أي بقايا جداول/مُشغّلات قديمة
    try {
      await databaseService.comprehensiveSalesOldCleanup();
      await databaseService.cleanupAllTriggers();
    } catch (e) {
      assert(() {
        // تجاهُل الخطأ هنا آمن في التطوير، الأهم عدم إيقاف التشغيل
        return true;
      }());
    }

    // تشغيل النسخ الاحتياطي التلقائي في الخلفية
    try {
      await databaseService.runAutoBackup();
    } catch (e) {
      assert(() {
        return true;
      }());
    }

    // فحص سلامة القاعدة ومحاولة الإصلاح التلقائي عند الحاجة
    final issues = await databaseService.checkDatabaseIntegrity();
    if (issues.isNotEmpty) {
      assert(() {
        return true;
      }());

      try {
        await databaseService.forceCleanup();

        // إعادة الفحص بعد التنظيف
        final remainingIssues = await databaseService.checkDatabaseIntegrity();
        if (remainingIssues.isEmpty) {
          assert(() {
            return true;
          }());
        } else {
          assert(() {
            return true;
          }());
          await databaseService.comprehensiveCleanup();

          // فحص نهائي
          final finalIssues = await databaseService.checkDatabaseIntegrity();
          if (finalIssues.isEmpty) {
            assert(() {
              return true;
            }());
          } else {
            assert(() {
              return true;
            }());
            await databaseService.aggressiveCleanup();

            // فحص أخير بعد أقسى تنظيف
            final finalFinalIssues =
                await databaseService.checkDatabaseIntegrity();
            if (finalFinalIssues.isEmpty) {
              assert(() {
                return true;
              }());
            } else {
              assert(() {
                return true;
              }());
            }
          }
        }
      } catch (e) {
        assert(() {
          return true;
        }());
        try {
          await databaseService.comprehensiveCleanup();
          assert(() {
            return true;
          }());
        } catch (comprehensiveError) {
          assert(() {
            return true;
          }());
          try {
            await databaseService.aggressiveCleanup();
            assert(() {
              return true;
            }());
          } catch (aggressiveError) {
            assert(() {
              return true;
            }());
          }
        }
      }
    }
  } catch (e) {
    assert(() {
      return true;
    }());

    // تحسين رسائل الخطأ لعرضها للمستخدم عند الفشل المبكر
    String errorMessage = 'خطأ في تهيئة قاعدة البيانات';
    if (e.toString().contains('database is locked')) {
      errorMessage = 'قاعدة البيانات قيد الاستخدام، يرجى إعادة تشغيل التطبيق';
    } else if (e.toString().contains('no such table')) {
      errorMessage = 'خطأ في هيكل قاعدة البيانات، سيتم إعادة إنشاؤها';
    } else if (e.toString().contains('disk I/O error')) {
      errorMessage = 'خطأ في القرص، تحقق من مساحة التخزين';
    } else {
      errorMessage = 'خطأ في قاعدة البيانات: ${e.toString()}';
    }

    assert(() {
      return true;
    }());

    // محاولة تنظيف طارئة قبل إعادة رمي الاستثناء
    try {
      await databaseService.forceCleanup();
      assert(() {
        return true;
      }());
    } catch (cleanupError) {
      assert(() {
        return true;
      }());
      try {
        await databaseService.comprehensiveCleanup();
        assert(() {
          return true;
        }());
      } catch (comprehensiveError) {
        assert(() {
          return true;
        }());
        try {
          await databaseService.aggressiveCleanup();
          assert(() {
            return true;
          }());
        } catch (aggressiveError) {
          assert(() {
            return true;
          }());
        }
      }
    }
    rethrow;
  }

  final storeConfig = StoreConfig();
  await storeConfig.initialize();

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
