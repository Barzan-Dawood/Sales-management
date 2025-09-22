import 'package:flutter_test/flutter_test.dart';
import 'package:rojsoft_manager/src/services/db/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
 
void main() {
  group('DatabaseService Tests', () {
    late DatabaseService databaseService;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      databaseService = DatabaseService();
      await databaseService.initialize();
    });

    tearDown(() async {
      await databaseService.database.close();
    });

    test('should initialize database successfully', () async {
      expect(databaseService.database, isNotNull);
      expect(databaseService.databasePath, isNotEmpty);
    });

    test('should create all required tables', () async {
      final db = databaseService.database;

      // Check if all core tables exist
      final tables = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

      final tableNames = tables.map((t) => t['name'] as String).toList();

      expect(tableNames, contains('users'));
      expect(tableNames, contains('products'));
      expect(tableNames, contains('categories'));
      expect(tableNames, contains('customers'));
      expect(tableNames, contains('suppliers'));
      expect(tableNames, contains('sales'));
      expect(tableNames, contains('sale_items'));
      expect(tableNames, contains('installments'));
    });

    test('should insert and retrieve products', () async {
      final productData = {
        'name': 'Test Product',
        'barcode': '123456789',
        'price': 100.0,
        'cost': 80.0,
        'quantity': 50,
        'category_id': 1,
      };

      final productId =
          await databaseService.database.insert('products', productData);
      expect(productId, greaterThan(0));

      final retrievedProduct = await databaseService.database.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );

      expect(retrievedProduct.length, equals(1));
      expect(retrievedProduct.first['name'], equals('Test Product'));
    });

    test('should handle foreign key constraints', () async {
      // Try to insert sale_item without valid sale_id
      expect(
        () async => await databaseService.database.insert('sale_items', {
          'sale_id': 999, // Non-existent sale
          'product_id': 1,
          'price': 100.0,
          'cost': 80.0,
          'quantity': 1,
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('should perform database integrity check', () async {
      final issues = await databaseService.checkDatabaseIntegrity();
      expect(issues, isA<List<String>>());
    });

    test('should handle database cleanup', () async {
      await expectLater(
        () => databaseService.forceCleanup(),
        returnsNormally,
      );
    });
  });
}
