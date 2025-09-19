// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../utils/strings.dart';
import '../services/store_config.dart';
import 'support_screen.dart';
import 'legal_card.dart';
import 'enhanced_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return const EnhancedSettingsScreen();
  }
}

// Keep the old implementation as backup
class _OldSettingsScreen extends StatefulWidget {
  const _OldSettingsScreen();

  @override
  State<_OldSettingsScreen> createState() => _OldSettingsScreenState();
}

class _OldSettingsScreenState extends State<_OldSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreConfig>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // Store Information Section (Read-only)
          Text(AppStrings.storeData,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/office.png',
                      width: 20,
                      height: 20,
                      color: Colors.blue.shade600,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.shopNameLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(store.shopName, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.phoneLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(store.phone, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.addressLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(store.address, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'نسخة التطبيق',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(store.displayVersion,
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Database Section
          Text(AppStrings.database,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'النسخ الاحتياطي والاستعادة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'يمكنك إنشاء نسخة احتياطية كاملة من قاعدة البيانات أو استعادة نسخة سابقة.\n'
                  '• النسخ الاحتياطي الكامل: نسخ شامل لجميع البيانات مع التحقق من التكامل\n'
                  '• الاستعادة الآمنة: استعادة البيانات مع الحفاظ على نسخة احتياطية من البيانات الحالية\n'
                  '• التحقق التلقائي: فحص صحة النسخ الاحتياطية قبل الحفظ والاستعادة',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Backup functionality removed
                    // Products backup functionality removed
                    // Restore functionality removed
                  ],
                ),
                const SizedBox(height: 12),

                // Products and Categories Restore
                Row(
                  children: [
                    // Products restore functionality removed
                  ],
                ),
                const SizedBox(height: 12),

                // Backup Directory Selection
                Row(
                  children: [
                    // Backup directory selection removed
                    const SizedBox(width: 8),
                    // Backup directory functionality removed
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Support Section
          Text('الدعم والتواصل', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _SupportCard(),

          const SizedBox(height: 16),

          // Database Management Section
          Text('إدارة قاعدة البيانات',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _DatabaseManagementCard(),

          const SizedBox(height: 16),

          // Legal Section
          Text('المعلومات القانونية',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const LegalCard(),
        ],
      ),
    );
  }
}

class _DatabaseManagementCard extends StatefulWidget {
  @override
  State<_DatabaseManagementCard> createState() =>
      _DatabaseManagementCardState();
}

class _DatabaseManagementCardState extends State<_DatabaseManagementCard> {
  Map<String, int> _dataCounts = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkDataExists();
  }

  Future<void> _checkDataExists() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<DatabaseService>();
      final counts = await db.checkDataExists();
      setState(() {
        _dataCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في فحص البيانات: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من حذف جميع البيانات؟\n'
          'هذا الإجراء لا يمكن التراجع عنه!\n\n'
          'سيتم حذف:\n'
          '• جميع المبيعات\n'
          '• جميع المنتجات\n'
          '• جميع العملاء\n'
          '• جميع الموردين\n'
          '• جميع الأقساط\n'
          '• جميع المصاريف\n'
          '• جميع التقارير',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final db = context.read<DatabaseService>();
        await db.deleteAllData();
        await _checkDataExists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف جميع البيانات بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في حذف البيانات: $e')),
          );
        }
      }
    }
  }

  Future<void> _resetCustomerDebts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الديون'),
        content: const Text(
          'هل تريد إعادة تعيين جميع ديون العملاء إلى صفر؟\n'
          'هذا سيقوم بتحديث حقل total_debt لجميع العملاء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final db = context.read<DatabaseService>();
        await db.resetAllCustomerDebts();
        await _checkDataExists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إعادة تعيين جميع الديون بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في إعادة تعيين الديون: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إدارة البيانات والإحصائيات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'يمكنك من هنا حذف جميع البيانات أو إعادة تعيين الديون لحل مشاكل الإحصائيات.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),

          // Data Statistics
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            const Text(
              'إحصائيات البيانات الحالية:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _dataCounts.entries.map((entry) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _isLoading ? null : _checkDataExists,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث الإحصائيات'),
              ),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _resetCustomerDebts,
                icon: const Icon(Icons.restore),
                label: const Text('إعادة تعيين الديون'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
              FilledButton.icon(
                onPressed: _isLoading ? null : _deleteAllData,
                icon: const Icon(Icons.delete_forever),
                label: const Text('حذف جميع البيانات'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.blue),
              title: const Text('الدعم الفني'),
              subtitle: const Text('تواصل مع فريق الدعم'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.storage, color: Colors.green),
              title: const Text('إدارة قاعدة البيانات'),
              subtitle: const Text('نسخ احتياطية وترحيل البيانات'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Database management functionality removed
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.orange),
              title: const Text('معلومات التطبيق'),
              subtitle: const Text('الإصدار والميزات'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showAppInfoDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
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
            const Text('نظام إدارة المكتب'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار: 1.0.0'),
            SizedBox(height: 8),
            Text('تاريخ الإصدار: 2024'),
            SizedBox(height: 8),
            Text('المطور: فريق التطوير العراقي'),
            SizedBox(height: 8),
            Text('اللغة: العربية'),
            SizedBox(height: 8),
            Text('البلد: جمهورية العراق'),
            SizedBox(height: 8),
            Text('نوع الترخيص: تجاري'),
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
