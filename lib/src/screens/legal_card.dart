import 'package:flutter/material.dart';
import 'package:office_mangment_system/src/screens/enhanced_privacy_policy_screen.dart';

class LegalCard extends StatelessWidget {
  const LegalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.blue),
              title: const Text('سياسة الخصوصية'),
              subtitle: const Text('كيف نحمي ونستخدم بياناتك'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EnhancedPrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.green),
              title: const Text('شروط الاستخدام'),
              subtitle: const Text('الشروط والأحكام للاستخدام'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EnhancedTermsConditionsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.copyright, color: Colors.orange),
              title: const Text('حقوق الطبع والنشر'),
              subtitle: const Text('جميع الحقوق محفوظة © 2024'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showCopyrightDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.gavel, color: Colors.purple),
              title: const Text('الإشعار القانوني'),
              subtitle: const Text('معلومات قانونية مهمة'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showLegalNoticeDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCopyrightDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              'assets/images/office.png',
              width: 32,
              height: 32,
              color: Colors.blue.shade600,
            ),
            const SizedBox(width: 12),
            const Text('حقوق الطبع والنشر'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '© 2024 نظام إدارة المكتب',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('جميع الحقوق محفوظة.'),
            SizedBox(height: 8),
            Text('هذا التطبيق مملوك ومطور بواسطة فريق التطوير.'),
            SizedBox(height: 8),
            Text(
                'لا يجوز نسخ أو توزيع أو تعديل أي جزء من هذا التطبيق بدون إذن كتابي صريح.'),
            SizedBox(height: 8),
            Text(
                'العلامات التجارية والعلامات التجارية المسجلة هي ملكية أصحابها.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showLegalNoticeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.gavel, color: Colors.purple.shade600),
            const SizedBox(width: 12),
            const Text('الإشعار القانوني'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إخلاء المسؤولية:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• هذا التطبيق مقدم "كما هو" بدون ضمانات.'),
            SizedBox(height: 4),
            Text('• نحن غير مسؤولين عن أي خسائر أو أضرار.'),
            SizedBox(height: 4),
            Text('• المستخدم مسؤول عن استخدام التطبيق بشكل قانوني.'),
            SizedBox(height: 8),
            Text(
              'القانون الحاكم:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('تخضع هذه الشروط لقوانين جمهورية العراق.'),
            SizedBox(height: 8),
            Text(
              'التواصل:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('للاستفسارات القانونية: barzan.dawood.dev@gmail.com'),
            SizedBox(height: 8),
            Text('جمهورية العراق - نينوى - سنجار'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
