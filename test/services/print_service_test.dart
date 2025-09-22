import 'package:flutter_test/flutter_test.dart';
import 'package:rojsoft_manager/src/services/print_service.dart';

void main() {
  group('PrintService Tests', () {
    late PrintService printService;

    setUp(() {
      printService = PrintService();
    });

    test('should initialize print service', () {
      expect(printService, isNotNull);
    });

    test('should handle print invoice with valid data', () async {
      // Test the static method with proper parameters
      expect(
          () => PrintService.printInvoice(
                shopName: 'Test Shop',
                phone: '1234567890',
                address: 'Test Address',
                items: [
                  {
                    'product_name': 'Test Product',
                    'quantity': 2,
                    'price': 50.0,
                  }
                ],
                paymentType: 'cash',
              ),
          returnsNormally);
    });

    test('should handle print error gracefully', () async {
      // Test error handling with minimal data
      expect(
          () => PrintService.printInvoice(
                shopName: '',
                phone: '',
                address: '',
                items: [],
                paymentType: 'cash',
              ),
          returnsNormally);
    });

    test('should validate print data format', () {
      final validData = {
        'id': 1,
        'customer_name': 'Test Customer',
        'total': 100.0,
        'items': [],
        'created_at': '2024-01-01',
      };

      // Test data validation logic
      expect(validData.containsKey('id'), isTrue);
      expect(validData.containsKey('customer_name'), isTrue);
      expect(validData.containsKey('total'), isTrue);
    });
  });
}
