import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configuration for running tests
class TestConfig {
  static bool _initialized = false;

  /// Initialize test environment
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    _initialized = true;
  }

  /// Clean up test environment
  static void cleanup() {
    _initialized = false;
  }
}

/// Test data helpers
class TestDataHelper {
  static Map<String, dynamic> getSampleProduct() {
    return {
      'name': 'Test Product',
      'barcode': '123456789',
      'price': 100.0,
      'cost': 80.0,
      'quantity': 50,
      'category_id': 1,
    };
  }

  static Map<String, dynamic> getSampleCustomer() {
    return {
      'name': 'Test Customer',
      'phone': '1234567890',
      'address': 'Test Address',
    };
  }

  static Map<String, dynamic> getSampleSale() {
    return {
      'customer_id': 1,
      'total': 100.0,
      'profit': 20.0,
      'type': 'cash',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> getSampleUser() {
    return {
      'username': 'testuser',
      'password': 'testpass',
      'name': 'Test User',
      'role': 'employee',
    };
  }
}
