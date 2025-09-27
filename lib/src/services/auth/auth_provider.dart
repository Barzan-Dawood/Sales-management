import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../db/database_service.dart';
import '../../models/user_model.dart';
import 'package:crypto/crypto.dart';

// Default usernames and passwords (manager can change them later from settings)
const String kDefaultAdminUsername = 'manager';
const String kDefaultSupervisorUsername = 'supervisor';
const String kDefaultEmployeeUsername = 'employee';

const String kDefaultAdminPassword = 'Manager@2025';
const String kDefaultSupervisorPassword = 'Supervisor@2025';
const String kDefaultEmployeePassword = 'Employee@2025';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._db);

  final DatabaseService _db;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Forced password change disabled per request
  bool get mustChangePassword => false;

  bool get isAuthenticated => _currentUser != null;
  bool get isManager => _currentUser?.role == UserRole.manager;
  bool get isSupervisor => _currentUser?.role == UserRole.supervisor;
  bool get isEmployee => _currentUser?.role == UserRole.employee;

  /// التحقق من وجود صلاحية معينة للمستخدم الحالي
  bool hasPermission(UserPermission permission) {
    return _currentUser?.hasPermission(permission) ?? false;
  }

  /// الحصول على اسم المستخدم الحالي
  String get currentUserName => _currentUser?.name ?? '';

  /// الحصول على رمز الموظف الحالي
  String get currentEmployeeCode => _currentUser?.employeeCode ?? '';

  /// الحصول على دور المستخدم الحالي
  String get currentUserRole => _currentUser?.roleDisplayName ?? '';

  Future<bool> login(String username, String password) async {
    debugPrint('محاولة تسجيل الدخول: $username');

    // التأكد من وجود المستخدمين الافتراضيين
    await _ensureDefaultUsersExist();

    final userData = await _db.findUserByCredentials(username, password);
    debugPrint('نتيجة البحث عن المستخدم: $userData');
    if (userData == null) return false;

    _currentUser = UserModel.fromMap(userData);
    notifyListeners();
    return true;
  }

  /// التأكد من وجود المستخدمين الافتراضيين
  Future<void> _ensureDefaultUsersExist() async {
    final nowIso = DateTime.now().toIso8601String();
    final defaultUsers = [
      {
        'name': 'المدير',
        'username': kDefaultAdminUsername,
        'password': _sha256Hex(kDefaultAdminPassword),
        'role': 'manager',
        'employee_code': 'A1',
        'active': 1,
        'created_at': nowIso,
        'updated_at': nowIso,
      },
      {
        'name': 'المشرف',
        'username': kDefaultSupervisorUsername,
        'password': _sha256Hex(kDefaultSupervisorPassword),
        'role': 'supervisor',
        'employee_code': 'S1',
        'active': 1,
        'created_at': nowIso,
        'updated_at': nowIso,
      },
      {
        'name': 'الموظف',
        'username': kDefaultEmployeeUsername,
        'password': _sha256Hex(kDefaultEmployeePassword),
        'role': 'employee',
        'employee_code': 'C1',
        'active': 1,
        'created_at': nowIso,
        'updated_at': nowIso,
      },
    ];

    for (final user in defaultUsers) {
      final existing = await _db.database.query(
        'users',
        where: 'username = ?',
        whereArgs: [user['username']],
        limit: 1,
      );

      if (existing.isEmpty) {
        try {
          await _db.database.insert('users', user);
          debugPrint('تم إضافة مستخدم: ${user['username']}');
        } catch (e) {
          debugPrint('خطأ في إضافة مستخدم ${user['username']}: $e');
        }
      } else {
        // تأكيد تطبيق كلمة مرور المدير Manager@2025 حتى إن كان موجوداً مسبقاً
        if (user['username'] == kDefaultAdminUsername) {
          try {
            await _db.database.update(
              'users',
              {
                'password': _sha256Hex(kDefaultAdminPassword),
                'name': 'المدير',
                'employee_code': 'A1',
                'active': 1,
                'updated_at': nowIso,
              },
              where: 'username = ?',
              whereArgs: [user['username']],
            );
            debugPrint('تم تحديث كلمة مرور المدير إلى القيمة الافتراضية.');
          } catch (e) {
            debugPrint('فشل تحديث بيانات المدير: $e');
          }
        }
      }
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Password changes are disabled per requirements.
  String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
