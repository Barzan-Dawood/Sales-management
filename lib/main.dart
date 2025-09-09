import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'src/app_shell.dart';
import 'src/services/db/database_service.dart';
import 'src/services/auth/auth_provider.dart';
import 'src/utils/strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final databaseService = DatabaseService();

  try {
    await databaseService.initialize();

    // Check database integrity and perform cleanup if needed
    final issues = await databaseService.checkDatabaseIntegrity();
    if (issues.isNotEmpty) {
      print('Database integrity issues found: ${issues.join(', ')}');
      print('Performing automatic cleanup...');

      try {
        await databaseService.forceCleanup();

        // Check again after cleanup
        final remainingIssues = await databaseService.checkDatabaseIntegrity();
        if (remainingIssues.isEmpty) {
          print('Database cleanup completed successfully');
        } else {
          print(
              'Some issues remain after normal cleanup: ${remainingIssues.join(', ')}');
          print('Performing aggressive cleanup...');
          await databaseService.aggressiveCleanup();

          // Final check
          final finalIssues = await databaseService.checkDatabaseIntegrity();
          if (finalIssues.isEmpty) {
            print('Aggressive cleanup completed successfully');
          } else {
            print('Some issues still remain: ${finalIssues.join(', ')}');
          }
        }
      } catch (e) {
        print('Normal cleanup failed, trying aggressive cleanup: $e');
        try {
          await databaseService.aggressiveCleanup();
          print('Aggressive cleanup completed');
        } catch (aggressiveError) {
          print('Aggressive cleanup also failed: $aggressiveError');
        }
      }
    }
  } catch (e) {
    print('Error initializing database: $e');
    // Try to perform emergency cleanup
    try {
      await databaseService.forceCleanup();
      print('Emergency cleanup completed');
    } catch (cleanupError) {
      print(
          'Emergency cleanup failed, trying aggressive cleanup: $cleanupError');
      try {
        await databaseService.aggressiveCleanup();
        print('Emergency aggressive cleanup completed');
      } catch (aggressiveError) {
        print('Emergency aggressive cleanup also failed: $aggressiveError');
      }
    }
    rethrow;
  }

  runApp(MultiProvider(
    providers: [
      Provider<DatabaseService>.value(value: databaseService),
      ChangeNotifierProvider(create: (_) => AuthProvider(databaseService)),
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
      title: AppStrings.appTitle,
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
