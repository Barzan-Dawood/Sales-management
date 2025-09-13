import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db/database_service.dart';

class DatabaseSettingsDialog extends StatefulWidget {
  const DatabaseSettingsDialog({super.key});

  @override
  State<DatabaseSettingsDialog> createState() => _DatabaseSettingsDialogState();
}

class _DatabaseSettingsDialogState extends State<DatabaseSettingsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _backupPath = '';
  String _autoBackupFrequency = 'weekly';
  bool _autoBackupEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // تحميل الإعدادات المحفوظة
    final prefs = await SharedPreferences.getInstance();

    // تحميل مسار النسخ الاحتياطية
    final savedBackupPath = prefs.getString('backup_path');
    if (savedBackupPath != null && savedBackupPath.isNotEmpty) {
      // استخدام المسار المحفوظ
      setState(() {
        _backupPath = savedBackupPath;
      });
    } else {
      // استخدام المسار الافتراضي
      final appDir = await getApplicationDocumentsDirectory();
      final defaultPath = path.join(appDir.path, 'backups');
      setState(() {
        _backupPath = defaultPath;
      });
      // حفظ المسار الافتراضي
      await _saveBackupPath(defaultPath);
    }

    // تحميل إعدادات النسخ التلقائي
    setState(() {
      _autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
      _autoBackupFrequency =
          prefs.getString('auto_backup_frequency') ?? 'weekly';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storage,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إعدادات قاعدة البيانات',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'إدارة النسخ الاحتياطية والاستعادة',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.blue.shade600,
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.backup, size: 20),
                    text: 'النسخ الاحتياطي',
                  ),
                  Tab(
                    icon: Icon(Icons.restore, size: 20),
                    text: 'الاستعادة',
                  ),
                  Tab(
                    icon: Icon(Icons.settings, size: 20),
                    text: 'الإعدادات',
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBackupTab(),
                  _buildRestoreTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'النسخ الاحتياطي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),

          // Full Backup
          _buildActionCard(
            icon: Icons.backup,
            title: 'نسخ احتياطي كامل',
            subtitle: 'نسخ جميع البيانات (مبيعات، عملاء، منتجات، إلخ)',
            color: Colors.green,
            onTap: () => _createFullBackup(),
          ),

          const SizedBox(height: 12),

          // Products Backup
          _buildActionCard(
            icon: Icons.inventory_2,
            title: 'نسخ المنتجات والأقسام',
            subtitle: 'نسخ المنتجات والأقسام فقط',
            color: Colors.orange,
            onTap: () => _createProductsBackup(),
          ),

          const SizedBox(height: 20),

          // Backup Path
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'مسار النسخ الاحتياطي',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _backupPath.isEmpty ? 'غير محدد' : _backupPath,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _selectBackupPath,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('اختيار مسار'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الاستعادة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),

          // Full Restore
          _buildActionCard(
            icon: Icons.restore,
            title: 'استعادة كاملة',
            subtitle: 'استعادة جميع البيانات من نسخة احتياطية',
            color: Colors.red,
            onTap: () => _restoreFullBackup(),
          ),

          const SizedBox(height: 12),

          // Products Restore
          _buildActionCard(
            icon: Icons.inventory_2,
            title: 'استعادة المنتجات والأقسام',
            subtitle: 'استعادة المنتجات والأقسام فقط',
            color: Colors.purple,
            onTap: () => _restoreProductsBackup(),
          ),

          const SizedBox(height: 20),

          // Warning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تحذير: الاستعادة ستحل محل البيانات الحالية. تأكد من إنشاء نسخة احتياطية قبل الاستعادة.',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),

          // Auto Backup Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                    Icon(Icons.schedule, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'النسخ الاحتياطي التلقائي',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Enable Auto Backup
                SwitchListTile(
                  title: const Text('تفعيل النسخ الاحتياطي التلقائي'),
                  subtitle:
                      const Text('إنشاء نسخ احتياطية تلقائية حسب الجدولة'),
                  value: _autoBackupEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoBackupEnabled = value;
                    });
                    _saveSettings();
                  },
                  activeThumbColor: Colors.blue.shade600,
                ),

                if (_autoBackupEnabled) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'تكرار النسخ الاحتياطي:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _autoBackupFrequency,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('يومي')),
                      DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                      DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _autoBackupFrequency = value!;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Database Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'معلومات قاعدة البيانات',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<DatabaseService>(
                  builder: (context, db, child) {
                    return FutureBuilder<String>(
                      future: db.getDatabaseSize(),
                      builder: (context, snapshot) {
                        return Column(
                          children: [
                            _buildInfoRow(
                                'مسار قاعدة البيانات', db.databasePath),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                                'حجم قاعدة البيانات',
                                snapshot.hasData
                                    ? snapshot.data!
                                    : 'جاري الحساب...'),
                            const SizedBox(height: 8),
                            FutureBuilder<Map<String, int>>(
                              future: db.getDatabaseStats(),
                              builder: (context, statsSnapshot) {
                                if (statsSnapshot.hasData) {
                                  final stats = statsSnapshot.data!;
                                  return Column(
                                    children: [
                                      _buildInfoRow('عدد المنتجات',
                                          '${stats['products'] ?? 0}'),
                                      const SizedBox(height: 4),
                                      _buildInfoRow('عدد العملاء',
                                          '${stats['customers'] ?? 0}'),
                                      const SizedBox(height: 4),
                                      _buildInfoRow('عدد المبيعات',
                                          '${stats['sales'] ?? 0}'),
                                      const SizedBox(height: 4),
                                      _buildInfoRow('عدد الأقسام',
                                          '${stats['categories'] ?? 0}'),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectBackupPath() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        setState(() {
          _backupPath = selectedDirectory;
        });
        // حفظ المسار الجديد في SharedPreferences
        await _saveBackupPath(selectedDirectory);
        _showSnackBar('تم تحديث مسار النسخ الاحتياطي', Colors.green);
      }
    } catch (e) {
      _showSnackBar('خطأ في اختيار المسار: $e', Colors.red);
    }
  }

  Future<void> _createFullBackup() async {
    // عرض نافذة تأكيد
    final confirmed = await _showBackupConfirmationDialog(
      'النسخ الاحتياطي الكامل',
      'هل تريد إنشاء نسخة احتياطية كاملة من جميع البيانات؟\n\nسيتم نسخ:\n• جميع المبيعات\n• جميع العملاء\n• جميع المنتجات\n• جميع الأقسام\n• جميع البيانات الأخرى',
    );

    if (!confirmed) return;

    try {
      // عرض مؤشر التحميل
      _showLoadingDialog('جاري إنشاء النسخة الاحتياطية...');

      final db = context.read<DatabaseService>();
      final backupPath = await db.createFullBackup(_backupPath);

      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      _showSnackBar(
          'تم إنشاء النسخة الاحتياطية الكاملة بنجاح\nالمسار: $backupPath',
          Colors.green);
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في إنشاء النسخة الاحتياطية: $e', Colors.red);
    }
  }

  Future<void> _createProductsBackup() async {
    // عرض نافذة تأكيد
    final confirmed = await _showBackupConfirmationDialog(
      'نسخ المنتجات والأقسام',
      'هل تريد إنشاء نسخة احتياطية للمنتجات والأقسام؟\n\nسيتم نسخ:\n• جميع المنتجات\n• جميع الأقسام\n• معلومات الأسعار والكميات',
    );

    if (!confirmed) return;

    try {
      // عرض مؤشر التحميل
      _showLoadingDialog('جاري إنشاء نسخة احتياطية للمنتجات...');

      final db = context.read<DatabaseService>();
      final backupPath = await db.createProductsBackup(_backupPath);

      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      _showSnackBar(
          'تم إنشاء نسخة احتياطية للمنتجات والأقسام\nالمسار: $backupPath',
          Colors.green);
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في إنشاء النسخة الاحتياطية: $e', Colors.red);
    }
  }

  Future<void> _restoreFullBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null) {
        final db = context.read<DatabaseService>();
        final backupFilePath = result.files.single.path!;

        await db.restoreFullBackup(backupFilePath);

        _showSnackBar('تم استعادة النسخة الاحتياطية بنجاح', Colors.green);
      }
    } catch (e) {
      _showSnackBar('خطأ في الاستعادة: $e', Colors.red);
    }
  }

  Future<void> _restoreProductsBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final db = context.read<DatabaseService>();
        final backupFilePath = result.files.single.path!;

        await db.restoreProductsBackup(backupFilePath);

        _showSnackBar('تم استعادة المنتجات والأقسام بنجاح', Colors.green);
      }
    } catch (e) {
      _showSnackBar('خطأ في الاستعادة: $e', Colors.red);
    }
  }

  /// حفظ مسار النسخ الاحتياطية
  Future<void> _saveBackupPath(String backupPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_path', backupPath);
  }

  /// حفظ إعدادات النسخ الاحتياطي التلقائي
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', _autoBackupEnabled);
    await prefs.setString('auto_backup_frequency', _autoBackupFrequency);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// عرض نافذة تأكيد للنسخ الاحتياطي
  Future<bool> _showBackupConfirmationDialog(
      String title, String message) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.backup,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تأكد من وجود مساحة كافية في القرص الصلب',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('موافق'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// عرض مؤشر التحميل
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
