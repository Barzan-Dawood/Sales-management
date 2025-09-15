// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
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
    _tabController = TabController(length: 4, vsync: this);
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isVerySmallScreen = screenSize.width < 400;

    final dialogWidth = isVerySmallScreen
        ? screenSize.width * 0.98
        : isSmallScreen
            ? screenSize.width * 0.95
            : screenSize.width * 0.85;

    final dialogHeight = isVerySmallScreen
        ? screenSize.height * 0.95
        : isSmallScreen
            ? screenSize.height * 0.9
            : screenSize.height * 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: screenSize.height * 0.9,
          minWidth: 300,
          minHeight: 400,
        ),
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
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.storage,
                      color: Colors.white,
                      size: isSmallScreen ? 24 : 28,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إعدادات قاعدة البيانات',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isSmallScreen)
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
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
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
                isScrollable: isSmallScreen,
                labelStyle: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: isSmallScreen ? 11 : 13,
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.backup, size: isSmallScreen ? 18 : 20),
                    text: isSmallScreen ? 'النسخ' : 'النسخ الاحتياطي',
                  ),
                  Tab(
                    icon: Icon(Icons.restore, size: isSmallScreen ? 18 : 20),
                    text: isSmallScreen ? 'الاستعادة' : 'الاستعادة',
                  ),
                  Tab(
                    icon: Icon(Icons.settings, size: isSmallScreen ? 18 : 20),
                    text: isSmallScreen ? 'الإعدادات' : 'الإعدادات',
                  ),
                  Tab(
                    icon: Icon(Icons.delete_forever,
                        size: isSmallScreen ? 18 : 20),
                    text: isSmallScreen ? 'الحذف' : 'حذف البيانات',
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
                  _buildDeleteTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupTab() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'النسخ الاحتياطي',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Full Backup
          _buildActionCard(
            icon: Icons.backup,
            title: 'نسخ احتياطي كامل',
            subtitle: 'نسخ جميع البيانات (مبيعات، عملاء، منتجات، إلخ)',
            color: Colors.green,
            onTap: () => _createFullBackup(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // View Available Backups
          _buildActionCard(
            icon: Icons.folder_open,
            title: 'عرض النسخ المتاحة',
            subtitle: 'عرض وإدارة النسخ الاحتياطية الموجودة',
            color: Colors.purple,
            onTap: () => _showAvailableBackups(),
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Information about backup files
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: isSmallScreen ? 18 : 20,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملاحظة حول ملفات النسخ الاحتياطي',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        'يتم إنشاء 3 ملفات مع النسخة الاحتياطية:\n'
                        '• الملف الرئيسي (.db)\n'
                        '• ملف السجل (.db-wal)\n'
                        '• ملف الذاكرة المشتركة (.db-shm)\n'
                        'هذه الملفات ضرورية لضمان سلامة البيانات.',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الاستعادة',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Full Restore
          _buildActionCard(
            icon: Icons.restore,
            title: 'استعادة كاملة',
            subtitle: 'استعادة جميع البيانات من نسخة احتياطية',
            color: Colors.red,
            onTap: () => _restoreFullBackup(),
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Warning
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Auto Backup Settings
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Database Info
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

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
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: isSmallScreen ? 14 : 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 4 : 8,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isSmallScreen ? 100 : 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 12 : 14,
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

  Future<void> _showAvailableBackups() async {
    try {
      final db = context.read<DatabaseService>();
      final backups = await db.getAvailableBackups(_backupPath);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _buildBackupsListDialog(backups),
      );
    } catch (e) {
      _showSnackBar('خطأ في عرض النسخ الاحتياطية: $e', Colors.red);
    }
  }

  Widget _buildBackupsListDialog(List<Map<String, dynamic>> backups) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.purple.shade700],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.folder_open,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'النسخ الاحتياطية المتاحة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: backups.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد نسخ احتياطية',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: backups.length,
                      itemBuilder: (context, index) {
                        final backup = backups[index];
                        return _buildBackupItem(backup);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(Map<String, dynamic> backup) {
    final name = backup['name'] as String;
    final size = backup['size'] as int;
    final date = backup['date'] as DateTime;
    final isValid = backup['isValid'] as bool;

    String formatSize(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.green.shade200 : Colors.red.shade200,
        ),
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
            color: isValid ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? Colors.green.shade600 : Colors.red.shade600,
            size: 24,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الحجم: ${formatSize(size)}'),
            Text('التاريخ: ${date.toString().split('.')[0]}'),
            Text(
              isValid ? 'صالح' : 'تالف',
              style: TextStyle(
                color: isValid ? Colors.green.shade600 : Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleBackupAction(value, backup),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('استعادة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'verify',
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green),
                  SizedBox(width: 8),
                  Text('التحقق'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBackupAction(
      String action, Map<String, dynamic> backup) async {
    final path = backup['path'] as String;
    final db = context.read<DatabaseService>();

    switch (action) {
      case 'restore':
        try {
          await db.restoreFullBackup(path);
          _showSnackBar('تم استعادة النسخة الاحتياطية بنجاح', Colors.green);
        } catch (e) {
          _showSnackBar('خطأ في الاستعادة: $e', Colors.red);
        }
        break;
      case 'verify':
        try {
          final isValid = await db.verifyBackup(path);
          _showSnackBar(
            isValid ? 'النسخة الاحتياطية صالحة' : 'النسخة الاحتياطية تالفة',
            isValid ? Colors.green : Colors.red,
          );
        } catch (e) {
          _showSnackBar('خطأ في التحقق: $e', Colors.red);
        }
        break;
      case 'delete':
        try {
          final file = File(path);
          await file.delete();
          _showSnackBar('تم حذف النسخة الاحتياطية', Colors.orange);
          // إعادة تحميل القائمة
          _showAvailableBackups();
        } catch (e) {
          _showSnackBar('خطأ في الحذف: $e', Colors.red);
        }
        break;
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

  Widget _buildDeleteTab() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حذف البيانات',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Warning
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                    'تحذير: عمليات الحذف لا يمكن التراجع عنها. تأكد من إنشاء نسخة احتياطية قبل الحذف.',
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

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Delete Products and Categories
          _buildDeleteActionCard(
            icon: Icons.inventory,
            title: 'حذف المنتجات والأقسام',
            subtitle:
                'حذف جميع المنتجات والأقسام وسجلات المبيعات (لن يتم إنشاء أي قسم جديد)',
            color: Colors.orange,
            onTap: () => _deleteProductsAndCategories(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Reports and Statistics
          _buildDeleteActionCard(
            icon: Icons.analytics,
            title: 'حذف الإحصائيات والتقارير',
            subtitle:
                'حذف المدفوعات والمصروفات والأقساط (سيتم الاحتفاظ بالبيانات الأساسية)',
            color: Colors.purple,
            onTap: () => _deleteReportsAndStatistics(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Sales Only
          _buildDeleteActionCard(
            icon: Icons.shopping_cart,
            title: 'حذف المبيعات فقط',
            subtitle:
                'حذف جميع المبيعات وسجلات المبيعات (سيتم الاحتفاظ بالمنتجات والعملاء)',
            color: Colors.blue,
            onTap: () => _deleteSalesOnly(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Customers Only
          _buildDeleteActionCard(
            icon: Icons.people,
            title: 'حذف العملاء فقط',
            subtitle: 'حذف جميع العملاء (سيتم الاحتفاظ بالمبيعات والمنتجات)',
            color: Colors.green,
            onTap: () => _deleteCustomersOnly(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Payments Only
          _buildDeleteActionCard(
            icon: Icons.payment,
            title: 'حذف المدفوعات فقط',
            subtitle:
                'حذف جميع سجلات المدفوعات (سيتم الاحتفاظ بالبيانات الأخرى)',
            color: Colors.teal,
            onTap: () => _deletePaymentsOnly(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Expenses Only
          _buildDeleteActionCard(
            icon: Icons.receipt,
            title: 'حذف المصروفات فقط',
            subtitle:
                'حذف جميع سجلات المصروفات (سيتم الاحتفاظ بالبيانات الأخرى)',
            color: Colors.indigo,
            onTap: () => _deleteExpensesOnly(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Installments Only
          _buildDeleteActionCard(
            icon: Icons.schedule,
            title: 'حذف الأقساط فقط',
            subtitle: 'حذف جميع سجلات الأقساط (سيتم الاحتفاظ بالبيانات الأخرى)',
            color: Colors.cyan,
            onTap: () => _deleteInstallmentsOnly(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Users Only
          _buildDeleteActionCard(
            icon: Icons.person,
            title: 'حذف المستخدمين فقط',
            subtitle: 'حذف جميع المستخدمين (سيتم الاحتفاظ بالبيانات الأخرى)',
            color: Colors.brown,
            onTap: () => _deleteUsersOnly(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Suppliers Only
          _buildDeleteActionCard(
            icon: Icons.local_shipping,
            title: 'حذف الموردين فقط',
            subtitle: 'حذف جميع الموردين (سيتم الاحتفاظ بالبيانات الأخرى)',
            color: Colors.deepOrange,
            onTap: () => _deleteSuppliersOnly(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Products Only
          _buildDeleteActionCard(
            icon: Icons.inventory_2,
            title: 'حذف المنتجات فقط',
            subtitle:
                'حذف جميع المنتجات وعناصر المبيعات المرتبطة بها مع الإبقاء على الأقسام',
            color: Colors.deepPurple,
            onTap: () => _deleteProductsOnly(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Empty Categories
          _buildDeleteActionCard(
            icon: Icons.category_outlined,
            title: 'حذف الأقسام الفارغة فقط',
            subtitle: 'حذف الأقسام التي لا تحتوي على أي منتجات',
            color: Colors.blueGrey,
            onTap: () => _deleteEmptyCategories(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Customers Without Sales
          _buildDeleteActionCard(
            icon: Icons.person_off_outlined,
            title: 'حذف العملاء بدون مبيعات',
            subtitle: 'تنظيف العملاء الذين لا يمتلكون أي فواتير مبيعات',
            color: Colors.teal,
            onTap: () => _deleteCustomersWithoutSales(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Delete Sales Before Date
          _buildDeleteActionCard(
            icon: Icons.history_toggle_off,
            title: 'حذف المبيعات قبل تاريخ...',
            subtitle:
                'حدد تاريخًا لحذف الفواتير الأقدم (مع العناصر والأقساط المتعلقة بها)',
            color: Colors.orange,
            onTap: () => _deleteSalesBeforeDate(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Reset Inventory Quantities To Zero
          _buildDeleteActionCard(
            icon: Icons.layers_clear,
            title: 'تصفير كميات المخزون',
            subtitle:
                'إعادة تعيين كميات جميع المنتجات إلى صفر بدون حذف المنتجات',
            color: Colors.redAccent,
            onTap: () => _resetInventoryToZero(),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Vacuum Database
          _buildDeleteActionCard(
            icon: Icons.cleaning_services,
            title: 'تنظيف قاعدة البيانات',
            subtitle: 'تنظيم القاعدة وإزالة المساحة غير المستخدمة بعد الحذف',
            color: Colors.brown,
            onTap: () => _vacuumDatabase(),
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Delete All Data - Moved to the end
          _buildDeleteActionCard(
            icon: Icons.delete_forever,
            title: 'حذف جميع البيانات',
            subtitle:
                'حذف جميع البيانات من قاعدة البيانات (مبيعات، عملاء، منتجات، أقسام، إحصائيات)',
            color: Colors.red,
            onTap: () => _deleteAllData(),
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Information about deletion
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: isSmallScreen ? 18 : 20,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات حول عمليات الحذف',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        '• حذف جميع البيانات: يمسح كل شيء من قاعدة البيانات\n'
                        '• حذف المنتجات والأقسام: يحتفظ بالمبيعات والعملاء\n'
                        '• حذف الإحصائيات: يحذف المدفوعات والمصروفات والأقساط\n'
                        '• جميع عمليات الحذف نهائية ولا يمكن التراجع عنها',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 14 : 16,
            color: color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: isSmallScreen ? 14 : 16,
          color: color.withOpacity(0.7),
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 4 : 8,
        ),
      ),
    );
  }

  Future<void> _deleteAllData() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف جميع البيانات',
      'هل أنت متأكد من حذف جميع البيانات؟\n\nسيتم حذف:\n• جميع المبيعات\n• جميع العملاء\n• جميع المنتجات\n• جميع الأقسام\n• جميع الإحصائيات والتقارير\n• جميع البيانات الأخرى\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف الكل',
      Colors.red,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف جميع البيانات...');

      final db = context.read<DatabaseService>();
      await db.deleteAllDataNew();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف جميع البيانات بنجاح', Colors.red);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف البيانات: $e', Colors.red);
    }
  }

  Future<void> _deleteProductsAndCategories() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف المنتجات والأقسام',
      'هل أنت متأكد من حذف جميع المنتجات والأقسام؟\n\nسيتم حذف:\n• جميع المنتجات\n• جميع الأقسام\n• جميع عناصر المبيعات\n\nملاحظة: لن يتم إنشاء أي قسم جديد تلقائياً\n\nسيتم الاحتفاظ بـ:\n• المبيعات الأساسية\n• العملاء\n• الإحصائيات\n• المستخدمين\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف المنتجات والأقسام',
      Colors.orange,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف المنتجات والأقسام...');

      final db = context.read<DatabaseService>();
      await db.deleteProductsAndCategories();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف المنتجات والأقسام بنجاح', Colors.orange);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف المنتجات والأقسام: $e', Colors.red);
    }
  }

  Future<void> _deleteReportsAndStatistics() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف الإحصائيات والتقارير',
      'هل أنت متأكد من حذف جميع الإحصائيات والتقارير؟\n\nسيتم حذف:\n• جميع المدفوعات\n• جميع المصروفات\n• جميع الأقساط\n• سجلات الأداء والنسخ الاحتياطي\n\nسيتم الاحتفاظ بـ:\n• المبيعات\n• العملاء\n• المنتجات\n• الأقسام\n• المستخدمين\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف الإحصائيات والتقارير',
      Colors.purple,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف الإحصائيات والتقارير...');

      final db = context.read<DatabaseService>();
      await db.deleteReportsAndStatistics();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف الإحصائيات والتقارير بنجاح', Colors.purple);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف الإحصائيات والتقارير: $e', Colors.red);
    }
  }

  Future<void> _deleteProductsOnly() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف المنتجات فقط',
      'هل أنت متأكد من حذف جميع المنتجات؟\n\nسيتم حذف:\n• جميع المنتجات\n• جميع عناصر المبيعات\n\nسيتم الاحتفاظ بـ:\n• الأقسام\n• المبيعات\n• العملاء\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف المنتجات',
      Colors.deepPurple,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف المنتجات...');

      final db = context.read<DatabaseService>();
      await db.deleteProductsOnly();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف المنتجات بنجاح', Colors.deepPurple);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف المنتجات: $e', Colors.red);
    }
  }

  Future<void> _deleteEmptyCategories() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف الأقسام الفارغة فقط',
      'سيتم حذف جميع الأقسام التي لا تحتوي على أي منتجات.\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف الأقسام الفارغة',
      Colors.blueGrey,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف الأقسام الفارغة...');

      final db = context.read<DatabaseService>();
      final deleted = await db.deleteEmptyCategories();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف $deleted قسم فارغ', Colors.blueGrey);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف الأقسام الفارغة: $e', Colors.red);
    }
  }

  Future<void> _deleteCustomersWithoutSales() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف العملاء بدون مبيعات',
      'سيتم حذف كل عميل لا يمتلك أي فواتير مبيعات، مع حذف مدفوعاته المرتبطة.\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف العملاء بدون مبيعات',
      Colors.teal,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف العملاء بدون مبيعات...');

      final db = context.read<DatabaseService>();
      await db.deleteCustomersWithoutSales();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف العملاء بدون مبيعات بنجاح', Colors.teal);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف العملاء بدون مبيعات: $e', Colors.red);
    }
  }

  Future<void> _deleteSalesBeforeDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'اختر التاريخ الحد الفاصل',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (date == null) return;

    final confirmed = await _showDeleteConfirmationDialog(
      'حذف المبيعات قبل ${date.toString().split(' ')[0]}',
      'سيتم حذف كل المبيعات الأقدم من التاريخ المحدد مع العناصر والأقساط المرتبطة بها.\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف المبيعات القديمة',
      Colors.orange,
    );
    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف المبيعات القديمة...');

      final db = context.read<DatabaseService>();
      await db.deleteSalesBefore(DateTime(date.year, date.month, date.day));

      Navigator.of(context).pop();
      _showSnackBar('تم حذف المبيعات القديمة بنجاح', Colors.orange);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف المبيعات القديمة: $e', Colors.red);
    }
  }

  Future<void> _resetInventoryToZero() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'تصفير كميات المخزون',
      'سيتم إعادة تعيين كمية جميع المنتجات إلى صفر.\n\nتحذير: هذا الإجراء خطير وقد يؤثر على تقارير المخزون.\n\nهل أنت متأكد؟',
      'تأكيد التصفير',
      Colors.redAccent,
    );
    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري تصفير كميات المخزون...');
      final db = context.read<DatabaseService>();
      await db.resetInventoryToZero();
      Navigator.of(context).pop();
      _showSnackBar('تم تصفير كميات المخزون بنجاح', Colors.redAccent);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في تصفير كميات المخزون: $e', Colors.red);
    }
  }

  Future<void> _vacuumDatabase() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'تنظيف قاعدة البيانات',
      'سيتم تنظيف قاعدة البيانات وإزالة المساحة غير المستخدمة. قد تستغرق العملية وقتاً حسب حجم البيانات.',
      'بدء التنظيف',
      Colors.brown,
    );
    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري تنظيف قاعدة البيانات...');
      final db = context.read<DatabaseService>();
      await db.vacuumDatabase();
      Navigator.of(context).pop();
      _showSnackBar('تم تنظيف قاعدة البيانات بنجاح', Colors.brown);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في تنظيف قاعدة البيانات: $e', Colors.red);
    }
  }

  /// عرض نافذة تأكيد للحذف
  Future<bool> _showDeleteConfirmationDialog(
      String title, String message, String confirmText, Color color) async {
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
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_forever,
                      color: color,
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
                        color: color,
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
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'هذه العملية لا يمكن التراجع عنها!',
                            style: TextStyle(
                              color: Colors.red.shade700,
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
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(confirmText),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // دوال الحذف المنفصلة
  Future<void> _deleteSalesOnly() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف المبيعات فقط',
      'هل أنت متأكد من حذف جميع المبيعات؟\n\nسيتم حذف:\n• جميع المبيعات\n• جميع سجلات المبيعات\n• جميع الأقساط المرتبطة\n\nسيتم الاحتفاظ بـ:\n• العملاء\n• المنتجات\n• الأقسام\n• المستخدمين\n• الموردين\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف المبيعات',
      Colors.blue,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف المبيعات...');

      final db = context.read<DatabaseService>();
      await db.deleteSalesOnly();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف المبيعات بنجاح', Colors.blue);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف المبيعات: $e', Colors.red);
    }
  }

  Future<void> _deleteCustomersOnly() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف العملاء فقط',
      'هل أنت متأكد من حذف جميع العملاء؟\n\nسيتم حذف:\n• جميع العملاء\n• جميع المدفوعات المرتبطة\n\nسيتم الاحتفاظ بـ:\n• المبيعات\n• المنتجات\n• الأقسام\n• المستخدمين\n• الموردين\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف العملاء',
      Colors.green,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف العملاء...');

      final db = context.read<DatabaseService>();
      await db.deleteCustomersOnly();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف العملاء بنجاح', Colors.green);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف العملاء: $e', Colors.red);
    }
  }

  Future<void> _deletePaymentsOnly() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف المدفوعات فقط',
      'هل أنت متأكد من حذف جميع المدفوعات؟\n\nسيتم حذف:\n• جميع سجلات المدفوعات\n\nسيتم الاحتفاظ بـ:\n• المبيعات\n• العملاء\n• المنتجات\n• الأقسام\n• المستخدمين\n• الموردين\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف المدفوعات',
      Colors.teal,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف المدفوعات...');

      final db = context.read<DatabaseService>();
      await db.deletePaymentsOnly();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف المدفوعات بنجاح', Colors.teal);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف المدفوعات: $e', Colors.red);
    }
  }

  Future<void> _deleteExpensesOnly() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف المصروفات فقط',
      'هل أنت متأكد من حذف جميع المصروفات؟\n\nسيتم حذف:\n• جميع سجلات المصروفات\n\nسيتم الاحتفاظ بـ:\n• المبيعات\n• العملاء\n• المنتجات\n• الأقسام\n• المستخدمين\n• الموردين\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف المصروفات',
      Colors.indigo,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف المصروفات...');

      final db = context.read<DatabaseService>();
      await db.deleteExpensesOnly();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف المصروفات بنجاح', Colors.indigo);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف المصروفات: $e', Colors.red);
    }
  }

  Future<void> _deleteInstallmentsOnly() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف الأقساط فقط',
      'هل أنت متأكد من حذف جميع الأقساط؟\n\nسيتم حذف:\n• جميع سجلات الأقساط\n\nسيتم الاحتفاظ بـ:\n• المبيعات\n• العملاء\n• المنتجات\n• الأقسام\n• المستخدمين\n• الموردين\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف الأقساط',
      Colors.cyan,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف الأقساط...');

      final db = context.read<DatabaseService>();
      await db.deleteInstallmentsOnly();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف الأقساط بنجاح', Colors.cyan);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف الأقساط: $e', Colors.red);
    }
  }

  Future<void> _deleteUsersOnly() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف المستخدمين فقط',
      'هل أنت متأكد من حذف جميع المستخدمين؟\n\nسيتم حذف:\n• جميع المستخدمين\n\nتحذير: قد تفقد القدرة على تسجيل الدخول!\n\nسيتم الاحتفاظ بـ:\n• المبيعات\n• العملاء\n• المنتجات\n• الأقسام\n• الموردين\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف المستخدمين',
      Colors.brown,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف المستخدمين...');

      final db = context.read<DatabaseService>();
      await db.deleteUsersOnly();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف المستخدمين بنجاح', Colors.brown);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف المستخدمين: $e', Colors.red);
    }
  }

  Future<void> _deleteSuppliersOnly() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'حذف الموردين فقط',
      'هل أنت متأكد من حذف جميع الموردين؟\n\nسيتم حذف:\n• جميع الموردين\n\nسيتم الاحتفاظ بـ:\n• المبيعات\n• العملاء\n• المنتجات\n• الأقسام\n• المستخدمين\n\nهذه العملية لا يمكن التراجع عنها!',
      'حذف الموردين',
      Colors.deepOrange,
    );

    if (!confirmed) return;

    try {
      _showLoadingDialog('جاري حذف الموردين...');

      final db = context.read<DatabaseService>();
      await db.deleteSuppliersOnly();

      Navigator.of(context).pop();
      _showSnackBar('تم حذف الموردين بنجاح', Colors.deepOrange);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showSnackBar('خطأ في حذف الموردين: $e', Colors.red);
    }
  }
}
