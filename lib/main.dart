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
import 'src/utils/app_themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة بيانات اللغة العربية
  await initializeDateFormatting('ar_IQ', null);
  // Basic crash reporting hook (prints in debug, can be wired to a service later)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    assert(() {
      // Only log stack in debug/profile
      // In release, integrate with a reporting service (e.g., Sentry) later
      debugPrint(details.toStringShort());
      return true;
    }());
  };
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final databaseService = DatabaseService();

  try {
    await databaseService.initialize();

    // تنظيف إضافي للتأكد من عدم وجود مراجع لـ sales_old
    try {
      await databaseService.comprehensiveSalesOldCleanup();
      await databaseService.cleanupAllTriggers();
    } catch (e) {
      assert(() {
        // Log details only in debug/profile builds
        return true;
      }());
    }

    // تشغيل النسخ الاحتياطي التلقائي
    try {
      await databaseService.runAutoBackup();
    } catch (e) {
      assert(() {
        return true;
      }());
    }

    // Check database integrity and perform cleanup if needed
    final issues = await databaseService.checkDatabaseIntegrity();
    if (issues.isNotEmpty) {
      assert(() {
        return true;
      }());

      try {
        await databaseService.forceCleanup();

        // Check again after cleanup
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

          // Final check
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

            // Final final check
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

    // تحسين رسائل الخطأ
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

    // Try to perform emergency cleanup
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

  runApp(MultiProvider(
    providers: [
      Provider<DatabaseService>.value(value: databaseService),
      ChangeNotifierProvider(create: (_) => AuthProvider(databaseService)),
      ChangeNotifierProvider.value(value: storeConfig),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LicenseProvider()),
    ],
    child: const MyApp(),
  ));
}

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
          home: const Directionality(
              textDirection: TextDirection.rtl, child: AppShell()),
        );
      },
    );
  }
}
