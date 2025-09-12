import 'package:flutter/foundation.dart';

import '../db/database_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._db);

  final DatabaseService _db;

  Map<String, Object?>? _currentUser;
  Map<String, Object?>? get currentUser => _currentUser;

  // Forced password change disabled per request
  bool get mustChangePassword => false;

  bool get isAuthenticated => _currentUser != null;
  bool get isManager => _currentUser?['role'] == 'manager';

  Future<bool> login(String username, String password) async {
    final user = await _db.findUserByCredentials(username, password);
    if (user == null) return false;
    _currentUser = user;
    // Force password change if default admin credentials are used
    // no-op
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    // no-op
    notifyListeners();
  }

  // Password changes are disabled per requirements.
}
