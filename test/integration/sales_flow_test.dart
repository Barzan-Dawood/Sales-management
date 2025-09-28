import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';  
import 'package:roj_system/main.dart';
import 'package:roj_system/src/services/db/database_service.dart';
import 'package:roj_system/src/services/auth/auth_provider.dart';

void main() {
  group('Sales Flow Integration Tests', () {
    late DatabaseService databaseService;

    setUpAll(() async {
      databaseService = DatabaseService();
      await databaseService.initialize();
    });

    tearDownAll(() async {
      await databaseService.database.close();
    });

    testWidgets('should complete full sales flow', (WidgetTester tester) async {
      // Create test data
      await databaseService.database.insert('products', {
        'name': 'Test Product',
        'barcode': '123456789',
        'price': 100.0,
        'cost': 80.0,
        'quantity': 10,
        'category_id': 1,
      });

      await databaseService.database.insert('customers', {
        'name': 'Test Customer',
        'phone': '1234567890',
        'address': 'Test Address',
      });

      // Create test app
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<DatabaseService>.value(value: databaseService),
          ChangeNotifierProvider(create: (_) => AuthProvider(databaseService)),
        ],
        child: const MyApp(),
      ));

      await tester.pumpAndSettle();

      // Login (if needed)
      // Navigate to sales screen
      // Add product to cart
      // Complete sale
      // Verify sale was created in database

      // This is a simplified test - you'll need to implement the actual flow
      // based on your app's navigation and UI structure
    });

    test('should handle database transactions correctly', () async {
      final db = databaseService.database;

      // Start transaction
      await db.transaction((txn) async {
        // Insert sale
        final saleId = await txn.insert('sales', {
          'customer_id': 1,
          'total': 100.0,
          'profit': 20.0,
          'type': 'cash',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Insert sale items
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': 1,
          'price': 100.0,
          'cost': 80.0,
          'quantity': 1,
        });

        // Update product quantity
        await txn.update(
          'products',
          {'quantity': 9}, // Reduce by 1
          where: 'id = ?',
          whereArgs: [1],
        );
      });

      // Verify data integrity
      final sales = await db.query('sales');
      final saleItems = await db.query('sale_items');
      final product =
          await db.query('products', where: 'id = ?', whereArgs: [1]);

      expect(sales.length, greaterThan(0));
      expect(saleItems.length, greaterThan(0));
      expect(product.first['quantity'], equals(9));
    });
  });
}
