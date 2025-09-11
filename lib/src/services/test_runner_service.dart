import 'dart:io';

class TestRunnerService {
  /// تشغيل جميع الاختبارات
  static Future<TestResult> runAllTests() async {
    try {
      final result = await Process.run(
        'flutter',
        ['test'],
        workingDirectory: Directory.current.path,
      );

      return TestResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.stderr.toString(),
        exitCode: result.exitCode,
      );
    } catch (e) {
      return TestResult(
        success: false,
        output: '',
        error: e.toString(),
        exitCode: -1,
      );
    }
  }

  /// تشغيل اختبارات قاعدة البيانات
  static Future<TestResult> runDatabaseTests() async {
    try {
      final result = await Process.run(
        'flutter',
        ['test', 'test/database/'],
        workingDirectory: Directory.current.path,
      );

      return TestResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.stderr.toString(),
        exitCode: result.exitCode,
      );
    } catch (e) {
      return TestResult(
        success: false,
        output: '',
        error: e.toString(),
        exitCode: -1,
      );
    }
  }

  /// تشغيل اختبارات واجهة المستخدم
  static Future<TestResult> runWidgetTests() async {
    try {
      final result = await Process.run(
        'flutter',
        ['test', 'test/widgets/'],
        workingDirectory: Directory.current.path,
      );

      return TestResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.stderr.toString(),
        exitCode: result.exitCode,
      );
    } catch (e) {
      return TestResult(
        success: false,
        output: '',
        error: e.toString(),
        exitCode: -1,
      );
    }
  }

  /// تشغيل اختبارات الوحدات
  static Future<TestResult> runUnitTests() async {
    try {
      final result = await Process.run(
        'flutter',
        ['test', 'test/unit/'],
        workingDirectory: Directory.current.path,
      );

      return TestResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.stderr.toString(),
        exitCode: result.exitCode,
      );
    } catch (e) {
      return TestResult(
        success: false,
        output: '',
        error: e.toString(),
        exitCode: -1,
      );
    }
  }

  /// تشغيل اختبارات الخدمات
  static Future<TestResult> runServiceTests() async {
    try {
      final result = await Process.run(
        'flutter',
        ['test', 'test/services/'],
        workingDirectory: Directory.current.path,
      );

      return TestResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.stderr.toString(),
        exitCode: result.exitCode,
      );
    } catch (e) {
      return TestResult(
        success: false,
        output: '',
        error: e.toString(),
        exitCode: -1,
      );
    }
  }

  /// تشغيل اختبارات التكامل
  static Future<TestResult> runIntegrationTests() async {
    try {
      final result = await Process.run(
        'flutter',
        ['test', 'test/integration/'],
        workingDirectory: Directory.current.path,
      );

      return TestResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.stderr.toString(),
        exitCode: result.exitCode,
      );
    } catch (e) {
      return TestResult(
        success: false,
        output: '',
        error: e.toString(),
        exitCode: -1,
      );
    }
  }

  /// تشغيل اختبارات الأداء
  static Future<TestResult> runPerformanceTests() async {
    try {
      final result = await Process.run(
        'flutter',
        ['test', 'test/performance/'],
        workingDirectory: Directory.current.path,
      );

      return TestResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.stderr.toString(),
        exitCode: result.exitCode,
      );
    } catch (e) {
      return TestResult(
        success: false,
        output: '',
        error: e.toString(),
        exitCode: -1,
      );
    }
  }

  /// تحليل نتائج الاختبارات
  static TestAnalysis analyzeTestOutput(String output) {
    final lines = output.split('\n');
    int totalTests = 0;
    int passedTests = 0;
    int failedTests = 0;
    int skippedTests = 0;

    for (final line in lines) {
      if (line.contains('All tests passed!')) {
        // جميع الاختبارات نجحت
        continue;
      } else if (line.contains('Some tests failed')) {
        // بعض الاختبارات فشلت
        continue;
      } else if (line.contains('test(s) passed')) {
        // استخراج عدد الاختبارات الناجحة
        final match = RegExp(r'(\d+) test\(s\) passed').firstMatch(line);
        if (match != null) {
          passedTests = int.tryParse(match.group(1) ?? '0') ?? 0;
        }
      } else if (line.contains('test(s) failed')) {
        // استخراج عدد الاختبارات الفاشلة
        final match = RegExp(r'(\d+) test\(s\) failed').firstMatch(line);
        if (match != null) {
          failedTests = int.tryParse(match.group(1) ?? '0') ?? 0;
        }
      } else if (line.contains('test(s) skipped')) {
        // استخراج عدد الاختبارات المتجاهلة
        final match = RegExp(r'(\d+) test\(s\) skipped').firstMatch(line);
        if (match != null) {
          skippedTests = int.tryParse(match.group(1) ?? '0') ?? 0;
        }
      }
    }

    totalTests = passedTests + failedTests + skippedTests;

    return TestAnalysis(
      totalTests: totalTests,
      passedTests: passedTests,
      failedTests: failedTests,
      skippedTests: skippedTests,
      successRate: totalTests > 0 ? (passedTests / totalTests) * 100 : 0,
    );
  }
}

class TestResult {
  final bool success;
  final String output;
  final String error;
  final int exitCode;

  TestResult({
    required this.success,
    required this.output,
    required this.error,
    required this.exitCode,
  });
}

class TestAnalysis {
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final int skippedTests;
  final double successRate;

  TestAnalysis({
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.skippedTests,
    required this.successRate,
  });
}
