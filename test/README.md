# اختبارات نظام إدارة المكتب

## 📁 هيكل الاختبارات

```
test/
├── database/                    # اختبارات قاعدة البيانات
│   └── database_service_test.dart
├── widgets/                     # اختبارات واجهة المستخدم
│   └── products_screen_test.dart
├── unit/                        # اختبارات الوحدات
│   └── auth_provider_test.dart
├── services/                    # اختبارات الخدمات
│   └── print_service_test.dart
├── integration/                 # اختبارات التكامل
│   └── sales_flow_test.dart
├── performance/                 # اختبارات الأداء
│   └── database_performance_test.dart
├── test_config.dart            # إعدادات الاختبارات
├── run_tests.dart              # تشغيل جميع الاختبارات
└── widget_test.dart            # الاختبار الرئيسي
```

## 🚀 كيفية تشغيل الاختبارات

### تشغيل جميع الاختبارات
```bash
flutter test
```

### تشغيل اختبارات محددة
```bash
# اختبارات قاعدة البيانات
flutter test test/database/

# اختبارات واجهة المستخدم
flutter test test/widgets/

# اختبارات الوحدات
flutter test test/unit/

# اختبارات الخدمات
flutter test test/services/

# اختبارات التكامل
flutter test test/integration/

# اختبارات الأداء
flutter test test/performance/
```

### تشغيل اختبار واحد
```bash
flutter test test/database/database_service_test.dart
```

## 📋 أنواع الاختبارات

### 1. اختبارات قاعدة البيانات (Database Tests)
- اختبار تهيئة قاعدة البيانات
- اختبار إنشاء الجداول
- اختبار إدراج واسترجاع البيانات
- اختبار قيود المفاتيح الخارجية
- اختبار سلامة قاعدة البيانات

### 2. اختبارات واجهة المستخدم (Widget Tests)
- اختبار عرض الشاشات
- اختبار التفاعل مع العناصر
- اختبار النماذج والتحقق من صحة البيانات
- اختبار التنقل بين الشاشات

### 3. اختبارات الوحدات (Unit Tests)
- اختبار منطق الأعمال
- اختبار معالجة البيانات
- اختبار التحقق من صحة المدخلات
- اختبار الحسابات والمعادلات

### 4. اختبارات الخدمات (Services Tests)
- اختبار خدمات الطباعة
- اختبار خدمات النسخ الاحتياطي
- اختبار خدمات PDF
- اختبار خدمات المصادقة

### 5. اختبارات التكامل (Integration Tests)
- اختبار تدفق العمل الكامل
- اختبار التفاعل بين المكونات
- اختبار معالجة الأخطاء
- اختبار الأداء العام

### 6. اختبارات الأداء (Performance Tests)
- اختبار سرعة قاعدة البيانات
- اختبار استهلاك الذاكرة
- اختبار العمليات المتزامنة
- اختبار الاستعلامات المعقدة

## 🔧 إعدادات الاختبارات

### ملف test_config.dart
يحتوي على:
- إعدادات بيئة الاختبار
- مساعدات البيانات التجريبية
- إعدادات قاعدة البيانات للاختبار

### مساعدات البيانات التجريبية
```dart
// منتج تجريبي
TestDataHelper.getSampleProduct()

// عميل تجريبي
TestDataHelper.getSampleCustomer()

// مبيعة تجريبية
TestDataHelper.getSampleSale()

// مستخدم تجريبي
TestDataHelper.getSampleUser()
```

## 📊 تقارير الاختبارات

### عرض النتائج
```bash
flutter test --reporter=expanded
```

### حفظ النتائج في ملف
```bash
flutter test > test_results.txt
```

### اختبارات التغطية
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 🐛 استكشاف الأخطاء

### مشاكل شائعة
1. **خطأ في قاعدة البيانات**: تأكد من تهيئة FFI للاختبارات
2. **خطأ في الواجهة**: تأكد من استخدام `pumpAndSettle()`
3. **خطأ في التوقيت**: استخدم `await` مع العمليات غير المتزامنة

### نصائح للاختبارات
1. استخدم `setUp()` و `tearDown()` لتنظيف البيانات
2. استخدم بيانات تجريبية منفصلة لكل اختبار
3. اختبر الحالات الحدية والأخطاء
4. تأكد من تنظيف الموارد بعد كل اختبار

## 📈 إضافة اختبارات جديدة

### خطوات إضافة اختبار جديد
1. اختر المجلد المناسب (database, widgets, unit, etc.)
2. أنشئ ملف الاختبار الجديد
3. استخدم `TestDataHelper` للبيانات التجريبية
4. اتبع نمط الاختبارات الموجودة
5. اختبر الحالات المختلفة (نجاح، فشل، حدود)

### مثال على اختبار جديد
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:office_mangment_system/src/services/your_service.dart';
import '../test_config.dart';

void main() {
  group('YourService Tests', () {
    late YourService service;

    setUp(() {
      service = YourService();
    });

    test('should perform expected action', () {
      // Arrange
      final input = TestDataHelper.getSampleData();
      
      // Act
      final result = service.performAction(input);
      
      // Assert
      expect(result, isNotNull);
      expect(result, equals(expectedValue));
    });
  });
}
```

## 🎯 أفضل الممارسات

1. **اختبار واحد لكل وظيفة**: كل اختبار يجب أن يختبر وظيفة واحدة
2. **أسماء واضحة**: استخدم أسماء وصفية للاختبارات
3. **ترتيب AAA**: Arrange, Act, Assert
4. **تنظيف البيانات**: تأكد من تنظيف البيانات بعد كل اختبار
5. **اختبار الأخطاء**: اختبر الحالات الاستثنائية والأخطاء
6. **السرعة**: اجعل الاختبارات سريعة وفعالة
7. **الاستقلالية**: كل اختبار يجب أن يكون مستقلاً عن الآخرين
