// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/format.dart';
import '../utils/dark_mode_utils.dart';

class FinancialTransactionsScreen extends StatefulWidget {
  const FinancialTransactionsScreen({super.key});

  @override
  State<FinancialTransactionsScreen> createState() =>
      _FinancialTransactionsScreenState();
}

class _FinancialTransactionsScreenState
    extends State<FinancialTransactionsScreen> {
  String _query = '';
  String? _selectedTransactionType;
  DateTime? _fromDate;
  DateTime? _toDate;

  final List<String> _transactionTypes = [
    'جميع المعاملات',
    'sales',
    'expenses',
    'payments',
  ];

  final Map<String, String> _transactionTypeLabels = {
    'جميع المعاملات': 'جميع المعاملات',
    'sales': 'مبيعات',
    'expenses': 'مصروفات',
    'payments': 'مدفوعات',
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // فحص صلاحية إدارة المعاملات المالية
    if (!auth.hasPermission(UserPermission.viewReports)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('سجل المعاملات المالية'),
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
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl, // RTL for Arabic
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // شريط البحث والفلترة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DarkModeUtils.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: DarkModeUtils.getBorderColor(context)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'بحث في المعاملات',
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedTransactionType,
                          decoration: InputDecoration(
                            labelText: 'نوع المعاملة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          items: _transactionTypes.map((type) {
                            return DropdownMenuItem(
                              value: type == 'جميع المعاملات' ? null : type,
                              child: Text(_transactionTypeLabels[type] ?? type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedTransactionType = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showDateRangePicker(),
                        icon: const Icon(Icons.date_range),
                        label: Text(_getDateRangeLabel()),
                      ),
                      const SizedBox(width: 8),
                      if (_fromDate != null || _toDate != null)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fromDate = null;
                              _toDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          tooltip: 'مسح الفلترة',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // قائمة المعاملات
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future:
                    context.read<DatabaseService>().getAllFinancialTransactions(
                          from: _fromDate,
                          to: _toDate,
                          transactionType: _selectedTransactionType,
                        ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('خطأ في تحميل المعاملات: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final transactions = snapshot.data ?? [];
                  final filteredTransactions =
                      transactions.where((transaction) {
                    if (_query.isEmpty) return true;
                    final searchText = _query.toLowerCase();
                    final title =
                        transaction['title']?.toString().toLowerCase() ?? '';
                    final description =
                        transaction['description']?.toString().toLowerCase() ??
                            '';
                    final customerName = transaction['customer_name']
                            ?.toString()
                            .toLowerCase() ??
                        '';
                    final typeLabel =
                        transaction['type_label']?.toString().toLowerCase() ??
                            '';
                    return title.contains(searchText) ||
                        description.contains(searchText) ||
                        customerName.contains(searchText) ||
                        typeLabel.contains(searchText);
                  }).toList();

                  if (filteredTransactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet,
                              size: 64,
                              color: DarkModeUtils.getTextColor(context)
                                  .withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد معاملات مالية',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    );
                  }

                  // حساب الإجماليات
                  double totalIncome = 0.0;
                  double totalExpenses = 0.0;
                  double totalPayments = 0.0;
                  double totalCashSales = 0.0; // المبيعات النقدية فقط
                  double totalCreditSales = 0.0; // المبيعات الآجلة

                  for (final transaction in filteredTransactions) {
                    final type =
                        transaction['transaction_type']?.toString() ?? '';
                    final amount =
                        (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                    if (type == 'sale') {
                      // حساب المبيعات حسب النوع
                      final saleType = transaction['type']?.toString() ?? '';
                      if (saleType == 'cash') {
                        totalCashSales += amount;
                        totalIncome +=
                            amount; // المبيعات النقدية = إيرادات مباشرة
                      } else {
                        totalCreditSales += amount;
                        // المبيعات الآجلة لا تُحسب كإيرادات نقدية حتى يتم تحصيلها
                      }
                    } else if (type == 'expense') {
                      totalExpenses += amount;
                    } else if (type == 'payment') {
                      totalPayments += amount;
                      // المدفوعات هي تحصيل ديون = إيرادات نقدية
                      totalIncome += amount;
                    }
                  }

                  // صافي الرصيد = الإيرادات النقدية - المصروفات
                  final netBalance = totalIncome - totalExpenses;

                  return Column(
                    children: [
                      // بطاقات الإجماليات
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  title: 'الإيرادات النقدية',
                                  amount: totalIncome,
                                  color: Colors.green,
                                  icon: Icons.trending_up,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _SummaryCard(
                                  title: 'إجمالي المصروفات',
                                  amount: totalExpenses,
                                  color: Colors.red,
                                  icon: Icons.trending_down,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _SummaryCard(
                                  title: 'المبيعات النقدية',
                                  amount: totalCashSales,
                                  color: Colors.green.shade700,
                                  icon: Icons.shopping_cart,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _SummaryCard(
                                  title: 'المبيعات الآجلة',
                                  amount: totalCreditSales,
                                  color: Colors.orange,
                                  icon: Icons.credit_card,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  title: 'إجمالي المدفوعات',
                                  amount: totalPayments,
                                  color: Colors.blue,
                                  icon: Icons.payments,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: _SummaryCard(
                                  title: 'صافي الرصيد النقدي',
                                  amount: netBalance,
                                  color: netBalance >= 0
                                      ? Colors.teal
                                      : Colors.orange,
                                  icon: Icons.account_balance,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // قائمة المعاملات
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];
                            return _TransactionCard(
                              transaction: transaction,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateRangeLabel() {
    if (_fromDate != null && _toDate != null) {
      return '${DateFormat('yyyy-MM-dd').format(_fromDate!)} - ${DateFormat('yyyy-MM-dd').format(_toDate!)}';
    } else if (_fromDate != null) {
      return 'من ${DateFormat('yyyy-MM-dd').format(_fromDate!)}';
    } else if (_toDate != null) {
      return 'إلى ${DateFormat('yyyy-MM-dd').format(_toDate!)}';
    }
    return 'اختر الفترة';
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    DateTime? startDate = _fromDate;
    DateTime? endDate = _toDate;

    final result = await showDialog<DateTimeRange?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: const Text('فلترة المعاملات'),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? now,
                        firstDate: DateTime(2020),
                        lastDate: endDate ?? now,
                        builder: (context, child) {
                          return Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('من تاريخ',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  startDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(startDate!)
                                      : 'اختر التاريخ',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? now,
                        firstDate: startDate ?? DateTime(2020),
                        lastDate: now,
                        builder: (context, child) {
                          return Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('إلى تاريخ',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  endDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(endDate!)
                                      : 'اختر التاريخ',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
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
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    startDate = null;
                    endDate = null;
                  });
                },
                child: const Text('مسح'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    startDate != null && endDate != null
                        ? DateTimeRange(start: startDate!, end: endDate!)
                        : null,
                  );
                },
                child: const Text('تطبيق'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _fromDate = result.start;
        _toDate = result.end;
      });
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
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
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currencyIQD(amount),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final type = transaction['transaction_type']?.toString() ?? '';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final dateStr = transaction['transaction_date']?.toString() ?? '';
    final typeLabel = transaction['type_label']?.toString() ?? '';
    final title = transaction['title']?.toString() ?? '';
    final description = transaction['description']?.toString();
    final customerName = transaction['customer_name']?.toString();
    final profit = transaction['profit'] as num?;

    DateTime? date;
    if (dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        // تجاهل خطأ التحليل
      }
    }

    Color cardColor;
    IconData icon;
    String transactionLabel;

    switch (type) {
      case 'sale':
        cardColor = Colors.green;
        icon = Icons.shopping_cart;
        transactionLabel = 'مبيعات';
        break;
      case 'expense':
        cardColor = Colors.red;
        icon = Icons.receipt_long;
        transactionLabel = 'مصروفات';
        break;
      case 'payment':
        cardColor = Colors.blue;
        icon = Icons.payments;
        transactionLabel = 'مدفوعات';
        break;
      default:
        cardColor = Colors.grey;
        icon = Icons.account_balance_wallet;
        transactionLabel = 'معاملة';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cardColor.withOpacity(0.2),
          child: Icon(icon, color: cardColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title.isNotEmpty ? title : customerName ?? transactionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transactionLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: cardColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null && description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(description),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (typeLabel.isNotEmpty)
                  Chip(
                    label: Text(typeLabel),
                    labelStyle: const TextStyle(fontSize: 11),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                if (customerName != null && type != 'expense')
                  Chip(
                    label: Text(customerName),
                    labelStyle: const TextStyle(fontSize: 11),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                if (date != null)
                  Text(
                    DateFormat('yyyy-MM-dd').format(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (profit != null && type == 'sale')
                  Chip(
                    label: Text(
                        'ربح: ${Formatters.currencyIQD(profit.toDouble())}'),
                    labelStyle: const TextStyle(fontSize: 11),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.currencyIQD(amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
            ),
            if (type == 'sale' && profit != null)
              Text(
                'ربح: ${Formatters.currencyIQD(profit.toDouble())}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
              ),
          ],
        ),
        isThreeLine: description != null && description.isNotEmpty,
      ),
    );
  }
}
