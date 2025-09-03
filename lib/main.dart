import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'src/app_shell.dart';
import 'src/services/db/database_service.dart';
import 'src/services/auth/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final databaseService = DatabaseService();
  await databaseService.initialize();

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
      title: 'نظام نقاط البيع - إدارة المحل',
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
