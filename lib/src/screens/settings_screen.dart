import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup/backup_service.dart';
import '../services/db/database_service.dart';
import '../utils/strings.dart';
import '../services/store_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _backupDirectory;

  @override
  Widget build(BuildContext context) {
    final backup = BackupService(context.read<DatabaseService>());
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
                    Icon(Icons.store, color: Colors.blue.shade600, size: 20),
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
                  'يمكنك إنشاء نسخة احتياطية من قاعدة البيانات أو استعادة نسخة سابقة.\n'
                  '• النسخ الاحتياطي الكامل: جميع البيانات (مبيعات، عملاء، منتجات، إلخ)\n'
                  '• نسخ المنتجات والأقسام: المنتجات والأقسام فقط\n'
                  '• الاستعادة: اختر ملف قاعدة بيانات سابق لاسترجاع بياناتك',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        final path = await backup.backupDatabase();
                        if (!mounted) return;
                        if (path != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('${AppStrings.backupSaved} $path')));
                        }
                      },
                      icon: const Icon(Icons.backup),
                      label: const Text('نسخ احتياطي كامل'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final path = await backup.backupProductsAndCategories();
                        if (!mounted) return;
                        if (path != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('تم حفظ نسخة المنتجات والأقسام: $path'),
                            backgroundColor: Colors.blue,
                          ));
                        }
                      },
                      icon: const Icon(Icons.inventory),
                      label: const Text('نسخ المنتجات والأقسام'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final name = await backup.restoreDatabase();
                        if (!mounted) return;
                        if (name != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('${AppStrings.backupRestored} $name')));
                        }
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text(AppStrings.restore),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Products and Categories Restore
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('تأكيد الاستعادة'),
                              content: const Text(
                                'هل تريد استعادة المنتجات والأقسام؟\n'
                                'سيتم حذف جميع المنتجات والأقسام الحالية واستبدالها بالبيانات من الملف المحدد.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('إلغاء'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('استعادة'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            final name =
                                await backup.restoreProductsAndCategories();
                            if (!mounted) return;
                            if (name != null) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    'تم استعادة المنتجات والأقسام من: $name'),
                                backgroundColor: Colors.green,
                              ));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('فشل في استعادة المنتجات والأقسام'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.restore_from_trash),
                        label: const Text('استعادة المنتجات والأقسام'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Backup Directory Selection
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final dir =
                              await FilePicker.platform.getDirectoryPath();
                          if (dir != null) {
                            setState(() => _backupDirectory = dir);
                          }
                        },
                        icon: const Icon(Icons.folder_open),
                        label: Text(
                            _backupDirectory ?? 'اختر مجلد النسخ الاحتياطي'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_backupDirectory != null)
                      FilledButton.icon(
                        onPressed: () async {
                          try {
                            final path = await backup
                                .backupToDirectory(_backupDirectory!);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('تم إنشاء نسخة احتياطية: $path'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('خطأ في النسخ الاحتياطي: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('نسخ احتياطي سريع'),
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.green),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Database Management Section
          Text('إدارة قاعدة البيانات',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _DatabaseManagementCard(),
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
