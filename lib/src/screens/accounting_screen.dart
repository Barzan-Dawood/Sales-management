import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../utils/format.dart';
import '../utils/export.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  DateTimeRange? _range;
  String? _selectedPeriodName;
  final _title = TextEditingController();
  final _amount = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(children: [
              OutlinedButton.icon(
                onPressed: () => _addExpense(context),
                icon: const Icon(Icons.add),
                label: const Text('إضافة مصروف'),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _range = null;
                    _selectedPeriodName = null;
                  });
                },
                icon: const Icon(Icons.all_inclusive),
                label: const Text('عرض الكل'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _showDateRangePicker(context),
                icon: const Icon(Icons.date_range),
                label: Text(_getDateRangeLabel()),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  await _exportAccountingSummary(context);
                },
                tooltip: 'تصدير الملخص PDF',
                icon: const Icon(Icons.picture_as_pdf),
              ),
            ]),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, double>>(
              future: db.profitAndLoss(from: _range?.start, to: _range?.end),
              builder: (context, snap) {
                final data = snap.data ??
                    {'sales': 0, 'profit': 0, 'expenses': 0, 'net': 0};
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.end,
                  children: [
                    _StatCard(
                      title: 'المبيعات',
                      value: Formatters.currencyIQD(data['sales'] ?? 0),
                      color: Colors.blue,
                      icon: Icons.shopping_cart_rounded,
                    ),
                    _StatCard(
                      title: 'الربح الإجمالي',
                      value: Formatters.currencyIQD(data['profit'] ?? 0),
                      color: Colors.green,
                      icon: Icons.trending_up_rounded,
                    ),
                    _StatCard(
                      title: 'المصاريف',
                      value: Formatters.currencyIQD(data['expenses'] ?? 0),
                      color: Colors.orange,
                      icon: Icons.receipt_long_rounded,
                    ),
                    _StatCard(
                      title: 'الصافي',
                      value: Formatters.currencyIQD(data['net'] ?? 0),
                      color: (data['net'] ?? 0) >= 0 ? Colors.teal : Colors.red,
                      icon: (data['net'] ?? 0) >= 0
                          ? Icons.account_balance_wallet_rounded
                          : Icons.warning_rounded,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.getExpenses(from: _range?.start, to: _range?.end),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final items = snap.data!;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'قائمة المصاريف',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () async {
                                  await _exportExpensesList(context, items);
                                },
                                tooltip: 'تصدير المصاريف PDF',
                                icon: const Icon(Icons.picture_as_pdf),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${items.length} مصروف',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: items.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'لا توجد مصاريف في هذه الفترة',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final e = items[i];
                                    return _ExpenseItem(
                                      title: e['title']?.toString() ?? '',
                                      amount:
                                          (e['amount'] as num?)?.toDouble() ??
                                              0.0,
                                      date: e['created_at']?.toString() ?? '',
                                      onDelete: () async {
                                        await db.deleteExpense(e['id'] as int);
                                        if (!mounted) return;
                                        setState(() {});
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _exportAccountingSummary(BuildContext context) async {
    try {
      final db = context.read<DatabaseService>();
      final data = await db.profitAndLoss(from: _range?.start, to: _range?.end);
      final rows = <List<String>>[
        ['البند', 'القيمة'],
        ['المبيعات', Formatters.currencyIQD(data['sales'] ?? 0)],
        ['الربح الإجمالي', Formatters.currencyIQD(data['profit'] ?? 0)],
        ['المصاريف', Formatters.currencyIQD(data['expenses'] ?? 0)],
        ['الصافي', Formatters.currencyIQD(data['net'] ?? 0)],
      ];
      final saved = await PdfExporter.exportSimpleTable(
        filename: 'accounting_summary.pdf',
        title:
            'ملخص الحسابات${_selectedPeriodName != null ? ' - $_selectedPeriodName' : ''}',
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
        SnackBar(content: Text('فشل تصدير ملخص الحسابات: $e')),
      );
    }
  }

  Future<void> _exportExpensesList(
      BuildContext context, List<Map<String, Object?>> items) async {
    try {
      final headers = ['العنوان', 'المبلغ', 'التاريخ'];
      final rows = items
          .map((e) => [
                (e['title'] ?? '').toString(),
                Formatters.currencyIQD((e['amount'] as num?)?.toDouble() ?? 0),
                (e['created_at'] ?? '').toString().substring(0, 10),
              ])
          .toList();
      final saved = await PdfExporter.exportDataTable(
        filename: 'expenses_list.pdf',
        title:
            'قائمة المصاريف${_selectedPeriodName != null ? ' - $_selectedPeriodName' : ''}',
        headers: headers,
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
        SnackBar(content: Text('فشل تصدير قائمة المصاريف: $e')),
      );
    }
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = _range ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

    DateTime? startDate = initialRange.start;
    DateTime? endDate = initialRange.end;
    String? selectedQuickButton = _selectedPeriodName;

    final result = await showDialog<DateTimeRange?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'اختيار الفترة',
              textAlign: TextAlign.right,
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Start Date
                  ListTile(
                    leading:
                        Icon(Icons.calendar_today, color: Colors.blue.shade600),
                    title: const Text('تاريخ البداية'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startDate.toString().substring(0, 10),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (selectedQuickButton != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'فترة: $selectedQuickButton',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(now.year - 5),
                        lastDate: endDate ?? DateTime(now.year + 1),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startDate = picked;
                          selectedQuickButton =
                              null; // إلغاء الاختيار السريع عند التعديل اليدوي
                        });
                      }
                    },
                  ),
                  const Divider(),
                  // End Date
                  ListTile(
                    leading: Icon(Icons.calendar_today,
                        color: Colors.green.shade600),
                    title: const Text('تاريخ النهاية'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          endDate.toString().substring(0, 10),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (selectedQuickButton != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'فترة: $selectedQuickButton',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate ?? DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 1),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          endDate = picked;
                          selectedQuickButton =
                              null; // إلغاء الاختيار السريع عند التعديل اليدوي
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Quick selection buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickDateButton(
                        label: 'اليوم',
                        isSelected: selectedQuickButton == 'اليوم',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = 'اليوم';
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: 'أسبوع',
                        isSelected: selectedQuickButton == 'أسبوع',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = 'أسبوع';
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: 'شهر',
                        isSelected: selectedQuickButton == 'شهر',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = 'شهر';
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: '3 أشهر',
                        isSelected: selectedQuickButton == '3 أشهر',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = '3 أشهر';
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: '6 أشهر',
                        isSelected: selectedQuickButton == '6 أشهر',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = '6 أشهر';
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: 'سنة',
                        isSelected: selectedQuickButton == 'سنة',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = 'سنة';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  DateTime finalStart = startDate!;
                  DateTime finalEnd = endDate!;

                  // تطبيق الفترة السريعة المختارة
                  if (selectedQuickButton != null) {
                    final now = DateTime.now();
                    switch (selectedQuickButton) {
                      case 'اليوم':
                        finalStart = DateTime(now.year, now.month, now.day);
                        finalEnd =
                            DateTime(now.year, now.month, now.day, 23, 59, 59);
                        break;
                      case 'أسبوع':
                        finalStart = now.subtract(const Duration(days: 7));
                        finalEnd = now;
                        break;
                      case 'شهر':
                        finalStart = now.subtract(const Duration(days: 30));
                        finalEnd = now;
                        break;
                      case '3 أشهر':
                        finalStart = now.subtract(const Duration(days: 90));
                        finalEnd = now;
                        break;
                      case '6 أشهر':
                        finalStart = now.subtract(const Duration(days: 180));
                        finalEnd = now;
                        break;
                      case 'سنة':
                        finalStart = now.subtract(const Duration(days: 365));
                        finalEnd = now;
                        break;
                    }
                  }

                  Navigator.pop(
                      context, DateTimeRange(start: finalStart, end: finalEnd));
                },
                child: const Text('تطبيق'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _range = result;
        // تحديد اسم الفترة بناءً على النطاق المحدد
        _selectedPeriodName = _determinePeriodName(result);
      });
    }
  }

  String _getDateRangeLabel() {
    if (_range == null) {
      return 'الفترة: آخر 30 يوم';
    }

    final dateRange =
        '${_range!.start.toString().substring(0, 10)} - ${_range!.end.toString().substring(0, 10)}';

    if (_selectedPeriodName != null) {
      return 'الفترة: $dateRange ($_selectedPeriodName)';
    }

    return 'الفترة: $dateRange';
  }

  String? _determinePeriodName(DateTimeRange range) {
    final now = DateTime.now();
    final start = range.start;
    final end = range.end;

    // التحقق من اليوم
    final todayStart = DateTime(now.year, now.month, now.day);
    if (_isSameDay(start, todayStart) && _isSameDay(end, todayStart)) {
      return 'اليوم';
    }

    // التحقق من الأسبوع (من 7 أيام مضت إلى اليوم)
    final weekStart = now.subtract(const Duration(days: 7));
    if (_isSameDay(start, weekStart) && _isSameDay(end, now)) {
      return 'أسبوع';
    }

    // التحقق من الشهر (من 30 يوم مضى إلى اليوم)
    final monthStart = now.subtract(const Duration(days: 30));
    if (_isSameDay(start, monthStart) && _isSameDay(end, now)) {
      return 'شهر';
    }

    // التحقق من 3 أشهر (من 90 يوم مضى إلى اليوم)
    final threeMonthsStart = now.subtract(const Duration(days: 90));
    if (_isSameDay(start, threeMonthsStart) && _isSameDay(end, now)) {
      return '3 أشهر';
    }

    // التحقق من 6 أشهر (من 180 يوم مضى إلى اليوم)
    final sixMonthsStart = now.subtract(const Duration(days: 180));
    if (_isSameDay(start, sixMonthsStart) && _isSameDay(end, now)) {
      return '6 أشهر';
    }

    // التحقق من السنة (من 365 يوم مضى إلى اليوم)
    final yearStart = now.subtract(const Duration(days: 365));
    if (_isSameDay(start, yearStart) && _isSameDay(end, now)) {
      return 'سنة';
    }

    return null; // فترة مخصصة
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _addExpense(BuildContext context) async {
    final db = context.read<DatabaseService>();
    _title.clear();
    _amount.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'إضافة مصروف',
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _title,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amount,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final amount = double.tryParse(_amount.text) ?? 0;
      await db.addExpense(_title.text.trim(), amount);
      if (!mounted) return;
      setState(() {});
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  const _ExpenseItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.onDelete,
  });

  final String title;
  final double amount;
  final String date;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left side - Icon, Name, Amount
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_rounded,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Name and Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Amount
                    Text(
                      Formatters.currencyIQD(amount),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Right side - Delete button only
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade500,
                size: 22,
              ),
              tooltip: 'حذف المصروف',
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDateButton extends StatelessWidget {
  const _QuickDateButton({
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.outline,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
