import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
import '../utils/format.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with TickerProviderStateMixin {
  String _query = '';
  bool _showOverdueOnly = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    try {
      _tabController.dispose();
    } catch (e) {
      // TabController already disposed or not initialized
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments, size: 22),
              const SizedBox(width: 8),
              const Text(
                'إدارة الديون والمدفوعات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ابحث باسم العميل أو الهاتف',
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('متأخرة فقط'),
                selected: _showOverdueOnly,
                onSelected: (v) => setState(() => _showOverdueOnly = v),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showBulkPaymentDialog(db),
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('تحصيل مجمع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Statistics Cards
          FutureBuilder<Map<String, double>>(
            future: db.getDebtStatistics(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()));
              }
              final stats = snapshot.data!;
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'إجمالي الديون',
                      Formatters.currencyIQD(stats['total_debt']!),
                      Icons.account_balance_wallet,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'ديون متأخرة',
                      Formatters.currencyIQD(stats['overdue_debt']!),
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'إجمالي المدفوعات',
                      Formatters.currencyIQD(stats['total_payments']!),
                      Icons.payment,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'عملاء مدينون',
                      '${stats['customers_with_debt']!.toInt()}',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'ملخص الديون', icon: Icon(Icons.summarize)),
              Tab(text: 'تحصيل المدفوعات', icon: Icon(Icons.payment)),
              Tab(text: 'تقرير الأعمار', icon: Icon(Icons.timeline)),
              Tab(text: 'تنبيهات متأخرة', icon: Icon(Icons.notifications)),
            ],
          ),
          const SizedBox(height: 12),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDebtSummaryTab(db),
                _buildPaymentCollectionTab(db),
                _buildAgingReportTab(db),
                _buildOverdueAlertsTab(db),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummaryTab(DatabaseService db) {
    return Row(
      children: [
        // Left: Customers summary
        Expanded(
          flex: 2,
          child: Card(
            elevation: 1,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'إجمالي الديون لكل عميل',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<Map<String, Object?>>>(
                    future: db.receivablesByCustomer(query: _query),
                    builder: (context, snapshot) {
                      final data = snapshot.data ?? [];
                      if (data.isEmpty) {
                        return const Center(child: Text('لا يوجد بيانات ديون'));
                      }
                      return ListView.separated(
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = data[i];
                          final name = (c['name'] ?? '').toString();
                          final phone = (c['phone'] ?? '').toString();
                          final totalDebt =
                              (c['total_debt'] as num? ?? 0).toDouble();
                          final nextDue = c['next_due_date']?.toString();
                          final isOverdue = nextDue != null &&
                              DateTime.tryParse(nextDue) != null &&
                              DateTime.parse(nextDue).isBefore(DateTime.now());

                          if (_showOverdueOnly && !isOverdue) {
                            return const SizedBox.shrink();
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isOverdue
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100,
                              child: Icon(
                                isOverdue ? Icons.warning_amber : Icons.person,
                                color: isOverdue
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                            title: Text(name),
                            subtitle: Text(
                              phone.isEmpty ? 'بدون هاتف' : phone,
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  Formatters.currencyIQD(totalDebt),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isOverdue
                                        ? Colors.orange.shade700
                                        : Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nextDue == null
                                      ? 'بدون تاريخ استحقاق'
                                      : 'أقرب استحقاق: ${DateTime.parse(nextDue).day}/${DateTime.parse(nextDue).month}/${DateTime.parse(nextDue).year}',
                                  style: TextStyle(
                                    color: isOverdue
                                        ? Colors.orange.shade700
                                        : Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Right: Credit sales list
        Expanded(
          flex: 3,
          child: Card(
            elevation: 1,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'فواتير بالأجل وتواريخ الاستحقاق',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<Map<String, Object?>>>(
                    future: db.creditSales(
                      overdueOnly: _showOverdueOnly,
                    ),
                    builder: (context, snapshot) {
                      final data = snapshot.data ?? [];
                      if (data.isEmpty) {
                        return const Center(
                            child: Text('لا يوجد مبيعات بالأجل'));
                      }
                      return ListView.separated(
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = data[i];
                          final cust = (s['customer_name'] ?? '').toString();
                          final total = (s['total'] as num? ?? 0).toDouble();
                          final createdAt =
                              DateTime.parse(s['created_at'] as String);
                          final due = s['due_date'] != null
                              ? DateTime.tryParse(s['due_date'] as String)
                              : null;
                          final overdue =
                              due != null && due.isBefore(DateTime.now());

                          return ListTile(
                            title: Text(cust.isEmpty ? 'بدون اسم' : cust),
                            subtitle: Text(
                                'تاريخ الفاتورة: ${createdAt.day}/${createdAt.month}/${createdAt.year}${due != null ? '  •  استحقاق: ${due.day}/${due.month}/${due.year}' : ''}'),
                            trailing: Text(
                              Formatters.currencyIQD(total),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: overdue
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCollectionTab(DatabaseService db) {
    return Column(
      children: [
        // Payment form
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تحصيل دفعة جديدة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _PaymentForm(db: db, onPaymentAdded: () => setState(() {})),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Payment history
        Expanded(
          child: Card(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'سجل المدفوعات',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<Map<String, Object?>>>(
                    future: db.getCustomerPayments(),
                    builder: (context, snapshot) {
                      final data = snapshot.data ?? [];
                      if (data.isEmpty) {
                        return const Center(child: Text('لا يوجد مدفوعات'));
                      }
                      return ListView.separated(
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final p = data[i];
                          final customerName =
                              (p['customer_name'] ?? '').toString();
                          final amount = (p['amount'] as num? ?? 0).toDouble();
                          final paymentDate =
                              DateTime.parse(p['payment_date'] as String);
                          final notes = (p['notes'] ?? '').toString();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Icon(Icons.payment,
                                  color: Colors.green.shade700),
                            ),
                            title: Text(customerName),
                            subtitle: Text(
                              '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}${notes.isNotEmpty ? ' - $notes' : ''}',
                            ),
                            trailing: Text(
                              Formatters.currencyIQD(amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            onLongPress: () =>
                                _showDeletePaymentDialog(db, p['id'] as int),
                            onTap: () => _showPaymentDetails(p),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgingReportTab(DatabaseService db) {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerLeft,
            child: const Text(
              'تقرير أعمار الديون',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: db.getDebtAgingReport(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('لا يوجد بيانات'));
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('العميل')),
                      DataColumn(label: Text('إجمالي الدين')),
                      DataColumn(label: Text('حالي')),
                      DataColumn(label: Text('30 يوم')),
                      DataColumn(label: Text('60 يوم')),
                      DataColumn(label: Text('90+ يوم')),
                    ],
                    rows: data.map((row) {
                      final name = (row['name'] ?? '').toString();
                      final totalDebt =
                          (row['total_debt'] as num? ?? 0).toDouble();
                      final current =
                          (row['current_amount'] as num? ?? 0).toDouble();
                      final overdue30 =
                          (row['overdue_30_amount'] as num? ?? 0).toDouble();
                      final overdue60 =
                          (row['overdue_60_amount'] as num? ?? 0).toDouble();
                      final overdue90 =
                          (row['overdue_90_amount'] as num? ?? 0).toDouble();

                      return DataRow(
                        cells: [
                          DataCell(Text(name)),
                          DataCell(Text(Formatters.currencyIQD(totalDebt))),
                          DataCell(Text(Formatters.currencyIQD(current))),
                          DataCell(Text(Formatters.currencyIQD(overdue30))),
                          DataCell(Text(Formatters.currencyIQD(overdue60))),
                          DataCell(Text(Formatters.currencyIQD(overdue90))),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueAlertsTab(DatabaseService db) {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerLeft,
            child: const Text(
              'تنبيهات الديون المتأخرة',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: db.getOverdueDebts(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('لا توجد ديون متأخرة'));
                }
                return ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = data[i];
                    final customerName = (s['customer_name'] ?? '').toString();
                    final phone = (s['customer_phone'] ?? '').toString();
                    final total = (s['total'] as num? ?? 0).toDouble();
                    final dueDate = DateTime.parse(s['due_date'] as String);
                    final daysOverdue =
                        (s['days_overdue'] as num? ?? 0).toDouble();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Icon(Icons.warning, color: Colors.red.shade700),
                      ),
                      title: Text(customerName),
                      subtitle: Text(
                        'هاتف: $phone\nتاريخ الاستحقاق: ${dueDate.day}/${dueDate.month}/${dueDate.year}\nمتأخر: ${daysOverdue.toInt()} يوم',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.currencyIQD(total),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${daysOverdue.toInt()} يوم',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeletePaymentDialog(DatabaseService db, int paymentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المدفوعة'),
        content: const Text('هل أنت متأكد من حذف هذه المدفوعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await db.deletePayment(paymentId);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Map<String, Object?> payment) {
    final customerName = (payment['customer_name'] ?? '').toString();
    final amount = (payment['amount'] as num? ?? 0).toDouble();
    final paymentDate = DateTime.parse(payment['payment_date'] as String);
    final notes = (payment['notes'] ?? '').toString();
    final createdAt = DateTime.parse(payment['created_at'] as String);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل المدفوعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('العميل:', customerName),
            _buildDetailRow('المبلغ:', Formatters.currencyIQD(amount)),
            _buildDetailRow('تاريخ الدفع:',
                '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}'),
            _buildDetailRow('تاريخ التسجيل:',
                '${createdAt.day}/${createdAt.month}/${createdAt.year}'),
            if (notes.isNotEmpty) _buildDetailRow('ملاحظات:', notes),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showBulkPaymentDialog(DatabaseService db) {
    showDialog(
      context: context,
      builder: (context) =>
          _BulkPaymentDialog(db: db, onPaymentsAdded: () => setState(() {})),
    );
  }
}

class _PaymentForm extends StatefulWidget {
  final DatabaseService db;
  final VoidCallback onPaymentAdded;

  const _PaymentForm({required this.db, required this.onPaymentAdded});

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  int? _selectedCustomerId;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customerController,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل',
                    prefixIcon: Icon(Icons.person),
                  ),
                  onChanged: (value) async {
                    if (value.trim().isNotEmpty) {
                      final customers =
                          await widget.db.getCustomers(query: value);
                      if (customers.isNotEmpty) {
                        _selectedCustomerId = customers.first['id'] as int;
                      }
                    }
                  },
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'يرجى إدخال اسم العميل';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'يرجى إدخال المبلغ';
                    }
                    final amount = double.tryParse(value!);
                    if (amount == null || amount <= 0) {
                      return 'يرجى إدخال مبلغ صحيح';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _paymentDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الدفع',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (_selectedCustomerId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يرجى اختيار عميل صحيح'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Get customer debt before payment
                  final customers = await widget.db.getCustomers();
                  final customer = customers.firstWhere(
                    (c) => c['id'] == _selectedCustomerId,
                    orElse: () => {'total_debt': 0},
                  );
                  final currentDebt =
                      (customer['total_debt'] as num? ?? 0).toDouble();
                  final paymentAmount = double.parse(_amountController.text);

                  await widget.db.addPayment(
                    customerId: _selectedCustomerId!,
                    amount: paymentAmount,
                    paymentDate: _paymentDate,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  );

                  _customerController.clear();
                  _amountController.clear();
                  _notesController.clear();
                  _selectedCustomerId = null;
                  _paymentDate = DateTime.now();

                  widget.onPaymentAdded();

                  // Show appropriate message
                  String message = 'تم تسجيل المدفوعة بنجاح';
                  Color backgroundColor = Colors.green;

                  if (paymentAmount >= currentDebt) {
                    message =
                        'تم تسجيل المدفوعة بنجاح - تم سداد الدين بالكامل!';
                    backgroundColor = Colors.blue;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: backgroundColor,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.payment),
              label: const Text('تسجيل المدفوعة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkPaymentDialog extends StatefulWidget {
  final DatabaseService db;
  final VoidCallback onPaymentsAdded;

  const _BulkPaymentDialog({required this.db, required this.onPaymentsAdded});

  @override
  State<_BulkPaymentDialog> createState() => _BulkPaymentDialogState();
}

class _BulkPaymentDialogState extends State<_BulkPaymentDialog> {
  final List<Map<String, dynamic>> _selectedCustomers = [];
  final Map<int, TextEditingController> _amountControllers = {};
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCustomersWithDebt();
  }

  @override
  void dispose() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCustomersWithDebt() async {
    final customers = await widget.db.receivablesByCustomer();
    setState(() {
      _selectedCustomers.clear();
      _amountControllers.clear();
      for (final customer in customers) {
        final debt = (customer['total_debt'] as num? ?? 0).toDouble();
        if (debt > 0) {
          _selectedCustomers.add(customer);
          _amountControllers[customer['id'] as int] = TextEditingController();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'تحصيل المدفوعات المجمعة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment date
            Row(
              children: [
                const Text('تاريخ الدفع: '),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _paymentDate = date);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customers list
            Expanded(
              child: _selectedCustomers.isEmpty
                  ? const Center(child: Text('لا يوجد عملاء مدينون'))
                  : ListView.builder(
                      itemCount: _selectedCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _selectedCustomers[index];
                        final customerId = customer['id'] as int;
                        final name = (customer['name'] ?? '').toString();
                        final phone = (customer['phone'] ?? '').toString();
                        final totalDebt =
                            (customer['total_debt'] as num? ?? 0).toDouble();
                        final controller = _amountControllers[customerId]!;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(color: Colors.blue.shade700),
                              ),
                            ),
                            title: Text(name),
                            subtitle: Text(
                                '$phone • ${Formatters.currencyIQD(totalDebt)}'),
                            trailing: SizedBox(
                              width: 120,
                              child: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  hintText: 'المبلغ',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final amount = double.tryParse(value);
                                  if (amount != null && amount > totalDebt) {
                                    controller.text = totalDebt.toString();
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processBulkPayments,
                    icon: const Icon(Icons.payment),
                    label: const Text('تسجيل المدفوعات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processBulkPayments() async {
    int processedCount = 0;
    int fullyPaidCount = 0;

    for (final customer in _selectedCustomers) {
      final customerId = customer['id'] as int;
      final controller = _amountControllers[customerId]!;
      final amountText = controller.text.trim();

      if (amountText.isNotEmpty) {
        final amount = double.tryParse(amountText);
        if (amount != null && amount > 0) {
          final currentDebt = (customer['total_debt'] as num? ?? 0).toDouble();

          await widget.db.addPayment(
            customerId: customerId,
            amount: amount,
            paymentDate: _paymentDate,
            notes: 'دفعة مجمعة',
          );

          processedCount++;
          if (amount >= currentDebt) {
            fullyPaidCount++;
          }
        }
      }
    }

    if (processedCount > 0) {
      widget.onPaymentsAdded();
      Navigator.pop(context);

      String message = 'تم تسجيل $processedCount مدفوعة بنجاح';
      if (fullyPaidCount > 0) {
        message += ' - تم سداد $fullyPaidCount دين بالكامل!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: fullyPaidCount > 0 ? Colors.blue : Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال مبالغ صحيحة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
