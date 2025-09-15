// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TestReportsScreen extends StatefulWidget {
  const TestReportsScreen({super.key});

  @override
  State<TestReportsScreen> createState() => _TestReportsScreenState();
}

class _TestReportsScreenState extends State<TestReportsScreen>
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
        title: const Text('تقارير الاختبارات'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'نظرة عامة'),
            Tab(icon: Icon(Icons.timeline), text: 'الاتجاهات'),
            Tab(icon: Icon(Icons.analytics), text: 'التحليل'),
            Tab(icon: Icon(Icons.history), text: 'التاريخ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTrendsTab(),
          _buildAnalyticsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // إحصائيات سريعة
          Row(
            children: [
              Expanded(
                  child: _buildQuickStatCard('إجمالي الاختبارات', '156',
                      Colors.blue, Icons.assignment)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildQuickStatCard(
                      'نجح', '142', Colors.green, Icons.check_circle)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child:
                      _buildQuickStatCard('فشل', '8', Colors.red, Icons.error)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildQuickStatCard(
                      'متجاهل', '6', Colors.grey, Icons.skip_next)),
            ],
          ),

          const SizedBox(height: 24),

          // مخطط دائري للنتائج
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'توزيع نتائج الاختبارات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: 142,
                            title: 'نجح\n91%',
                            color: Colors.green,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 8,
                            title: 'فشل\n5%',
                            color: Colors.red,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 6,
                            title: 'متجاهل\n4%',
                            color: Colors.grey,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // تفاصيل الاختبارات
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تفاصيل الاختبارات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTestDetailRow('اختبارات قاعدة البيانات', 25, 23, 2, 0),
                  _buildTestDetailRow('اختبارات واجهة المستخدم', 30, 28, 1, 1),
                  _buildTestDetailRow('اختبارات الوحدات', 35, 33, 2, 0),
                  _buildTestDetailRow('اختبارات الخدمات', 20, 18, 1, 1),
                  _buildTestDetailRow('اختبارات التكامل', 25, 24, 1, 0),
                  _buildTestDetailRow('اختبارات الأداء', 21, 16, 1, 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestDetailRow(
      String category, int total, int passed, int failed, int skipped) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(category,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusIndicator('إجمالي', total, Colors.blue),
                _buildStatusIndicator('نجح', passed, Colors.green),
                _buildStatusIndicator('فشل', failed, Colors.red),
                _buildStatusIndicator('متجاهل', skipped, Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 8),
        ),
      ],
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اتجاه نجاح الاختبارات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}%');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'أول',
                                  'ثاني',
                                  'ثالث',
                                  'رابع',
                                  'خامس',
                                  'سادس',
                                  'سابع'
                                ];
                                return Text(days[value.toInt() % days.length]);
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 85),
                              FlSpot(1, 88),
                              FlSpot(2, 90),
                              FlSpot(3, 87),
                              FlSpot(4, 92),
                              FlSpot(5, 89),
                              FlSpot(6, 91),
                            ],
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
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

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تحليل الأداء',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildAnalyticsRow(
                      'متوسط وقت التشغيل', '2.3 ثانية', Colors.blue),
                  _buildAnalyticsRow('أسرع اختبار', '0.1 ثانية', Colors.green),
                  _buildAnalyticsRow('أبطأ اختبار', '8.5 ثانية', Colors.red),
                  _buildAnalyticsRow('معدل النجاح', '91%', Colors.green),
                  _buildAnalyticsRow(
                      'الاختبارات المتكررة', '12', Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3 ? Colors.green : Colors.orange,
              child: Icon(
                index < 3 ? Icons.check : Icons.warning,
                color: Colors.white,
              ),
            ),
            title: Text(
                'تشغيل الاختبارات - ${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]}'),
            subtitle: Text('${156 - index * 2} اختبار - ${91 + index}% نجاح'),
            trailing: Text('${2 + index * 0.5} ثانية'),
          ),
        );
      },
    );
  }
}
