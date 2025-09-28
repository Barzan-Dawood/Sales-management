import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:roj_system/main.dart';
import 'package:roj_system/src/services/db/database_service.dart';
import 'package:roj_system/src/services/auth/auth_provider.dart';

void main() {
  group('Office Management System - Main App Tests', () {
    late DatabaseService databaseService;

    setUpAll(() async {
      databaseService = DatabaseService();
      await databaseService.initialize();
    });

    tearDownAll(() async {
      await databaseService.database.close();
    });

    testWidgets('App should start and show login screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<DatabaseService>.value(value: databaseService),
          ChangeNotifierProvider(create: (_) => AuthProvider(databaseService)),
        ],
        child: const MyApp(),
      ));

      await tester.pumpAndSettle();

      // Verify app title is displayed
      expect(find.text('نظام إدارة المكتب'), findsOneWidget);
    });

    testWidgets('App should handle authentication flow',
        (WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<DatabaseService>.value(value: databaseService),
          ChangeNotifierProvider(create: (_) => AuthProvider(databaseService)),
        ],
        child: const MyApp(),
      ));

      await tester.pumpAndSettle();

      // Check if login screen is shown when not authenticated
      expect(find.byType(TextField), findsWidgets);
    });
  });
}
