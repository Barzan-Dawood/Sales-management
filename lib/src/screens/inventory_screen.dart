import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: 'نقص الكمية'), Tab(text: 'بطيء الحركة')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                FutureBuilder<List<Map<String, Object?>>>(
                  future: db.getLowStock(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final items = snapshot.data!;
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = items[i];
                        return ListTile(
                          title: Text(p['name']?.toString() ?? ''),
                          subtitle: Text(
                              'الكمية: ${p['quantity']} | الحد الأدنى: ${p['min_quantity']}'),
                        );
                      },
                    );
                  },
                ),
                FutureBuilder<List<Map<String, Object?>>>(
                  future: db.slowMovingProducts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final items = snapshot.data!;
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = items[i];
                        return ListTile(
                          title: Text(p['name']?.toString() ?? ''),
                          subtitle: const Text('لا توجد مبيعات خلال 30 يوماً'),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
