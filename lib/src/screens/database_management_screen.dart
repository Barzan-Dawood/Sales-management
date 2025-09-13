import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_migration_service.dart';

class DatabaseManagementScreen extends StatefulWidget {
  final bool showAppBar;

  const DatabaseManagementScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<DatabaseManagementScreen> createState() =>
      _DatabaseManagementScreenState();
}

class _DatabaseManagementScreenState extends State<DatabaseManagementScreen> {
  Map<String, dynamic>? _databaseInfo;
  List<Map<String, dynamic>> _backups = [];
  bool _loading = false;
  String _customDatabasePath = '';

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
    _loadBackups();
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() => _loading = true);
    try {
      final info = await DatabaseMigrationService.getDatabaseInfo();
      setState(() => _databaseInfo = info);
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل معلومات قاعدة البيانات: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadBackups() async {
    try {
      final backups = await DatabaseMigrationService.getBackupList();
      setState(() => _backups = backups);
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل النسخ الاحتياطية: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات قاعدة البيانات
                  if (_databaseInfo != null) ...[
                    _buildDatabaseInfoCard(),
                    const SizedBox(height: 6),
                  ],

                  // عمليات النسخ الاحتياطي
                  _buildBackupSection(),
                  const SizedBox(height: 6),

                  // عمليات الترحيل
                  _buildMigrationSection(),
                  const SizedBox(height: 6),

                  // النسخ الاحتياطية المحفوظة
                  _buildBackupsList(),
                ],
              ),
            ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة قاعدة البيانات',
              style: TextStyle(fontSize: 14)),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 48,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () {
                _loadDatabaseInfo();
                _loadBackups();
              },
            ),
          ],
        ),
        body: content,
      );
    } else {
      return content;
    }
  }

  Widget _buildDatabaseInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.storage,
                      color: Colors.blue.shade600, size: 14),
                ),
                const SizedBox(width: 6),
                const Text(
                  'معلومات قاعدة البيانات',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildInfoRow('الإصدار', '${_databaseInfo!['version']}'),
            _buildInfoRow('الوصف', _databaseInfo!['versionDescription']),
            _buildInfoRow('عدد الجداول', '${_databaseInfo!['tablesCount']}'),
            _buildInfoRow('حجم قاعدة البيانات',
                _formatFileSize(_databaseInfo!['databaseSize'])),
            _buildDatabasePathRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.backup,
                      color: Colors.green.shade600, size: 20),
                ),
                const SizedBox(width: 6),
                const Text(
                  'النسخ الاحتياطية',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createBackup,
                    icon: const Icon(Icons.backup, size: 14),
                    label: const Text('إنشاء', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _restoreFromBackup,
                    icon: const Icon(Icons.restore, size: 14),
                    label:
                        const Text('استعادة', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportDatabase,
                    icon: const Icon(Icons.upload, size: 14),
                    label: const Text('تصدير', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _importDatabase,
                    icon: const Icon(Icons.download, size: 14),
                    label:
                        const Text('استيراد', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.upgrade,
                      color: Colors.purple.shade600, size: 20),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ترحيل قاعدة البيانات',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'ترحيل قاعدة البيانات إلى الإصدار الأحدث مع الحفاظ على جميع البيانات.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _migrateDatabase,
                icon: const Icon(Icons.upgrade, size: 18),
                label: const Text('ترحيل إلى الإصدار الأحدث',
                    style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.history,
                      color: Colors.orange.shade600, size: 20),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'النسخ الاحتياطية المحفوظة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadBackups,
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_backups.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    'لا توجد نسخ احتياطية',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _backups.length,
                itemBuilder: (context, index) {
                  final backup = _backups[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.backup,
                            color: Colors.blue.shade600, size: 14),
                      ),
                      title: Text(
                        backup['name'],
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'الحجم: ${_formatFileSize(backup['size'])} • التاريخ: ${_formatDate(backup['created'])}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'restore',
                            child: Row(
                              children: [
                                Icon(Icons.restore,
                                    color: Colors.green.shade600, size: 14),
                                const SizedBox(width: 6),
                                const Text('استعادة',
                                    style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete,
                                    color: Colors.red.shade600, size: 14),
                                const SizedBox(width: 6),
                                const Text('حذف',
                                    style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'restore') {
                            _restoreFromSpecificBackup(backup['path']);
                          } else if (value == 'delete') {
                            _deleteBackup(backup['path']);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildDatabasePathRow() {
    final currentPath = _customDatabasePath.isNotEmpty
        ? _customDatabasePath
        : _databaseInfo!['databasePath'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'مسار قاعدة البيانات',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    currentPath,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _changeDatabasePath,
                      icon: const Icon(Icons.folder_open, size: 14),
                      label: const Text('تغيير المسار',
                          style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: _resetToDefaultPath,
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('إعادة تعيين',
                          style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: () => _copyPathToClipboard(currentPath),
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('نسخ', style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // الوظائف
  Future<void> _createBackup() async {
    try {
      setState(() => _loading = true);
      await DatabaseMigrationService.createBackup();
      _showSuccessSnackBar('تم إنشاء النسخة الاحتياطية بنجاح');
      _loadBackups();
    } catch (e) {
      _showErrorSnackBar('خطأ في إنشاء النسخة الاحتياطية: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _restoreFromBackup() async {
    final confirmed = await _showConfirmDialog(
      'استعادة النسخة الاحتياطية',
      'هل أنت متأكد من استعادة النسخة الاحتياطية؟ سيتم استبدال البيانات الحالية.',
    );

    if (confirmed) {
      try {
        setState(() => _loading = true);
        await DatabaseMigrationService.restoreFromFile();
        _showSuccessSnackBar('تم استعادة النسخة الاحتياطية بنجاح');
        _loadDatabaseInfo();
      } catch (e) {
        _showErrorSnackBar('خطأ في استعادة النسخة الاحتياطية: $e');
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _restoreFromSpecificBackup(String backupPath) async {
    final confirmed = await _showConfirmDialog(
      'استعادة النسخة الاحتياطية',
      'هل أنت متأكد من استعادة هذه النسخة الاحتياطية؟ سيتم استبدال البيانات الحالية.',
    );

    if (confirmed) {
      try {
        setState(() => _loading = true);
        // تنفيذ استعادة من مسار محدد
        await DatabaseMigrationService.restoreFromFile();
        _showSuccessSnackBar('تم استعادة النسخة الاحتياطية بنجاح');
        _loadDatabaseInfo();
      } catch (e) {
        _showErrorSnackBar('خطأ في استعادة النسخة الاحتياطية: $e');
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _exportDatabase() async {
    try {
      setState(() => _loading = true);
      await DatabaseMigrationService.exportDatabase();
      _showSuccessSnackBar('تم تصدير قاعدة البيانات بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تصدير قاعدة البيانات: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _importDatabase() async {
    final confirmed = await _showConfirmDialog(
      'استيراد قاعدة البيانات',
      'هل أنت متأكد من استيراد قاعدة البيانات؟ سيتم استبدال البيانات الحالية.',
    );

    if (confirmed) {
      try {
        setState(() => _loading = true);
        await DatabaseMigrationService.importDatabase();
        _showSuccessSnackBar('تم استيراد قاعدة البيانات بنجاح');
        _loadDatabaseInfo();
      } catch (e) {
        _showErrorSnackBar('خطأ في استيراد قاعدة البيانات: $e');
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _migrateDatabase() async {
    final confirmed = await _showConfirmDialog(
      'ترحيل قاعدة البيانات',
      'هل أنت متأكد من ترحيل قاعدة البيانات إلى الإصدار الأحدث؟ يُنصح بإنشاء نسخة احتياطية أولاً.',
    );

    if (confirmed) {
      try {
        setState(() => _loading = true);
        await DatabaseMigrationService.migrateToNewVersion();
        _showSuccessSnackBar('تم ترحيل قاعدة البيانات بنجاح');
        _loadDatabaseInfo();
      } catch (e) {
        _showErrorSnackBar('خطأ في ترحيل قاعدة البيانات: $e');
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteBackup(String backupPath) async {
    final confirmed = await _showConfirmDialog(
      'حذف النسخة الاحتياطية',
      'هل أنت متأكد من حذف هذه النسخة الاحتياطية؟',
    );

    if (confirmed) {
      try {
        await DatabaseMigrationService.deleteBackup(backupPath);
        _showSuccessSnackBar('تم حذف النسخة الاحتياطية بنجاح');
        _loadBackups();
      } catch (e) {
        _showErrorSnackBar('خطأ في حذف النسخة الاحتياطية: $e');
      }
    }
  }

  // الوظائف المساعدة
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // دوال إدارة مسار قاعدة البيانات
  Future<void> _changeDatabasePath() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder_open, color: Colors.blue.shade600),
            const SizedBox(width: 6),
            const Text('تغيير مسار قاعدة البيانات'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر مجلد جديد لحفظ قاعدة البيانات:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'المسار الحالي: ${_customDatabasePath.isNotEmpty ? _customDatabasePath : _databaseInfo!['databasePath']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'تحذير: تغيير مسار قاعدة البيانات يتطلب إعادة تشغيل التطبيق',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _selectNewDatabasePath();
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('اختيار مجلد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectNewDatabasePath() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        final confirmed = await _showConfirmDialog(
          'تأكيد تغيير المسار',
          'هل أنت متأكد من تغيير مسار قاعدة البيانات إلى:\n$selectedDirectory\n\nسيتم إعادة تشغيل التطبيق بعد التغيير.',
        );

        if (confirmed) {
          setState(() {
            _customDatabasePath = selectedDirectory;
          });

          _showSuccessSnackBar('تم تغيير مسار قاعدة البيانات بنجاح');

          // عرض رسالة إعادة التشغيل
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.restart_alt, color: Colors.blue.shade600),
                    const SizedBox(width: 6),
                    const Text('إعادة تشغيل مطلوبة'),
                  ],
                ),
                content: const Text(
                  'تم تغيير مسار قاعدة البيانات بنجاح.\n\nيرجى إعادة تشغيل التطبيق لتطبيق التغييرات.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // يمكن إضافة منطق إعادة التشغيل هنا
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('موافق'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار المجلد: $e');
    }
  }

  Future<void> _resetToDefaultPath() async {
    final confirmed = await _showConfirmDialog(
      'إعادة تعيين المسار',
      'هل أنت متأكد من إعادة تعيين مسار قاعدة البيانات إلى المسار الافتراضي؟',
    );

    if (confirmed) {
      setState(() {
        _customDatabasePath = '';
      });

      _showSuccessSnackBar(
          'تم إعادة تعيين مسار قاعدة البيانات إلى المسار الافتراضي');
    }
  }

  Future<void> _copyPathToClipboard(String path) async {
    try {
      await Clipboard.setData(ClipboardData(text: path));
      _showSuccessSnackBar('تم نسخ المسار إلى الحافظة');
    } catch (e) {
      _showErrorSnackBar('خطأ في نسخ المسار: $e');
    }
  }
}
