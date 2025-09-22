import 'package:flutter_test/flutter_test.dart';
import 'package:rojsoft_manager/src/services/db/database_service.dart';
void main() {
  group('Database Performance Tests', () {
    late DatabaseService databaseService;

    setUpAll(() async {
      databaseService = DatabaseService();
      await databaseService.initialize();
    });

    tearDownAll(() async {
      await databaseService.database.close();
    });

    test('should handle large number of products efficiently', () async {
      final stopwatch = Stopwatch()..start();

      // Insert 1000 products
      for (int i = 0; i < 1000; i++) {
        await databaseService.database.insert('products', {
          'name': 'Product $i',
          'barcode': 'barcode_$i',
          'price': 100.0 + i,
          'cost': 80.0 + i,
          'quantity': 10 + i,
          'category_id': 1,
        });
      }

      stopwatch.stop();
 
      // Should complete within reasonable time (adjust threshold as needed)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('should query products efficiently', () async {
      final stopwatch = Stopwatch()..start();

      // Query all products
      final products = await databaseService.database.query('products');

      stopwatch.stop();
  
      expect(products.length, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('should handle complex joins efficiently', () async {
      final stopwatch = Stopwatch()..start();

      // Complex query with joins
      final result = await databaseService.database.rawQuery('''
        SELECT 
          s.id,
          s.total,
          s.profit,
          c.name as customer_name,
          COUNT(si.id) as item_count
        FROM sales s
        LEFT JOIN customers c ON s.customer_id = c.id
        LEFT JOIN sale_items si ON s.id = si.sale_id
        GROUP BY s.id
        ORDER BY s.created_at DESC
        LIMIT 100
      ''');

      stopwatch.stop();
  
      expect(result, isA<List>());
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    test('should handle concurrent operations', () async {
      final futures = <Future>[];

      // Start multiple concurrent operations
      for (int i = 0; i < 10; i++) {
        futures.add(databaseService.database.insert('products', {
          'name': 'Concurrent Product $i',
          'barcode': 'concurrent_$i',
          'price': 100.0,
          'cost': 80.0,
          'quantity': 10,
          'category_id': 1,
        }));
      }

      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });
}
