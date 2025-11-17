import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tijarati/src/screens/products/products_screen.dart';
import 'package:tijarati/src/services/db/database_service.dart';
import 'package:tijarati/src/services/auth/auth_provider.dart';

void main() {
  group('ProductsScreen Widget Tests', () {
    late DatabaseService databaseService;

    setUpAll(() async {
      // Initialize database for testing
      databaseService = DatabaseService();
      await databaseService.initialize();
    });

    tearDownAll(() async {
      await databaseService.database.close();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          Provider<DatabaseService>.value(value: databaseService),
          ChangeNotifierProvider(create: (_) => AuthProvider(databaseService)),
        ],
        child: MaterialApp(
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: ProductsScreen(),
          ),
        ),
      );
    }

    testWidgets('should display products screen with search field',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check if search field is present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('البحث عن المنتجات...'), findsOneWidget);
    });

    testWidgets('should display add product button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check if add product button is present
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('إضافة منتج'), findsOneWidget);
    });

    testWidgets('should open add product dialog when add button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap add product button
      await tester.tap(find.text('إضافة منتج'));
      await tester.pumpAndSettle();

      // Check if dialog is opened
      expect(find.text('إضافة منتج جديد'), findsOneWidget);
      expect(find.text('اسم المنتج'), findsOneWidget);
      expect(find.text('السعر'), findsOneWidget);
      expect(find.text('الكمية'), findsOneWidget);
    });

    testWidgets('should validate required fields in add product form',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open add product dialog
      await tester.tap(find.text('إضافة منتج'));
      await tester.pumpAndSettle();

      // Try to save without filling required fields
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Check if validation errors are shown
      expect(find.text('اسم المنتج مطلوب'), findsOneWidget);
      expect(find.text('السعر مطلوب'), findsOneWidget);
      expect(find.text('الكمية مطلوبة'), findsOneWidget);
    });

    testWidgets('should filter products when searching',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Check if search is performed (this depends on your implementation)
      // You might need to adjust this based on how your search works
    });
  });
}
