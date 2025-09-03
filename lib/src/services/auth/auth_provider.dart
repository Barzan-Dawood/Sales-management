import 'package:flutter/foundation.dart';

import '../db/database_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._db);

  final DatabaseService _db;

  Map<String, Object?>? _currentUser;
  Map<String, Object?>? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;
  bool get isManager => _currentUser?['role'] == 'manager';

  Future<bool> login(String username, String password) async {
    final user = await _db.findUserByCredentials(username, password);
    if (user == null) return false;
    _currentUser = user;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}


