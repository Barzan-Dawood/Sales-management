# 🔌 وثائق واجهات برمجة التطبيقات (API)

## 📋 جدول المحتويات

1. [نظرة عامة](#نظرة-عامة)
2. [Authentication APIs](#authentication-apis)
3. [User Management APIs](#user-management-apis)
4. [Product APIs](#product-apis)
5. [Sales APIs](#sales-apis)
6. [Customer APIs](#customer-apis)
7. [Inventory APIs](#inventory-apis)
8. [Report APIs](#report-apis)
9. [System APIs](#system-apis)
10. [Error Handling](#error-handling)

## 🎯 نظرة عامة

هذه الوثائق توضح واجهات برمجة التطبيقات الداخلية للنظام. جميع الـ APIs تستخدم نمط **Provider** مع **ChangeNotifier** لإدارة الحالة.

### معلومات عامة
- **Base URL**: Local Database (SQLite)
- **Authentication**: Session-based
- **Data Format**: JSON
- **Error Handling**: Centralized Error Handler

## 🔐 Authentication APIs

### AuthProvider Class

#### تسجيل الدخول
```dart
Future<bool> login(String username, String password)
```

**المعاملات:**
- `username` (String): اسم المستخدم
- `password` (String): كلمة المرور

**القيمة المُرجعة:**
- `bool`: true إذا نجح تسجيل الدخول، false إذا فشل

**مثال الاستخدام:**
```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final success = await authProvider.login('admin', 'password123');
if (success) {
  // تم تسجيل الدخول بنجاح
  Navigator.pushReplacementNamed(context, '/dashboard');
} else {
  // فشل تسجيل الدخول
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('اسم المستخدم أو كلمة المرور غير صحيحة'))
  );
}
```

#### تسجيل الخروج
```dart
Future<void> logout()
```

**المعاملات:** لا يوجد

**القيمة المُرجعة:** void

**مثال الاستخدام:**
```dart
await authProvider.logout();
Navigator.pushReplacementNamed(context, '/login');
```

#### فحص حالة المصادقة
```dart
bool get isAuthenticated
User? get currentUser
```

**القيمة المُرجعة:**
- `isAuthenticated`: true إذا كان المستخدم مسجل الدخول
- `currentUser`: بيانات المستخدم الحالي أو null

## 👥 User Management APIs

### User Management Provider

#### إضافة مستخدم جديد
```dart
Future<bool> addUser({
  required String username,
  required String password,
  required String fullName,
  required UserRole role,
  String? phone,
  String? email,
})
```

**المعاملات:**
- `username` (String): اسم المستخدم (مطلوب)
- `password` (String): كلمة المرور (مطلوب)
- `fullName` (String): الاسم الكامل (مطلوب)
- `role` (UserRole): دور المستخدم (مطلوب)
- `phone` (String?): رقم الهاتف (اختياري)
- `email` (String?): البريد الإلكتروني (اختياري)

**القيمة المُرجعة:**
- `bool`: true إذا تم إنشاء المستخدم بنجاح

**مثال الاستخدام:**
```dart
final userProvider = Provider.of<UserManagementProvider>(context, listen: false);
final success = await userProvider.addUser(
  username: 'employee1',
  password: 'password123',
  fullName: 'أحمد محمد',
  role: UserRole.employee,
  phone: '0501234567',
  email: 'ahmed@example.com',
);
```

#### تحديث بيانات المستخدم
```dart
Future<bool> updateUser({
  required int userId,
  String? username,
  String? password,
  String? fullName,
  UserRole? role,
  String? phone,
  String? email,
  bool? isActive,
})
```

**المعاملات:**
- `userId` (int): معرف المستخدم (مطلوب)
- باقي المعاملات اختيارية للتحديث

**القيمة المُرجعة:**
- `bool`: true إذا تم التحديث بنجاح

#### حذف المستخدم
```dart
Future<bool> deleteUser(int userId)
```

**المعاملات:**
- `userId` (int): معرف المستخدم

**القيمة المُرجعة:**
- `bool`: true إذا تم الحذف بنجاح

#### الحصول على قائمة المستخدمين
```dart
Future<List<User>> getUsers()
```

**القيمة المُرجعة:**
- `List<User>`: قائمة بجميع المستخدمين

## 📦 Product APIs

### Product Provider

#### إضافة منتج جديد
```dart
Future<bool> addProduct({
  required String name,
  required double price,
  required double cost,
  int quantity = 0,
  String? barcode,
  int? categoryId,
  String? description,
  String? imagePath,
})
```

**المعاملات:**
- `name` (String): اسم المنتج (مطلوب)
- `price` (double): سعر البيع (مطلوب)
- `cost` (double): سعر التكلفة (مطلوب)
- `quantity` (int): الكمية المتوفرة (افتراضي: 0)
- `barcode` (String?): الباركود (اختياري)
- `categoryId` (int?): معرف التصنيف (اختياري)
- `description` (String?): الوصف (اختياري)
- `imagePath` (String?): مسار الصورة (اختياري)

**القيمة المُرجعة:**
- `bool`: true إذا تم إضافة المنتج بنجاح

**مثال الاستخدام:**
```dart
final productProvider = Provider.of<ProductProvider>(context, listen: false);
final success = await productProvider.addProduct(
  name: 'منتج جديد',
  price: 100.0,
  cost: 80.0,
  quantity: 50,
  barcode: '1234567890123',
  categoryId: 1,
  description: 'وصف المنتج',
);
```

#### تحديث المنتج
```dart
Future<bool> updateProduct({
  required int productId,
  String? name,
  double? price,
  double? cost,
  int? quantity,
  String? barcode,
  int? categoryId,
  String? description,
  String? imagePath,
})
```

#### حذف المنتج
```dart
Future<bool> deleteProduct(int productId)
```

#### الحصول على المنتجات
```dart
Future<List<Product>> getProducts({
  int? categoryId,
  String? searchQuery,
  bool includeInactive = false,
})
```

**المعاملات:**
- `categoryId` (int?): فلترة حسب التصنيف
- `searchQuery` (String?): البحث في أسماء المنتجات
- `includeInactive` (bool): تضمين المنتجات غير النشطة

#### البحث بالباركود
```dart
Future<Product?> getProductByBarcode(String barcode)
```

## 🛒 Sales APIs

### Sales Provider

#### إنشاء عملية بيع جديدة
```dart
Future<Sale?> createSale({
  required List<SaleItem> items,
  int? customerId,
  double discountAmount = 0,
  double taxAmount = 0,
  String paymentMethod = 'cash',
  String? notes,
})
```

**المعاملات:**
- `items` (List<SaleItem>): قائمة المنتجات (مطلوب)
- `customerId` (int?): معرف العميل (اختياري)
- `discountAmount` (double): مبلغ الخصم
- `taxAmount` (double): مبلغ الضريبة
- `paymentMethod` (String): طريقة الدفع
- `notes` (String?): ملاحظات

**القيمة المُرجعة:**
- `Sale?`: بيانات الفاتورة أو null إذا فشلت

**مثال الاستخدام:**
```dart
final salesProvider = Provider.of<SalesProvider>(context, listen: false);
final saleItems = [
  SaleItem(
    productId: 1,
    quantity: 2,
    unitPrice: 50.0,
    totalPrice: 100.0,
  ),
];

final sale = await salesProvider.createSale(
  items: saleItems,
  customerId: 1,
  discountAmount: 10.0,
  paymentMethod: 'cash',
);
```

#### الحصول على تاريخ المبيعات
```dart
Future<List<Sale>> getSalesHistory({
  DateTime? startDate,
  DateTime? endDate,
  int? customerId,
  String? paymentMethod,
})
```

#### الحصول على فاتورة محددة
```dart
Future<Sale?> getSaleById(int saleId)
```

#### إلغاء الفاتورة
```dart
Future<bool> voidSale(int saleId, String reason)
```

#### إنشاء مرتجع
```dart
Future<bool> createRefund({
  required int saleId,
  required List<RefundItem> items,
  required String reason,
})
```

## 👤 Customer APIs

### Customer Provider

#### إضافة عميل جديد
```dart
Future<bool> addCustomer({
  required String name,
  String? phone,
  String? email,
  String? address,
  double creditLimit = 0,
})
```

**المعاملات:**
- `name` (String): اسم العميل (مطلوب)
- `phone` (String?): رقم الهاتف
- `email` (String?): البريد الإلكتروني
- `address` (String?): العنوان
- `creditLimit` (double): حد الائتمان

**مثال الاستخدام:**
```dart
final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
final success = await customerProvider.addCustomer(
  name: 'محمد أحمد',
  phone: '0501234567',
  email: 'mohamed@example.com',
  address: 'الرياض، المملكة العربية السعودية',
  creditLimit: 1000.0,
);
```

#### تحديث بيانات العميل
```dart
Future<bool> updateCustomer({
  required int customerId,
  String? name,
  String? phone,
  String? email,
  String? address,
  double? creditLimit,
})
```

#### حذف العميل
```dart
Future<bool> deleteCustomer(int customerId)
```

#### الحصول على العملاء
```dart
Future<List<Customer>> getCustomers({
  String? searchQuery,
  bool includeInactive = false,
})
```

#### البحث بالهاتف
```dart
Future<Customer?> getCustomerByPhone(String phone)
```

#### تحديث رصيد العميل
```dart
Future<bool> updateCustomerBalance(int customerId, double amount)
```

## 📊 Inventory APIs

### Inventory Provider

#### تحديث كمية المنتج
```dart
Future<bool> updateProductQuantity({
  required int productId,
  required int newQuantity,
  String? reason,
})
```

**المعاملات:**
- `productId` (int): معرف المنتج (مطلوب)
- `newQuantity` (int): الكمية الجديدة (مطلوب)
- `reason` (String?): سبب التحديث

#### إضافة كمية للمنتج
```dart
Future<bool> addProductQuantity({
  required int productId,
  required int quantity,
  String? reason,
})
```

#### تقليل كمية المنتج
```dart
Future<bool> subtractProductQuantity({
  required int productId,
  required int quantity,
  String? reason,
})
```

#### الحصول على المنتجات منخفضة المخزون
```dart
Future<List<Product>> getLowStockProducts({
  int threshold = 10,
})
```

#### تسجيل حركة المخزون
```dart
Future<bool> logInventoryMovement({
  required int productId,
  required int quantity,
  required String movementType, // 'in', 'out', 'adjustment'
  String? reason,
  int? relatedSaleId,
})
```

## 📈 Report APIs

### Report Provider

#### تقرير المبيعات اليومية
```dart
Future<DailySalesReport> getDailySalesReport(DateTime date)
```

**القيمة المُرجعة:**
```dart
class DailySalesReport {
  final DateTime date;
  final double totalSales;
  final int totalTransactions;
  final double totalDiscount;
  final double totalTax;
  final List<ProductSalesSummary> topProducts;
}
```

#### تقرير المبيعات الشهرية
```dart
Future<MonthlySalesReport> getMonthlySalesReport(DateTime month)
```

#### تقرير المخزون الحالي
```dart
Future<InventoryReport> getInventoryReport({
  int? categoryId,
  bool includeZeroStock = false,
})
```

#### تقرير أفضل العملاء
```dart
Future<List<CustomerSummary>> getTopCustomers({
  DateTime? startDate,
  DateTime? endDate,
  int limit = 10,
})
```

#### تقرير المنتجات الأكثر مبيعاً
```dart
Future<List<ProductSalesSummary>> getTopSellingProducts({
  DateTime? startDate,
  DateTime? endDate,
  int limit = 10,
})
```

#### تقرير الأرباح والخسائر
```dart
Future<ProfitLossReport> getProfitLossReport({
  required DateTime startDate,
  required DateTime endDate,
})
```

## ⚙️ System APIs

### System Provider

#### إنشاء نسخة احتياطية
```dart
Future<String?> createBackup()
```

**القيمة المُرجعة:**
- `String?`: مسار النسخة الاحتياطية أو null إذا فشلت

#### استعادة النسخة الاحتياطية
```dart
Future<bool> restoreBackup(String backupPath)
```

#### تنظيف قاعدة البيانات
```dart
Future<bool> cleanupDatabase({
  bool deleteOldSales = false,
  int daysToKeep = 365,
})
```

#### الحصول على إحصائيات النظام
```dart
Future<SystemStats> getSystemStats()
```

**القيمة المُرجعة:**
```dart
class SystemStats {
  final int totalProducts;
  final int totalCustomers;
  final int totalSales;
  final double totalRevenue;
  final DateTime lastBackup;
  final String databaseSize;
}
```

## ⚠️ Error Handling

### معالجة الأخطاء

جميع الـ APIs تستخدم نظام معالجة الأخطاء الموحد:

```dart
try {
  final result = await someApiCall();
  // معالجة النتيجة
} catch (error) {
  ErrorHandlerService.handleError(
    context,
    () async => throw error,
    showSnackBar: true,
    onError: () {
      // معالجة الخطأ
    },
  );
}
```

### أنواع الأخطاء

#### DatabaseError
```dart
class DatabaseError implements Exception {
  final String message;
  final String? sql;
  final List<dynamic>? arguments;
  
  DatabaseError(this.message, {this.sql, this.arguments});
}
```

#### ValidationError
```dart
class ValidationError implements Exception {
  final String field;
  final String message;
  
  ValidationError(this.field, this.message);
}
```

#### PermissionError
```dart
class PermissionError implements Exception {
  final String permission;
  final String message;
  
  PermissionError(this.permission, this.message);
}
```

### أكواد الخطأ الشائعة

| الكود | الوصف | الحل |
|-------|--------|------|
| `DB_LOCKED` | قاعدة البيانات مقفلة | إعادة تشغيل التطبيق |
| `INVALID_CREDENTIALS` | بيانات دخول خاطئة | التحقق من البيانات |
| `INSUFFICIENT_PERMISSIONS` | صلاحيات غير كافية | التحقق من الدور |
| `PRODUCT_NOT_FOUND` | المنتج غير موجود | التحقق من معرف المنتج |
| `INSUFFICIENT_STOCK` | مخزون غير كافي | التحقق من الكمية المتوفرة |
| `CUSTOMER_NOT_FOUND` | العميل غير موجود | التحقق من معرف العميل |

## 📝 أمثلة متقدمة

### مثال شامل - عملية بيع كاملة
```dart
Future<void> completeSaleProcess(BuildContext context) async {
  final salesProvider = Provider.of<SalesProvider>(context, listen: false);
  final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
  
  try {
    // 1. التحقق من توفر المنتجات
    final products = await salesProvider.getProducts();
    final selectedProducts = products.where((p) => p.quantity > 0).take(3).toList();
    
    if (selectedProducts.isEmpty) {
      throw Exception('لا توجد منتجات متوفرة');
    }
    
    // 2. إنشاء عناصر البيع
    final saleItems = selectedProducts.map((product) => SaleItem(
      productId: product.id,
      quantity: 1,
      unitPrice: product.price,
      totalPrice: product.price,
    )).toList();
    
    // 3. إنشاء البيع
    final sale = await salesProvider.createSale(
      items: saleItems,
      paymentMethod: 'cash',
      notes: 'بيع تجريبي',
    );
    
    if (sale != null) {
      // 4. تحديث المخزون
      for (final item in saleItems) {
        await inventoryProvider.subtractProductQuantity(
          productId: item.productId,
          quantity: item.quantity,
          reason: 'بيع - فاتورة رقم ${sale.id}',
        );
      }
      
      // 5. عرض رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء الفاتورة بنجاح - رقم ${sale.id}')),
      );
    }
    
  } catch (error) {
    ErrorHandlerService.handleError(
      context,
      () async => throw error,
      showSnackBar: true,
      onError: () {
        // معالجة الخطأ
      },
    );
  }
}
```

### مثال - تقرير شامل
```dart
Future<void> generateComprehensiveReport(BuildContext context) async {
  final reportProvider = Provider.of<ReportProvider>(context, listen: false);
  
  final today = DateTime.now();
  final startOfMonth = DateTime(today.year, today.month, 1);
  
  try {
    // 1. تقرير المبيعات اليومية
    final dailyReport = await reportProvider.getDailySalesReport(today);
    
    // 2. تقرير المبيعات الشهرية
    final monthlyReport = await reportProvider.getMonthlySalesReport(startOfMonth);
    
    // 3. تقرير المخزون
    final inventoryReport = await reportProvider.getInventoryReport();
    
    // 4. أفضل العملاء
    final topCustomers = await reportProvider.getTopCustomers(
      startDate: startOfMonth,
      endDate: today,
      limit: 5,
    );
    
    // 5. أفضل المنتجات
    final topProducts = await reportProvider.getTopSellingProducts(
      startDate: startOfMonth,
      endDate: today,
      limit: 10,
    );
    
    // عرض النتائج
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        dailyReport: dailyReport,
        monthlyReport: monthlyReport,
        inventoryReport: inventoryReport,
        topCustomers: topCustomers,
        topProducts: topProducts,
      ),
    );
    
  } catch (error) {
    ErrorHandlerService.handleError(
      context,
      () async => throw error,
      showSnackBar: true,
    );
  }
}
```

---

## 📋 ملاحظات مهمة

### أفضل الممارسات
1. **استخدم Provider.of مع listen: false** للعمليات غير المتزامنة
2. **تحقق من الصلاحيات** قبل تنفيذ العمليات الحساسة
3. **استخدم معالجة الأخطاء الموحدة** في جميع الـ APIs
4. **اختبر جميع الحالات** بما في ذلك حالات الخطأ
5. **وثق التغييرات** في الـ APIs

### أداء الـ APIs
1. **استخدم الفهرسة** في استعلامات قاعدة البيانات
2. **قلل من عدد الاستعلامات** باستخدام JOIN
3. **استخدم التخزين المؤقت** للبيانات المتكررة
4. **حسن من استعلامات البحث** باستخدام LIMIT

### الأمان
1. **تحقق من الصلاحيات** في كل API call
2. **قم بتشفير البيانات الحساسة**
3. **استخدم معاملات قاعدة البيانات** للعمليات الحرجة
4. **سجل جميع العمليات الحساسة**

---

*آخر تحديث: ديسمبر 2024*
*إصدار API: 1.0*
