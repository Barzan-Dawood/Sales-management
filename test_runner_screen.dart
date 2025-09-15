// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class TestRunnerScreen extends StatefulWidget {
  const TestRunnerScreen({super.key});

  @override
  State<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends State<TestRunnerScreen> {
  bool _isRunning = false;
  final List<TestResult> _testResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبارات النظام'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runAllTests,
            tooltip: 'تشغيل جميع الاختبارات',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التحكم
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runAllTests,
                    icon: _isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isRunning
                        ? 'جاري التشغيل...'
                        : 'تشغيل جميع الاختبارات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runDatabaseTests,
                    icon: const Icon(Icons.storage),
                    label: const Text('اختبارات قاعدة البيانات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runWidgetTests,
                    icon: const Icon(Icons.widgets),
                    label: const Text('اختبارات الواجهة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // إحصائيات الاختبارات
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard(
                  'إجمالي الاختبارات',
                  '${_testResults.length}',
                  Icons.assignment,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'نجح',
                  '${_testResults.where((r) => r.status == TestStatus.passed).length}',
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'فشل',
                  '${_testResults.where((r) => r.status == TestStatus.failed).length}',
                  Icons.error,
                  Colors.red,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'متجاهل',
                  '${_testResults.where((r) => r.status == TestStatus.skipped).length}',
                  Icons.skip_next,
                  Colors.grey,
                ),
              ],
            ),
          ),

          // نتائج الاختبارات
          Expanded(
            child: _testResults.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لم يتم تشغيل أي اختبارات بعد',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'اضغط على "تشغيل جميع الاختبارات" لبدء الاختبار',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _testResults.length,
                    itemBuilder: (context, index) {
                      final result = _testResults[index];
                      return _buildTestResultCard(result);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultCard(TestResult result) {
    Color statusColor;
    IconData statusIcon;

    switch (result.status) {
      case TestStatus.passed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TestStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case TestStatus.skipped:
        statusColor = Colors.grey;
        statusIcon = Icons.skip_next;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          result.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.description),
            if (result.duration != null)
              Text(
                'المدة: ${result.duration!.inMilliseconds}ms',
                style: const TextStyle(fontSize: 12),
              ),
            if (result.error != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: Text(
          result.status.name.toUpperCase(),
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    // محاكاة تشغيل الاختبارات
    await _simulateTestRun([
      'اختبارات قاعدة البيانات',
      'اختبارات واجهة المستخدم',
      'اختبارات الوحدات',
      'اختبارات الخدمات',
      'اختبارات التكامل',
      'اختبارات الأداء',
    ]);

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _runDatabaseTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    await _simulateTestRun([
      'تهيئة قاعدة البيانات',
      'إنشاء الجداول',
      'إدراج البيانات',
      'استرجاع البيانات',
      'قيود المفاتيح الخارجية',
    ]);

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _runWidgetTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    await _simulateTestRun([
      'عرض شاشة المنتجات',
      'نموذج إضافة منتج',
      'التحقق من صحة البيانات',
      'البحث والتصفية',
    ]);

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _simulateTestRun(List<String> testNames) async {
    for (int i = 0; i < testNames.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));

      final result = TestResult(
        name: testNames[i],
        description: 'اختبار ${testNames[i]}',
        status: i == 2 ? TestStatus.failed : TestStatus.passed,
        duration: Duration(milliseconds: 100 + (i * 50)),
        error: i == 2 ? 'خطأ في التحقق من صحة البيانات' : null,
      );

      setState(() {
        _testResults.add(result);
      });
    }
  }
}

enum TestStatus { passed, failed, skipped }

class TestResult {
  final String name;
  final String description;
  final TestStatus status;
  final Duration? duration;
  final String? error;

  TestResult({
    required this.name,
    required this.description,
    required this.status,
    this.duration,
    this.error,
  });
}
