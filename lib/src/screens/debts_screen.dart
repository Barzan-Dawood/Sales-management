// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures, use_build_context_synchronously, unused_local_variable

import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/click_guard.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/store_config.dart';
import 'package:flutter/material.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../services/print_service.dart';
import '../utils/format.dart';
import '../utils/export.dart';
import '../utils/dark_mode_utils.dart';
import '../services/error_handler_service.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  int _refreshKey = 0; // مفتاح لإعادة تحميل البيانات

  // فلترة الأقساط
  String _installmentFilter = 'all'; // all, paid, unpaid, overdue
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // دالة لإعادة تحميل البيانات
  void _refreshData() {
    setState(() {
      _refreshKey++;
    });
  }

  // دالة للحصول على معرف منتج الدين أو إنشاؤه إذا لم يكن موجوداً
  Future<int> _getDebtProductId(DatabaseService db) async {
    try {
      // البحث عن منتج الدين الموجود
      final existingProducts = await db.database.query(
        'products',
        where: 'name = ? AND category_id IS NULL',
        whereArgs: ['دين/قرض'],
        limit: 1,
      );

      if (existingProducts.isNotEmpty) {
        return existingProducts.first['id'] as int;
      }

      // إنشاء منتج الدين إذا لم يكن موجوداً
      final productId = await db.database.insert('products', {
        'name': 'دين/قرض',
        'description': 'منتج وهمي لتمثيل الديون والقروض',
        'price': 0.0,
        'cost': 0.0,
        'quantity': 999999, // كمية كبيرة جداً
        'min_quantity': 0,
        'barcode': 'DEBT_PRODUCT',
        'category_id': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return productId;
    } catch (e) {
      // في حالة الخطأ، إرجاع معرف افتراضي
      print('خطأ في إنشاء منتج الدين: $e');
      return 1; // معرف افتراضي
    }
  }

  Future<Map<String, dynamic>> _getCustomerDebtData(
      int customerId, DatabaseService db) async {
    try {
      // الحصول على بيانات العميل مباشرة
      final customers = await db.getCustomers();
      final customer = customers.firstWhere(
        (c) => c['id'] == customerId,
        orElse: () => {'total_debt': 0.0},
      );

      // الحصول على المدفوعات
      final payments = await db.getCustomerPayments(customerId: customerId);
      double totalPaid = 0;
      for (final payment in payments) {
        totalPaid += (payment['amount'] as num).toDouble();
      }

      // total_debt في جدول العملاء يحتوي على المتبقي بعد المدفوعات
      // لذلك نحتاج لحساب إجمالي الدين الأصلي
      final remainingDebt = (customer['total_debt'] as num).toDouble();
      final originalDebt = remainingDebt + totalPaid;

      return {
        'totalDebt': originalDebt,
        'totalPaid': totalPaid,
        'remainingDebt': remainingDebt,
      };
    } catch (e) {
      return {
        'totalDebt': 0.0,
        'totalPaid': 0.0,
        'remainingDebt': 0.0,
      };
    }
  }

  // دالة لجلب تفاصيل الأقساط للعميل
  Future<List<Map<String, dynamic>>> _getCustomerInstallments(
      int customerId, DatabaseService db) async {
    try {
      final installments = await db.getInstallments(customerId: customerId);
      return installments.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // دالة لحساب ملخص الأقساط
  Future<Map<String, double>> _getInstallmentsSummary(
      DatabaseService db) async {
    try {
      final installments = await db.getInstallments();
      double installmentTotal = 0.0;
      double creditTotal = 0.0;

      for (final installment in installments) {
        final amount = (installment['amount'] as num?)?.toDouble() ?? 0.0;
        final saleType = installment['sale_type']?.toString();

        if (saleType == 'installment') {
          installmentTotal += amount;
        } else if (saleType == 'credit') {
          creditTotal += amount;
        }
      }

      return {
        'installment': installmentTotal,
        'credit': creditTotal,
      };
    } catch (e) {
      return {'installment': 0.0, 'credit': 0.0};
    }
  }

  // دالة لعرض المعاينة المفصلة للعميل
  void _showCustomerDetailedPreview(
    BuildContext context,
    Map<String, dynamic> customer,
    DatabaseService db,
  ) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Row(
                  children: [
                    Icon(Icons.person,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'معاينة مفصلة - ${customer['name'] ?? 'غير محدد'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),

                // المحتوى
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _getDetailedCustomerData(customer['id'], db),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = snapshot.data!;
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // معلومات العميل
                            _buildInfoSection('معلومات العميل', [
                              _buildInfoRow(
                                  'الاسم', customer['name'] ?? 'غير محدد'),
                              _buildInfoRow(
                                  'الهاتف', customer['phone'] ?? 'غير محدد'),
                              _buildInfoRow(
                                  'العنوان', customer['address'] ?? 'غير محدد'),
                            ]),

                            const SizedBox(height: 16),

                            // ملخص الحساب
                            _buildInfoSection('ملخص الحساب', [
                              _buildInfoRow(
                                  'إجمالي الدين الأصلي',
                                  Formatters.currencyIQD(
                                      data['totalDebt'] ?? 0.0),
                                  valueColor: Colors.red),
                              _buildInfoRow(
                                  'إجمالي المدفوع',
                                  Formatters.currencyIQD(
                                      data['totalPaid'] ?? 0.0),
                                  valueColor:
                                      DarkModeUtils.getSuccessColor(context)),
                              _buildInfoRow(
                                  'المتبقي',
                                  Formatters.currencyIQD(
                                      data['remainingDebt'] ?? 0.0),
                                  valueColor: data['remainingDebt'] > 0
                                      ? Theme.of(context).colorScheme.error
                                      : DarkModeUtils.getSuccessColor(context)),
                            ]),

                            const SizedBox(height: 16),

                            // تفاصيل الديون (credit sales)
                            if (data['creditSales'] != null &&
                                (data['creditSales'] as List).isNotEmpty) ...[
                              _buildCreditSalesSection(
                                data['creditSales']
                                    as List<Map<String, dynamic>>,
                                db,
                                customer,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // تفاصيل الأقساط
                            if (data['installments'] != null &&
                                (data['installments'] as List).isNotEmpty) ...[
                              _buildInstallmentsSection(
                                data['installments']
                                    as List<Map<String, dynamic>>,
                                db,
                                customer,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // سجل المدفوعات
                            if (data['payments'] != null &&
                                (data['payments'] as List).isNotEmpty) ...[
                              _buildPaymentsSection(data['payments']
                                  as List<Map<String, dynamic>>),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // أزرار الإجراءات
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => ClickGuard.runExclusive(
                        'debts_add_payment_dialog_bottom',
                        () {
                          Navigator.of(context).pop();
                          _showAddPaymentDialog(context, db,
                              customer: customer);
                        },
                      ),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('إضافة دفعة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DarkModeUtils.getSuccessColor(context),
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => ClickGuard.runExclusive(
                        'debts_print_options',
                        () {
                          Navigator.of(context).pop();
                          _showPrintOptionsDialog(context, customer, db);
                        },
                      ),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('طباعة كشف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة لجلب البيانات المفصلة للعميل
  Future<Map<String, dynamic>> _getDetailedCustomerData(
      int customerId, DatabaseService db) async {
    try {
      final debtData = await _getCustomerDebtData(customerId, db);
      final payments = await db.getCustomerPayments(customerId: customerId);
      final installments = await _getCustomerInstallments(customerId, db);
      final creditSales = await db.creditSales(customerId: customerId);

      return {
        'totalDebt': debtData['totalDebt'],
        'totalPaid': debtData['totalPaid'],
        'remainingDebt': debtData['remainingDebt'],
        'payments': payments,
        'installments': installments,
        'creditSales': creditSales,
      };
    } catch (e) {
      return {
        'totalDebt': 0.0,
        'totalPaid': 0.0,
        'remainingDebt': 0.0,
        'payments': <Map<String, dynamic>>[],
        'installments': <Map<String, dynamic>>[],
        'creditSales': <Map<String, dynamic>>[],
      };
    }
  }

  // دالة لبناء قسم المعلومات
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }

  // دالة لبناء صف معلومات
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // دالة لترجمة نوع البيع
  String _translateSaleType(String? saleType) {
    switch (saleType?.toLowerCase()) {
      case 'installment':
        return 'قسط';
      case 'cash':
        return 'نقدي';
      case 'credit':
        return 'آجل';
      default:
        return saleType ?? 'غير محدد';
    }
  }

  // دالة لبناء قسم الديون (credit sales)
  Widget _buildCreditSalesSection(
    List<Map<String, dynamic>> creditSales,
    DatabaseService db,
    Map<String, dynamic> customer,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الديون (مبيعات آجلة)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...creditSales.map((sale) {
              final saleId = sale['id'] as int;
              final total = (sale['total'] as num).toDouble();
              final createdAt =
                  DateTime.tryParse(sale['created_at']?.toString() ?? '');
              final dueDate = sale['due_date'] != null
                  ? DateTime.tryParse(sale['due_date']?.toString() ?? '')
                  : null;
              final isOverdue =
                  dueDate != null && dueDate.isBefore(DateTime.now());

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Theme.of(context).colorScheme.error.withOpacity(0.08)
                      : Colors.orange.withOpacity(0.08),
                  border: Border.all(
                    color: isOverdue
                        ? Theme.of(context).colorScheme.error.withOpacity(0.4)
                        : Colors.orange.withOpacity(0.35),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'دين رقم $saleId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'المبلغ: ${Formatters.currencyIQD(total)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              'تاريخ البيع: ${DateFormat('yyyy/MM/dd').format(createdAt)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          if (dueDate != null)
                            Text(
                              'تاريخ الاستحقاق: ${DateFormat('yyyy/MM/dd').format(dueDate)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isOverdue
                                    ? Theme.of(context).colorScheme.error
                                    : Colors.orange,
                                fontWeight: isOverdue
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _showDeleteCreditSaleDialog(
                        context,
                        sale,
                        db,
                        customer,
                      ),
                      tooltip: 'حذف الدين',
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // دالة لبناء قسم الأقساط
  Widget _buildInstallmentsSection(
    List<Map<String, dynamic>> installments,
    DatabaseService db,
    Map<String, dynamic> customer,
  ) {
    // تشخيص مؤقت
    print(
        'Building installments section with ${installments.length} installments');
    if (installments.isNotEmpty) {
      print('First installment data: ${installments.first}');
    }

    // حساب إجمالي مبلغ الأقساط الأصلية والبيع الآجل
    double totalInstallmentAmount = 0.0;
    double totalCreditAmount = 0.0;

    for (final installment in installments) {
      final amount = (installment['amount'] as num?)?.toDouble() ?? 0.0;
      final saleType = installment['sale_type']?.toString();

      if (saleType == 'installment') {
        totalInstallmentAmount += amount;
      } else if (saleType == 'credit') {
        totalCreditAmount += amount;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل الأقساط',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),

            // إضافة ملخص المبالغ
            if (totalInstallmentAmount > 0 || totalCreditAmount > 0) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    if (totalInstallmentAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'إجمالي مبلغ الأقساط الأصلية:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            Formatters.currencyIQD(totalInstallmentAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (totalCreditAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'إجمالي مبلغ البيع الآجل:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          Text(
                            Formatters.currencyIQD(totalCreditAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المجموع الكلي:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          Formatters.currencyIQD(
                              totalInstallmentAmount + totalCreditAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            ...installments.asMap().entries.map((entry) {
              final index = entry.key;
              final installment = entry.value;

              final isPaid = (installment['paid'] as int?) == 1;
              final dueDate =
                  DateTime.tryParse(installment['due_date']?.toString() ?? '');
              final isOverdue = dueDate != null &&
                  dueDate.isBefore(DateTime.now()) &&
                  !isPaid;

              return Container(
                margin: const EdgeInsets.only(bottom: 3),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? DarkModeUtils.getSuccessColor(context).withOpacity(0.08)
                      : isOverdue
                          ? Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.08)
                          : Colors.orange.withOpacity(0.08),
                  border: Border.all(
                    color: isPaid
                        ? DarkModeUtils.getSuccessColor(context)
                            .withOpacity(0.4)
                        : isOverdue
                            ? Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.4)
                            : Colors.orange.withOpacity(0.35),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'القسط ${index + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? DarkModeUtils.getSuccessColor(context)
                                : isOverdue
                                    ? Theme.of(context).colorScheme.error
                                    : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isPaid
                                ? 'مدفوع'
                                : isOverdue
                                    ? 'متأخر'
                                    : 'مستحق',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('المبلغ: ',
                                style: const TextStyle(fontSize: 9)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: installment['sale_type'] == 'installment'
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                Formatters.currencyIQD(
                                    (installment['amount'] as num?)
                                            ?.toDouble() ??
                                        0.0),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  color: installment['sale_type'] ==
                                          'installment'
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                            'تاريخ الاستحقاق: ${dueDate != null ? DateFormat('yyyy/MM/dd').format(dueDate) : 'غير محدد'}',
                            style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'معرف القسط: ${installment['id'] ?? 'غير محدد'}',
                          style:
                              const TextStyle(fontSize: 8, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: installment['sale_type'] == 'installment'
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      installment['sale_type'] == 'installment'
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.3)
                                          : Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'نوع البيع: ${_translateSaleType(installment['sale_type'])}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: installment['sale_type'] ==
                                          'installment'
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 16),
                              onPressed: () => _deleteInstallment(
                                context,
                                installment,
                                db,
                              ),
                              tooltip: 'حذف القسط',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isPaid && installment['payment_date'] != null) ...[
                      const SizedBox(height: 0.1),
                      Text(
                        'تاريخ الدفع: ${DateFormat('yyyy/MM/dd').format(DateTime.parse(installment['payment_date']))}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // دالة لعرض خيارات الطباعة
  void _showPrintOptionsDialog(
    BuildContext context,
    Map<String, dynamic> customer,
    DatabaseService db,
  ) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Row(
                  children: [
                    Icon(Icons.print, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'اختيار نوع الطابعة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // خيارات الطابعة
                const Text(
                  'اختر نوع الطابعة:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // طابعة حرارية 58mm
                _buildPrinterOption(
                  context,
                  '58',
                  'طابعة حرارية 58mm',
                  'فواتير صغيرة ومضغوطة - مناسبة للفواتير البسيطة',
                  Icons.receipt,
                  Colors.orange,
                  () => _printWithFormat(context, customer, db, '58'),
                ),

                const SizedBox(height: 6),

                // طابعة حرارية 80mm
                _buildPrinterOption(
                  context,
                  '80',
                  'طابعة حرارية 80mm',
                  'فواتير متوسطة الحجم - الأكثر استخداماً',
                  Icons.receipt_long,
                  Colors.blue,
                  () => _printWithFormat(context, customer, db, '80'),
                ),

                const SizedBox(height: 6),

                // ورقة A4
                _buildPrinterOption(
                  context,
                  'A4',
                  'ورقة A4',
                  'تقارير مفصلة وواضحة - مناسبة للطباعة المكتبية',
                  Icons.description,
                  Colors.green,
                  () => _printWithFormat(context, customer, db, 'A4'),
                ),

                const SizedBox(height: 6),

                // ورقة A5
                _buildPrinterOption(
                  context,
                  'A5',
                  'ورقة A5',
                  'تقارير متوسطة الحجم - توازن بين الوضوح والاقتصاد',
                  Icons.description_outlined,
                  Colors.purple,
                  () => _printWithFormat(context, customer, db, 'A5'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة لبناء خيار الطابعة
  Widget _buildPrinterOption(
    BuildContext context,
    String format,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // دالة للطباعة بنوع معين
  void _printWithFormat(
    BuildContext context,
    Map<String, dynamic> customer,
    DatabaseService db,
    String format,
  ) {
    Navigator.of(context).pop(); // إغلاق نافذة اختيار الطابعة
    _printCustomerStatement(context, customer, db, pageFormat: format);
  }

  // دالة لبناء قسم المدفوعات
  Widget _buildPaymentsSection(List<Map<String, dynamic>> payments) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سجل المدفوعات',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            ...payments.map((payment) {
              final paymentDate =
                  DateTime.tryParse(payment['payment_date'] ?? '');
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.currencyIQD(
                              (payment['amount'] as num).toDouble()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (payment['description'] != null &&
                            payment['description'].toString().isNotEmpty)
                          Text(
                            payment['description'].toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    Text(
                      paymentDate != null
                          ? DateFormat('yyyy/MM/dd').format(paymentDate)
                          : 'غير محدد',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text(
            'دفتر الديون',
            style: TextStyle(color: Colors.blue, fontSize: 12),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
          foregroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.onSurface
              : Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.add,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.black),
              onPressed: () => ClickGuard.runExclusive(
                'debts_add_payment',
                () => _showAddPaymentDialog(context, db),
              ),
              tooltip: 'إضافة دفعة',
            ),
            IconButton(
              icon: Icon(Icons.picture_as_pdf,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.black),
              tooltip: 'تصدير PDF',
              onPressed: () => ClickGuard.runExclusive(
                'debts_export_summary',
                () => _exportDebtsSummary(db),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط البحث
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'البحث عن العميل...',
                  prefixIcon: Icon(Icons.search,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.4)),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // إحصائيات بسيطة
            Container(
              padding: const EdgeInsets.all(8),
              child: FutureBuilder<Map<String, dynamic>>(
                future: db.getDebtStatistics(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final stats = snapshot.data!;
                  return Row(
                    children: [
                      Expanded(
                        child: _buildSimpleStatCard(
                          'إجمالي الديون',
                          Formatters.currencyIQD(stats['total_debt'] ?? 0),
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildSimpleStatCard(
                          'المدفوع',
                          Formatters.currencyIQD(stats['total_payments'] ?? 0),
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildSimpleStatCard(
                          'المتبقي',
                          Formatters.currencyIQD((stats['total_debt'] ?? 0) -
                              (stats['total_payments'] ?? 0)),
                          Colors.orange,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // تبويبات
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.warning, size: 16),
                    text: 'الذين لديهم ديون',
                    height: 50,
                  ),
                  Tab(
                    icon: Icon(Icons.schedule, size: 16),
                    text: 'الأقساط',
                    height: 50,
                  ),
                  Tab(
                    icon: Icon(Icons.check_circle, size: 16),
                    text: 'المدفوعين بالكامل',
                    height: 50,
                  ),
                  Tab(
                    icon: Icon(Icons.people, size: 16),
                    text: 'جميع العملاء',
                    height: 50,
                  ),
                  Tab(
                    icon: Icon(Icons.analytics, size: 16),
                    text: 'التقارير',
                    height: 50,
                  ),
                ],
              ),
            ),

            // محتوى التبويبات
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // تبويب الذين لديهم ديون
                  _buildDebtorsTab(db),
                  // تبويب الأقساط
                  _buildInstallmentsTab(db),
                  // تبويب المدفوعين بالكامل
                  _buildFullyPaidCustomersTab(db),
                  // تبويب جميع العملاء
                  _buildAllCustomersTab(db),
                  // تبويب التقارير
                  _buildReportsTab(db),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDebtsSummary(DatabaseService db) async {
    try {
      final stats = await db.getDebtStatistics();
      final rows = <List<String>>[
        ['البند', 'القيمة'],
        ['إجمالي الديون', Formatters.currencyIQD(stats['total_debt'] ?? 0)],
        ['ديون متأخرة', Formatters.currencyIQD(stats['overdue_debt'] ?? 0)],
        [
          'إجمالي المدفوعات',
          Formatters.currencyIQD(stats['total_payments'] ?? 0)
        ],
        [
          'عدد العملاء المدينين',
          (stats['customers_with_debt'] ?? 0).toString()
        ],
      ];
      final saved = await PdfExporter.exportSimpleTable(
        filename: 'debts_summary.pdf',
        title: 'تقرير الديون',
        rows: rows,
      );
      if (!mounted) return;
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ التقرير في: $saved')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير تقرير الديون: $e')),
      );
    }
  }

  Widget _buildSimpleStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: DarkModeUtils.getShadowColor(context),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtorsTab(DatabaseService db) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('debtors_$_refreshKey'),
      future: db.getCustomers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> customers = snapshot.data!;

        // تصفية العملاء حسب البحث
        if (_searchQuery.isNotEmpty) {
          customers = customers.where((customer) {
            return customer['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (customers.isEmpty) {
          return Center(
            child: Text(
              'لا توجد عملاء',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            return _buildCustomerDebtCard(context, customer, db,
                showOnlyDebtors: true);
          },
        );
      },
    );
  }

  Widget _buildFullyPaidCustomersTab(DatabaseService db) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('fully_paid_$_refreshKey'),
      future: db.getCustomers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> customers = snapshot.data!;

        // تصفية العملاء حسب البحث
        if (_searchQuery.isNotEmpty) {
          customers = customers.where((customer) {
            return customer['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (customers.isEmpty) {
          return Center(
            child: Text(
              'لا توجد عملاء',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            return _buildCustomerDebtCard(context, customer, db,
                showOnlyFullyPaid: true);
          },
        );
      },
    );
  }

  Widget _buildInstallmentsTab(DatabaseService db) {
    return Column(
      children: [
        // شريط الفلترة
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _installmentFilter,
                      decoration: InputDecoration(
                        labelText: 'فلترة الأقساط',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.4),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('جميع الأقساط')),
                        DropdownMenuItem(
                            value: 'paid', child: Text('المدفوعة')),
                        DropdownMenuItem(
                            value: 'unpaid', child: Text('غير المدفوعة')),
                        DropdownMenuItem(
                            value: 'overdue', child: Text('المتأخرة')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _installmentFilter = value ?? 'all';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showDateRangeDialog(),
                    icon: Icon(
                      Icons.date_range,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
                    tooltip: 'فلترة بالتاريخ',
                  ),
                ],
              ),
              if (_fromDate != null || _toDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_fromDate != null)
                      Chip(
                        label: Text(
                            'من: ${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'),
                        onDeleted: () {
                          setState(() {
                            _fromDate = null;
                          });
                        },
                      ),
                    if (_toDate != null)
                      Chip(
                        label: Text(
                            'إلى: ${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'),
                        onDeleted: () {
                          setState(() {
                            _toDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // ملخص إجمالي الأقساط
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: FutureBuilder<Map<String, double>>(
            future: _getInstallmentsSummary(db),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final summary = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'إجمالي الأقساط الأصلية',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(
                            Formatters.currencyIQD(summary['installment'] ?? 0),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Theme.of(context).dividerColor,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'إجمالي البيع الآجل',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(
                            Formatters.currencyIQD(summary['credit'] ?? 0),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Theme.of(context).dividerColor,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'المجموع الكلي',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(
                            Formatters.currencyIQD(
                                (summary['installment'] ?? 0) +
                                    (summary['credit'] ?? 0)),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),

        // قائمة الأقساط
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('installments_$_refreshKey'),
            future: db.getInstallments(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final installments = snapshot.data!;
              final filteredInstallments = installments.where((installment) {
                // فلترة بالبحث
                final customerName =
                    installment['customer_name']?.toString().toLowerCase() ??
                        '';
                final phone =
                    installment['customer_phone']?.toString().toLowerCase() ??
                        '';
                final query = _searchQuery.toLowerCase();
                final matchesSearch =
                    customerName.contains(query) || phone.contains(query);

                if (!matchesSearch) return false;

                // فلترة بالحالة
                final isPaid = (installment['paid'] as int) == 1;
                final dueDate = DateTime.parse(installment['due_date']);
                final isOverdue = dueDate.isBefore(DateTime.now()) && !isPaid;

                switch (_installmentFilter) {
                  case 'paid':
                    return isPaid;
                  case 'unpaid':
                    return !isPaid;
                  case 'overdue':
                    return isOverdue;
                  default:
                    return true;
                }
              }).where((installment) {
                // فلترة بالتاريخ
                if (_fromDate == null && _toDate == null) return true;

                final dueDate = DateTime.parse(installment['due_date']);

                if (_fromDate != null && dueDate.isBefore(_fromDate!))
                  return false;
                if (_toDate != null && dueDate.isAfter(_toDate!)) return false;

                return true;
              }).toList();

              if (filteredInstallments.isEmpty) {
                return const Center(
                  child: Text('لا يوجد أقساط تطابق الفلترة المحددة'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filteredInstallments.length,
                itemBuilder: (context, index) {
                  final installment = filteredInstallments[index];
                  return _buildInstallmentCard(context, installment, db);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllCustomersTab(DatabaseService db) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('all_customers_$_refreshKey'),
      future: db.getCustomers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> customers = snapshot.data!;

        // تصفية العملاء حسب البحث
        if (_searchQuery.isNotEmpty) {
          customers = customers.where((customer) {
            return customer['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (customers.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد عملاء',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            return _buildCustomerDebtCard(context, customer, db);
          },
        );
      },
    );
  }

  Widget _buildReportsTab(DatabaseService db) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // إحصائيات الأقساط
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إحصائيات الأقساط',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: db.getInstallmentStatistics(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final stats = snapshot.data!;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'إجمالي الأقساط',
                                  '${stats['total_count']}',
                                  Formatters.currencyIQD(stats['total_amount']),
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _buildStatCard(
                                  'المدفوعة',
                                  '${stats['paid_count']}',
                                  Formatters.currencyIQD(stats['paid_amount']),
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'غير المدفوعة',
                                  '${stats['unpaid_count']}',
                                  Formatters.currencyIQD(
                                      stats['unpaid_amount']),
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _buildStatCard(
                                  'المتأخرة',
                                  '${stats['overdue_count']}',
                                  Formatters.currencyIQD(
                                      stats['overdue_amount']),
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // الأقساط المتأخرة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الأقساط المتأخرة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: db.getOverdueInstallments(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final overdueInstallments = snapshot.data!;

                      if (overdueInstallments.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد أقساط متأخرة',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: overdueInstallments.length,
                        itemBuilder: (context, index) {
                          final installment = overdueInstallments[index];
                          final daysOverdue =
                              (installment['days_overdue'] as num).toInt();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.red.shade50,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(0xFFFEE2E2), // Light Red
                                child: Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                installment['customer_name'] ?? 'غير محدد',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'المبلغ: ${Formatters.currencyIQD(installment['amount'])}'),
                                  Text('متأخر $daysOverdue يوم'),
                                ],
                              ),
                              trailing: Text(
                                '${DateTime.parse(installment['due_date']).day}/${DateTime.parse(installment['due_date']).month}/${DateTime.parse(installment['due_date']).year}',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // الأقساط المستحقة هذا الشهر
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الأقساط المستحقة هذا الشهر',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: db.getCurrentMonthInstallments(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final currentMonthInstallments = snapshot.data!;

                      if (currentMonthInstallments.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد أقساط مستحقة هذا الشهر',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentMonthInstallments.length,
                        itemBuilder: (context, index) {
                          final installment = currentMonthInstallments[index];
                          final dueDate =
                              DateTime.parse(installment['due_date']);
                          final isOverdue = dueDate.isBefore(DateTime.now());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isOverdue
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isOverdue
                                    ? Colors.orange.shade100
                                    : Colors.blue.shade100,
                                child: Icon(
                                  isOverdue ? Icons.warning : Icons.schedule,
                                  color:
                                      isOverdue ? Colors.orange : Colors.blue,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                installment['customer_name'] ?? 'غير محدد',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'المبلغ: ${Formatters.currencyIQD(installment['amount'])}'),
                              trailing: Text(
                                '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                                style: TextStyle(
                                  color:
                                      isOverdue ? Colors.orange : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // دالة عرض نافذة اختيار نطاق التاريخ
  void _showDateRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('فلترة بالتاريخ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('من تاريخ'),
                subtitle: Text(_fromDate != null
                    ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                    : 'لم يتم تحديد تاريخ'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _fromDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    useRootNavigator: true,
                    builder: (ctx, child) => Directionality(
                      textDirection: ui.TextDirection.rtl,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                  if (date != null) {
                    setState(() {
                      _fromDate = date;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('إلى تاريخ'),
                subtitle: Text(_toDate != null
                    ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                    : 'لم يتم تحديد تاريخ'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _toDate ?? DateTime.now(),
                    firstDate: _fromDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                    useRootNavigator: true,
                    builder: (ctx, child) => Directionality(
                      textDirection: ui.TextDirection.rtl,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                  if (date != null) {
                    setState(() {
                      _toDate = date;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                });
                Navigator.pop(context);
              },
              child: const Text('مسح الفلترة'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentCard(
    BuildContext context,
    Map<String, dynamic> installment,
    DatabaseService db,
  ) {
    final dueDate = DateTime.parse(installment['due_date'] as String);
    final isOverdue = dueDate.isBefore(DateTime.now());
    final isPaid = (installment['paid'] as int) == 1;
    final amount = (installment['amount'] as num).toDouble();
    final customerName = installment['customer_name'] ?? 'غير محدد';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: isPaid
              ? Colors.green.shade100
              : isOverdue
                  ? Colors.red.shade100
                  : Colors.orange.shade100,
          child: Icon(
            isPaid
                ? Icons.check_circle
                : isOverdue
                    ? Icons.warning
                    : Icons.schedule,
            color: isPaid
                ? Colors.green
                : isOverdue
                    ? Colors.red
                    : Colors.orange,
            size: 16,
          ),
        ),
        title: Text(
          customerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المبلغ: ${Formatters.currencyIQD(amount)}',
                style: const TextStyle(fontSize: 11)),
            Text(
                'تاريخ الاستحقاق: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                style: const TextStyle(fontSize: 11)),
            if (isPaid)
              Text(
                'تم الدفع في: ${DateTime.parse(installment['paid_at'] as String).day}/${DateTime.parse(installment['paid_at'] as String).month}/${DateTime.parse(installment['paid_at'] as String).year}',
                style: const TextStyle(color: Colors.green, fontSize: 11),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'pay' && !isPaid) {
              _showPayInstallmentDialog(context, installment, db);
            } else if (value == 'edit') {
              _editInstallment(context, installment, db);
            } else if (value == 'print') {
              _printInstallmentReport(context, installment, db);
            } else if (value == 'delete') {
              _deleteInstallment(context, installment, db);
            }
          },
          itemBuilder: (context) => [
            if (!isPaid) ...[
              const PopupMenuItem(
                value: 'pay',
                child: Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Text('دفع القسط'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('تعديل القسط'),
                  ],
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('طباعة كشف القسط'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف القسط'),
                ],
              ),
            ),
          ],
        ),
        onTap: () =>
            _showCustomerDetailsFromInstallment(context, installment, db),
      ),
    );
  }

  void _showCustomerDetailsFromInstallment(
    BuildContext context,
    Map<String, dynamic> installment,
    DatabaseService db,
  ) async {
    // جلب معلومات العميل من القسط
    final customerId = installment['customer_id'];
    if (customerId == null) return;

    // جلب بيانات العميل
    final customers = await db.getCustomers();
    final customer = customers.firstWhere(
      (c) => c['id'] == customerId,
      orElse: () => <String, dynamic>{},
    );

    if (customer.isEmpty) return;

    // عرض تفاصيل العميل
    _showCustomerDetailedPreview(context, customer, db);
  }

  Widget _buildCustomerDebtCard(
    BuildContext context,
    Map<String, dynamic> customer,
    DatabaseService db, {
    bool showOnlyDebtors = false,
    bool showOnlyPaid = false,
    bool showOnlyFullyPaid = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey('customer_debt_${customer['id']}_$_refreshKey'),
        future: _getCustomerDebtData(customer['id'], db),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ListTile(
              title: Text('جاري التحميل...'),
              leading: CircularProgressIndicator(),
            );
          }

          final debtData = snapshot.data!;
          final remaining = debtData['remainingDebt'] ?? 0.0;

          // تصفية حسب نوع التبويب
          if (showOnlyDebtors && remaining <= 0) {
            return const SizedBox.shrink(); // إخفاء العملاء المدفوعين
          }
          if (showOnlyPaid && remaining > 0) {
            return const SizedBox.shrink(); // إخفاء العملاء الذين لديهم ديون
          }
          if (showOnlyFullyPaid && remaining > 0) {
            return const SizedBox
                .shrink(); // إخفاء العملاء الذين لديهم ديون (المدفوعين بالكامل فقط)
          }

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor:
                  remaining > 0 ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(
                remaining > 0 ? Icons.warning : Icons.check_circle,
                color: remaining > 0 ? Colors.red : Colors.green,
                size: 16,
              ),
            ),
            title: Text(
              customer['name'] ?? 'غير محدد',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الهاتف: ${customer['phone'] ?? 'غير محدد'}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'المتبقي: ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      Formatters.currencyIQD(remaining),
                      style: TextStyle(
                        color: remaining > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'payments') {
                  _showCustomerPayments(context, customer, db);
                } else if (value == 'add_payment') {
                  _showAddPaymentDialog(context, db, customer: customer);
                } else if (value == 'add_debt') {
                  _showAddDebtDialog(context, db, customer: customer);
                } else if (value == 'add_installment') {
                  _showAddInstallmentDialog(context, db, customer: customer);
                } else if (value == 'print_statement') {
                  _printCustomerStatement(context, customer, db);
                } else if (value == 'view_installments') {
                  _showCustomerInstallments(context, customer, db);
                } else if (value == 'delete') {
                  _showDeleteCustomerDialog(context, customer, db);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'payments',
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 16),
                      SizedBox(width: 8),
                      Text('سجل المدفوعات'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_payment',
                  child: Row(
                    children: [
                      Icon(Icons.payment, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('إضافة دفعة', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_debt',
                  child: Row(
                    children: [
                      Icon(Icons.add_card, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('إضافة دين', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_installment',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('إضافة دين بالأقساط',
                          style: TextStyle(color: Colors.purple)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'print_statement',
                  child: Row(
                    children: [
                      Icon(Icons.print, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('طباعة كشف حساب',
                          style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'view_installments',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('عرض الأقساط',
                          style: TextStyle(color: Colors.indigo)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف العميل', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _showCustomerDetailedPreview(context, customer, db),
          );
        },
      ),
    );
  }

  void _showCustomerInstallments(
    BuildContext context,
    Map<String, dynamic> customer,
    DatabaseService db,
  ) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'أقساط العميل - ${customer['name']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getCustomerInstallments(customer['id'], db),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final installments = snapshot.data!;

                      if (installments.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد أقساط لهذا العميل',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: installments.length,
                        itemBuilder: (context, index) {
                          final installment = installments[index];
                          return _buildInstallmentCard(
                              context, installment, db);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomerPayments(
    BuildContext context,
    Map<String, dynamic> customer,
    DatabaseService db,
  ) {
    showDialog(
        context: context,
        builder: (context) => Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Dialog(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'سجل المدفوعات - ${customer['name']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: db.getCustomerPayments(
                              customerId: customer['id']),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final payments = snapshot.data!;

                            if (payments.isEmpty) {
                              return const Center(
                                child: Text('لا توجد مدفوعات'),
                              );
                            }

                            return ListView.builder(
                              itemCount: payments.length,
                              itemBuilder: (context, index) {
                                final payment = payments[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(Icons.payment,
                                        color: Colors.green),
                                    title: Text(
                                      Formatters.currencyIQD(payment['amount']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    subtitle: Builder(builder: (context) {
                                      final raw =
                                          (payment['payment_date'] ?? '')
                                              .toString();
                                      DateTime? dt;
                                      try {
                                        dt = DateTime.parse(raw);
                                      } catch (_) {}
                                      final formatted = dt != null
                                          ? DateFormat('yyyy/MM/dd').format(dt)
                                          : raw.toString().split('T').first;
                                      return Text('التاريخ: $formatted');
                                    }),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => ClickGuard.runExclusive(
                                        'debts_delete_payment_${payment['id']}',
                                        () => _deletePayment(
                                            context, payment['id'], db),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => ClickGuard.runExclusive(
                                'debts_add_payment_dialog',
                                () {
                                  Navigator.pop(context);
                                  _showAddPaymentDialog(context, db,
                                      customer: customer);
                                },
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة دفعة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color(0xFF1976D2), // Professional Blue
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ));
  }

  void _showAddPaymentDialog(
    BuildContext context,
    DatabaseService db, {
    Map<String, dynamic>? customer,
  }) {
    final amountController = TextEditingController();
    final dateController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0],
    );
    Map<String, dynamic>? selectedCustomer = customer;

    showDialog(
      context: context,
      builder: (context) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('إضافة دفعة'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (customer == null) ...[
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: db.getCustomers(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final customers = snapshot.data!;
                          return DropdownButtonFormField<int>(
                            initialValue: selectedCustomer?['id'],
                            decoration: const InputDecoration(
                              labelText: 'العميل',
                              border: OutlineInputBorder(),
                            ),
                            items: customers.map((customer) {
                              return DropdownMenuItem<int>(
                                value: customer['id'],
                                child: Text(customer['name'] ?? 'غير محدد'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCustomer = customers.firstWhere(
                                  (c) => c['id'] == value,
                                  orElse: () => customers.first,
                                );
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        border: OutlineInputBorder(),
                        prefixText: 'د.ع ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'التاريخ',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          useRootNavigator: true,
                          builder: (ctx, child) => Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: child ?? const SizedBox.shrink(),
                          ),
                        );
                        if (date != null) {
                          dateController.text = date.toString().split(' ')[0];
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedCustomer == null ||
                        amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                      );
                      return;
                    }

                    try {
                      await db.addPayment(
                        customerId: selectedCustomer!['id'],
                        amount: double.parse(amountController.text),
                        paymentDate: DateTime.parse(dateController.text),
                      );

                      Navigator.pop(context);
                      // إعادة تحميل البيانات
                      _refreshData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إضافة الدفعة بنجاح')),
                      );
                    } catch (e) {
                      ErrorHandlerService.handleError(
                        context,
                        () async => throw e,
                        showSnackBar: true,
                        showDialog: false,
                      );
                    }
                  },
                  child: const Text('إضافة'),
                ),
              ],
            ),
          )),
    );
  }

  void _deletePayment(BuildContext context, int paymentId, DatabaseService db) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذه الدفعة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final auth = context.read<AuthProvider>();
                  final currentUser = auth.currentUser;
                  await db.deletePayment(
                    paymentId,
                    userId: currentUser?.id,
                    username: currentUser?.username,
                    name: currentUser?.name,
                  );
                  Navigator.pop(context);
                  // إعادة تحميل البيانات
                  _refreshData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الدفعة بنجاح')),
                  );
                } catch (e) {
                  ErrorHandlerService.handleError(
                    context,
                    () async => throw e,
                    showSnackBar: true,
                    showDialog: false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFDC2626)), // Professional Red
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInstallmentDialog(
    BuildContext context,
    DatabaseService db, {
    Map<String, dynamic>? customer,
  }) {
    final amountController = TextEditingController();
    final downPaymentController = TextEditingController();
    final installmentCountController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0],
    );
    Map<String, dynamic>? selectedCustomer = customer;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('إضافة دين بالأقساط'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (customer == null) ...[
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: db.getCustomers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final customers = snapshot.data!;
                        return DropdownButtonFormField<int>(
                          initialValue: selectedCustomer?['id'],
                          decoration: const InputDecoration(
                            labelText: 'العميل',
                            border: OutlineInputBorder(),
                          ),
                          items: customers.map((customer) {
                            return DropdownMenuItem<int>(
                              value: customer['id'],
                              child: Text(customer['name'] ?? 'غير محدد'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCustomer = customers.firstWhere(
                                (c) => c['id'] == value,
                                orElse: () => customers.first,
                              );
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'إجمالي المبلغ',
                      border: OutlineInputBorder(),
                      prefixText: 'د.ع ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: downPaymentController,
                    decoration: const InputDecoration(
                      labelText: 'المقدم (اختياري)',
                      border: OutlineInputBorder(),
                      prefixText: 'د.ع ',
                      hintText: 'اتركه فارغ إذا لم يكن هناك مقدم',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: installmentCountController,
                    decoration: const InputDecoration(
                      labelText: 'عدد الأقساط',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'وصف البيع (اختياري)',
                      border: OutlineInputBorder(),
                      hintText: 'مثال: بيع جهاز كمبيوتر',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ البيع',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        useRootNavigator: true,
                        builder: (ctx, child) => Directionality(
                          textDirection: ui.TextDirection.rtl,
                          child: child ?? const SizedBox.shrink(),
                        ),
                      );
                      if (date != null) {
                        dateController.text = date.toString().split(' ')[0];
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCustomer == null ||
                      amountController.text.isEmpty ||
                      installmentCountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يرجى ملء جميع الحقول المطلوبة'),
                      ),
                    );
                    return;
                  }

                  try {
                    final totalAmount = double.parse(amountController.text);
                    final downPayment =
                        double.tryParse(downPaymentController.text) ?? 0.0;
                    final installmentCount =
                        int.parse(installmentCountController.text);

                    if (downPayment >= totalAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('المقدم يجب أن يكون أقل من إجمالي المبلغ'),
                        ),
                      );
                      return;
                    }

                    // إضافة البيع بالأقساط
                    await db.createSale(
                      customerId: selectedCustomer!['id'],
                      type: 'installment',
                      items: [
                        {
                          'product_id':
                              await _getDebtProductId(db), // معرف منتج الدين
                          'price': totalAmount,
                          'cost': 0.0,
                          'quantity': 1,
                        }
                      ],
                      decrementStock: false,
                      installmentCount: installmentCount,
                      downPayment: downPayment,
                      firstInstallmentDate:
                          DateTime.now().add(const Duration(days: 30)),
                    );

                    Navigator.pop(context);
                    // إعادة تحميل البيانات
                    _refreshData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'تم إضافة دين بالأقساط ${Formatters.currencyIQD(totalAmount)} للعميل ${selectedCustomer!['name']}'),
                        backgroundColor:
                            Color(0xFF059669), // Professional Green
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ في إضافة الدين بالأقساط: $e'),
                        backgroundColor: Color(0xFFDC2626), // Professional Red
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7C3AED), // Professional Purple
                  foregroundColor: Colors.white,
                ),
                child: const Text('إضافة دين بالأقساط'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDebtDialog(
    BuildContext context,
    DatabaseService db, {
    Map<String, dynamic>? customer,
  }) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0],
    );
    Map<String, dynamic>? selectedCustomer = customer;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('إضافة دين جديد'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (customer == null) ...[
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: db.getCustomers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final customers = snapshot.data!;
                        return DropdownButtonFormField<int>(
                          initialValue: selectedCustomer?['id'],
                          decoration: const InputDecoration(
                            labelText: 'العميل',
                            border: OutlineInputBorder(),
                          ),
                          items: customers.map((customer) {
                            return DropdownMenuItem<int>(
                              value: customer['id'],
                              child: Text(customer['name'] ?? 'غير محدد'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCustomer = customers.firstWhere(
                                (c) => c['id'] == value,
                                orElse: () => customers.first,
                              );
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ الدين',
                      border: OutlineInputBorder(),
                      prefixText: 'د.ع ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'وصف الدين (اختياري)',
                      border: OutlineInputBorder(),
                      hintText: 'مثال: فاتورة رقم 123',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الدين',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        useRootNavigator: true,
                        builder: (ctx, child) => Directionality(
                          textDirection: ui.TextDirection.rtl,
                          child: child ?? const SizedBox.shrink(),
                        ),
                      );
                      if (date != null) {
                        dateController.text = date.toString().split(' ')[0];
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCustomer == null ||
                      amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('يرجى ملء جميع الحقول المطلوبة')),
                    );
                    return;
                  }

                  try {
                    // إضافة الدين كفاتورة جديدة
                    await db.createSale(
                      customerId: selectedCustomer!['id'],
                      type: 'credit', // دين
                      items: [
                        {
                          'product_id':
                              await _getDebtProductId(db), // معرف منتج الدين
                          'price': double.parse(amountController.text),
                          'cost': 0.0,
                          'quantity': 1,
                        }
                      ],
                      decrementStock: false, // لا ننقص المخزون للدين
                    );

                    Navigator.pop(context);
                    // إعادة تحميل البيانات
                    _refreshData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'تم إضافة دين ${Formatters.currencyIQD(double.parse(amountController.text))} للعميل ${selectedCustomer!['name']}'),
                        backgroundColor:
                            Color(0xFF059669), // Professional Green
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ في إضافة الدين: $e'),
                        backgroundColor: Color(0xFFDC2626), // Professional Red
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF59E0B)), // Professional Orange
                child: const Text('إضافة الدين'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPayInstallmentDialog(
    BuildContext context,
    Map<String, dynamic> installment,
    DatabaseService db,
  ) {
    final amountController = TextEditingController(
      text: (installment['amount'] as num).toString(),
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('دفع القسط'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('العميل: ${installment['customer_name']}'),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'مبلغ الدفع',
                    border: OutlineInputBorder(),
                    prefixText: 'د.ع ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال مبلغ الدفع')),
                  );
                  return;
                }

                // التحقق من أن القسط غير مدفوع
                final isPaid = (installment['paid'] as int?) == 1;
                if (isPaid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('القسط مدفوع بالفعل ولا يمكن دفعه مرة أخرى'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                  return;
                }

                final paymentAmount = double.parse(amountController.text);
                final installmentAmount =
                    (installment['amount'] as num).toDouble();

                // التحقق من أن المبلغ المدفوع لا يتجاوز مبلغ القسط
                if (paymentAmount > installmentAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'المبلغ المدفوع ($paymentAmount) يتجاوز مبلغ القسط ($installmentAmount)'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                  return;
                }

                try {
                  await db.payInstallment(
                    installment['id'],
                    paymentAmount,
                    notes: notesController.text.isNotEmpty
                        ? notesController.text
                        : null,
                  );

                  Navigator.pop(context);
                  // إعادة تحميل البيانات
                  _refreshData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم دفع القسط بنجاح'),
                      backgroundColor: Color(0xFF059669), // Professional Green
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في دفع القسط: $e'),
                      backgroundColor: Color(0xFFDC2626), // Professional Red
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF059669)), // Professional Green
              child: const Text('دفع القسط'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCustomerDialog(
    BuildContext context,
    Map<String, dynamic> customer,
    DatabaseService db,
  ) async {
    // التحقق من وجود بيانات مرتبطة قبل عرض الحوار
    try {
      final relatedData = await db.getCustomerRelatedDataCount(customer['id']);
      final hasRelatedData =
          relatedData['sales']! > 0 || relatedData['payments']! > 0;

      if (hasRelatedData) {
        // عرض تحذير واضح بأن الحذف غير ممكن
        showDialog(
          context: context,
          builder: (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Color(0xFFDC2626), size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'لا يمكن حذف العميل',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'العميل: ${customer['name'] ?? 'غير محدد'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'هذا العميل مرتبط ببيانات مهمة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (relatedData['sales']! > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_cart,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text('${relatedData['sales']} عملية بيع'),
                        ],
                      ),
                    ),
                  if (relatedData['payments']! > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.payment, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('${relatedData['payments']} دفعة'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFFFC107)),
                    ),
                    child: const Text(
                      'لحماية السجلات المالية والتاريخية، يجب حذف جميع المبيعات والمدفوعات المرتبطة بهذا العميل أولاً قبل حذف العميل نفسه.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF856404),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                  ),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          ),
        );
        return;
      }
    } catch (e) {
      // في حالة حدوث خطأ في التحقق، نتابع مع الحذف العادي
      debugPrint('خطأ في التحقق من البيانات المرتبطة: $e');
    }

    // إذا لم يكن هناك بيانات مرتبطة، عرض حوار الحذف العادي
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد حذف العميل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('هل أنت متأكد من حذف العميل:'),
              const SizedBox(height: 4),
              Text(
                '${customer['name'] ?? 'غير محدد'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ملاحظة: هذا العميل لا يحتوي على أي مبيعات أو مدفوعات مرتبطة به.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final auth = context.read<AuthProvider>();
                  final currentUser = auth.currentUser;
                  final deletedRows = await db.deleteCustomer(
                    customer['id'],
                    userId: currentUser?.id,
                    username: currentUser?.username,
                    name: currentUser?.name,
                  );

                  if (deletedRows > 0) {
                    Navigator.pop(context);
                    _refreshData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('تم حذف العميل ${customer['name']} بنجاح'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('لم يتم العثور على العميل'),
                        backgroundColor: Color(0xFFF59E0B),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);

                  String errorMessage = 'خطأ في حذف العميل';
                  final errorString = e.toString();

                  if (errorString.contains('لا يمكن حذف العميل')) {
                    // رسالة الخطأ من قاعدة البيانات
                    errorMessage = errorString.replaceAll('Exception: ', '');
                  } else if (errorString.contains('database is locked')) {
                    errorMessage =
                        'قاعدة البيانات قيد الاستخدام، حاول مرة أخرى';
                  } else if (errorString.contains('no such table')) {
                    errorMessage =
                        'خطأ في قاعدة البيانات، يرجى إعادة تشغيل التطبيق';
                  } else {
                    errorMessage = 'خطأ في حذف العميل: $errorString';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Color(0xFFDC2626),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFFDC2626)),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  // دالة حذف الدين (credit sale)
  void _showDeleteCreditSaleDialog(
    BuildContext context,
    Map<String, dynamic> sale,
    DatabaseService db,
    Map<String, dynamic> customer,
  ) async {
    // التحقق من وجود مدفوعات مرتبطة
    final saleId = sale['id'] as int;
    final customerId = customer['id'] as int;
    final saleTotal = (sale['total'] as num).toDouble();

    try {
      final hasPayments = await db.hasPaymentsForCreditSale(saleId, customerId);
      final paymentsTotal = hasPayments
          ? await db.getPaymentsForCreditSale(saleId, customerId)
          : 0.0;

      if (hasPayments && paymentsTotal > 0) {
        // عرض تحذير بأن هناك مدفوعات مرتبطة
        showDialog(
          context: context,
          builder: (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Color(0xFFDC2626), size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تحذير: لا يمكن حذف الدين',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'هذا الدين مرتبط بمدفوعات:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('مبلغ الدين: ${Formatters.currencyIQD(saleTotal)}'),
                  Text(
                      'إجمالي المدفوعات: ${Formatters.currencyIQD(paymentsTotal)}'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFFFC107)),
                    ),
                    child: const Text(
                      'لحذف هذا الدين، يجب حذف جميع المدفوعات المرتبطة به أولاً من سجل المدفوعات.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF856404),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                  ),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          ),
        );
        return;
      }
    } catch (e) {
      // في حالة حدوث خطأ في التحقق، نتابع مع الحذف العادي
      debugPrint('خطأ في التحقق من المدفوعات: $e');
    }

    // إذا لم يكن هناك مدفوعات، عرض حوار الحذف العادي
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الدين'),
          content: Text(
            'هل أنت متأكد من حذف الدين رقم $saleId بقيمة ${Formatters.currencyIQD(saleTotal)}؟\n\n'
            'سيتم حذف هذا الدين فقط دون التأثير على باقي بيانات العميل أو المبيعات الأخرى.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final deleted = await db.deleteSale(saleId);
                  if (deleted) {
                    Navigator.pop(context);
                    Navigator.pop(context); // إغلاق المعاينة التفصيلية أيضاً
                    _refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم حذف الدين رقم $saleId بنجاح',
                        ),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل حذف الدين'),
                        backgroundColor: Color(0xFFDC2626),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في حذف الدين: $e'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC2626),
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  // دالة تعديل القسط
  void _editInstallment(
    BuildContext context,
    Map<String, dynamic> installment,
    DatabaseService db,
  ) {
    final amountController = TextEditingController(
      text: (installment['amount'] as num).toString(),
    );
    final dueDateController = TextEditingController(
      text: installment['due_date'].toString().split(' ')[0],
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل القسط'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'مبلغ القسط',
                    border: OutlineInputBorder(),
                    prefixText: 'د.ع ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dueDateController,
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الاستحقاق',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(installment['due_date']),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      useRootNavigator: true,
                      builder: (ctx, child) => Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: child ?? const SizedBox.shrink(),
                      ),
                    );
                    if (date != null) {
                      dueDateController.text = date.toString().split(' ')[0];
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                // التحقق من أن القسط غير مدفوع
                final isPaid = (installment['paid'] as int?) == 1;
                if (isPaid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لا يمكن تعديل قسط مدفوع'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                  return;
                }

                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال مبلغ القسط'),
                      backgroundColor: Color(0xFFDC2626), // Professional Red
                    ),
                  );
                  return;
                }

                try {
                  await db.updateInstallment(
                    installment['id'],
                    double.parse(amountController.text),
                    DateTime.parse(dueDateController.text),
                  );

                  Navigator.pop(context);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تعديل القسط بنجاح'),
                      backgroundColor: Color(0xFF059669), // Professional Green
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في تعديل القسط: $e'),
                      backgroundColor: Color(0xFFDC2626), // Professional Red
                    ),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  // دالة حذف القسط
  void _deleteInstallment(
    BuildContext context,
    Map<String, dynamic> installment,
    DatabaseService db,
  ) {
    final isPaid = (installment['paid'] as int?) == 1;
    final amount = (installment['amount'] as num?)?.toDouble() ?? 0.0;
    final customerName = installment['customer_name'] ?? 'غير محدد';

    // إذا كان القسط مدفوعاً، عرض تحذير
    if (isPaid) {
      showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Color(0xFFDC2626), size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'تحذير: القسط مدفوع',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القسط المحدد مدفوع بالفعل:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('المبلغ: ${Formatters.currencyIQD(amount)}'),
                Text('العميل: $customerName'),
                if (installment['paid_at'] != null)
                  Text(
                    'تاريخ الدفع: ${DateFormat('yyyy/MM/dd').format(DateTime.parse(installment['paid_at'].toString()))}',
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFFFC107)),
                  ),
                  child: const Text(
                    'لا يمكن حذف قسط مدفوع. إذا كنت تريد إلغاء الدفع، يجب حذف المدفوعة المرتبطة به من سجل المدفوعات أولاً.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF856404),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
                ),
                child: const Text('حسناً'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // إذا لم يكن مدفوعاً، عرض حوار الحذف العادي
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف القسط'),
          content: Text(
            'هل أنت متأكد من حذف قسط ${Formatters.currencyIQD(amount)} للعميل $customerName؟\n\n'
            'سيتم حذف هذا القسط فقط دون التأثير على باقي بيانات العميل أو المبيعات الأخرى.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final auth = context.read<AuthProvider>();
                  final currentUser = auth.currentUser;
                  await db.deleteInstallment(
                    installment['id'],
                    userId: currentUser?.id,
                    username: currentUser?.username,
                    name: currentUser?.name,
                  );
                  Navigator.pop(context);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف القسط بنجاح'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في حذف القسط: $e'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC2626),
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  // دالة طباعة كشف حساب العميل
  void _printCustomerStatement(
    BuildContext context,
    Map<String, dynamic> customer,
    DatabaseService db, {
    String? pageFormat,
  }) async {
    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // الحصول على بيانات العميل والمدفوعات
      final customerId = customer['id'];
      final payments = await db.getCustomerPayments(customerId: customerId);
      final debtData = await _getCustomerDebtData(customerId, db);

      // إغلاق مؤشر التحميل
      Navigator.pop(context);

      // إنشاء كشف الحساب (تم الإبقاء على الاستدعاء إذا كان يُستخدم مستقبلاً)
      _generateCustomerStatement(
        customer,
        payments,
        debtData,
      );

      // طباعة كشف الحساب
      final store = context.read<StoreConfig>();
      await PrintService.printCustomerStatement(
        shopName: store.shopName,
        phone: store.phone,
        address: store.address,
        customer: customer,
        payments: payments,
        debtData: debtData,
        pageFormat: pageFormat,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم طباعة كشف الحساب بنجاح'),
          backgroundColor: Color(0xFF059669), // Professional Green
        ),
      );
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في طباعة كشف الحساب: $e'),
          backgroundColor: Color(0xFFDC2626), // Professional Red
        ),
      );
    }
  }

  // دالة إنشاء كشف الحساب
  String _generateCustomerStatement(
    Map<String, dynamic> customer,
    List<Map<String, dynamic>> payments,
    Map<String, dynamic> debtData,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('=' * 50);
    buffer.writeln('كشف حساب العميل');
    buffer.writeln('=' * 50);
    buffer.writeln();

    buffer.writeln('اسم العميل: ${customer['name'] ?? 'غير محدد'}');
    buffer.writeln('رقم الهاتف: ${customer['phone'] ?? 'غير محدد'}');
    buffer.writeln('العنوان: ${customer['address'] ?? 'غير محدد'}');
    buffer.writeln(
        'تاريخ الطباعة: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln();

    buffer.writeln('-' * 50);
    buffer.writeln('ملخص الحساب');
    buffer.writeln('-' * 50);
    buffer.writeln(
        'إجمالي الدين: ${Formatters.currencyIQD(debtData['totalDebt'])}');
    buffer.writeln(
        'إجمالي المدفوع: ${Formatters.currencyIQD(debtData['totalPaid'])}');
    buffer.writeln(
        'المتبقي: ${Formatters.currencyIQD(debtData['remainingDebt'])}');
    buffer.writeln();

    if (payments.isNotEmpty) {
      buffer.writeln('-' * 50);
      buffer.writeln('سجل المدفوعات');
      buffer.writeln('-' * 50);

      for (final payment in payments) {
        buffer.writeln('التاريخ: ${payment['payment_date']}');
        buffer.writeln('المبلغ: ${Formatters.currencyIQD(payment['amount'])}');
        buffer.writeln('الوصف: ${payment['description'] ?? 'دفعة'}');
        buffer.writeln();
      }
    }

    buffer.writeln('=' * 50);
    buffer.writeln('نهاية كشف الحساب');
    buffer.writeln('=' * 50);

    return buffer.toString();
  }

  // دالة طباعة كشف القسط
  void _printInstallmentReport(
    BuildContext context,
    Map<String, dynamic> installment,
    DatabaseService db,
  ) async {
    try {
      // الحصول على معلومات العميل
      final customerId = installment['customer_id'] as int;
      final customers = await db.getCustomers();
      final customer = customers.firstWhere(
        (c) => c['id'] == customerId,
        orElse: () => <String, Object?>{},
      );

      if (customer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ: لم يتم العثور على معلومات العميل'),
            backgroundColor: Color(0xFFDC2626), // Professional Red
          ),
        );
        return;
      }

      // الحصول على جميع أقساط العميل
      final allInstallments = await db.getInstallments(customerId: customerId);

      // الحصول على جميع دفعات العميل
      final payments = await db.getCustomerPayments(customerId: customerId);

      // حساب الإجماليات
      final totalDebt = allInstallments.fold<double>(
          0.0, (sum, inst) => sum + (inst['amount'] as num).toDouble());

      final paidAmount = allInstallments
          .where((inst) => (inst['paid'] as int) == 1)
          .fold<double>(
              0.0, (sum, inst) => sum + (inst['amount'] as num).toDouble());

      final remainingAmount = totalDebt - paidAmount;

      // إنشاء PDF لكشف القسط
      final pdfBytes = await _generateInstallmentReportPDF(
        customer: customer,
        installment: installment,
        allInstallments: allInstallments,
        payments: payments,
        totalDebt: totalDebt,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
      );

      // طباعة PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name:
            'كشف_القسط_${customer['name']}_${DateTime.now().millisecondsSinceEpoch}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم طباعة كشف القسط بنجاح'),
          backgroundColor: Color(0xFF059669), // Professional Green
        ),
      );
    } catch (e) {
      debugPrint('خطأ في طباعة كشف القسط: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في طباعة كشف القسط: $e'),
          backgroundColor: Color(0xFFDC2626), // Professional Red
        ),
      );
    }
  }

  // إنشاء PDF لكشف القسط
  Future<Uint8List> _generateInstallmentReportPDF({
    required Map<String, dynamic> customer,
    required Map<String, dynamic> installment,
    required List<Map<String, dynamic>> allInstallments,
    required List<Map<String, dynamic>> payments,
    required double totalDebt,
    required double paidAmount,
    required double remainingAmount,
  }) async {
    final doc = pw.Document();
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // تحميل الخط العربي
    final arabicFont = await _loadArabicFont();

    // الصفحة الأولى - المعلومات الأساسية
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(8),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // رأس كشف القسط
                _buildInstallmentReportHeader(customer, date, arabicFont),
                pw.SizedBox(height: 20),

                // ملخص القسط الحالي
                _buildCurrentInstallmentSummary(installment, arabicFont),
                pw.SizedBox(height: 20),

                // ملخص إجمالي الدين
                _buildTotalDebtSummary(
                    totalDebt, paidAmount, remainingAmount, arabicFont),
                pw.SizedBox(height: 20),

                // جدول جميع الأقساط
                _buildAllInstallmentsTable(allInstallments, arabicFont),
                pw.SizedBox(height: 20),

                // تذييل
                _buildInstallmentReportFooter(arabicFont),
              ],
            ),
          );
        },
      ),
    );

    // الصفحة الثانية - جدول الدفعات (إذا كانت موجودة)
    if (payments.isNotEmpty) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(8),
          build: (context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // رأس الصفحة الثانية
                  _buildPaymentsPageHeader(customer, date, arabicFont),
                  pw.SizedBox(height: 20),

                  // جدول الدفعات
                  _buildPaymentsTable(payments, arabicFont),
                  pw.SizedBox(height: 20),

                  // ملخص الدفعات
                  _buildPaymentsSummary(payments, arabicFont),
                  pw.SizedBox(height: 20),

                  // تذييل
                  _buildInstallmentReportFooter(arabicFont),
                ],
              ),
            );
          },
        ),
      );
    }

    return doc.save();
  }

  // بناء رأس كشف القسط
  pw.Widget _buildInstallmentReportHeader(
    Map<String, dynamic> customer,
    String date,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'كشف القسط',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'نظام إدارة المكتب',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'العميل: ${customer['name'] ?? 'غير محدد'}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (customer['phone'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'هاتف العميل: ${customer['phone']}',
              style: pw.TextStyle(fontSize: 10, font: arabicFont),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Text(
            'تاريخ الكشف: $date',
            style: pw.TextStyle(fontSize: 10, font: arabicFont),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // بناء ملخص القسط الحالي
  pw.Widget _buildCurrentInstallmentSummary(
    Map<String, dynamic> installment,
    pw.Font arabicFont,
  ) {
    final amount = (installment['amount'] as num).toDouble();
    final dueDate = DateTime.parse(installment['due_date'] as String);
    final isPaid = (installment['paid'] as int) == 1;
    final paymentDate = installment['paid_at'] != null
        ? DateTime.parse(installment['paid_at'] as String)
        : null;

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: isPaid ? PdfColors.green50 : PdfColors.orange50,
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'تفاصيل القسط الحالي',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'مبلغ القسط:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                '${amount.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تاريخ الاستحقاق:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                DateFormat('dd/MM/yyyy').format(dueDate),
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'الحالة:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                isPaid ? 'مدفوع' : 'غير مدفوع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: isPaid ? PdfColors.green : PdfColors.red,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          if (isPaid && paymentDate != null) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تاريخ الدفع:',
                  style: pw.TextStyle(fontSize: 10, font: arabicFont),
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy').format(paymentDate),
                  style: pw.TextStyle(fontSize: 10, font: arabicFont),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // بناء ملخص إجمالي الدين
  pw.Widget _buildTotalDebtSummary(
    double totalDebt,
    double paidAmount,
    double remainingAmount,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص إجمالي الدين',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي الدين:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                '${totalDebt.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي المدفوع:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                '${paidAmount.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المتبقي:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
              ),
              pw.Text(
                '${remainingAmount.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: remainingAmount > 0 ? PdfColors.red : PdfColors.green,
                  font: arabicFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء جدول جميع الأقساط
  pw.Widget _buildAllInstallmentsTable(
    List<Map<String, dynamic>> installments,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'جدول جميع الأقساط',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            font: arabicFont,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          columnWidths: {
            0: const pw.FixedColumnWidth(40),
            1: const pw.FixedColumnWidth(80),
            2: const pw.FixedColumnWidth(80),
            3: const pw.FixedColumnWidth(60),
            4: const pw.FixedColumnWidth(60),
          },
          children: [
            // رأس الجدول
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'رقم القسط',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'المبلغ',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'تاريخ الاستحقاق',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'الحالة',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'تاريخ الدفع',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font: arabicFont,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
            // صفوف الأقساط
            ...installments.asMap().entries.map((entry) {
              final index = entry.key;
              final installment = entry.value;
              final amount = (installment['amount'] as num).toDouble();
              final dueDate = DateTime.parse(installment['due_date'] as String);
              final isPaid = (installment['paid'] as int) == 1;
              final paymentDate = installment['paid_at'] != null
                  ? DateTime.parse(installment['paid_at'] as String)
                  : null;

              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '${index + 1}',
                      style: pw.TextStyle(fontSize: 9, font: arabicFont),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '${amount.toStringAsFixed(0)} د.ع',
                      style: pw.TextStyle(fontSize: 9, font: arabicFont),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      DateFormat('dd/MM/yyyy').format(dueDate),
                      style: pw.TextStyle(fontSize: 9, font: arabicFont),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      isPaid ? 'مدفوع' : 'غير مدفوع',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: isPaid ? PdfColors.green : PdfColors.red,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      paymentDate != null
                          ? DateFormat('dd/MM/yyyy').format(paymentDate)
                          : '-',
                      style: pw.TextStyle(fontSize: 9, font: arabicFont),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // بناء تذييل كشف القسط
  pw.Widget _buildInstallmentReportFooter(pw.Font arabicFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'شكراً لاختياركم خدماتنا',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            font: arabicFont,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'هذا الكشف صادر من نظام إدارة المكتب',
          style: pw.TextStyle(fontSize: 8, font: arabicFont),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // بناء رأس صفحة الدفعات
  pw.Widget _buildPaymentsPageHeader(
    Map<String, dynamic> customer,
    String date,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'سجل الدفعات',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'نظام إدارة المكتب',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'العميل: ${customer['name'] ?? 'غير محدد'}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (customer['phone'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'هاتف العميل: ${customer['phone']}',
              style: pw.TextStyle(fontSize: 10, font: arabicFont),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Text(
            'تاريخ الكشف: $date',
            style: pw.TextStyle(fontSize: 10, font: arabicFont),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // بناء جدول الدفعات
  pw.Widget _buildPaymentsTable(
    List<Map<String, dynamic>> payments,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'تفاصيل الدفعات',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            font: arabicFont,
          ),
        ),
        pw.SizedBox(height: 8),
        if (payments.isEmpty)
          pw.Text(
            'لا توجد دفعات مسجلة',
            style: pw.TextStyle(fontSize: 10, font: arabicFont),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(width: 1),
            columnWidths: {
              0: const pw.FixedColumnWidth(60),
              1: const pw.FixedColumnWidth(100),
              2: const pw.FixedColumnWidth(80),
              3: const pw.FixedColumnWidth(60),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // رأس الجدول
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'رقم الدفعة',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'التاريخ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'المبلغ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'الطريقة',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'الوصف',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
              // صفوف الدفعات
              ...payments.asMap().entries.map((entry) {
                final index = entry.key;
                final payment = entry.value;
                final amount = (payment['amount'] as num).toDouble();
                final paymentDate =
                    DateTime.parse(payment['payment_date'] as String);
                final method = payment['payment_method'] ?? 'نقد';
                final description = payment['description'] ?? 'دفعة';

                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${index + 1}',
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(paymentDate),
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${amount.toStringAsFixed(0)} د.ع',
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        method,
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        description,
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  // بناء ملخص الدفعات
  pw.Widget _buildPaymentsSummary(
    List<Map<String, dynamic>> payments,
    pw.Font arabicFont,
  ) {
    final totalPayments = payments.fold<double>(
      0.0,
      (sum, payment) => sum + (payment['amount'] as num).toDouble(),
    );

    final cashPayments = payments
        .where((p) => (p['payment_method'] ?? 'نقد')
            .toString()
            .toLowerCase()
            .contains('نقد'))
        .fold<double>(
          0.0,
          (sum, payment) => sum + (payment['amount'] as num).toDouble(),
        );

    final bankPayments = payments
        .where((p) => (p['payment_method'] ?? 'نقد')
            .toString()
            .toLowerCase()
            .contains('بنك'))
        .fold<double>(
          0.0,
          (sum, payment) => sum + (payment['amount'] as num).toDouble(),
        );

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص الدفعات',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي الدفعات:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                '${totalPayments.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'الدفعات النقدية:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                '${cashPayments.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'الدفعات البنكية:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                '${bankPayments.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'عدد الدفعات:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
              ),
              pw.Text(
                '${payments.length} دفعة',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple,
                  font: arabicFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // تحميل الخط العربي
  Future<pw.Font> _loadArabicFont() async {
    try {
      final fontData = await rootBundle
          .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      debugPrint('خطأ في تحميل الخط العربي: $e');
      return pw.Font.helvetica();
    }
  }
}
