import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../db/database_service.dart';
import '../../models/user_model.dart';
import 'package:crypto/crypto.dart';

// Default usernames and passwords (manager can change them later from settings)
// كلمات المرور الافتراضية: admin123, super123, emp123
const String kDefaultAdminUsername = 'manager';
const String kDefaultSupervisorUsername = 'supervisor';
const String kDefaultEmployeeUsername = 'employee';

const String kDefaultAdminPassword = 'admin123';
const String kDefaultSupervisorPassword = 'super123';
const String kDefaultEmployeePassword = 'emp123';

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
        try {
          await _db.database.insert('users', user);
        } catch (e) {
          // تجاهل خطأ إضافة المستخدم إذا كان موجوداً بالفعل
        }
      } else {
        // تأكيد تطبيق كلمات المرور الافتراضية لجميع المستخدمين حتى إن كانوا موجودين مسبقاً
        try {
          String passwordToStore;
          if (user['username'] == kDefaultAdminUsername) {
            passwordToStore = _sha256Hex(kDefaultAdminPassword);
          } else if (user['username'] == kDefaultSupervisorUsername) {
            passwordToStore = _sha256Hex(kDefaultSupervisorPassword);
          } else if (user['username'] == kDefaultEmployeeUsername) {
            passwordToStore = _sha256Hex(kDefaultEmployeePassword);
          } else {
            passwordToStore = _sha256Hex(user['password'] as String);
          }

          // Only update safe fields to avoid UNIQUE constraint conflicts.
          // Do NOT overwrite existing employee_code; it may already be used elsewhere.
          await _db.database.update(
            'users',
            {
              'password': passwordToStore,
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
