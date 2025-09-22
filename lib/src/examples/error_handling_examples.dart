import 'package:flutter/material.dart';
import '../services/error_handler_service.dart';
import '../widgets/error_display_widgets.dart' as error_widgets;
import '../services/db/database_service.dart';
import '../utils/error_messages.dart';

/// أمثلة على كيفية استخدام نظام معالجة الأخطاء المحسن

class ErrorHandlingExamples {
  /// مثال 1: معالجة خطأ في عملية قاعدة البيانات
  static Future<void> addProductExample(
      BuildContext context, DatabaseService db) async {
    await ErrorHandlerService.handleError(
      context,
      () async {
        // محاولة إضافة منتج جديد
        await db.insertProduct({
          'name': 'منتج جديد',
          'price': 100.0,
          'cost': 80.0,
          'quantity': 10,
          'category_id': 1,
          'barcode': '123456789',
        });

        // رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المنتج بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      },
      showSnackBar: true,
      showDialog: false,
      onSuccess: () {
        // إعادة تحميل البيانات
        print('تم إضافة المنتج بنجاح');
      },
      onError: () {
        // تسجيل الخطأ أو إجراءات إضافية
        print('فشل في إضافة المنتج');
      },
    );
  }

  /// مثال 2: معالجة خطأ مع إعادة المحاولة
  static Future<void> loadDataWithRetryExample(
      BuildContext context, DatabaseService db) async {
    await ErrorHandlerService.handleErrorWithRetry(
      context,
      () async {
        // محاولة تحميل البيانات
        final customers = await db.getCustomers();
        return customers;
      },
      maxRetries: 3,
      retryDelay: const Duration(seconds: 2),
      retryLabel: 'إعادة تحميل',
      dismissLabel: 'إلغاء',
    );
  }

  /// مثال 3: معالجة عملية حرجة
  static Future<void> criticalOperationExample(
      BuildContext context, DatabaseService db) async {
    final success = await ErrorHandlerService.handleCriticalOperation(
      context,
      () async {
        // عملية حرجة مثل إضافة مصروف
        await db.addExpense('مصروف تجريبي', 100.0);
      },
      operationName: 'إضافة مصروف',
      showProgressDialog: true,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تنفيذ العملية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// مثال 4: التحقق من صحة البيانات
  static bool validateCustomerData(
      BuildContext context, Map<String, String> data) {
    final nameError =
        ErrorHandlerService.validateRequired(data['name'], 'الاسم');
    final phoneError = ErrorHandlerService.validatePhone(data['phone']);
    final emailError = data['email']?.isNotEmpty == true
        ? ErrorHandlerService.validateEmail(data['email'])
        : null;

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
      return false;
    }

    if (phoneError != null) {
      error_widgets.ErrorSnackBar.show(
        context,
        ErrorInfo(
          title: 'خطأ في رقم الهاتف',
          message: phoneError,
          solution: 'يرجى إدخال رقم هاتف صحيح',
          type: ErrorType.warning,
        ),
      );
      return false;
    }

    if (emailError != null) {
      error_widgets.ErrorSnackBar.show(
        context,
        ErrorInfo(
          title: 'خطأ في البريد الإلكتروني',
          message: emailError,
          solution: 'يرجى إدخال بريد إلكتروني صحيح',
          type: ErrorType.warning,
        ),
      );
      return false;
    }

    return true;
  }

  /// مثال 5: استخدام مكون عرض الخطأ
  static Widget buildCustomerListWithError(
      BuildContext context, DatabaseService db) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.getCustomers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return error_widgets.ErrorWidget(
            error: snapshot.error!,
            onRetry: () {
              // إعادة بناء الـ FutureBuilder
              (context as Element).markNeedsBuild();
            },
            retryLabel: 'إعادة تحميل العملاء',
          );
        }

        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return error_widgets.ErrorWidget(
            error: ErrorInfo(
              title: 'لا توجد بيانات',
              message: 'لم يتم العثور على عملاء في النظام',
              solution: 'أضف عملاء جدد للبدء',
              type: ErrorType.warning,
            ),
            customIcon: const Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final customer = snapshot.data![index];
            return ListTile(
              title: Text(customer['name'] ?? 'بدون اسم'),
              subtitle: Text(customer['phone'] ?? 'بدون هاتف'),
            );
          },
        );
      },
    );
  }

  /// مثال 6: معالجة أخطاء متعددة
  static Future<void> complexOperationExample(
      BuildContext context, DatabaseService db) async {
    await ErrorHandlerService.handleError(
      context,
      () async {
        // خطوة 1: إضافة منتج
        await db.insertProduct({
          'name': 'منتج جديد',
          'price': 100.0,
          'cost': 80.0,
          'quantity': 10,
          'category_id': 1,
          'barcode': '123456789',
        });

        // خطوة 2: إضافة مصروف
        await db.addExpense('مصروف تجريبي', 50.0);

        // خطوة 3: إضافة مبيعات
        await db.createSale(
          customerId: 1,
          type: 'cash',
          items: [
            {
              'product_id': 1,
              'quantity': 2,
              'price': 100.0,
              'discount_percent': 0.0,
            }
          ],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تنفيذ جميع العمليات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      },
      showSnackBar: true,
      showDialog: true, // عرض حوار للعمليات المعقدة
      onSuccess: () {
        print('تم تنفيذ العملية المعقدة بنجاح');
      },
    );
  }

  /// مثال 7: تسجيل الأخطاء للتحليل
  static Future<void> operationWithLoggingExample(
      BuildContext context, DatabaseService db) async {
    try {
      await db.getCustomers();
    } catch (error) {
      // تسجيل الخطأ مع معلومات إضافية
      ErrorHandlerService.logError(
        error,
        context: 'تحميل العملاء',
        additionalInfo: {
          'user_action': 'view_customers',
          'timestamp': DateTime.now().toIso8601String(),
          'database_version': '1.0',
        },
      );

      // عرض الخطأ للمستخدم
      error_widgets.ErrorSnackBar.show(context, error);
    }
  }

  /// مثال 8: عرض خطأ مخصص
  static void showCustomErrorExample(BuildContext context) {
    final customError = ErrorInfo(
      title: 'خطأ مخصص',
      message: 'هذا مثال على خطأ مخصص مع رسالة واضحة',
      solution: 'يمكنك إضافة حل مخصص هنا',
      type: ErrorType.error,
    );

    error_widgets.ErrorDialog.show(
      context,
      customError,
      retryLabel: 'إعادة المحاولة',
      dismissLabel: 'إغلاق',
      onRetry: () {
        print('تم الضغط على إعادة المحاولة');
      },
      onDismiss: () {
        print('تم إغلاق الحوار');
      },
    );
  }

  /// مثال 9: معالجة خطأ في عملية غير متزامنة
  static void handleAsyncErrorExample(
      BuildContext context, DatabaseService db) {
    ErrorHandlerService.handleAsyncError(
      context,
      () async {
        // عملية غير متزامنة
        await Future.delayed(const Duration(seconds: 2));
        await db.getCustomers();
      },
      showSnackBar: true,
      onSuccess: () {
        print('تمت العملية غير المتزامنة بنجاح');
      },
      onError: () {
        print('فشلت العملية غير المتزامنة');
      },
    );
  }

  /// مثال 10: استخدام مكون التحميل مع الخطأ
  static Widget loadingWithErrorExample(
      BuildContext context, DatabaseService db) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.getCustomers(),
      builder: (context, snapshot) {
        return error_widgets.LoadingWithErrorWidget(
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          error: snapshot.hasError ? snapshot.error : null,
          loadingMessage: 'جاري تحميل العملاء...',
          onRetry: () {
            // إعادة تحميل البيانات
            (context as Element).markNeedsBuild();
          },
          child: ListView.builder(
            itemCount: snapshot.data?.length ?? 0,
            itemBuilder: (context, index) {
              final customer = snapshot.data![index];
              return ListTile(
                title: Text(customer['name'] ?? 'بدون اسم'),
                subtitle: Text(customer['phone'] ?? 'بدون هاتف'),
              );
            },
          ),
        );
      },
    );
  }
}

/// مثال على استخدام مكون LoadingWithErrorWidget في صفحة
class CustomerListPage extends StatefulWidget {
  final DatabaseService db;

  const CustomerListPage({super.key, required this.db});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  List<Map<String, dynamic>>? customers;
  dynamic error;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await widget.db.getCustomers();
      setState(() {
        customers = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة العملاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: error_widgets.LoadingWithErrorWidget(
        isLoading: isLoading,
        error: error,
        loadingMessage: 'جاري تحميل العملاء...',
        onRetry: _loadCustomers,
        child: customers == null || customers!.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد عملاء في النظام',
                  style: TextStyle(fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: customers!.length,
                itemBuilder: (context, index) {
                  final customer = customers![index];
                  return ListTile(
                    title: Text(customer['name'] ?? 'بدون اسم'),
                    subtitle: Text(customer['phone'] ?? 'بدون هاتف'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // مثال على حذف العميل مع معالجة الخطأ
                        ErrorHandlerService.handleError(
                          context,
                          () async {
                            // await widget.db.deleteCustomer(customer['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم حذف العميل بنجاح'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadCustomers(); // إعادة تحميل القائمة
                          },
                          showSnackBar: true,
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
