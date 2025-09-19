import 'package:flutter/foundation.dart';

class StoreConfig extends ChangeNotifier {
  // معلومات ثابتة للمحل
  static const String _appTitle = 'نظام إدارة المكتب';
  static const String _shopName = 'لخدمات الانترنت والهواتف';
  static const String _shopCode = '(ROJ NET)';
  static const String _phone = '07512277690 - 07853203919';
  static const String _address = 'شنكال - سايدين حي الشهداء';
  static const String _displayVersion = '1.0.0';
  static const String _logoAssetPath = 'assets/images/office.png';

  String get appTitle => _appTitle;
  String get shopName => _shopName;
  String get shopCode => _shopCode;
  String get phone => _phone;
  String get address => _address;
  String get displayVersion => _displayVersion;
  String? get logoAssetPath => _logoAssetPath;

  // لا نحتاج إلى تحميل من ملفات خارجية
  Future<void> initialize() async {
    // المعلومات ثابتة، لا نحتاج إلى فعل أي شيء
    notifyListeners();
  }
}
