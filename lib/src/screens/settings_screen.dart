import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup/backup_service.dart';
import '../services/db/database_service.dart';
import '../utils/strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final backup = BackupService(context.read<DatabaseService>());
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
                Text(
                  AppStrings.defaultShopName,
                  style: const TextStyle(fontSize: 16),
                ),
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
                Text(
                  AppStrings.defaultPhone,
                  style: const TextStyle(fontSize: 16),
                ),
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
                Text(
                  AppStrings.defaultAddress,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Developer Information Section
          Text(AppStrings.developerTitle1,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.code, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.developerTitle2,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.developerInfo,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Database Section
          Text(AppStrings.database,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              onPressed: () async {
                final path = await backup.backupDatabase();
                if (!mounted) return;
                if (path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${AppStrings.backupSaved} $path')));
                }
              },
              icon: const Icon(Icons.backup),
              label: const Text(AppStrings.backup),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final name = await backup.restoreDatabase();
                if (!mounted) return;
                if (name != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${AppStrings.backupRestored} $name')));
                }
              },
              icon: const Icon(Icons.restore),
              label: const Text(AppStrings.restore),
            ),
            const SizedBox(height: 4),
            const Text(
              'النسخ الاحتياطي: سيُطلب منك اختيار مكان لحفظ ملف قاعدة البيانات (.db).\n'
              'الاستعادة: اختر ملف قاعدة بيانات سابق لاسترجاع بياناتك. سيتم إغلاق القاعدة مؤقتاً ثم إعادة فتحها.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ]),
          const SizedBox(height: 16),
          Text('النسخ الاحتياطي التلقائي',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _AutoBackupCard(backup: backup),
        ],
      ),
    );
  }
}

class _AutoBackupCard extends StatefulWidget {
  const _AutoBackupCard({required this.backup});
  final BackupService backup;
  @override
  State<_AutoBackupCard> createState() => _AutoBackupCardState();
}

class _AutoBackupCardState extends State<_AutoBackupCard> {
  String _frequency = 'off'; // off, daily, weekly
  String? _directory;
  int _keep = 10;

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
            'اختر تكرار النسخ ومجلد الحفظ وعدد النسخ التي سيتم الاحتفاظ بها.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(children: [
            DropdownButton<String>(
              value: _frequency,
              items: const [
                DropdownMenuItem(value: 'off', child: Text('إيقاف')),
                DropdownMenuItem(value: 'daily', child: Text('يومي')),
                DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
              ],
              onChanged: (v) => setState(() => _frequency = v ?? 'off'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final dir = await FilePicker.platform.getDirectoryPath();
                  if (dir != null) setState(() => _directory = dir);
                },
                icon: const Icon(Icons.folder_open),
                label: Text(_directory ?? 'اختر مجلد النسخ'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'عدد النسخ',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: _keep.toString()),
                keyboardType: TextInputType.number,
                onSubmitted: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null && parsed > 0) {
                    setState(() => _keep = parsed);
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            FilledButton.icon(
              onPressed: _directory == null
                  ? null
                  : () async {
                      final path =
                          await widget.backup.backupToDirectory(_directory!);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم إنشاء نسخة: $path')),
                      );
                    },
              icon: const Icon(Icons.play_arrow),
              label: const Text('إنشاء نسخة الآن'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'تم حفظ الإعدادات: التكرار=$_frequency، المجلد=${_directory ?? '-'}، الاحتفاظ=$_keep'),
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('حفظ الإعدادات'),
            ),
          ]),
        ],
      ),
    );
  }
}
