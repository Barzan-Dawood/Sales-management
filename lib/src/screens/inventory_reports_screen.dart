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

class InventoryReportsScreen extends StatefulWidget {
  const InventoryReportsScreen({super.key});

  @override
  State<InventoryReportsScreen> createState() => _InventoryReportsScreenState();
}

class _InventoryReportsScreenState extends State<InventoryReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير الجرد الشاملة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'تصدير PDF',
            onPressed: () => _exportCurrentTab(),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'طباعة التقرير',
            onPressed: () => _printCurrentTab(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printReport,
            tooltip: 'طباعة التقرير',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'ملخص الجرد', icon: Icon(Icons.inventory)),
            Tab(text: 'الأكثر مبيعاً', icon: Icon(Icons.trending_up)),
            Tab(text: 'بطيء الحركة', icon: Icon(Icons.trending_down)),
            Tab(text: 'تحليل المخزون', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInventorySummaryTab(),
          _buildTopSellingTab(),
          _buildSlowMovingTab(),
          _buildInventoryAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildInventorySummaryTab() {
    final db = context.read<DatabaseService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: db.getInventoryReport(),
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
        final totalProducts = data['total_products'] as int? ?? 0;
        final totalQuantity = data['total_quantity'] as int? ?? 0;
        final totalValue = data['total_value'] as double? ?? 0.0;
        final totalCost = data['total_cost'] as double? ?? 0.0;
        final inventoryTurnover = data['inventory_turnover'] as double? ?? 0.0;
        final lowStockCount = data['low_stock_count'] as int? ?? 0;
        final outOfStockCount = data['out_of_stock_count'] as int? ?? 0;

        // إذا كانت البيانات فارغة، اعرض رسالة توضيحية
        if (totalProducts == 0 && totalQuantity == 0 && totalValue == 0.0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'لا توجد منتجات في المخزون',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'قم بإضافة منتجات لرؤية تقارير الجرد',
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
              _buildReportHeader('ملخص الجرد الشامل'),
              const SizedBox(height: 20),

              // مؤشرات الجرد الرئيسية
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceCard(
                      'إجمالي المنتجات',
                      totalProducts.toString(),
                      'منتج',
                      Colors.blue,
                      Icons.inventory,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPerformanceCard(
                      'إجمالي الكمية',
                      totalQuantity.toString(),
                      'وحدة',
                      Colors.green,
                      Icons.shopping_cart,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceCard(
                      'القيمة الإجمالية',
                      Formatters.currencyIQD(totalValue),
                      '',
                      Colors.orange,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPerformanceCard(
                      'التكلفة الإجمالية',
                      Formatters.currencyIQD(totalCost),
                      '',
                      Colors.red,
                      Icons.money_off,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // مؤشرات الأداء
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceCard(
                      'معدل دوران المخزون',
                      inventoryTurnover.toStringAsFixed(2),
                      'مرة',
                      Colors.purple,
                      Icons.rotate_right,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPerformanceCard(
                      'منخفض الكمية',
                      lowStockCount.toString(),
                      'منتج',
                      Colors.amber,
                      Icons.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceCard(
                      'نفد من المخزون',
                      outOfStockCount.toString(),
                      'منتج',
                      Colors.red,
                      Icons.error,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPerformanceCard(
                      'هامش الربح',
                      totalValue > 0
                          ? '${((totalValue - totalCost) / totalValue * 100).toStringAsFixed(1)}%'
                          : '0%',
                      '',
                      Colors.green,
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // مخطط توزيع المخزون
              _buildInventoryDistributionChart(
                  totalValue, totalCost, lowStockCount, outOfStockCount),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSellingTab() {
    final db = context.read<DatabaseService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: db.getInventoryReport(),
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
        final topSellingProducts =
            data['top_selling_products'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('المنتجات الأكثر مبيعاً (آخر 30 يوم)'),
              const SizedBox(height: 20),
              if (topSellingProducts.isEmpty)
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد بيانات مبيعات في آخر 30 يوم',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                _buildTopSellingTable(topSellingProducts),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlowMovingTab() {
    final db = context.read<DatabaseService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: db.getInventoryReport(),
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
        final slowMovingProducts =
            data['slow_moving_products'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('المنتجات بطيئة الحركة (آخر 90 يوم)'),
              const SizedBox(height: 20),
              if (slowMovingProducts.isEmpty)
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.trending_down, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'جميع المنتجات تتحرك بشكل جيد',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                _buildSlowMovingTable(slowMovingProducts),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryAnalysisTab() {
    final db = context.read<DatabaseService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: db.getInventoryReport(),
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
        final totalValue = data['total_value'] as double? ?? 0.0;
        final totalCost = data['total_cost'] as double? ?? 0.0;
        final lowStockCount = data['low_stock_count'] as int? ?? 0;
        final outOfStockCount = data['out_of_stock_count'] as int? ?? 0;
        final totalProducts = data['total_products'] as int? ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('تحليل المخزون المتقدم'),
              const SizedBox(height: 20),

              // تحليل القيمة
              _buildAnalysisCard(
                'تحليل القيمة',
                [
                  'القيمة الإجمالية: ${Formatters.currencyIQD(totalValue)}',
                  'التكلفة الإجمالية: ${Formatters.currencyIQD(totalCost)}',
                  'الربح المحتمل: ${Formatters.currencyIQD(totalValue - totalCost)}',
                  'هامش الربح: ${totalValue > 0 ? ((totalValue - totalCost) / totalValue * 100).toStringAsFixed(1) : 0}%',
                ],
                Colors.blue,
                Icons.account_balance_wallet,
              ),

              const SizedBox(height: 16),

              // تحليل الكمية
              _buildAnalysisCard(
                'تحليل الكمية',
                [
                  'إجمالي المنتجات: $totalProducts',
                  'منخفض الكمية: $lowStockCount (${totalProducts > 0 ? (lowStockCount / totalProducts * 100).toStringAsFixed(1) : 0}%)',
                  'نفد من المخزون: $outOfStockCount (${totalProducts > 0 ? (outOfStockCount / totalProducts * 100).toStringAsFixed(1) : 0}%)',
                  'مخزون صحي: ${totalProducts - lowStockCount - outOfStockCount}',
                ],
                Colors.green,
                Icons.inventory,
              ),

              const SizedBox(height: 20),

              // مخطط تحليل المخزون
              _buildInventoryAnalysisChart(
                  totalProducts, lowStockCount, outOfStockCount),

              const SizedBox(height: 20),

              // توصيات
              _buildRecommendationsCard(
                  lowStockCount, outOfStockCount, totalProducts),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory, color: Colors.white, size: 32),
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
                  _formatDateForDisplay(DateTime.now()),
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

  Widget _buildPerformanceCard(
      String title, String value, String unit, Color color, IconData icon) {
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$value $unit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
      String title, List<String> items, Color color, IconData icon) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTopSellingTable(List<dynamic> products) {
    return Container(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('المنتج')),
            DataColumn(label: Text('الباركود')),
            DataColumn(label: Text('الكمية المباعة')),
            DataColumn(label: Text('إجمالي الإيرادات')),
          ],
          rows: products.map((product) {
            return DataRow(
              cells: [
                DataCell(Text(product['name'] as String? ?? '')),
                DataCell(Text(product['barcode'] as String? ?? '')),
                DataCell(Text('${product['total_sold']}')),
                DataCell(Text(Formatters.currencyIQD(
                    product['total_revenue'] as double? ?? 0.0))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSlowMovingTable(List<dynamic> products) {
    return Container(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('المنتج')),
            DataColumn(label: Text('الباركود')),
            DataColumn(label: Text('الكمية المتاحة')),
            DataColumn(label: Text('السعر')),
            DataColumn(label: Text('التكلفة')),
          ],
          rows: products.map((product) {
            return DataRow(
              cells: [
                DataCell(Text(product['name'] as String? ?? '')),
                DataCell(Text(product['barcode'] as String? ?? '')),
                DataCell(Text('${product['quantity']}')),
                DataCell(Text(Formatters.currencyIQD(
                    product['price'] as double? ?? 0.0))),
                DataCell(Text(
                    Formatters.currencyIQD(product['cost'] as double? ?? 0.0))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInventoryDistributionChart(
      double totalValue, double totalCost, int lowStock, int outOfStock) {
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
            'توزيع قيمة المخزون',
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
                    value: totalCost,
                    title: 'التكلفة',
                    color: Colors.red,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: totalValue - totalCost,
                    title: 'الربح',
                    color: Colors.green,
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

  Widget _buildInventoryAnalysisChart(
      int totalProducts, int lowStock, int outOfStock) {
    final healthyStock = totalProducts - lowStock - outOfStock;

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
            'تحليل حالة المخزون',
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
                    value: healthyStock.toDouble(),
                    title: 'مخزون صحي',
                    color: Colors.green,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: lowStock.toDouble(),
                    title: 'منخفض الكمية',
                    color: Colors.orange,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: outOfStock.toDouble(),
                    title: 'نفد من المخزون',
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

  Widget _buildRecommendationsCard(
      int lowStock, int outOfStock, int totalProducts) {
    final recommendations = <String>[];

    if (outOfStock > 0) {
      recommendations.add('إعادة توريد $outOfStock منتج نفد من المخزون فوراً');
    }

    if (lowStock > 0) {
      recommendations.add('مراجعة $lowStock منتج منخفض الكمية');
    }

    if (recommendations.isEmpty) {
      recommendations.add('المخزون في حالة ممتازة');
    }

    recommendations.add('مراجعة دورية للمخزون كل أسبوع');
    recommendations.add('تحديد مستويات إعادة التوريد لكل منتج');

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
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'التوصيات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ميزة الطباعة قيد التطوير'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('d - M - yyyy', 'ar').format(date);
  }

  String _formatDateForFilename(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _exportCurrentTab() async {
    final currentIndex = _tabController.index;
    final db = context.read<DatabaseService>();
    String? savedPath;

    try {
      switch (currentIndex) {
        case 0: // ملخص الجرد
          savedPath = await _exportInventorySummary(db);
          break;
        case 1: // الأكثر مبيعاً
          savedPath = await _exportTopSelling(db);
          break;
        case 2: // بطيء الحركة
          savedPath = await _exportSlowMoving(db);
          break;
        case 3: // تحليل المخزون
          savedPath = await _exportInventoryAnalysis(db);
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

  Future<String?> _exportInventorySummary(DatabaseService db) async {
    final data = await db.getInventoryReport();
    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المنتجات', '${data['total_products'] ?? 0} منتج'),
      MapEntry('إجمالي الكمية', '${data['total_quantity'] ?? 0} وحدة'),
      MapEntry('القيمة الإجمالية',
          Formatters.currencyIQD(data['total_value'] ?? 0.0)),
      MapEntry('التكلفة الإجمالية',
          Formatters.currencyIQD(data['total_cost'] ?? 0.0)),
      MapEntry('معدل دوران المخزون',
          '${(data['inventory_turnover'] ?? 0.0).toStringAsFixed(2)} مرة'),
      MapEntry('منخفض الكمية', '${data['low_stock_count'] ?? 0} منتج'),
      MapEntry('نفد من المخزون', '${data['out_of_stock_count'] ?? 0} منتج'),
      MapEntry('هامش الربح',
          '${(data['profit_margin'] ?? 0.0).toStringAsFixed(1)}%'),
    ];

    final now = DateTime.now();
    final dateStr = _formatDateForFilename(now);
    return await PdfExporter.exportKeyValue(
      filename: 'ملخص_الجرد_$dateStr.pdf',
      title: 'ملخص الجرد الشامل - ${_formatDateForDisplay(now)}',
      items: items,
    );
  }

  Future<String?> _exportTopSelling(DatabaseService db) async {
    final data = await db.getInventoryReport();
    final topSelling = data['top_selling_products'] as List<dynamic>? ?? [];

    final rows = <List<String>>[
      ['المنتج', 'الكمية المباعة', 'القيمة'],
      ...topSelling.map((product) => [
            product['name'] as String? ?? '',
            '${product['total_sold'] ?? 0}',
            Formatters.currencyIQD(product['total_revenue'] ?? 0.0),
          ]),
    ];

    final now = DateTime.now();
    final dateStr = _formatDateForFilename(now);
    return await PdfExporter.exportDataTable(
      filename: 'الأكثر_مبيعاً_$dateStr.pdf',
      title: 'المنتجات الأكثر مبيعاً - ${_formatDateForDisplay(now)}',
      headers: ['المنتج', 'الكمية المباعة', 'القيمة'],
      rows: rows,
    );
  }

  Future<String?> _exportSlowMoving(DatabaseService db) async {
    final data = await db.getInventoryReport();
    final slowMoving = data['slow_moving_products'] as List<dynamic>? ?? [];

    final rows = <List<String>>[
      ['المنتج', 'الباركود', 'الكمية المتاحة', 'السعر', 'التكلفة'],
      ...slowMoving.map((product) => [
            product['name'] as String? ?? '',
            product['barcode'] as String? ?? '',
            '${product['quantity'] ?? 0}',
            Formatters.currencyIQD(product['price'] ?? 0.0),
            Formatters.currencyIQD(product['cost'] ?? 0.0),
          ]),
    ];

    final now = DateTime.now();
    final dateStr = _formatDateForFilename(now);
    return await PdfExporter.exportDataTable(
      filename: 'بطيء_الحركة_$dateStr.pdf',
      title: 'المنتجات بطيئة الحركة - ${_formatDateForDisplay(now)}',
      headers: ['المنتج', 'الباركود', 'الكمية المتاحة', 'السعر', 'التكلفة'],
      rows: rows,
    );
  }

  Future<String?> _exportInventoryAnalysis(DatabaseService db) async {
    final data = await db.getInventoryReport();
    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المنتجات', '${data['total_products'] ?? 0} منتج'),
      MapEntry('إجمالي الكمية', '${data['total_quantity'] ?? 0} وحدة'),
      MapEntry('القيمة الإجمالية',
          Formatters.currencyIQD(data['total_value'] ?? 0.0)),
      MapEntry('التكلفة الإجمالية',
          Formatters.currencyIQD(data['total_cost'] ?? 0.0)),
      MapEntry('معدل دوران المخزون',
          '${(data['inventory_turnover'] ?? 0.0).toStringAsFixed(2)} مرة'),
      MapEntry('منخفض الكمية', '${data['low_stock_count'] ?? 0} منتج'),
      MapEntry('نفد من المخزون', '${data['out_of_stock_count'] ?? 0} منتج'),
      MapEntry('هامش الربح',
          '${(data['profit_margin'] ?? 0.0).toStringAsFixed(1)}%'),
    ];

    final now = DateTime.now();
    final dateStr = _formatDateForFilename(now);
    return await PdfExporter.exportKeyValue(
      filename: 'تحليل_المخزون_$dateStr.pdf',
      title: 'تحليل المخزون الشامل - ${_formatDateForDisplay(now)}',
      items: items,
    );
  }

  // دالة الطباعة
  Future<void> _printCurrentTab() async {
    final currentIndex = _tabController.index;
    final db = context.read<DatabaseService>();
    final storeConfig = context.read<StoreConfig>();

    try {
      switch (currentIndex) {
        case 0: // ملخص الجرد
          await _printInventorySummary(db, storeConfig);
          break;
        case 1: // الأكثر مبيعاً
          await _printTopSelling(db, storeConfig);
          break;
        case 2: // بطيء الحركة
          await _printSlowMoving(db, storeConfig);
          break;
        case 3: // تحليل المخزون
          await _printInventoryAnalysis(db, storeConfig);
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

  Future<void> _printInventorySummary(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getInventoryReport();
    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المنتجات', '${data['total_products'] ?? 0} منتج'),
      MapEntry('إجمالي الكمية', '${data['total_quantity'] ?? 0} وحدة'),
      MapEntry('القيمة الإجمالية',
          Formatters.currencyIQD(data['total_value'] ?? 0.0)),
      MapEntry('التكلفة الإجمالية',
          Formatters.currencyIQD(data['total_cost'] ?? 0.0)),
      MapEntry('معدل دوران المخزون',
          '${(data['inventory_turnover'] ?? 0.0).toStringAsFixed(2)} مرة'),
      MapEntry('منخفض الكمية', '${data['low_stock_count'] ?? 0} منتج'),
      MapEntry('نفد من المخزون', '${data['out_of_stock_count'] ?? 0} منتج'),
    ];

    await PrintService.printInventoryReport(
      reportType: 'ملخص_الجرد',
      title: 'ملخص الجرد الشامل',
      items: items,
      reportDate: DateTime.now(),
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }

  Future<void> _printTopSelling(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getInventoryReport();
    final topSelling = data['top_selling_products'] as List<dynamic>? ?? [];

    final headers = ['المنتج', 'الكمية المباعة', 'القيمة'];
    final rows = topSelling
        .map((product) => [
              product['name'] as String? ?? '',
              '${product['total_sold'] ?? 0}',
              Formatters.currencyIQD(product['total_revenue'] ?? 0.0),
            ])
        .toList();

    await PrintService.printTableReport(
      reportType: 'الأكثر_مبيعاً',
      title: 'المنتجات الأكثر مبيعاً',
      headers: headers,
      rows: rows,
      reportDate: DateTime.now(),
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }

  Future<void> _printSlowMoving(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getInventoryReport();
    final slowMoving = data['slow_moving_products'] as List<dynamic>? ?? [];

    final headers = [
      'المنتج',
      'الباركود',
      'الكمية المتاحة',
      'السعر',
      'التكلفة'
    ];
    final rows = slowMoving
        .map((product) => [
              product['name'] as String? ?? '',
              product['barcode'] as String? ?? '',
              '${product['quantity'] ?? 0}',
              Formatters.currencyIQD(product['price'] ?? 0.0),
              Formatters.currencyIQD(product['cost'] ?? 0.0),
            ])
        .toList();

    await PrintService.printTableReport(
      reportType: 'بطيء_الحركة',
      title: 'المنتجات بطيئة الحركة',
      headers: headers,
      rows: rows,
      reportDate: DateTime.now(),
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }

  Future<void> _printInventoryAnalysis(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getInventoryReport();
    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المنتجات', '${data['total_products'] ?? 0} منتج'),
      MapEntry('إجمالي الكمية', '${data['total_quantity'] ?? 0} وحدة'),
      MapEntry('القيمة الإجمالية',
          Formatters.currencyIQD(data['total_value'] ?? 0.0)),
      MapEntry('التكلفة الإجمالية',
          Formatters.currencyIQD(data['total_cost'] ?? 0.0)),
      MapEntry('معدل دوران المخزون',
          '${(data['inventory_turnover'] ?? 0.0).toStringAsFixed(2)} مرة'),
      MapEntry('منخفض الكمية', '${data['low_stock_count'] ?? 0} منتج'),
      MapEntry('نفد من المخزون', '${data['out_of_stock_count'] ?? 0} منتج'),
      MapEntry('هامش الربح',
          '${(data['profit_margin'] ?? 0.0).toStringAsFixed(1)}%'),
    ];

    await PrintService.printInventoryReport(
      reportType: 'تحليل_المخزون',
      title: 'تحليل المخزون الشامل',
      items: items,
      reportDate: DateTime.now(),
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }
}
