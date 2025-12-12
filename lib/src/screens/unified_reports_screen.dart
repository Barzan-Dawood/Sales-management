// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/format.dart';
import '../utils/export.dart';
import 'reports_screen.dart';
import 'advanced_reports_screen.dart';
import 'inventory_reports_screen.dart';

/// صفحة التقارير الموحدة - تجمع جميع التقارير في مكان واحد
class UnifiedReportsScreen extends StatefulWidget {
  const UnifiedReportsScreen({super.key});

  @override
  State<UnifiedReportsScreen> createState() => _UnifiedReportsScreenState();
}

class _UnifiedReportsScreenState extends State<UnifiedReportsScreen>
    with TickerProviderStateMixin {
  late TabController _categoryTabController;

  // فئات التقارير
  final List<ReportCategory> _categories = [
    ReportCategory(
      title: 'الملخص العام',
      icon: Icons.dashboard,
      color: Colors.blue,
      description: 'نظرة شاملة على الأداء',
    ),
    ReportCategory(
      title: 'التقارير المالية',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
      description: 'قائمة الدخل، الميزانية، مؤشرات الأداء',
    ),
    ReportCategory(
      title: 'تقارير المخزون',
      icon: Icons.inventory_2,
      color: Colors.orange,
      description: 'الجرد، الأكثر مبيعاً، بطيء الحركة',
    ),
    ReportCategory(
      title: 'تقارير المبيعات',
      icon: Icons.receipt_long,
      color: Colors.purple,
      description: 'تفصيل المبيعات حسب النوع',
    ),
    ReportCategory(
      title: 'تقارير الديون',
      icon: Icons.payments,
      color: Colors.red,
      description: 'إحصائيات الديون والفواتير المتأخرة',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(
      length: _categories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _categoryTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // فحص صلاحية عرض التقارير
    if (!auth.hasPermission(UserPermission.viewReports)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('التقارير الموحدة'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التقارير الموحدة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? scheme.surface : Color(0xFFFFFFFF),
        foregroundColor: isDark ? scheme.onSurface : Colors.black,
        bottom: TabBar(
          controller: _categoryTabController,
          isScrollable: true,
          labelColor: isDark ? scheme.primary : Colors.black,
          unselectedLabelColor:
              isDark ? scheme.onSurface.withOpacity(0.7) : Colors.grey,
          indicatorColor: isDark ? scheme.primary : Colors.black,
          tabs: _categories.map((category) {
            return Tab(
              icon: Icon(category.icon),
              text: category.title,
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _categoryTabController,
        children: [
          _buildSummaryCategory(),
          _buildFinancialCategory(),
          _buildInventoryCategory(),
          _buildSalesCategory(),
          _buildDebtsCategory(),
        ],
      ),
    );
  }

  /// فئة الملخص العام
  Widget _buildSummaryCategory() {
    return const ReportsScreen();
  }

  /// فئة التقارير المالية
  Widget _buildFinancialCategory() {
    return const AdvancedReportsScreen();
  }

  /// فئة تقارير المخزون
  Widget _buildInventoryCategory() {
    return const InventoryReportsScreen();
  }

  /// فئة تقارير المبيعات
  Widget _buildSalesCategory() {
    final db = context.read<DatabaseService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader(
            'تقارير المبيعات',
            'تفصيل المبيعات حسب نوع الدفع والفترة',
            Icons.receipt_long,
            Colors.purple,
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, Object?>>>(
            future: db.getSalesHistory(sortDescending: true),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return Center(
                  child: Column(
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('خطأ في تحميل البيانات: ${snap.error}'),
                    ],
                  ),
                );
              }

              final rows = snap.data ?? const [];
              final totals = <String, double>{};
              for (final r in rows) {
                final type = (r['type'] as String?) ?? '';
                final total = (r['total'] as num?)?.toDouble() ?? 0.0;
                final typeAr = _getPaymentTypeText(type);
                totals[typeAr] = (totals[typeAr] ?? 0) + total;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // إحصائيات حسب نوع الدفع
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'تفصيل حسب نوع الدفع',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final csv = <List<String>>[
                                    ['النوع', 'القيمة'],
                                    ...totals.entries
                                        .map((e) => [e.key, e.value.toString()])
                                  ];
                                  await PdfExporter.exportDataTable(
                                    filename: 'sales_breakdown.pdf',
                                    title: 'تفصيل المبيعات',
                                    headers: ['النوع', 'القيمة'],
                                    rows: csv.skip(1).toList(),
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تصدير التقرير بنجاح'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('تصدير PDF'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: totals.entries
                                .map((e) => _buildStatCard(
                                      e.key,
                                      Formatters.currencyIQD(e.value),
                                      Colors.purple,
                                      Icons.payment,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // آخر الفواتير
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'آخر 20 فاتورة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rows.length.clamp(0, 20),
                            itemBuilder: (context, i) {
                              final r = rows[i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.receipt_long),
                                title: Text(
                                  '#${r['id']} - ${_getPaymentTypeText((r['type'] as String?) ?? '')}',
                                ),
                                subtitle: Text(
                                  (r['created_at'] as String?)
                                          ?.substring(0, 16) ??
                                      '',
                                ),
                                trailing: Text(
                                  Formatters.currencyIQD(
                                    ((r['total'] as num?)?.toDouble() ?? 0),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// فئة تقارير الديون
  Widget _buildDebtsCategory() {
    final db = context.read<DatabaseService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader(
            'تقارير الديون',
            'إحصائيات الديون والفواتير المتأخرة',
            Icons.payments,
            Colors.red,
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, double>>(
            future: db.getDebtStatistics(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return Center(
                  child: Column(
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('خطأ في تحميل البيانات: ${snap.error}'),
                    ],
                  ),
                );
              }

              final stats = snap.data ??
                  {
                    'total_debt': 0,
                    'overdue_debt': 0,
                    'total_payments': 0,
                    'customers_with_debt': 0,
                  };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // إحصائيات الديون
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatCard(
                        'إجمالي الديون',
                        Formatters.currencyIQD(stats['total_debt'] ?? 0),
                        Colors.deepOrange,
                        Icons.account_balance_wallet,
                      ),
                      _buildStatCard(
                        'ديون متأخرة',
                        Formatters.currencyIQD(stats['overdue_debt'] ?? 0),
                        Colors.red,
                        Icons.warning,
                      ),
                      _buildStatCard(
                        'إجمالي المدفوعات',
                        Formatters.currencyIQD(stats['total_payments'] ?? 0),
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _buildStatCard(
                        'عملاء مدينون',
                        '${stats['customers_with_debt'] ?? 0}',
                        Colors.indigo,
                        Icons.people,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // فواتير متأخرة
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'فواتير متأخرة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final overdue =
                                      await db.creditSales(overdueOnly: true);
                                  final rows = <List<String>>[
                                    [
                                      '#',
                                      'العميل',
                                      'المبلغ',
                                      'تاريخ الاستحقاق'
                                    ],
                                    ...overdue.map((r) => [
                                          (r['id'] ?? '').toString(),
                                          (r['customer_name'] ?? '').toString(),
                                          (r['total'] ?? 0).toString(),
                                          (r['due_date'] ?? '')
                                              .toString()
                                              .substring(0, 10),
                                        ]),
                                  ];
                                  await PdfExporter.exportDataTable(
                                    filename: 'overdue_invoices.pdf',
                                    title: 'فواتير متأخرة',
                                    headers: rows.first,
                                    rows: rows.skip(1).toList(),
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تصدير التقرير بنجاح'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('تصدير PDF'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<List<Map<String, Object?>>>(
                            future: db.creditSales(overdueOnly: true),
                            builder: (context, snap) {
                              final rows = snap.data ?? const [];
                              if (rows.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text('لا توجد فواتير متأخرة'),
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: rows.length,
                                itemBuilder: (context, i) {
                                  final r = rows[i];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      '#${r['id']} - ${(r['customer_name'] ?? '').toString()}',
                                    ),
                                    subtitle: Text(
                                      'استحقاق: ${(r['due_date'] ?? '').toString().substring(0, 10)}',
                                    ),
                                    trailing: Text(
                                      Formatters.currencyIQD(
                                        ((r['total'] as num?)?.toDouble() ?? 0),
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
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

  String _getPaymentTypeText(String type) {
    switch (type) {
      case 'cash':
        return 'نقدي';
      case 'credit':
        return 'أجل';
      case 'installment':
        return 'أقساط';
      default:
        return 'غير محدد';
    }
  }
}

/// نموذج فئة التقرير
class ReportCategory {
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  ReportCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });
}
