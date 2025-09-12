import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'src/app_shell.dart';
import 'src/services/db/database_service.dart';
import 'src/services/auth/auth_provider.dart';
import 'src/services/store_config.dart';
import 'src/utils/strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        print('Error during sales_old cleanup: $e');
        return true;
      }());
    }

    // Check database integrity and perform cleanup if needed
    final issues = await databaseService.checkDatabaseIntegrity();
    if (issues.isNotEmpty) {
      assert(() {
        print('Database integrity issues found: ${issues.join(', ')}');
        print('Performing automatic cleanup...');
        return true;
      }());

      try {
        await databaseService.forceCleanup();

        // Check again after cleanup
        final remainingIssues = await databaseService.checkDatabaseIntegrity();
        if (remainingIssues.isEmpty) {
          assert(() {
            print('Database cleanup completed successfully');
            return true;
          }());
        } else {
          assert(() {
            print(
                'Some issues remain after normal cleanup: ${remainingIssues.join(', ')}');
            print('Performing comprehensive cleanup...');
            return true;
          }());
          await databaseService.comprehensiveCleanup();

          // Final check
          final finalIssues = await databaseService.checkDatabaseIntegrity();
          if (finalIssues.isEmpty) {
            assert(() {
              print('Comprehensive cleanup completed successfully');
              return true;
            }());
          } else {
            assert(() {
              print(
                  'Some issues still remain, trying aggressive cleanup: ${finalIssues.join(', ')}');
              return true;
            }());
            await databaseService.aggressiveCleanup();

            // Final final check
            final finalFinalIssues =
                await databaseService.checkDatabaseIntegrity();
            if (finalFinalIssues.isEmpty) {
              assert(() {
                print('Aggressive cleanup completed successfully');
                return true;
              }());
            } else {
              assert(() {
                print(
                    'Some issues still remain: ${finalFinalIssues.join(', ')}');
                return true;
              }());
            }
          }
        }
      } catch (e) {
        assert(() {
          print('Normal cleanup failed, trying comprehensive cleanup: $e');
          return true;
        }());
        try {
          await databaseService.comprehensiveCleanup();
          assert(() {
            print('Comprehensive cleanup completed');
            return true;
          }());
        } catch (comprehensiveError) {
          assert(() {
            print(
                'Comprehensive cleanup failed, trying aggressive cleanup: $comprehensiveError');
            return true;
          }());
          try {
            await databaseService.aggressiveCleanup();
            assert(() {
              print('Aggressive cleanup completed');
              return true;
            }());
          } catch (aggressiveError) {
            assert(() {
              print('Aggressive cleanup also failed: $aggressiveError');
              return true;
            }());
          }
        }
      }
    }
  } catch (e) {
    assert(() {
      print('Error initializing database: $e');
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
      print('Database error: $errorMessage');
      return true;
    }());

    // Try to perform emergency cleanup
    try {
      await databaseService.forceCleanup();
      assert(() {
        print('Emergency cleanup completed');
        return true;
      }());
    } catch (cleanupError) {
      assert(() {
        print(
            'Emergency cleanup failed, trying comprehensive cleanup: $cleanupError');
        return true;
      }());
      try {
        await databaseService.comprehensiveCleanup();
        assert(() {
          print('Emergency comprehensive cleanup completed');
          return true;
        }());
      } catch (comprehensiveError) {
        assert(() {
          print(
              'Emergency comprehensive cleanup failed, trying aggressive cleanup: $comprehensiveError');
          return true;
        }());
        try {
          await databaseService.aggressiveCleanup();
          assert(() {
            print('Emergency aggressive cleanup completed');
            return true;
          }());
        } catch (aggressiveError) {
          assert(() {
            print('Emergency aggressive cleanup also failed: $aggressiveError');
            print(
                'Critical database error - application may not function properly');
            return true;
          }());
        }
      }
    }
    rethrow;
  }

  final storeConfig = StoreConfig();
  await storeConfig.loadFromAssets();

  runApp(MultiProvider(
    providers: [
      Provider<DatabaseService>.value(value: databaseService),
      ChangeNotifierProvider(create: (_) => AuthProvider(databaseService)),
      ChangeNotifierProvider.value(value: storeConfig),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: context.watch<StoreConfig>().appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        snackBarTheme:
            const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const Directionality(
          textDirection: TextDirection.rtl, child: AppShell()),
    );
  }
}
