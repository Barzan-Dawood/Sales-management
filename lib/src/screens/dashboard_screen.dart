import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
import '../utils/format.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _todaySales = 0;
  double _todayProfit = 0;
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = context.read<DatabaseService>().database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final sales = await db.rawQuery(
        "SELECT IFNULL(SUM(total),0) as t, IFNULL(SUM(profit),0) as p FROM sales WHERE substr(created_at,1,10)=?",
        [today]);
    final low = await db.rawQuery(
        "SELECT COUNT(*) as c FROM products WHERE quantity <= min_quantity");
    setState(() {
      _todaySales = (sales.first['t'] as num).toDouble();
      _todayProfit = (sales.first['p'] as num).toDouble();
      _lowStockCount = (low.first['c'] as int);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                  title: 'مبيعات اليوم',
                  value: Formatters.currencyIQD(_todaySales),
                  color: Colors.blue),
              _StatCard(
                  title: 'ربح اليوم',
                  value: Formatters.currencyIQD(_todayProfit),
                  color: Colors.green),
              _StatCard(
                  title: 'تنبيهات نقص المخزون',
                  value: '$_lowStockCount',
                  color: Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LineChart(
                  LineChartData(
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        spots: List.generate(
                            7,
                            (i) => FlSpot(
                                i.toDouble(), (i * 10 % 40 + 10).toDouble())),
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 120,
      child: Card(
        color: color.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
