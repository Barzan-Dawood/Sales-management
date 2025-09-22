# 📚 أمثلة استخدام نظام معالجة الأخطاء

## 🎯 نظرة عامة

هذا الملف يحتوي على أمثلة عملية لكيفية استخدام نظام معالجة الأخطاء المحسن في التطبيق.

## 📁 الملفات المطلوبة

```dart
import '../services/error_handler_service.dart';
import '../widgets/error_display_widgets.dart' as error_widgets;
import '../services/db/database_service.dart';
import '../utils/error_messages.dart';
```

## 🚀 الأمثلة المتاحة

### 1. مثال إضافة منتج مع معالجة الخطأ

```dart
await ErrorHandlerService.handleError(
  context,
  () async {
    await db.insertProduct({
      'name': 'منتج جديد',
      'price': 100.0,
      'cost': 80.0,
      'quantity': 10,
      'category_id': 1,
      'barcode': '123456789',
    });
  },
  showSnackBar: true,
  onSuccess: () => print('تم بنجاح'),
  onError: () => print('حدث خطأ'),
);
```

### 2. مثال تحميل البيانات مع إعادة المحاولة

```dart
await ErrorHandlerService.handleErrorWithRetry(
  context,
  () async {
    final customers = await db.getCustomers();
    return customers;
  },
  maxRetries: 3,
  retryDelay: Duration(seconds: 2),
);
```

### 3. مثال العمليات الحرجة

```dart
final success = await ErrorHandlerService.handleCriticalOperation(
  context,
  () async {
    await db.addExpense('مصروف تجريبي', 100.0);
  },
  operationName: 'إضافة مصروف',
  showProgressDialog: true,
);
```

### 4. مثال التحقق من صحة البيانات

```dart
final nameError = ErrorHandlerService.validateRequired(name, 'الاسم');
if (nameError != null) {
  error_widgets.ErrorSnackBar.show(
    context,
    ErrorInfo(
      title: 'خطأ في البيانات',
      message: nameError,
      solution: 'يرجى إدخال الاسم',
      type: ErrorType.warning,
    ),
  );
  return;
}
```

### 5. مثال عرض الخطأ في الصفحة

```dart
if (snapshot.hasError) {
  return error_widgets.ErrorWidget(
    error: snapshot.error!,
    onRetry: () => _loadData(),
    retryLabel: 'إعادة تحميل',
  );
}
```

### 6. مثال مكون التحميل مع الخطأ

```dart
error_widgets.LoadingWithErrorWidget(
  isLoading: isLoading,
  error: error,
  loadingMessage: 'جاري التحميل...',
  onRetry: _loadData,
  child: YourContentWidget(),
)
```

### 7. مثال تسجيل الأخطاء

```dart
try {
  await db.getCustomers();
} catch (error) {
  ErrorHandlerService.logError(
    error,
    context: 'تحميل العملاء',
    additionalInfo: {
      'user_id': currentUser.id,
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
  
  error_widgets.ErrorSnackBar.show(context, error);
}
```

### 8. مثال خطأ مخصص

```dart
final customError = ErrorInfo(
  title: 'خطأ مخصص',
  message: 'هذا مثال على خطأ مخصص',
  solution: 'يمكنك إضافة حل مخصص هنا',
  type: ErrorType.error,
);

error_widgets.ErrorDialog.show(
  context,
  customError,
  retryLabel: 'إعادة المحاولة',
  onRetry: () => print('تم إعادة المحاولة'),
);
```

## 🎨 أنواع الأخطاء

### ErrorType.warning
- **اللون:** برتقالي
- **الاستخدام:** تحذيرات يمكن تجاهلها

### ErrorType.error  
- **اللون:** أحمر
- **الاستخدام:** أخطاء تتطلب إجراء

### ErrorType.critical
- **اللون:** أحمر داكن
- **الاستخدام:** أخطاء حرجة تمنع الاستخدام

## 📱 مكونات العرض

### ErrorSnackBar
```dart
error_widgets.ErrorSnackBar.show(
  context,
  error,
  onActionPressed: () => _retry(),
  actionLabel: 'إعادة المحاولة',
);
```

### ErrorDialog
```dart
error_widgets.ErrorDialog.show(
  context,
  error,
  onRetry: () => _retry(),
  retryLabel: 'إعادة المحاولة',
);
```

### ErrorWidget
```dart
error_widgets.ErrorWidget(
  error: error,
  onRetry: () => _retry(),
  retryLabel: 'إعادة المحاولة',
);
```

### LoadingWithErrorWidget
```dart
error_widgets.LoadingWithErrorWidget(
  isLoading: isLoading,
  error: error,
  onRetry: () => _retry(),
  child: YourContentWidget(),
)
```

## ✅ التحقق من صحة البيانات

```dart
// التحقق من الحقول المطلوبة
final nameError = ErrorHandlerService.validateRequired(name, 'الاسم');
final phoneError = ErrorHandlerService.validatePhone(phone);
final emailError = ErrorHandlerService.validateEmail(email);
final amountError = ErrorHandlerService.validateAmount(amount);
final quantityError = ErrorHandlerService.validateQuantity(quantity);
```

## 🔄 أفضل الممارسات

1. **استخدم الرسائل الواضحة** - تجنب الرسائل التقنية
2. **قدم حلول عملية** - اقترح خطوات للحل
3. **صنف الأخطاء بشكل صحيح** - اختر النوع المناسب
4. **سجل الأخطاء** - للمساعدة في التحليل
5. **اختبر جميع الحالات** - تأكد من معالجة جميع الأخطاء

## 🎯 مثال تطبيقي كامل

```dart
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool isLoading = false;
  dynamic error;
  List<Map<String, dynamic>>? data;

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    await ErrorHandlerService.handleError(
      context,
      () async {
        data = await db.getCustomers();
        setState(() {
          isLoading = false;
        });
      },
      showSnackBar: true,
      onSuccess: () => print('تم تحميل البيانات بنجاح'),
      onError: () => setState(() {
        isLoading = false;
        error = 'فشل في تحميل البيانات';
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('قائمة العملاء')),
      body: error_widgets.LoadingWithErrorWidget(
        isLoading: isLoading,
        error: error,
        loadingMessage: 'جاري تحميل العملاء...',
        onRetry: _loadData,
        child: ListView.builder(
          itemCount: data?.length ?? 0,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(data![index]['name']),
            );
          },
        ),
      ),
    );
  }
}
```

---

**هذه الأمثلة توضح كيفية استخدام نظام معالجة الأخطاء بشكل صحيح وفعال! 🎉**
