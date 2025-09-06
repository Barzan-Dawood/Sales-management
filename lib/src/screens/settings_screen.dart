import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          Wrap(spacing: 8, children: [
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
          ]),
        ],
      ),
    );
  }
}
