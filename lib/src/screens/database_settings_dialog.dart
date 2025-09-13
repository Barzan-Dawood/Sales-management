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
