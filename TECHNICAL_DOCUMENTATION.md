# 🔧 الوثائق التقنية - نظام إدارة المكتب

## 📋 جدول المحتويات

1. [نظرة عامة على النظام](#نظرة-عامة-على-النظام)
2. [البنية المعمارية](#البنية-المعمارية)
3. [قاعدة البيانات](#قاعدة-البيانات)
4. [الخدمات والمزودين](#الخدمات-والمزودين)
5. [واجهات المستخدم](#واجهات-المستخدم)
6. [نظام الأمان](#نظام-الأمان)
7. [نظام الترخيص](#نظام-الترخيص)
8. [معالجة الأخطاء](#معالجة-الأخطاء)
9. [الأداء والتحسين](#الأداء-والتحسين)
10. [التطوير والصيانة](#التطوير-والصيانة)

## 🎯 نظرة عامة على النظام

### معلومات عامة
- **الاسم**: نظام إدارة المكتب (Office Management System)
- **الإصدار**: 1.0.0
- **المنصة**: Flutter/Dart
- **قاعدة البيانات**: SQLite
- **إدارة الحالة**: Provider Pattern

### المتطلبات التقنية
- **Flutter SDK**: >= 3.3.0
- **Dart SDK**: >= 3.3.0
- **منصات مدعومة**: Windows, macOS, Linux, Android, iOS, Web

### المكتبات الرئيسية
```yaml
dependencies:
  flutter: sdk
  provider: ^6.0.5          # إدارة الحالة
  sqflite: ^2.3.3           # قاعدة البيانات
  sqflite_common_ffi: ^2.3.3 # قاعدة البيانات لسطح المكتب
  fl_chart: ^0.68.0         # الرسوم البيانية
  barcode_widget: ^2.0.4    # الباركود
  pdf: ^3.11.0              # إنشاء PDF
  printing: ^5.13.3         # الطباعة
  crypto: ^3.0.3            # التشفير
  google_fonts: ^6.2.1      # الخطوط
  url_launcher: ^6.2.2      # فتح الروابط
  shared_preferences: ^2.2.2 # التفضيلات
  device_info_plus: ^10.1.0  # معلومات الجهاز
  encrypt: ^5.0.1           # التشفير المتقدم
  uuid: ^4.4.0              # معرفات فريدة
```

## 🏗️ البنية المعمارية

### نمط التصميم
النظام يستخدم **MVVM (Model-View-ViewModel)** مع **Provider Pattern**:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      View       │◄──►│   ViewModel     │◄──►│     Model       │
│   (Screens)     │    │   (Providers)   │    │ (Database/APIs) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### هيكل المجلدات
```
lib/src/
├── app_shell.dart          # الحاوية الرئيسية
├── config/                 # ملفات الإعداد
│   ├── store_info.dart     # معلومات المحل
│   └── README.md          # دليل الإعداد
├── models/                 # نماذج البيانات
│   ├── user_model.dart     # نموذج المستخدم
│   └── product_model.dart  # نموذج المنتج
├── screens/                # الشاشات
│   ├── dashboard_screen.dart
│   ├── sales_screen.dart
│   ├── products/
│   └── ...
├── services/               # الخدمات
│   ├── auth/              # خدمة المصادقة
│   ├── db/                # خدمة قاعدة البيانات
│   ├── license/           # خدمة الترخيص
│   └── ...
├── utils/                  # الأدوات المساعدة
│   ├── strings.dart       # النصوص
│   ├── themes.dart        # الثيمات
│   └── ...
└── widgets/                # المكونات القابلة لإعادة الاستخدام
    ├── error_display_widgets.dart
    └── ...
```

## 🗄️ قاعدة البيانات

### هيكل قاعدة البيانات

#### جدول المستخدمين (users)
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('manager', 'supervisor', 'employee')),
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### جدول المنتجات (products)
```sql
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  barcode TEXT UNIQUE,
  price REAL NOT NULL,
  cost REAL NOT NULL,
  quantity INTEGER DEFAULT 0,
  min_quantity INTEGER DEFAULT 0,
  category_id INTEGER,
  description TEXT,
  image_path TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id)
);
```

#### جدول العملاء (customers)
```sql
CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  credit_limit REAL DEFAULT 0,
  balance REAL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### جدول المبيعات (sales)
```sql
CREATE TABLE sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER,
  user_id INTEGER NOT NULL,
  total_amount REAL NOT NULL,
  discount_amount REAL DEFAULT 0,
  tax_amount REAL DEFAULT 0,
  payment_method TEXT NOT NULL,
  notes TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  FOREIGN KEY (user_id) REFERENCES users (id)
);
```

#### جدول تفاصيل المبيعات (sale_items)
```sql
CREATE TABLE sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  total_price REAL NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales (id),
  FOREIGN KEY (product_id) REFERENCES products (id)
);
```

### خدمة قاعدة البيانات

#### DatabaseService Class
```dart
class DatabaseService {
  static Database? _database;
  
  // تهيئة قاعدة البيانات
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  // إنشاء قاعدة البيانات والجداول
  static Future<Database> _initDatabase() async {
    final dbPath = await _getDatabasePath();
    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  // إنشاء الجداول
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createUsersTable);
    await db.execute(_createProductsTable);
    await db.execute(_createCustomersTable);
    await db.execute(_createSalesTable);
    await db.execute(_createSaleItemsTable);
    // ... باقي الجداول
  }
}
```

## 🔧 الخدمات والمزودين

### AuthProvider - مزود المصادقة
```dart
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  
  // تسجيل الدخول
  Future<bool> login(String username, String password) async {
    try {
      final user = await DatabaseService.authenticateUser(username, password);
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      ErrorHandlerService.logError(e, context: 'AuthProvider.login');
      return false;
    }
  }
  
  // تسجيل الخروج
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
```

### StoreConfig - إعدادات المحل
```dart
class StoreConfig extends ChangeNotifier {
  StoreInfo _storeInfo = StoreInfo();
  
  StoreInfo get storeInfo => _storeInfo;
  
  // تحديث معلومات المحل
  Future<void> updateStoreInfo(StoreInfo newInfo) async {
    _storeInfo = newInfo;
    await _saveToPreferences();
    notifyListeners();
  }
  
  // حفظ في التفضيلات
  Future<void> _saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_info', jsonEncode(_storeInfo.toJson()));
  }
}
```

## 🎨 واجهات المستخدم

### نظام الثيمات
```dart
class AppThemes {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.notoSansArabicTextTheme(),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.notoSansArabicTextTheme(
      ThemeData.dark().textTheme,
    ),
  );
}
```

### مكونات واجهة المستخدم

#### AppShell - الحاوية الرئيسية
```dart
class AppShell extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isAuthenticated) {
          return LoginScreen();
        }
        
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: _buildNavigationItems(),
          ),
        );
      },
    );
  }
}
```

## 🔒 نظام الأمان

### تشفير كلمات المرور
```dart
class SecurityService {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password + _salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
```

### إدارة الصلاحيات
```dart
class PermissionService {
  static bool hasPermission(User user, UserPermission permission) {
    return user.role.permissions.contains(permission);
  }
  
  static bool canAccessScreen(User user, String screenName) {
    switch (screenName) {
      case 'users_management':
        return hasPermission(user, UserPermission.manageUsers);
      case 'reports':
        return hasPermission(user, UserPermission.viewReports);
      default:
        return true;
    }
  }
}
```

## 📄 نظام الترخيص

### LicenseProvider - مزود الترخيص
```dart
class LicenseProvider extends ChangeNotifier {
  bool _isActivated = false;
  bool _isTrialActive = false;
  DateTime? _trialEndDate;
  
  bool get isActivated => _isActivated;
  bool get isTrialActive => _isTrialActive;
  
  // تهيئة الترخيص
  Future<void> initialize() async {
    await _checkActivationStatus();
    await _checkTrialStatus();
    notifyListeners();
  }
  
  // فحص حالة التفعيل
  Future<void> _checkActivationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isActivated = prefs.getBool('license_activated') ?? false;
  }
  
  // فحص حالة التجربة المجانية
  Future<void> _checkTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStart = prefs.getString('trial_start_date');
    
    if (trialStart != null) {
      final startDate = DateTime.parse(trialStart);
      final endDate = startDate.add(Duration(days: 30));
      _trialEndDate = endDate;
      _isTrialActive = DateTime.now().isBefore(endDate);
    }
  }
}
```

## ⚠️ معالجة الأخطاء

### ErrorHandlerService - خدمة معالجة الأخطاء
```dart
class ErrorHandlerService {
  // معالجة الخطأ الأساسية
  static Future<T?> handleError<T>(
    BuildContext context,
    Future<T> Function() operation, {
    bool showSnackBar = true,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final result = await operation();
      onSuccess?.call();
      return result;
    } catch (error) {
      logError(error);
      if (showSnackBar) {
        _showErrorSnackBar(context, error);
      }
      onError?.call();
      return null;
    }
  }
  
  // معالجة الخطأ مع إعادة المحاولة
  static Future<T?> handleErrorWithRetry<T>(
    BuildContext context,
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (error) {
        if (i == maxRetries - 1) {
          logError(error);
          _showErrorDialog(context, error);
          return null;
        }
        await Future.delayed(retryDelay);
      }
    }
    return null;
  }
  
  // تسجيل الخطأ
  static void logError(dynamic error, {String? context, Map<String, dynamic>? additionalInfo}) {
    print('ERROR: ${DateTime.now()}');
    if (context != null) print('Context: $context');
    print('Error: $error');
    if (additionalInfo != null) {
      print('Additional Info: $additionalInfo');
    }
    print('Stack Trace: ${StackTrace.current}');
  }
}
```

### أنواع الأخطاء
```dart
enum ErrorType {
  warning,    // تحذير
  error,      // خطأ
  critical,   // خطأ حرج
}

class ErrorInfo {
  final String title;
  final String message;
  final String? solution;
  final ErrorType type;
  
  const ErrorInfo({
    required this.title,
    required this.message,
    this.solution,
    this.type = ErrorType.error,
  });
}
```

## 🚀 الأداء والتحسين

### تحسين قاعدة البيانات
```dart
class DatabaseOptimization {
  // إنشاء الفهارس
  static Future<void> createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(created_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)');
  }
  
  // تنظيف البيانات القديمة
  static Future<void> cleanupOldData(Database db) async {
    // حذف الفواتير الأقدم من سنة
    final oneYearAgo = DateTime.now().subtract(Duration(days: 365));
    await db.delete('sales', where: 'created_at < ?', whereArgs: [oneYearAgo.toIso8601String()]);
  }
}
```

### تحسين الذاكرة
```dart
class MemoryOptimization {
  // تحسين تحميل الصور
  static Widget buildOptimizedImage(String? imagePath, {double? width, double? height}) {
    if (imagePath == null || imagePath.isEmpty) {
      return Icon(Icons.image, size: width ?? height ?? 48);
    }
    
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.broken_image, size: width ?? height ?? 48);
      },
    );
  }
  
  // تحسين القوائم الطويلة
  static Widget buildOptimizedList(List<dynamic> items, Widget Function(BuildContext, int) itemBuilder) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: itemBuilder,
      cacheExtent: 1000, // تحسين التخزين المؤقت
    );
  }
}
```

## 🔄 التطوير والصيانة

### نظام الاختبارات
```dart
// اختبار وحدة - AuthProvider
void main() {
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;
    
    setUp(() {
      authProvider = AuthProvider();
    });
    
    test('should login successfully with valid credentials', () async {
      final result = await authProvider.login('admin', 'password');
      expect(result, true);
      expect(authProvider.isAuthenticated, true);
    });
    
    test('should fail login with invalid credentials', () async {
      final result = await authProvider.login('invalid', 'wrong');
      expect(result, false);
      expect(authProvider.isAuthenticated, false);
    });
  });
}
```

### نظام النسخ الاحتياطي
```dart
class BackupService {
  // إنشاء نسخة احتياطية
  static Future<String> createBackup() async {
    final dbPath = await DatabaseService.getDatabasePath();
    final backupDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${backupDir.path}/backup_$timestamp.db';
    
    await File(dbPath).copy(backupPath);
    return backupPath;
  }
  
  // استعادة النسخة الاحتياطية
  static Future<bool> restoreBackup(String backupPath) async {
    try {
      final dbPath = await DatabaseService.getDatabasePath();
      await File(backupPath).copy(dbPath);
      return true;
    } catch (e) {
      ErrorHandlerService.logError(e, context: 'BackupService.restoreBackup');
      return false;
    }
  }
}
```

### نظام التحديثات
```dart
class UpdateService {
  // فحص التحديثات
  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse('https://api.example.com/updates'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UpdateInfo.fromJson(data);
      }
    } catch (e) {
      ErrorHandlerService.logError(e, context: 'UpdateService.checkForUpdates');
    }
    return null;
  }
  
  // تحميل التحديث
  static Future<bool> downloadUpdate(String downloadUrl) async {
    try {
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final documentsDir = await getApplicationDocumentsDirectory();
        final updatePath = '${documentsDir.path}/update.apk';
        await File(updatePath).writeAsBytes(response.bodyBytes);
        return true;
      }
    } catch (e) {
      ErrorHandlerService.logError(e, context: 'UpdateService.downloadUpdate');
    }
    return false;
  }
}
```

## 📊 مراقبة الأداء

### مقاييس الأداء
```dart
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  
  // بدء قياس الوقت
  static void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }
  
  // إنهاء قياس الوقت
  static Duration endTimer(String name) {
    final timer = _timers.remove(name);
    if (timer != null) {
      timer.stop();
      print('$name took: ${timer.elapsedMilliseconds}ms');
      return timer.elapsed;
    }
    return Duration.zero;
  }
  
  // قياس استخدام الذاكرة
  static void logMemoryUsage() {
    final info = ProcessInfo.currentRss;
    print('Memory usage: ${info ~/ 1024 ~/ 1024} MB');
  }
}
```

## 🔧 أدوات التطوير

### أدوات التصحيح
```dart
class DebugTools {
  static bool _isDebugMode = false;
  
  static void enableDebugMode() {
    _isDebugMode = true;
    print('Debug mode enabled');
  }
  
  static void log(String message, {String? tag}) {
    if (_isDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      print('[$timestamp] ${tag ?? 'DEBUG'}: $message');
    }
  }
  
  static void logDatabaseQuery(String query, {List<dynamic>? arguments}) {
    if (_isDebugMode) {
      print('SQL: $query');
      if (arguments != null) print('Args: $arguments');
    }
  }
}
```

---

## 📝 ملاحظات التطوير

### أفضل الممارسات
1. **استخدم Provider Pattern** لإدارة الحالة
2. **فصل المنطق عن العرض** (MVVM)
3. **معالجة الأخطاء بشكل شامل**
4. **كتابة اختبارات شاملة**
5. **توثيق الكود باللغة العربية**
6. **تحسين الأداء والذاكرة**

### إرشادات الأمان
1. **تشفير كلمات المرور**
2. **التحقق من الصلاحيات**
3. **حماية البيانات الحساسة**
4. **نسخ احتياطية منتظمة**

### إرشادات الصيانة
1. **مراقبة الأداء**
2. **تنظيف قاعدة البيانات**
3. **تحديث المكتبات**
4. **مراجعة الأمان**

---

*آخر تحديث: ديسمبر 2024*
*إصدار الوثائق: 1.0*
