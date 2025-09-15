// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../utils/format.dart';
import '../services/store_config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  double _todaySales = 0;
  double _todayProfit = 0;
  int _lowStockCount = 0;
  int _totalProducts = 0;
  int _availableProductsCount = 0;
  int _totalProductQuantity = 0;
  int _totalCustomers = 0;
  int _totalSuppliers = 0;
  double _monthlySales = 0;
  double _monthlyProfit = 0;
  double _totalDebt = 0;
  double _overdueDebt = 0;
  int _customersWithDebt = 0;
  List<Map<String, dynamic>> _recentSales = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _lowStockProducts = [];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _loadStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final db = context.read<DatabaseService>().database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final currentMonth = DateTime.now().toIso8601String().substring(0, 7);

    // اليوم
    final todaySales = await db.rawQuery(
        "SELECT IFNULL(SUM(total),0) as t, IFNULL(SUM(profit),0) as p FROM sales WHERE substr(created_at,1,10)=?",
        [today]);

    // الشهر
    final monthSales = await db.rawQuery(
        "SELECT IFNULL(SUM(total),0) as t, IFNULL(SUM(profit),0) as p FROM sales WHERE substr(created_at,1,7)=?",
        [currentMonth]);

    // إحصائيات عامة
    final products = await db.rawQuery("SELECT COUNT(*) as c FROM products");
    final availableProducts = await db
        .rawQuery("SELECT COUNT(*) as c FROM products WHERE quantity > 0");
    final totalQty =
        await db.rawQuery("SELECT IFNULL(SUM(quantity),0) as q FROM products");
    final customers = await db.rawQuery("SELECT COUNT(*) as c FROM customers");
    final suppliers = await db.rawQuery("SELECT COUNT(*) as c FROM suppliers");
    final lowStock = await db.rawQuery(
        "SELECT COUNT(*) as c FROM products WHERE quantity <= min_quantity");

    // آخر المنتجات المباعة
    final recentSales = await db.rawQuery('''
      SELECT p.name, p.price, si.quantity, si.price as sale_price, s.created_at
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      JOIN sales s ON si.sale_id = s.id
      ORDER BY s.created_at DESC 
      LIMIT 8
    ''');

    // المنتجات الأكثر مبيعاً
    final topProducts = await db.rawQuery(
        "SELECT p.name, p.quantity, p.price FROM products p ORDER BY p.quantity DESC LIMIT 5");

    // المنتجات منخفضة المخزون
    final lowStockProducts = await db.rawQuery(
        "SELECT name, quantity, min_quantity FROM products WHERE quantity <= min_quantity LIMIT 5");

    // إحصائيات الديون
    final debtStats = await context.read<DatabaseService>().getDebtStatistics();

    if (mounted) {
      setState(() {
        _todaySales = (todaySales.first['t'] as num).toDouble();
        _todayProfit = (todaySales.first['p'] as num).toDouble();
        _monthlySales = (monthSales.first['t'] as num).toDouble();
        _monthlyProfit = (monthSales.first['p'] as num).toDouble();
        _totalProducts = (products.first['c'] as int);
        _availableProductsCount = (availableProducts.first['c'] as int);
        _totalProductQuantity = (totalQty.first['q'] as num).toInt();
        _totalCustomers = (customers.first['c'] as int);
        _totalSuppliers = (suppliers.first['c'] as int);
        _lowStockCount = (lowStock.first['c'] as int);
        _recentSales = recentSales;
        _topProducts = topProducts;
        _lowStockProducts = lowStockProducts;
        _totalDebt = debtStats['total_debt']!;
        _overdueDebt = debtStats['overdue_debt']!;
        _customersWithDebt = debtStats['customers_with_debt']!.toInt();
      });

      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(),
                const SizedBox(height: 32),

                // Stats Cards
                _buildStatsSection(),
                const SizedBox(height: 32),

                // Charts Section
                _buildChartsSection(),
                const SizedBox(height: 32),

                // Bottom Section
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.purple.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك في لوحة التحكم ${context.watch<StoreConfig>().shopName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'نظرة شاملة على أداء متجرك',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              DateTime.now().toString().substring(0, 10),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإحصائيات السريعة',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.0,
          children: [
            _buildStatCard(
              'مبيعات اليوم',
              Formatters.currencyIQD(_todaySales),
              Icons.trending_up,
              Colors.green,
              Colors.green.shade50,
            ),
            _buildStatCard(
              'ربح اليوم',
              Formatters.currencyIQD(_todayProfit),
              Icons.monetization_on,
              Colors.blue,
              Colors.blue.shade50,
            ),
            _buildStatCard(
              'مبيعات الشهر',
              Formatters.currencyIQD(_monthlySales),
              Icons.calendar_month,
              Colors.purple,
              Colors.purple.shade50,
            ),
            _buildStatCard(
              'ربح الشهر',
              Formatters.currencyIQD(_monthlyProfit),
              Icons.account_balance_wallet,
              Colors.orange,
              Colors.orange.shade50,
            ),
            _buildStatCard(
              'إجمالي المنتجات',
              '$_totalProducts',
              Icons.inventory_2,
              Colors.indigo,
              Colors.indigo.shade50,
            ),
            _buildStatCard(
              'إجمالي الكمية في المخزون',
              '$_totalProductQuantity',
              Icons.warehouse,
              Colors.brown,
              Colors.brown.shade50,
            ),
            _buildStatCard(
              'عدد المنتجات المتوفرة',
              '$_availableProductsCount',
              Icons.inventory,
              Colors.deepPurple,
              Colors.deepPurple.shade50,
            ),
            _buildStatCard(
              'العملاء',
              '$_totalCustomers',
              Icons.people,
              Colors.teal,
              Colors.teal.shade50,
            ),
            _buildStatCard(
              'الموردون',
              '$_totalSuppliers',
              Icons.local_shipping,
              Colors.cyan,
              Colors.cyan.shade50,
            ),
            _buildStatCard(
              'تنبيهات المخزون',
              '$_lowStockCount',
              Icons.warning,
              Colors.red,
              Colors.red.shade50,
            ),
            _buildStatCard(
              'إجمالي الديون',
              Formatters.currencyIQD(_totalDebt),
              Icons.account_balance_wallet,
              Colors.deepOrange,
              Colors.deepOrange.shade50,
            ),
            _buildStatCard(
              'ديون متأخرة',
              Formatters.currencyIQD(_overdueDebt),
              Icons.warning_amber,
              Colors.red,
              Colors.red.shade50,
            ),
            _buildStatCard(
              'عملاء مدينون',
              '$_customersWithDebt',
              Icons.people_outline,
              Colors.amber,
              Colors.amber.shade50,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
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
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.3),
                        color.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: color.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  color: color.withOpacity(0.7),
                  size: 12,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 1),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildSalesChart(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildTopProductsChart(),
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'مبيعات الأسبوع',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
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
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const days = [
                          'أحد',
                          'اثنين',
                          'ثلاثاء',
                          'أربعاء',
                          'خميس',
                          'جمعة',
                          'سبت'
                        ];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toInt()}K',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(1, 2),
                      const FlSpot(2, 5),
                      const FlSpot(3, 3.1),
                      const FlSpot(4, 4),
                      const FlSpot(5, 3),
                      const FlSpot(6, 4),
                    ],
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blue.shade600,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400.withOpacity(0.3),
                          Colors.purple.shade400.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أفضل المنتجات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: _topProducts.length,
              itemBuilder: (context, index) {
                final product = _topProducts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: Colors.blue.shade600,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name']?.toString() ?? 'منتج',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              'الكمية: ${product['quantity']}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          Formatters.currencyIQD(
                              (product['price'] as num?) ?? 0),
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildRecentSales(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildLowStockAlert(),
        ),
      ],
    );
  }

  Widget _buildRecentSales() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'آخر المنتجات المباعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: _recentSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات مباعة حديثاً',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _recentSales.length,
                    itemBuilder: (context, index) {
                      final product = _recentSales[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: Colors.green.shade600,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name']?.toString() ?? 'منتج',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'الكمية: ${product['quantity']}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        product['created_at']
                                                ?.toString()
                                                .substring(0, 16) ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                Formatters.currencyIQD(
                                    (product['sale_price'] as num?) ?? 0),
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تنبيهات المخزون',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: _lowStockProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'المخزون آمن',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _lowStockProducts.length,
                    itemBuilder: (context, index) {
                      final product = _lowStockProducts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name']?.toString() ?? 'منتج',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'الكمية: ${product['quantity']} (الحد الأدنى: ${product['min_quantity']})',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'منخفض',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
