// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/format.dart';
import '../utils/dark_mode_utils.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';
  bool _showOnlyWithDebt = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // فحص صلاحية إدارة العملاء
    if (!auth.hasPermission(UserPermission.manageCustomers)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة العملاء'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'ليس لديك صلاحية للوصول إلى هذه الصفحة',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'هذه الصفحة متاحة للمديرين والمشرفين فقط',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DarkModeUtils.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DarkModeUtils.getBorderColor(context)),
            ),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'بحث بالاسم أو الهاتف',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة عميل'),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: Text(_showOnlyWithDebt
                            ? 'العملاء المدينون فقط'
                            : 'جميع العملاء'),
                        selected: _showOnlyWithDebt,
                        onSelected: (selected) {
                          setState(() {
                            _showOnlyWithDebt = selected;
                          });
                        },
                        avatar: Icon(
                          _showOnlyWithDebt ? Icons.warning : Icons.people,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showCustomerStats(),
                      icon: const Icon(Icons.bar_chart),
                      tooltip: 'إحصائيات العملاء',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ملاحظة توضيحية
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DarkModeUtils.getInfoColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: DarkModeUtils.getInfoColor(context).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: DarkModeUtils.getInfoColor(context), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الدين: هو المبلغ المستحق استلامه من العميل. تظهر القيمة باللون الأحمر إن كان عليه دين وبالأخضر إذا لا يوجد دين.',
                    style: TextStyle(
                        fontSize: 12,
                        color: DarkModeUtils.getInfoColor(context)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: _getFilteredCustomers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final items = snapshot.data!;

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: DarkModeUtils.getBackgroundColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: DarkModeUtils.getBorderColor(context),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 64,
                                color: DarkModeUtils.getSecondaryTextColor(
                                    context),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا يوجد عملاء',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: DarkModeUtils.getSecondaryTextColor(
                                      context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _query.isEmpty
                                    ? 'قم بإضافة عملاء جدد للبدء'
                                    : 'لم يتم العثور على عملاء مطابقين للبحث',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: DarkModeUtils.getSecondaryTextColor(
                                      context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _openEditor(),
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة عميل جديد'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      DarkModeUtils.getInfoColor(context),
                                  foregroundColor:
                                      DarkModeUtils.getCardColor(context),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    final name = c['name']?.toString() ?? '';
                    final phone = c['phone']?.toString() ?? '';
                    final debt = (c['total_debt'] as num?)?.toDouble() ?? 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: DarkModeUtils.getCardColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: DarkModeUtils.getBorderColor(context)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Avatar circle
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    DarkModeUtils.getInfoColor(context)
                                        .withOpacity(0.1),
                                child: Icon(Icons.person,
                                    color: DarkModeUtils.getInfoColor(context),
                                    size: 18),
                              ),
                              const SizedBox(width: 10),
                              // Name & phone
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.phone,
                                            size: 14,
                                            color: DarkModeUtils
                                                .getSecondaryTextColor(
                                                    context)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            phone.isEmpty ? '-' : phone,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: DarkModeUtils
                                                    .getSecondaryTextColor(
                                                        context)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Debt with label
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('الدين',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: DarkModeUtils
                                              .getSecondaryTextColor(context),
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text(
                                    Formatters.currencyIQD(debt),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _getDebtColor(debt),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'عرض التفاصيل',
                                        onPressed: () =>
                                            _showCustomerDetails(c),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 18,
                                          color: Colors.green,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'تعديل',
                                        onPressed: () =>
                                            _openEditor(customer: c),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'حذف',
                                        onPressed: () =>
                                            _delete(c['id'] as int),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Future<void> _delete(int id) async {
    final db = context.read<DatabaseService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العميل'),
        content: const Text('هل تريد حذف هذا العميل؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final deletedRows = await db.deleteCustomer(id);
      if (!mounted) return;

      if (deletedRows > 0) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف العميل بنجاح'),
            backgroundColor: Color(0xFF059669), // Professional Green
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على العميل أو حدث خطأ في الحذف'),
            backgroundColor: Color(0xFFF59E0B), // Professional Orange
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'خطأ في حذف العميل';
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        errorMessage = 'لا يمكن حذف العميل لأنه مرتبط بفواتير أو مدفوعات';
      } else if (e.toString().contains('database is locked')) {
        errorMessage = 'قاعدة البيانات قيد الاستخدام، حاول مرة أخرى';
      } else {
        errorMessage = 'خطأ في حذف العميل: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Color(0xFFDC2626), // Professional Red
        ),
      );
    }
  }

  Future<void> _openEditor({Map<String, Object?>? customer}) async {
    final db = context.read<DatabaseService>();
    final name =
        TextEditingController(text: customer?['name']?.toString() ?? '');
    final phone =
        TextEditingController(text: customer?['phone']?.toString() ?? '');
    final address =
        TextEditingController(text: customer?['address']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(customer == null ? 'إضافة عميل' : 'تعديل عميل'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'الاسم')),
              const SizedBox(height: 8),
              TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'الهاتف')),
              const SizedBox(height: 8),
              TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'العنوان')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال اسم العميل'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true) {
      await db.upsertCustomer({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim()
      }, id: customer?['id'] as int?);
      if (!mounted) return;
      setState(() {});
    }
  }

  /// الحصول على قائمة العملاء المفلترة
  Future<List<Map<String, Object?>>> _getFilteredCustomers() async {
    final db = context.read<DatabaseService>();
    final customers = await db.getCustomers(query: _query);

    if (_showOnlyWithDebt) {
      return customers.where((customer) {
        final debt = (customer['total_debt'] as num?)?.toDouble() ?? 0.0;
        return debt > 0;
      }).toList();
    }

    return customers;
  }

  /// عرض إحصائيات العملاء
  Future<void> _showCustomerStats() async {
    final db = context.read<DatabaseService>();
    final customers = await db.getCustomers();

    final totalCustomers = customers.length;
    final customersWithDebt = customers.where((c) {
      final debt = (c['total_debt'] as num?)?.toDouble() ?? 0.0;
      return debt > 0;
    }).length;

    final totalDebt = customers.fold<double>(0.0, (sum, c) {
      final debt = (c['total_debt'] as num?)?.toDouble() ?? 0.0;
      return sum + debt;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إحصائيات العملاء'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatCard(
              'إجمالي العملاء',
              totalCustomers.toString(),
              Icons.people,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'العملاء المدينون',
              customersWithDebt.toString(),
              Icons.warning,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'إجمالي الديون',
              Formatters.currencyIQD(totalDebt),
              Icons.money_off,
              totalDebt > 0 ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'العملاء غير المدينين',
              (totalCustomers - customersWithDebt).toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة إحصائية
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: DarkModeUtils.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DarkModeUtils.getTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// عرض تفاصيل العميل وتاريخ المعاملات
  Future<void> _showCustomerDetails(Map<String, Object?> customer) async {
    final db = context.read<DatabaseService>();
    final customerId = customer['id'] as int;
    final customerName = customer['name']?.toString() ?? '';

    // جلب بيانات العميل التفصيلية
    final customerSales = await db.database.rawQuery('''
      SELECT 
        s.*,
        GROUP_CONCAT(p.name || ' (' || si.quantity || 'x' || si.price || ')') as items_summary
      FROM sales s
      LEFT JOIN sale_items si ON s.id = si.sale_id
      LEFT JOIN products p ON si.product_id = p.id
      WHERE s.customer_id = ?
      GROUP BY s.id
      ORDER BY s.created_at DESC
    ''', [customerId]);

    final customerPayments = await db.database.rawQuery('''
      SELECT * FROM payments 
      WHERE customer_id = ?
      ORDER BY payment_date DESC
    ''', [customerId]);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 32,
                      color: DarkModeUtils.getInfoColor(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفاصيل العميل: $customerName',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: DarkModeUtils.getTextColor(context),
                            ),
                          ),
                          Text(
                            'الهاتف: ${customer['phone']?.toString() ?? 'غير محدد'}',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  DarkModeUtils.getSecondaryTextColor(context),
                            ),
                          ),
                          Text(
                            'العنوان: ${customer['address']?.toString() ?? 'غير محدد'}',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  DarkModeUtils.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Debt Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DarkModeUtils.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: DarkModeUtils.getBorderColor(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDetailCard(
                          'إجمالي الدين',
                          Formatters.currencyIQD(
                              (customer['total_debt'] as num?)?.toDouble() ??
                                  0.0),
                          Icons.money_off,
                          _getDebtColor(
                              (customer['total_debt'] as num?)?.toDouble() ??
                                  0.0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailCard(
                          'عدد المعاملات',
                          customerSales.length.toString(),
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailCard(
                          'عدد المدفوعات',
                          customerPayments.length.toString(),
                          Icons.payments,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tabs
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: DarkModeUtils.getTextColor(context),
                          unselectedLabelColor:
                              DarkModeUtils.getSecondaryTextColor(context),
                          indicatorColor: DarkModeUtils.getInfoColor(context),
                          tabs: const [
                            Tab(
                                text: 'المعاملات',
                                icon: Icon(Icons.receipt_long)),
                            Tab(text: 'المدفوعات', icon: Icon(Icons.payments)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Sales Tab
                              _buildSalesList(customerSales),
                              // Payments Tab
                              _buildPaymentsList(customerPayments),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء بطاقة تفصيلية
  Widget _buildDetailCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: DarkModeUtils.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DarkModeUtils.getTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء قائمة المعاملات
  Widget _buildSalesList(List<Map<String, Object?>> sales) {
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: DarkModeUtils.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد معاملات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DarkModeUtils.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        final total = (sale['total'] as num?)?.toDouble() ?? 0.0;
        final type = sale['type']?.toString() ?? '';
        final createdAt = sale['created_at']?.toString() ?? '';

        Color typeColor;
        String typeText;
        switch (type) {
          case 'cash':
            typeColor = Colors.green;
            typeText = 'نقدي';
            break;
          case 'credit':
            typeColor = Colors.orange;
            typeText = 'آجل';
            break;
          case 'installment':
            typeColor = Colors.blue;
            typeText = 'تقسيط';
            break;
          default:
            typeColor = Colors.grey;
            typeText = type;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DarkModeUtils.getCardColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DarkModeUtils.getBorderColor(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.receipt,
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فاتورة #${sale['id']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: DarkModeUtils.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'النوع: $typeText',
                      style: TextStyle(
                        fontSize: 12,
                        color: typeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (sale['items_summary'] != null)
                      Text(
                        sale['items_summary'].toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: DarkModeUtils.getSecondaryTextColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.currencyIQD(total),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DarkModeUtils.getTextColor(context),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: DarkModeUtils.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// بناء قائمة المدفوعات
  Widget _buildPaymentsList(List<Map<String, Object?>> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payments,
              size: 64,
              color: DarkModeUtils.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مدفوعات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DarkModeUtils.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
        final paymentDate = payment['payment_date']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DarkModeUtils.getCardColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DarkModeUtils.getBorderColor(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.payments,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دفعة #${payment['id']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: DarkModeUtils.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (payment['notes'] != null &&
                        payment['notes'].toString().isNotEmpty)
                      Text(
                        payment['notes'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: DarkModeUtils.getSecondaryTextColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.currencyIQD(amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(paymentDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: DarkModeUtils.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// تنسيق التاريخ
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  /// الحصول على لون مناسب للدين
  Color _getDebtColor(double debt) {
    if (debt > 0) {
      return const Color(0xFFE53E3E); // أحمر واضح
    } else {
      return const Color(0xFF38A169); // أخضر واضح
    }
  }
}
