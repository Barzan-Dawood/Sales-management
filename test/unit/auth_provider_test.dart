import 'package:flutter_test/flutter_test.dart';
import 'package:office_mangment_system/src/services/auth/auth_provider.dart';
import 'package:office_mangment_system/src/services/db/database_service.dart';

void main() {
  group('AuthProvider Unit Tests', () {
    late AuthProvider authProvider;
    late DatabaseService databaseService;

    setUpAll(() async {
      databaseService = DatabaseService();
      await databaseService.initialize();
    });

    setUp(() {
      authProvider = AuthProvider(databaseService);
    });

    tearDownAll(() async {
      await databaseService.database.close();
    });

    test('should initialize with no authenticated user', () {
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isManager, isFalse);
    });

    test('should handle login with valid credentials', () async {
      // First, create a test user
      await databaseService.database.insert('users', {
        'username': 'testuser',
        'password': 'testpass',
        'name': 'Test User',
        'role': 'employee',
      });

      final result = await authProvider.login('testuser', 'testpass');

      expect(result, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser!['username'], equals('testuser'));
    });

    test('should handle login with invalid credentials', () async {
      final result = await authProvider.login('invalid', 'invalid');

      expect(result, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
    });

    test('should handle logout correctly', () async {
      // First login
      await databaseService.database.insert('users', {
        'username': 'testuser2',
        'password': 'testpass2',
        'name': 'Test User 2',
        'role': 'manager',
      });

      await authProvider.login('testuser2', 'testpass2');
      expect(authProvider.isAuthenticated, isTrue);

      // Then logout
      authProvider.logout();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
    });

    test('should correctly identify manager role', () async {
      await databaseService.database.insert('users', {
        'username': 'manager',
        'password': 'managerpass',
        'name': 'Manager User',
        'role': 'manager',
      });

      await authProvider.login('manager', 'managerpass');
      expect(authProvider.isManager, isTrue);
    });

    test('should correctly identify employee role', () async {
      await databaseService.database.insert('users', {
        'username': 'employee',
        'password': 'employeepass',
        'name': 'Employee User',
        'role': 'employee',
      });

      await authProvider.login('employee', 'employeepass');
      expect(authProvider.isManager, isFalse);
    });
  });
}
