import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم والتواصل'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات التطبيق
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/pos.png',
                          width: 32,
                          height: 32,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'نظام إدارة المكتب',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('الإصدار: 1.0.0'),
                    Text(
                        'تاريخ الإصدار: ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // قنوات التواصل
            const Text(
              'قنوات التواصل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // البريد الإلكتروني
            _buildContactCard(
              icon: Icons.email,
              title: 'البريد الإلكتروني',
              subtitle: 'barzan.dawood.dev@gmail.com',
              onTap: () => _launchEmail('barzan.dawood.dev@gmail.com'),
            ),

            // الهاتف
            _buildContactCard(
              icon: Icons.phone,
              title: 'الهاتف',
              subtitle: '+964 786 674 4144',
              onTap: () => _launchPhone('+9647866744144'),
            ),

            // الواتساب
            _buildContactCard(
              icon: Icons.chat,
              title: 'واتساب',
              subtitle: '+964 786 674 4144',
              onTap: () => _launchWhatsApp('+9647866744144'),
            ),

            // الموقع الإلكتروني
            _buildContactCard(
              icon: Icons.language,
              title: 'الموقع الإلكتروني',
              subtitle: 'www.office-management.com',
              onTap: () => _launchWebsite('https://www.office-management.com'),
            ),

            const SizedBox(height: 20),

            // ساعات العمل
            const Text(
              'ساعات العمل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildWorkingHoursRow('الأحد - الخميس', '8:00 ص - 5:00 م'),
                    const Divider(),
                    _buildWorkingHoursRow('الجمعة', 'مغلق'),
                    const Divider(),
                    _buildWorkingHoursRow('السبت', '9:00 ص - 2:00 م'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // التحديثات المستقبلية
            const Text(
              'التحديثات المستقبلية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الإصدار القادم 1.1.0',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('الميزات الجديدة:'),
                    const SizedBox(height: 8),
                    _buildFeatureItem('• ترحيل قاعدة البيانات المحسّن'),
                    _buildFeatureItem('• دعم النسخ الاحتياطي السحابي'),
                    _buildFeatureItem('• تقارير متقدمة'),
                    _buildFeatureItem('• دعم متعدد المستخدمين'),
                    _buildFeatureItem('• واجهة محسّنة'),
                    const SizedBox(height: 12),
                    const Text(
                      'تاريخ الإصدار المتوقع: قريباً',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // معلومات إضافية
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معلومات إضافية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem('نوع الترخيص', 'تجاري'),
                    _buildInfoItem('نظام التشغيل المدعوم',
                        'Android, iOS, Windows, macOS, Web'),
                    _buildInfoItem('اللغة المدعومة', 'العربية'),
                    _buildInfoItem('حجم قاعدة البيانات', 'غير محدود'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade600),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildWorkingHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(hours, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(feature),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // وظائف التواصل
  Future<void> _launchEmail(String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    // يمكن إضافة رسالة للمستخدم هنا
  }

  Future<void> _launchPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    // يمكن إضافة رسالة للمستخدم هنا
  }

  Future<void> _launchWhatsApp(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    // يمكن إضافة رسالة للمستخدم هنا
  }

  Future<void> _launchWebsite(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    // يمكن إضافة رسالة للمستخدم هنا
  }
}
