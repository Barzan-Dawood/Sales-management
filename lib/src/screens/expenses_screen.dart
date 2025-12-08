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

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _query = '';
  String? _selectedCategory;
  DateTime? _fromDate;
  DateTime? _toDate;
  List<String> _categories = [
    'إيجار',
    'رواتب',
    'كهرباء',
    'ماء',
    'إنترنت',
    'صيانة',
    'تسويق',
    'أخرى',
    'عام'
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = context.read<DatabaseService>();
    try {
      final categories = await db.getExpenseCategories();
      if (categories.isNotEmpty) {
        setState(() {
          _categories = [..._categories, ...categories];
          _categories = _categories.toSet().toList();
        });
      }
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // فحص صلاحية إدارة المصروفات
    if (!auth.hasPermission(UserPermission.viewReports)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المصروفات'),
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
                            hintText: 'بحث في المصروفات',
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
                        onPressed: () => _openExpenseEditor(),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة مصروف'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'نوع المصروف',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('جميع الأنواع'),
                            ),
                            ..._categories.map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showManageCategoriesDialog(),
                        icon: const Icon(Icons.category),
                        label: const Text('إدارة الأنواع'),
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
            // قائمة المصروفات
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: context.read<DatabaseService>().getExpenses(
                      from: _fromDate,
                      to: _toDate,
                      category: _selectedCategory,
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
                          Text('خطأ في تحميل المصروفات: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final expenses = snapshot.data ?? [];
                  final filteredExpenses = expenses.where((expense) {
                    if (_query.isEmpty) return true;
                    final title =
                        expense['title']?.toString().toLowerCase() ?? '';
                    final description =
                        expense['description']?.toString().toLowerCase() ?? '';
                    return title.contains(_query.toLowerCase()) ||
                        description.contains(_query.toLowerCase());
                  }).toList();

                  if (filteredExpenses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 64,
                              color: DarkModeUtils.getTextColor(context)
                                  .withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد مصروفات',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    );
                  }

                  // حساب الإجمالي
                  final total = filteredExpenses.fold<double>(
                    0.0,
                    (sum, expense) =>
                        sum + ((expense['amount'] as num?)?.toDouble() ?? 0.0),
                  );

                  return Column(
                    children: [
                      // بطاقة الإجمالي
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'إجمالي المصروفات:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              Formatters.currencyIQD(total),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // قائمة المصروفات
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
                            return _ExpenseCard(
                              expense: expense,
                              onEdit: () =>
                                  _openExpenseEditor(expense: expense),
                              onDelete: () =>
                                  _deleteExpense(expense['id'] as int),
                              canEdit: auth
                                  .hasPermission(UserPermission.manageProducts),
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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text('فلترة المصروفات', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick selection buttons
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: [
                      _QuickDateButton(
                        label: 'اليوم',
                        onTap: () {
                          setDialogState(() {
                            startDate = DateTime(now.year, now.month, now.day);
                            endDate = DateTime(now.year, now.month, now.day);
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: 'هذا الأسبوع',
                        onTap: () {
                          final weekStart =
                              now.subtract(Duration(days: now.weekday - 1));
                          setDialogState(() {
                            startDate = DateTime(
                                weekStart.year, weekStart.month, weekStart.day);
                            endDate = DateTime(now.year, now.month, now.day);
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: 'هذا الشهر',
                        onTap: () {
                          setDialogState(() {
                            startDate = DateTime(now.year, now.month, 1);
                            endDate = DateTime(now.year, now.month + 1, 0);
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: 'آخر 30 يوم',
                        onTap: () {
                          setDialogState(() {
                            startDate = now.subtract(const Duration(days: 30));
                            endDate = now;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Start Date
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
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'من تاريخ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  startDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(startDate!)
                                      : 'اختر التاريخ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // End Date
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
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إلى تاريخ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  endDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(endDate!)
                                      : 'اختر التاريخ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
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

  Future<void> _openExpenseEditor({Map<String, dynamic>? expense}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ExpenseEditorDialog(
        expense: expense,
        categories: _categories,
      ),
    );

    if (result != null && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteExpense(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المصروف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<DatabaseService>().deleteExpense(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المصروف بنجاح')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في حذف المصروف: $e')),
          );
        }
      }
    }
  }

  Future<void> _showManageCategoriesDialog() async {
    final db = context.read<DatabaseService>();

    if (!mounted) return;

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) {
                // استخدام جميع الأنواع من القائمة المحلية
                final categoriesSet = _categories.toSet();
                final allCategories = <String>[];

                // إضافة "عام" في البداية إن وجد
                if (categoriesSet.contains('عام')) {
                  allCategories.add('عام');
                }

                // إضافة باقي الأنواع مرتبة أبجدياً (عدا "عام" و "أخرى")
                final otherCategories = categoriesSet
                    .where((cat) => cat != 'عام' && cat != 'أخرى')
                    .toList()
                  ..sort();
                allCategories.addAll(otherCategories);

                // إضافة "أخرى" في النهاية إن وجد
                if (categoriesSet.contains('أخرى')) {
                  allCategories.add('أخرى');
                }

                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;

                return Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.38,
                      constraints: const BoxConstraints(maxWidth: 450),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  theme.colorScheme.surface,
                                  theme.colorScheme.surface.withOpacity(0.95),
                                ]
                              : [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.orange.shade400,
                                        Colors.deepOrange.shade500,
                                      ]
                                    : [
                                        Colors.orange.shade300,
                                        Colors.deepOrange.shade400,
                                      ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.category,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'إدارة أنواع المصروفات',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  tooltip: 'إغلاق',
                                ),
                              ],
                            ),
                          ),
                          // Content
                          Flexible(
                            child: allCategories.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.category_outlined,
                                          size: 56,
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'لا توجد أنواع مصروفات',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : FutureBuilder<Map<String, int>>(
                                    future: () async {
                                      final counts = <String, int>{};
                                      for (final cat in allCategories) {
                                        counts[cat] = await db
                                            .getExpenseCountByCategory(cat);
                                      }
                                      return counts;
                                    }(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }

                                      final categoryCounts =
                                          snapshot.data ?? <String, int>{};

                                      // دالة لإضافة نوع جديد مع التحديث المباشر
                                      void showAddCategoryDialogLocal() {
                                        final controller =
                                            TextEditingController();
                                        showDialog(
                                          context: context,
                                          builder: (context) => Directionality(
                                            textDirection: ui.TextDirection.rtl,
                                            child: AlertDialog(
                                              title: const Text(
                                                  'إضافة نوع مصروف جديد'),
                                              content: TextField(
                                                controller: controller,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'اسم النوع',
                                                  border: OutlineInputBorder(),
                                                ),
                                                autofocus: true,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    controller.clear();
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('إلغاء'),
                                                ),
                                                FilledButton(
                                                  onPressed: () {
                                                    final newCategory =
                                                        controller.text.trim();
                                                    if (newCategory
                                                        .isNotEmpty) {
                                                      // تحديث القائمة المحلية
                                                      setState(() {
                                                        if (!_categories
                                                            .contains(
                                                                newCategory)) {
                                                          _categories
                                                              .add(newCategory);
                                                        }
                                                      });
                                                      // تحديث النافذة مباشرة
                                                      setDialogState(() {});
                                                      controller.clear();
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: const Text('إضافة'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: [
                                          // Add Category Button
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: FilledButton.icon(
                                              onPressed:
                                                  showAddCategoryDialogLocal,
                                              icon: const Icon(Icons.add,
                                                  size: 20),
                                              label: const Text(
                                                  'إضافة نوع جديد',
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: isDark
                                                    ? Colors.deepOrange.shade500
                                                    : Colors
                                                        .deepOrange.shade400,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Divider(height: 1),
                                          // Categories List
                                          Flexible(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              padding: const EdgeInsets.all(12),
                                              itemCount: allCategories.length,
                                              itemBuilder: (context, index) {
                                                final category =
                                                    allCategories[index];
                                                final count =
                                                    categoryCounts[category] ??
                                                        0;
                                                final isDefault =
                                                    category == 'عام';

                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 10),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? theme
                                                            .colorScheme.surface
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: isDefault
                                                          ? Colors.orange
                                                              .withOpacity(0.3)
                                                          : Colors.grey
                                                              .withOpacity(0.2),
                                                      width: isDefault ? 2 : 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: isDark
                                                            ? Colors.black
                                                                .withOpacity(
                                                                    0.3)
                                                            : Colors.black
                                                                .withOpacity(
                                                                    0.05),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    leading: Container(
                                                      width: 44,
                                                      height: 44,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: isDefault
                                                              ? [
                                                                  Colors.orange
                                                                      .shade300,
                                                                  Colors
                                                                      .deepOrange
                                                                      .shade400,
                                                                ]
                                                              : [
                                                                  Colors.orange
                                                                      .withOpacity(
                                                                          0.2),
                                                                  Colors.orange
                                                                      .withOpacity(
                                                                          0.1),
                                                                ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: Icon(
                                                        Icons.category,
                                                        color: isDefault
                                                            ? Colors.white
                                                            : Colors.orange,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    title: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            category,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 15,
                                                              color: isDefault
                                                                  ? Colors
                                                                      .orange
                                                                      .shade700
                                                                  : theme
                                                                      .colorScheme
                                                                      .onSurface,
                                                            ),
                                                          ),
                                                        ),
                                                        if (isDefault)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 3,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .orange
                                                                  .withOpacity(
                                                                      0.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: Text(
                                                              'افتراضي',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .orange
                                                                    .shade700,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    subtitle: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 4),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.receipt_long,
                                                            size: 12,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                    0.6),
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '$count مصروف',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.7),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    trailing: isDefault
                                                        ? const SizedBox
                                                            .shrink()
                                                        : Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.red
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: IconButton(
                                                              icon: const Icon(
                                                                Icons
                                                                    .delete_outline,
                                                                color:
                                                                    Colors.red,
                                                                size: 20,
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                // تأكيد الحذف
                                                                final confirm =
                                                                    await showDialog<
                                                                        bool>(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) =>
                                                                          Directionality(
                                                                    textDirection: ui
                                                                        .TextDirection
                                                                        .rtl,
                                                                    child:
                                                                        AlertDialog(
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(16),
                                                                      ),
                                                                      title:
                                                                          Row(
                                                                        children: [
                                                                          Icon(
                                                                            Icons.warning_amber_rounded,
                                                                            color:
                                                                                Colors.red,
                                                                          ),
                                                                          const SizedBox(
                                                                              width: 8),
                                                                          const Text(
                                                                              'تأكيد الحذف'),
                                                                        ],
                                                                      ),
                                                                      content:
                                                                          Text(
                                                                        count > 0
                                                                            ? 'سيتم تحديث $count مصروف من نوع "$category" إلى "عام". هل تريد المتابعة؟'
                                                                            : 'هل تريد حذف نوع "$category"؟',
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              context,
                                                                              false),
                                                                          child:
                                                                              const Text('إلغاء'),
                                                                        ),
                                                                        FilledButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              context,
                                                                              true),
                                                                          style:
                                                                              FilledButton.styleFrom(
                                                                            backgroundColor:
                                                                                Colors.red,
                                                                          ),
                                                                          child:
                                                                              const Text('حذف'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );

                                                                if (confirm ==
                                                                        true &&
                                                                    mounted) {
                                                                  try {
                                                                    await db.deleteExpenseCategory(
                                                                        category);
                                                                    if (mounted) {
                                                                      // حذف النوع من القائمة المحلية
                                                                      setState(
                                                                          () {
                                                                        _categories
                                                                            .remove(category);
                                                                        // التأكد من وجود "عام" في القائمة
                                                                        if (!_categories
                                                                            .contains('عام')) {
                                                                          _categories.insert(
                                                                              0,
                                                                              'عام');
                                                                        }
                                                                        if (_selectedCategory ==
                                                                            category) {
                                                                          _selectedCategory =
                                                                              null;
                                                                        }
                                                                      });

                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                          content:
                                                                              Text(
                                                                            count > 0
                                                                                ? 'تم تحديث $count مصروف إلى "عام"'
                                                                                : 'تم حذف النوع بنجاح',
                                                                          ),
                                                                          backgroundColor:
                                                                              Colors.green,
                                                                        ),
                                                                      );

                                                                      // تحديث النافذة مباشرة
                                                                      setDialogState(
                                                                          () {});
                                                                    }
                                                                  } catch (e) {
                                                                    if (mounted) {
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                          content:
                                                                              Text('خطأ: $e'),
                                                                          backgroundColor:
                                                                              Colors.red,
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                }
                                                              },
                                                              tooltip:
                                                                  'حذف النوع',
                                                            ),
                                                          ),
                                                  ),
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
                  ),
                );
              },
            ));
  }
}

class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canEdit;

  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
    final title = expense['title']?.toString() ?? '';
    final category = expense['category']?.toString() ?? 'عام';
    final description = expense['description']?.toString();
    final expenseDate = expense['expense_date']?.toString();

    DateTime? date;
    if (expenseDate != null) {
      try {
        date = DateTime.parse(expenseDate);
      } catch (e) {
        // تجاهل خطأ التحليل
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.2),
          child: const Icon(Icons.receipt_long, color: Colors.orange),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null && description.isNotEmpty)
              Text(description),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(category),
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                if (date != null)
                  Text(
                    DateFormat('yyyy-MM-dd').format(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Formatters.currencyIQD(amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
            ),
            if (canEdit) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
                tooltip: 'تعديل',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'حذف',
              ),
            ],
          ],
        ),
        isThreeLine: description != null && description.isNotEmpty,
      ),
    );
  }
}

class _ExpenseEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? expense;
  final List<String> categories;

  const _ExpenseEditorDialog({
    this.expense,
    required this.categories,
  });

  @override
  State<_ExpenseEditorDialog> createState() => _ExpenseEditorDialogState();
}

class _ExpenseEditorDialogState extends State<_ExpenseEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'عام';
  DateTime _selectedDate = DateTime.now();
  final _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _titleController.text = widget.expense!['title']?.toString() ?? '';
      _amountController.text =
          (widget.expense!['amount'] as num?)?.toString() ?? '';
      _descriptionController.text =
          widget.expense!['description']?.toString() ?? '';
      _selectedCategory = widget.expense!['category']?.toString() ?? 'عام';

      final expenseDate = widget.expense!['expense_date']?.toString();
      if (expenseDate != null) {
        try {
          _selectedDate = DateTime.parse(expenseDate);
        } catch (e) {
          // تجاهل خطأ التحليل
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withOpacity(0.95),
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.orange.shade400,
                            Colors.deepOrange.shade500,
                          ]
                        : [
                            Colors.orange.shade300,
                            Colors.deepOrange.shade400,
                          ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.expense == null
                            ? 'إضافة مصروف جديد'
                            : 'تعديل المصروف',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),
              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title Field
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _titleController,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'عنوان المصروف',
                              hintText: 'مثال: إيجار المحل',
                              prefixIcon:
                                  const Icon(Icons.title, color: Colors.orange),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال عنوان المصروف';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Category and Amount Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.surface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedCategory,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  dropdownColor: isDark
                                      ? theme.colorScheme.surface
                                      : Colors.white,
                                  iconEnabledColor: Colors.orange,
                                  iconDisabledColor: theme.colorScheme.onSurface
                                      .withOpacity(0.38),
                                  decoration: InputDecoration(
                                    labelText: 'نوع المصروف',
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                    prefixIcon: const Icon(Icons.category,
                                        color: Colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? theme.colorScheme.surface
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                  ),
                                  items: [
                                    ...widget.categories
                                        .map((cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(
                                                cat,
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme.onSurface,
                                                ),
                                              ),
                                            )),
                                    DropdownMenuItem(
                                      value: 'new',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.add,
                                            size: 18,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'إضافة نوع جديد',
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == 'new') {
                                      _showAddCategoryDialog();
                                    } else {
                                      setState(() =>
                                          _selectedCategory = value ?? 'عام');
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.surface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _amountController,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'المبلغ (د.ع)',
                                    hintText: '0.00',
                                    prefixIcon: const Icon(Icons.attach_money,
                                        color: Colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? theme.colorScheme.surface
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'يرجى إدخال المبلغ';
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount <= 0) {
                                      return 'يرجى إدخال مبلغ صحيح';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Date Picker
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'تاريخ المصروف',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('yyyy-MM-dd', 'en_US')
                                              .format(_selectedDate),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Description Field
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _descriptionController,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'الوصف (اختياري)',
                              hintText: 'أضف وصفاً تفصيلياً للمصروف...',
                              prefixIcon: const Icon(Icons.description,
                                  color: Colors.orange),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                              contentPadding: const EdgeInsets.all(20),
                            ),
                            maxLines: 4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Text(
                                  'إلغاء',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: _saveExpense,
                                style: FilledButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.deepOrange.shade500
                                      : Colors.deepOrange.shade400,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'حفظ المصروف',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة نوع مصروف جديد'),
          content: TextField(
            controller: _newCategoryController,
            decoration: const InputDecoration(
              labelText: 'اسم النوع',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _newCategoryController.clear();
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final newCategory = _newCategoryController.text.trim();
                if (newCategory.isNotEmpty) {
                  setState(() {
                    _selectedCategory = newCategory;
                    if (!widget.categories.contains(newCategory)) {
                      widget.categories.add(newCategory);
                    }
                  });
                  _newCategoryController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text);
    final category = _selectedCategory;
    final description = _descriptionController.text.trim();
    final expenseDate = _selectedDate;

    try {
      final db = context.read<DatabaseService>();

      if (widget.expense == null) {
        await db.createExpense(
          title: title,
          amount: amount,
          category: category,
          description: description.isEmpty ? null : description,
          expenseDate: expenseDate,
        );
      } else {
        await db.updateExpense(
          id: widget.expense!['id'] as int,
          title: title,
          amount: amount,
          category: category,
          description: description.isEmpty ? null : description,
          expenseDate: expenseDate,
        );
      }

      if (mounted) {
        Navigator.pop(context, {'success': true});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ المصروف: $e')),
        );
      }
    }
  }
}

class _QuickDateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDateButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
