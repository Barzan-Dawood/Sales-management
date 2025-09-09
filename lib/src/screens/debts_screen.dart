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

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('دفتر الديون'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddPaymentDialog(context, db),
              tooltip: 'إضافة دفعة',
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط البحث
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'البحث عن العميل...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
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
              padding: const EdgeInsets.all(16),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSimpleStatCard(
                          'المدفوع',
                          Formatters.currencyIQD(stats['total_payments'] ?? 0),
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
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
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue.shade700,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.warning, size: 20),
                    text: 'الذين لديهم ديون',
                  ),
                  Tab(
                    icon: Icon(Icons.schedule, size: 20),
                    text: 'الأقساط',
                  ),
                  Tab(
                    icon: Icon(Icons.check_circle, size: 20),
                    text: 'المدفوعين بالكامل',
                  ),
                  Tab(
                    icon: Icon(Icons.people, size: 20),
                    text: 'جميع العملاء',
                  ),
                  Tab(
                    icon: Icon(Icons.analytics, size: 20),
                    text: 'التقارير',
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

  Widget _buildSimpleStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
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
          return const Center(
            child: Text(
              'لا توجد عملاء',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
          return const Center(
            child: Text(
              'لا توجد عملاء',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _installmentFilter,
                      decoration: const InputDecoration(
                        labelText: 'فلترة الأقساط',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    icon: const Icon(Icons.date_range),
                    tooltip: 'فلترة بالتاريخ',
                  ),
                ],
              ),
              if (_fromDate != null || _toDate != null) ...[
                const SizedBox(height: 8),
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
                padding: const EdgeInsets.all(16),
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
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // إحصائيات الأقساط
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إحصائيات الأقساط',
                    style: TextStyle(
                      fontSize: 18,
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
                              const SizedBox(width: 8),
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
                          const SizedBox(height: 8),
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
                              const SizedBox(width: 8),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الأقساط المتأخرة',
                    style: TextStyle(
                      fontSize: 18,
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
                                backgroundColor: Colors.red.shade100,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الأقساط المستحقة هذا الشهر',
                    style: TextStyle(
                      fontSize: 18,
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
      padding: const EdgeInsets.all(12),
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
              fontSize: 16,
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
        textDirection: TextDirection.rtl,
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
    final customerPhone = installment['customer_phone'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
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
            size: 20,
          ),
        ),
        title: Text(
          customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customerPhone.isNotEmpty) Text('الهاتف: $customerPhone'),
            Text('المبلغ: ${Formatters.currencyIQD(amount)}'),
            Text(
                'تاريخ الاستحقاق: ${dueDate.day}/${dueDate.month}/${dueDate.year}'),
            if (isPaid)
              Text(
                'تم الدفع في: ${DateTime.parse(installment['paid_at'] as String).day}/${DateTime.parse(installment['paid_at'] as String).month}/${DateTime.parse(installment['paid_at'] as String).year}',
                style: const TextStyle(color: Colors.green),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'pay' && !isPaid) {
              _showPayInstallmentDialog(context, installment, db);
            } else if (value == 'edit') {
              _editInstallment(context, installment, db);
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
            ],
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
      ),
    );
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
            leading: CircleAvatar(
              backgroundColor:
                  remaining > 0 ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(
                remaining > 0 ? Icons.warning : Icons.check_circle,
                color: remaining > 0 ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            title: Text(
              customer['name'] ?? 'غير محدد',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الهاتف: ${customer['phone'] ?? 'غير محدد'}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'المتبقي: ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
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
            onTap: () => _showCustomerPayments(context, customer, db),
          );
        },
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
              textDirection: TextDirection.rtl,
              child: Dialog(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'سجل المدفوعات - ${customer['name']}',
                            style: const TextStyle(
                              fontSize: 18,
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
                                    subtitle: Text(
                                      'التاريخ: ${payment['payment_date']}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deletePayment(
                                          context, payment['id'], db),
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
                              onPressed: () {
                                Navigator.pop(context);
                                _showAddPaymentDialog(context, db,
                                    customer: customer);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة دفعة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
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
          textDirection: TextDirection.rtl,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: $e')),
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
        textDirection: TextDirection.rtl,
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
                  await db.deletePayment(paymentId);
                  Navigator.pop(context);
                  // إعادة تحميل البيانات
                  _refreshData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الدفعة بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        textDirection: TextDirection.rtl,
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
                          'product_id': 0, // معرف وهمي للدين
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
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ في إضافة الدين بالأقساط: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
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
        textDirection: TextDirection.rtl,
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
                          'product_id': 0, // معرف وهمي للدين
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
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ في إضافة الدين: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
        textDirection: TextDirection.rtl,
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

                try {
                  await db.payInstallment(
                    installment['id'],
                    double.parse(amountController.text),
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
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في دفع القسط: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
  ) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد حذف العميل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('هل أنت متأكد من حذف العميل:'),
              const SizedBox(height: 8),
              Text(
                '${customer['name'] ?? 'غير محدد'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'تحذير: سيتم حذف جميع البيانات المرتبطة بهذا العميل بما في ذلك المدفوعات والفواتير.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
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
                  print(
                      'Attempting to delete customer: ${customer['id']} - ${customer['name']}');

                  // التحقق من وجود العميل قبل المحاولة
                  final customers = await db.getCustomers();
                  final customerExists =
                      customers.any((c) => c['id'] == customer['id']);
                  print('Customer exists before deletion: $customerExists');

                  // حذف العميل (سيحذف جميع البيانات المرتبطة تلقائياً)
                  final deletedRows = await db.deleteCustomer(customer['id']);

                  print('Delete result: $deletedRows rows deleted');

                  // التحقق من وجود العميل بعد المحاولة
                  final customersAfter = await db.getCustomers();
                  final customerExistsAfter =
                      customersAfter.any((c) => c['id'] == customer['id']);
                  print('Customer exists after deletion: $customerExistsAfter');

                  if (deletedRows > 0) {
                    Navigator.pop(context);
                    // إعادة تحميل البيانات
                    _refreshData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('تم حذف العميل ${customer['name']} بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'لم يتم العثور على العميل أو حدث خطأ في الحذف'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error deleting customer: $e');
                  Navigator.pop(context);

                  // تحسين رسائل الخطأ
                  String errorMessage = 'خطأ في حذف العميل';
                  if (e.toString().contains('FOREIGN KEY constraint failed')) {
                    errorMessage =
                        'لا يمكن حذف العميل لأنه مرتبط بفواتير أو مدفوعات';
                  } else if (e.toString().contains('database is locked')) {
                    errorMessage =
                        'قاعدة البيانات قيد الاستخدام، حاول مرة أخرى';
                  } else if (e.toString().contains('no such table')) {
                    errorMessage =
                        'خطأ في قاعدة البيانات، يرجى إعادة تشغيل التطبيق';
                  } else {
                    errorMessage = 'خطأ في حذف العميل: ${e.toString()}';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف العميل'),
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
        textDirection: TextDirection.rtl,
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
                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال مبلغ القسط'),
                      backgroundColor: Colors.red,
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
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في تعديل القسط: $e'),
                      backgroundColor: Colors.red,
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
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف القسط'),
          content: Text(
            'هل أنت متأكد من حذف قسط ${Formatters.currencyIQD(installment['amount'])} للعميل ${installment['customer_name']}؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await db.deleteInstallment(installment['id']);
                  Navigator.pop(context);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف القسط بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في حذف القسط: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    DatabaseService db,
  ) async {
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

      // إنشاء كشف الحساب
      final statement = _generateCustomerStatement(
        customer,
        payments,
        debtData,
      );

      // طباعة كشف الحساب
      await _printStatement(statement);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم طباعة كشف الحساب بنجاح'),
          backgroundColor: Colors.green,
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
          backgroundColor: Colors.red,
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

  // دالة طباعة كشف الحساب
  Future<void> _printStatement(String statement) async {
    // في التطبيق الحقيقي، يمكن استخدام مكتبة الطباعة
    // هنا سنعرض النص في نافذة منبثقة للعرض
    print('كشف الحساب:');
    print(statement);
  }
}
