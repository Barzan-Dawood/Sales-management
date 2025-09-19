import 'package:flutter/foundation.dart';
import '../config/store_info.dart';

class StoreConfig extends ChangeNotifier {
  // استخدام معلومات المحل من الملف المنفصل
  String get appTitle => StoreInfo.appTitle;
  String get shopName => StoreInfo.shopName;
  String get shopDescription => StoreInfo.shopDescription;
  String get phone => StoreInfo.phone;
  String get address => StoreInfo.address;
  String get displayVersion => StoreInfo.displayVersion;
  String? get logoAssetPath => StoreInfo.logoAssetPath;

  // معلومات إضافية متاحة الآن
  String get email => StoreInfo.email;
  String get whatsapp => StoreInfo.whatsapp;
  String get city => StoreInfo.city;
  String get country => StoreInfo.country;
  String get developer => StoreInfo.developer;
  String get language => StoreInfo.language;
  String get releaseYear => StoreInfo.releaseYear;

  // لا نحتاج إلى تحميل من ملفات خارجية
  Future<void> initialize() async {
    // المعلومات ثابتة، لا نحتاج إلى فعل أي شيء
    notifyListeners();
  }
}
