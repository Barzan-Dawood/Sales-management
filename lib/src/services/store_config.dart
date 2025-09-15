import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class StoreConfig extends ChangeNotifier {
  String _appTitle = 'نظام إدارة المكتب';
  String _shopName = 'متجري';
  String _phone = '';
  String _address = '';
  String _displayVersion = '1.0.0';
  String? _logoAssetPath; // optional app/logo used inside UI, not launcher

  String get appTitle => _appTitle;
  String get shopName => _shopName;
  String get phone => _phone;
  String get address => _address;
  String get displayVersion => _displayVersion;
  String? get logoAssetPath => _logoAssetPath;

  Future<void> loadFromAssets(
      {String path = 'assets/store_config.json'}) async {
    try {
      final jsonStr = await rootBundle.loadString(path);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      _appTitle = (data['appTitle'] as String?)?.trim().isNotEmpty == true
          ? data['appTitle'] as String
          : _appTitle;
      _shopName = (data['shopName'] as String?)?.trim().isNotEmpty == true
          ? data['shopName'] as String
          : _shopName;
      _phone = (data['phone'] as String?)?.trim().isNotEmpty == true
          ? data['phone'] as String
          : _phone;
      _address = (data['address'] as String?)?.trim().isNotEmpty == true
          ? data['address'] as String
          : _address;
      _displayVersion =
          (data['displayVersion'] as String?)?.trim().isNotEmpty == true
              ? data['displayVersion'] as String
              : _displayVersion;
      _logoAssetPath =
          (data['logoAssetPath'] as String?)?.trim().isNotEmpty == true
              ? data['logoAssetPath'] as String
              : _logoAssetPath;
      notifyListeners();
    } catch (e) {
      // Keep defaults on failure
      if (kDebugMode) {
        // ignore: avoid_print
       }
    }
  }
}
