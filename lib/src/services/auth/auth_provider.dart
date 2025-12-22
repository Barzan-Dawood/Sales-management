import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../db/database_service.dart';
import '../../models/user_model.dart';
import 'package:crypto/crypto.dart';

// Default usernames and passwords
// IMPORTANT: These default passwords should be changed immediately after first login for security
// كلمات المرور الافتراضية يجب تغييرها فوراً بعد أول تسجيل دخول للأمان
const String kDefaultAdminUsername = 'manager';
const String kDefaultSupervisorUsername = 'supervisor';
const String kDefaultEmployeeUsername = 'employee';

// Default passwords - MUST be changed after first installation
const String kDefaultAdminPassword = 'man2026';
const String kDefaultSupervisorPassword = 'sup2026';
const String kDefaultEmployeePassword = 'emp2026';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._db);

  final DatabaseService _db;

  UserModel? _currentUser;
  GroupModel? _currentGroup;

  UserModel? get currentUser => _currentUser;
  GroupModel? get currentGroup => _currentGroup;

  // Forced password change disabled per request
  bool get mustChangePassword => false;

  bool get isAuthenticated => _currentUser != null;
  bool get isManager => _currentUser?.role == UserRole.manager;
  bool get isSupervisor => _currentUser?.role == UserRole.supervisor;
  bool get isEmployee => _currentUser?.role == UserRole.employee;

  /// التحقق من وجود صلاحية معينة للمستخدم الحالي
  bool hasPermission(UserPermission permission) {
    if (_currentUser == null) return false;

    // استخدام نظام المجموعات إذا كان المستخدم لديه مجموعة
    if (_currentGroup != null) {
      return _currentGroup!.hasPermission(permission);
    }

    // استخدام النظام القديم (roles) للتوافق
    return _currentUser!.hasPermission(permission, group: null);
  }

  /// الحصول على اسم المستخدم الحالي
  String get currentUserName => _currentUser?.username ?? '';

  /// الحصول على رمز الموظف الحالي
  String get currentEmployeeCode => _currentUser?.employeeCode ?? '';

  /// الحصول على دور المستخدم الحالي
  String get currentUserRole => _currentUser?.roleDisplayName ?? '';

  Future<bool> login(String username, String password) async {
    // التأكد من وجود المستخدمين الافتراضيين
    await _ensureDefaultUsersExist();

    final userData = await _db.findUserByCredentials(username, password);
    if (userData == null) {
      return false;
    }

    _currentUser = UserModel.fromMap(userData);

    // تحميل مجموعة المستخدم إذا كان لديه group_id
    if (_currentUser?.groupId != null) {
      try {
        _currentGroup = await _db.getUserGroup(_currentUser!.id!);
      } catch (e) {
        _currentGroup = null;
      }
    } else {
      _currentGroup = null;
    }

    // تسجيل حدث تسجيل الدخول
    try {
      await _db.logEvent(
        eventType: 'login',
        entityType: 'user',
        entityId: _currentUser?.id,
        userId: _currentUser?.id,
        username: _currentUser?.username,
        description:
            'تسجيل دخول المستخدم: ${_currentUser?.name} (${_currentUser?.username})',
        details: 'الدور: ${_currentUser?.roleDisplayName}',
      );
    } catch (e) {
      // تجاهل خطأ تسجيل الحدث والاستمرار في تسجيل الدخول
    }

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
        // إضافة المستخدم فقط إذا لم يكن موجوداً
        try {
          await _db.database.insert('users', user);
        } catch (e) {
          // تجاهل خطأ إضافة المستخدم إذا كان موجوداً بالفعل
        }
      } else {
        // المستخدم موجود - تحديث الحقول الآمنة فقط (لا كلمة المرور)
        // لا نقوم بتحديث كلمة المرور لأنها قد تكون تم تغييرها مسبقاً
        try {
          // Only update safe fields to avoid UNIQUE constraint conflicts.
          // Do NOT overwrite existing employee_code; it may already be used elsewhere.
          // Do NOT overwrite password; it may have been changed by the admin
          await _db.database.update(
            'users',
            {
              'name': user['name'],
              'active': 1,
              'updated_at': nowIso,
            },
            where: 'username = ?',
            whereArgs: [user['username']],
          );
        } catch (e) {
          // تجاهل خطأ تحديث المستخدم والاستمرار
        }
      }
    }
  }

  void logout() async {
    // تسجيل حدث تسجيل الخروج قبل مسح المستخدم
    if (_currentUser != null) {
      try {
        await _db.logEvent(
          eventType: 'logout',
          entityType: 'user',
          entityId: _currentUser?.id,
          userId: _currentUser?.id,
          username: _currentUser?.username,
          description:
              'تسجيل خروج المستخدم: ${_currentUser?.name} (${_currentUser?.username})',
          details: 'الدور: ${_currentUser?.roleDisplayName}',
        );
      } catch (e) {
        // تجاهل خطأ تسجيل الحدث والاستمرار في تسجيل الخروج
      }
    }

    _currentUser = null;
    _currentGroup = null;
    notifyListeners();
  }

  // Password changes are disabled per requirements.
  String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
