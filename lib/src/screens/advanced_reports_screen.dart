// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/db/database_service.dart';
import '../utils/format.dart';
import '../utils/export.dart';
import '../services/print_service.dart';
import '../services/store_config.dart';

class AdvancedReportsScreen extends StatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends State<AdvancedReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final int _selectedMonths = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية المتقدمة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'تصدير PDF',
            onPressed: () => _exportCurrentTab(db),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'طباعة التقرير',
            onPressed: () => _printCurrentTab(db),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'اختيار التاريخ',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'تحديث البيانات',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'قائمة الدخل', icon: Icon(Icons.account_balance_wallet)),
            Tab(text: 'الميزانية', icon: Icon(Icons.balance)),
            Tab(text: 'مؤشرات الأداء', icon: Icon(Icons.trending_up)),
            Tab(text: 'تحليل الاتجاهات', icon: Icon(Icons.analytics)),
            Tab(text: 'تقرير المبيعات', icon: Icon(Icons.receipt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomeStatementTab(db),
          _buildBalanceSheetTab(db),
          _buildKPIsTab(db),
          _buildTrendAnalysisTab(db),
          _buildTaxReportTab(db),
        ],
      ),
    );
  }

  Widget _buildIncomeStatementTab(DatabaseService db) {
    return FutureBuilder<Map<String, dynamic>>(
      future: db.getIncomeStatement(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البيانات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final revenue = data['revenue'] as double? ?? 0.0;
        final cogs = data['cogs'] as double? ?? 0.0;
        final grossProfit = data['gross_profit'] as double? ?? 0.0;
        final expenses = data['expenses'] as double? ?? 0.0;
        final netProfit = data['net_profit'] as double? ?? 0.0;

        // إذا كانت البيانات فارغة، اعرض رسالة توضيحية
        if (revenue == 0.0 && cogs == 0.0 && grossProfit == 0.0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'لا توجد بيانات مالية للشهر المحدد',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'قم بإضافة مبيعات لرؤية التقارير المالية',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('قائمة الدخل', _selectedDate),
              const SizedBox(height: 20),

              // الإيرادات
              _buildFinancialCard(
                'الإيرادات',
                revenue,
                Colors.green,
                Icons.trending_up,
              ),

              // تكلفة البضائع المباعة
              _buildFinancialCard(
                'تكلفة البضائع المباعة',
                cogs,
                Colors.red,
                Icons.inventory,
              ),

              // إجمالي الربح
              _buildFinancialCard(
                'إجمالي الربح',
                grossProfit,
                Colors.blue,
                Icons.account_balance_wallet,
              ),

              // المصروفات
              _buildFinancialCard(
                'المصروفات',
                expenses,
                Colors.orange,
                Icons.money_off,
              ),

              // صافي الربح
              _buildFinancialCard(
                'صافي الربح',
                netProfit,
                netProfit >= 0 ? Colors.green : Colors.red,
                Icons.account_balance,
                isHighlight: true,
              ),

              const SizedBox(height: 20),

              // مخطط دائري للربح
              _buildProfitPieChart(grossProfit, expenses, netProfit),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceSheetTab(DatabaseService db) {
    return FutureBuilder<Map<String, dynamic>>(
      future: db.getBalanceSheet(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البيانات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final assets = data['assets'] as double? ?? 0.0;
        final liabilities = data['liabilities'] as double? ?? 0.0;
        final equity = data['equity'] as double? ?? 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('الميزانية العمومية', _selectedDate),
              const SizedBox(height: 20),

              // الأصول
              _buildFinancialCard(
                'الأصول',
                assets,
                Colors.green,
                Icons.account_balance_wallet,
              ),

              // الخصوم
              _buildFinancialCard(
                'الخصوم',
                liabilities,
                Colors.red,
                Icons.credit_card,
              ),

              // حقوق الملكية
              _buildFinancialCard(
                'حقوق الملكية',
                equity,
                Colors.blue,
                Icons.business,
                isHighlight: true,
              ),

              const SizedBox(height: 20),

              // مخطط الميزانية
              _buildBalanceSheetChart(assets, liabilities, equity),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPIsTab(DatabaseService db) {
    return FutureBuilder<Map<String, dynamic>>(
      future: db.getKPIs(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البيانات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final monthlyRevenue = data['monthly_revenue'] as double? ?? 0.0;
        final monthlyProfit = data['monthly_profit'] as double? ?? 0.0;
        final avgSaleAmount = data['avg_sale_amount'] as double? ?? 0.0;
        final newCustomers = data['new_customers'] as int? ?? 0;
        final profitMargin = data['profit_margin'] as double? ?? 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('مؤشرات الأداء الرئيسية', _selectedDate),
              const SizedBox(height: 20),

              // شبكة مؤشرات الأداء
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                childAspectRatio: 1.1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildKPICard(
                    'إجمالي المبيعات',
                    monthlyRevenue,
                    'د.ع',
                    Colors.green,
                    Icons.trending_up,
                  ),
                  _buildKPICard(
                    'صافي الربح',
                    monthlyProfit,
                    'د.ع',
                    Colors.blue,
                    Icons.account_balance,
                  ),
                  _buildKPICard(
                    'عدد المبيعات',
                    (data['sales_count'] as int? ?? 0).toDouble(),
                    'مبيعة',
                    Colors.orange,
                    Icons.shopping_cart,
                  ),
                  _buildKPICard(
                    'متوسط قيمة المبيعة',
                    avgSaleAmount,
                    'د.ع',
                    Colors.purple,
                    Icons.analytics,
                  ),
                  _buildKPICard(
                    'عملاء جدد',
                    newCustomers.toDouble(),
                    'عميل',
                    Colors.teal,
                    Icons.person_add,
                  ),
                  _buildKPICard(
                    'هامش الربح',
                    profitMargin,
                    '%',
                    Colors.indigo,
                    Icons.percent,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendAnalysisTab(DatabaseService db) {
    return FutureBuilder<Map<String, dynamic>>(
      future: db.getTrendAnalysis(_selectedMonths),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البيانات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final monthlyData = data['monthly_data'] as List<dynamic>? ?? [];
        final growthRate = data['growth_rate'] as double? ?? 0.0;
        final predictedRevenue = data['predicted_revenue'] as double? ?? 0.0;
        final trendDirection = data['trend_direction'] as String? ?? 'stable';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('تحليل الاتجاهات والتنبؤات', _selectedDate),
              const SizedBox(height: 20),

              // مؤشرات الاتجاه
              Row(
                children: [
                  Expanded(
                    child: _buildTrendCard(
                      'معدل النمو',
                      '${growthRate.toStringAsFixed(1)}%',
                      growthRate > 0
                          ? Colors.green
                          : growthRate < 0
                              ? Colors.red
                              : Colors.grey,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTrendCard(
                      'التنبؤ بالشهر القادم',
                      Formatters.currencyIQD(predictedRevenue),
                      Colors.blue,
                      Icons.visibility,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // مخطط الاتجاهات
              _buildTrendChart(monthlyData),

              const SizedBox(height: 20),

              // تفاصيل الاتجاه
              _buildTrendDetails(monthlyData, trendDirection),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxReportTab(DatabaseService db) {
    final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    return FutureBuilder<Map<String, dynamic>>(
      future: db.getTaxReport(startDate, endDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البيانات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final totalSales = data['total_sales'] as double? ?? 0.0;
        final totalProfit = data['total_profit'] as double? ?? 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('تقرير المبيعات', _selectedDate),
              const SizedBox(height: 20),

              // ملخص المبيعات
              _buildFinancialCard(
                'إجمالي المبيعات',
                totalSales,
                Colors.blue,
                Icons.receipt,
              ),

              _buildFinancialCard(
                'إجمالي الأرباح',
                totalProfit,
                Colors.green,
                Icons.trending_up,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportHeader(String title, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.assessment, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDateForDisplay(date),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(
      String title, double amount, Color color, IconData icon,
      {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isHighlight ? Border.all(color: color, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.currencyIQD(amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatKPIValue(double value, String unit) {
    // للأرقام (عدد العملاء، عدد المبيعات) - عرض بدون عملة
    if (unit == 'عميل' || unit == 'مبيعة') {
      return '${value.toInt()} $unit';
    }
    // للنسب المئوية - عرض بدون عملة
    if (unit == '%') {
      return '${value.toStringAsFixed(1)}%';
    }
    // للمبالغ المالية - عرض مع عملة (بدون تكرار)
    if (unit == 'د.ع') {
      return Formatters.currencyIQD(value);
    }
    // للحالات الأخرى
    return '${Formatters.currencyIQD(value)} $unit';
  }

  Widget _buildKPICard(
      String title, double value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _formatKPIValue(value, unit),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfitPieChart(
      double grossProfit, double expenses, double netProfit) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'توزيع الأرباح',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: grossProfit,
                    title: 'إجمالي الربح',
                    color: Colors.green,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: expenses,
                    title: 'المصروفات',
                    color: Colors.red,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSheetChart(
      double assets, double liabilities, double equity) {
    return Container(
      height: 450,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'الميزانية العمومية',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: [assets, liabilities, equity]
                        .reduce((a, b) => a > b ? a : b) *
                    1.3,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      const titles = ['الأصول', 'الخصوم', 'حقوق الملكية'];
                      return BarTooltipItem(
                        '${titles[group.x.toInt()]}\n${Formatters.currencyIQD(rod.toY)}',
                        const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const titles = ['الأصول', 'الخصوم', 'حقوق الملكية'];
                        const colors = [Colors.green, Colors.red, Colors.blue];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors[value.toInt()].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: colors[value.toInt()].withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              titles[value.toInt()],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colors[value.toInt()],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Container(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            Formatters.currencyIQD(value),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: assets,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.green.shade300,
                            Colors.green.shade600,
                          ],
                        ),
                        width: 30,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: liabilities,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.red.shade300,
                            Colors.red.shade600,
                          ],
                        ),
                        width: 30,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: equity,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.blue.shade300,
                            Colors.blue.shade600,
                          ],
                        ),
                        width: 30,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<dynamic> monthlyData) {
    if (monthlyData.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('لا توجد بيانات للعرض'),
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'اتجاه المبيعات الشهرية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() < monthlyData.length) {
                          final month =
                              monthlyData[value.toInt()]['month'] as String? ??
                                  '';
                          return Text(
                            month.substring(5), // عرض الشهر فقط
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          Formatters.currencyIQD(value),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final revenue = data['total_revenue'] as double? ?? 0.0;
                      return FlSpot(index.toDouble(), revenue);
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendDetails(List<dynamic> monthlyData, String trendDirection) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحليل الاتجاه',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                trendDirection == 'up'
                    ? Icons.trending_up
                    : trendDirection == 'down'
                        ? Icons.trending_down
                        : Icons.trending_flat,
                color: trendDirection == 'up'
                    ? Colors.green
                    : trendDirection == 'down'
                        ? Colors.red
                        : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                trendDirection == 'up'
                    ? 'اتجاه صاعد'
                    : trendDirection == 'down'
                        ? 'اتجاه هابط'
                        : 'اتجاه مستقر',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: trendDirection == 'up'
                      ? Colors.green
                      : trendDirection == 'down'
                          ? Colors.red
                          : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'عدد الأشهر المحللة: ${monthlyData.length}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('d - M - yyyy', 'ar').format(date);
  }

  String _formatDateForFilename(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _exportCurrentTab(DatabaseService db) async {
    final currentIndex = _tabController.index;
    String? savedPath;

    try {
      switch (currentIndex) {
        case 0: // قائمة الدخل
          savedPath = await _exportIncomeStatement(db);
          break;
        case 1: // الميزانية
          savedPath = await _exportBalanceSheet(db);
          break;
        case 2: // مؤشرات الأداء
          savedPath = await _exportKPIs(db);
          break;
        case 3: // تحليل الاتجاهات
          savedPath = await _exportTrendAnalysis(db);
          break;
        case 4: // تقرير المبيعات
          savedPath = await _exportSalesReport(db);
          break;
      }

      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ التقرير في: $savedPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التصدير: $e')),
        );
      }
    }
  }

  Future<String?> _exportIncomeStatement(DatabaseService db) async {
    final data = await db.getIncomeStatement(_selectedDate);
    final items = <MapEntry<String, String>>[
      MapEntry('الإيرادات', Formatters.currencyIQD(data['revenue'] ?? 0.0)),
      MapEntry(
          'تكلفة البضائع المباعة', Formatters.currencyIQD(data['cogs'] ?? 0.0)),
      MapEntry(
          'إجمالي الربح', Formatters.currencyIQD(data['gross_profit'] ?? 0.0)),
      MapEntry('المصروفات', Formatters.currencyIQD(data['expenses'] ?? 0.0)),
      MapEntry('صافي الربح', Formatters.currencyIQD(data['net_profit'] ?? 0.0)),
    ];

    final dateStr = _formatDateForFilename(_selectedDate);
    return await PdfExporter.exportKeyValue(
      filename: 'قائمة_الدخل_$dateStr.pdf',
      title: 'قائمة الدخل - ${_formatDateForDisplay(_selectedDate)}',
      items: items,
    );
  }

  Future<String?> _exportBalanceSheet(DatabaseService db) async {
    final data = await db.getBalanceSheet(_selectedDate);
    final items = <MapEntry<String, String>>[
      MapEntry('الأصول', Formatters.currencyIQD(data['assets'] ?? 0.0)),
      MapEntry('الخصوم', Formatters.currencyIQD(data['liabilities'] ?? 0.0)),
      MapEntry('حقوق الملكية', Formatters.currencyIQD(data['equity'] ?? 0.0)),
    ];

    final dateStr = _formatDateForFilename(_selectedDate);
    return await PdfExporter.exportKeyValue(
      filename: 'الميزانية_العمومية_$dateStr.pdf',
      title: 'الميزانية العمومية - ${_formatDateForDisplay(_selectedDate)}',
      items: items,
    );
  }

  Future<String?> _exportKPIs(DatabaseService db) async {
    final data = await db.getKPIs(_selectedDate);
    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المبيعات',
          Formatters.currencyIQD(data['monthly_revenue'] ?? 0.0)),
      MapEntry(
          'صافي الربح', Formatters.currencyIQD(data['monthly_profit'] ?? 0.0)),
      MapEntry('عدد المبيعات', '${data['sales_count'] ?? 0} مبيعة'),
      MapEntry('متوسط قيمة المبيعة',
          Formatters.currencyIQD(data['avg_sale_amount'] ?? 0.0)),
      MapEntry('عملاء جدد', '${data['new_customers'] ?? 0} عميل'),
      MapEntry('هامش الربح',
          '${(data['profit_margin'] ?? 0.0).toStringAsFixed(1)}%'),
    ];

    final dateStr = _formatDateForFilename(_selectedDate);
    return await PdfExporter.exportKeyValue(
      filename: 'مؤشرات_الأداء_$dateStr.pdf',
      title: 'مؤشرات الأداء - ${_formatDateForDisplay(_selectedDate)}',
      items: items,
    );
  }

  Future<String?> _exportTrendAnalysis(DatabaseService db) async {
    final data = await db.getTrendAnalysis(_selectedMonths);
    final monthlyData = data['monthly_data'] as List<dynamic>? ?? [];

    final rows = <List<String>>[
      ['الشهر', 'الإيرادات', 'الأرباح', 'عدد المبيعات'],
      ...monthlyData.map((month) => [
            month['month'] as String? ?? '',
            Formatters.currencyIQD(month['revenue'] ?? 0.0),
            Formatters.currencyIQD(month['profit'] ?? 0.0),
            '${month['sales_count'] ?? 0}',
          ]),
    ];

    return await PdfExporter.exportDataTable(
      filename: 'تحليل_الاتجاهات_${_selectedMonths}_شهر.pdf',
      title: 'تحليل الاتجاهات - آخر $_selectedMonths أشهر',
      headers: ['الشهر', 'الإيرادات', 'الأرباح', 'عدد المبيعات'],
      rows: rows,
    );
  }

  Future<String?> _exportSalesReport(DatabaseService db) async {
    final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final data = await db.getTaxReport(startDate, endDate);

    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المبيعات',
          Formatters.currencyIQD(data['total_sales'] ?? 0.0)),
      MapEntry('إجمالي الأرباح',
          Formatters.currencyIQD(data['total_profit'] ?? 0.0)),
    ];

    final dateStr = _formatDateForFilename(_selectedDate);
    return await PdfExporter.exportKeyValue(
      filename: 'تقرير_المبيعات_$dateStr.pdf',
      title: 'تقرير المبيعات - ${_formatDateForDisplay(_selectedDate)}',
      items: items,
    );
  }

  // دالة الطباعة
  Future<void> _printCurrentTab(DatabaseService db) async {
    final currentIndex = _tabController.index;
    final storeConfig = context.read<StoreConfig>();

    try {
      switch (currentIndex) {
        case 0: // قائمة الدخل
          await _printIncomeStatement(db, storeConfig);
          break;
        case 1: // الميزانية
          await _printBalanceSheet(db, storeConfig);
          break;
        case 2: // مؤشرات الأداء
          await _printKPIs(db, storeConfig);
          break;
        case 3: // تحليل الاتجاهات
          await _printTrendAnalysis(db, storeConfig);
          break;
        case 4: // تقرير المبيعات
          await _printSalesReport(db, storeConfig);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الطباعة: $e')),
        );
      }
    }
  }

  Future<void> _printIncomeStatement(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getIncomeStatement(_selectedDate);
    final items = <MapEntry<String, String>>[
      MapEntry('الإيرادات', Formatters.currencyIQD(data['revenue'] ?? 0.0)),
      MapEntry(
          'تكلفة البضائع المباعة', Formatters.currencyIQD(data['cogs'] ?? 0.0)),
      MapEntry(
          'إجمالي الربح', Formatters.currencyIQD(data['gross_profit'] ?? 0.0)),
      MapEntry('المصروفات', Formatters.currencyIQD(data['expenses'] ?? 0.0)),
      MapEntry('صافي الربح', Formatters.currencyIQD(data['net_profit'] ?? 0.0)),
    ];

    await PrintService.printFinancialReport(
      reportType: 'قائمة_الدخل',
      title: 'قائمة الدخل',
      items: items,
      reportDate: _selectedDate,
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }

  Future<void> _printBalanceSheet(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getBalanceSheet(_selectedDate);
    final items = <MapEntry<String, String>>[
      MapEntry('الأصول', Formatters.currencyIQD(data['assets'] ?? 0.0)),
      MapEntry('الخصوم', Formatters.currencyIQD(data['liabilities'] ?? 0.0)),
      MapEntry('حقوق الملكية', Formatters.currencyIQD(data['equity'] ?? 0.0)),
    ];

    await PrintService.printFinancialReport(
      reportType: 'الميزانية_العمومية',
      title: 'الميزانية العمومية',
      items: items,
      reportDate: _selectedDate,
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }

  Future<void> _printKPIs(DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getKPIs(_selectedDate);
    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المبيعات',
          Formatters.currencyIQD(data['monthly_revenue'] ?? 0.0)),
      MapEntry(
          'صافي الربح', Formatters.currencyIQD(data['monthly_profit'] ?? 0.0)),
      MapEntry('عدد المبيعات', '${data['sales_count'] ?? 0} مبيعة'),
      MapEntry('متوسط قيمة المبيعة',
          Formatters.currencyIQD(data['avg_sale_amount'] ?? 0.0)),
      MapEntry('عملاء جدد', '${data['new_customers'] ?? 0} عميل'),
      MapEntry('هامش الربح',
          '${(data['profit_margin'] ?? 0.0).toStringAsFixed(1)}%'),
      MapEntry('معدل التحويل',
          '${(data['conversion_rate'] ?? 0.0).toStringAsFixed(1)}%'),
    ];

    await PrintService.printFinancialReport(
      reportType: 'مؤشرات_الأداء',
      title: 'مؤشرات الأداء',
      items: items,
      reportDate: _selectedDate,
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }

  Future<void> _printTrendAnalysis(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getTrendAnalysis(_selectedMonths);
    final monthlyData = data['monthly_data'] as List<dynamic>? ?? [];

    final headers = ['الشهر', 'الإيرادات', 'الأرباح', 'عدد المبيعات'];
    final rows = monthlyData
        .map((month) => [
              month['month'] as String? ?? '',
              Formatters.currencyIQD(month['revenue'] ?? 0.0),
              Formatters.currencyIQD(month['profit'] ?? 0.0),
              '${month['sales_count'] ?? 0}',
            ])
        .toList();

    await PrintService.printTableReport(
      reportType: 'تحليل_الاتجاهات',
      title: 'تحليل الاتجاهات - آخر $_selectedMonths أشهر',
      headers: headers,
      rows: rows,
      reportDate: _selectedDate,
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }

  Future<void> _printSalesReport(
      DatabaseService db, StoreConfig storeConfig) async {
    final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final data = await db.getTaxReport(startDate, endDate);

    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المبيعات',
          Formatters.currencyIQD(data['total_sales'] ?? 0.0)),
      MapEntry('إجمالي الأرباح',
          Formatters.currencyIQD(data['total_profit'] ?? 0.0)),
    ];

    await PrintService.printFinancialReport(
      reportType: 'تقرير_المبيعات',
      title: 'تقرير المبيعات',
      items: items,
      reportDate: _selectedDate,
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }
}
