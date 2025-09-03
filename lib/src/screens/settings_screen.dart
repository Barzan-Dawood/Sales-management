import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/backup/backup_service.dart';
import '../services/db/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _shopName = TextEditingController();
  final _phone = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>().database;
    final backup = BackupService(context.read<DatabaseService>());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('بيانات المحل', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _shopName,
                    decoration: const InputDecoration(labelText: 'اسم المحل'))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _phone,
                    decoration:
                        const InputDecoration(labelText: 'رقم الهاتف'))),
          ]),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () async {
                final has = await db.query('settings', limit: 1);
                if (has.isEmpty) {
                  await db.insert('settings', {
                    'shop_name': _shopName.text.trim(),
                    'phone': _phone.text.trim()
                  });
                } else {
                  await db.update(
                      'settings',
                      {
                        'shop_name': _shopName.text.trim(),
                        'phone': _phone.text.trim()
                      },
                      where: 'id = ?',
                      whereArgs: [has.first['id']]);
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
              },
              child: const Text('حفظ'),
            ),
          ),
          const SizedBox(height: 16),
          Text('قاعدة البيانات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            FilledButton.icon(
              onPressed: () async {
                final path = await backup.backupDatabase();
                if (!mounted) return;
                if (path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('تم حفظ النسخة الاحتياطية في: $path')));
                }
              },
              icon: const Icon(Icons.backup),
              label: const Text('نسخ احتياطي'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final name = await backup.restoreDatabase();
                if (!mounted) return;
                if (name != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم الاسترجاع من: $name')));
                }
              },
              icon: const Icon(Icons.restore),
              label: const Text('استرجاع'),
            ),
          ]),
        ],
      ),
    );
  }
}
