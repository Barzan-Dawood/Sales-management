import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
import '../utils/export.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _slowDays = 30;

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المخزون'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'نقص الكمية'),
              Tab(text: 'بطيء الحركة'),
              Tab(text: 'نفاد'),
            ],
          ),
          actions: [
            PopupMenuButton<int>(
              tooltip: 'تحديد فترة البطء',
              onSelected: (v) => setState(() => _slowDays = v),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 7, child: Text('آخر 7 أيام')),
                PopupMenuItem(value: 30, child: Text('آخر 30 يوماً')),
                PopupMenuItem(value: 90, child: Text('آخر 90 يوماً')),
              ],
              icon: const Icon(Icons.trending_down),
            ),
            IconButton(
              onPressed: () async {
                await _exportInventory(db);
              },
              tooltip: 'تصدير PDF',
              icon: const Icon(Icons.picture_as_pdf),
            ),
            IconButton(
              onPressed: _refresh,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.getLowStock(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                        message: snapshot.error.toString(), onRetry: _refresh);
                  }
                  final items = snapshot.data ?? const <Map<String, Object?>>[];
                  if (items.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: 'لا توجد أصناف منخفضة الكمية',
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final name = p['name']?.toString() ?? '';
                      final quantity = p['quantity']?.toString() ?? '0';
                      final minQuantity = p['min_quantity']?.toString() ?? '0';
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                              name.isNotEmpty ? name.characters.first : '?'),
                        ),
                        title: Text(name, textAlign: TextAlign.right),
                        subtitle: Text(
                            'الكمية: $quantity | الحد الأدنى: $minQuantity',
                            textAlign: TextAlign.right),
                        trailing: _StatusChip(
                            label: 'منخفض',
                            color: Colors.red.shade100,
                            textColor: Colors.red.shade800),
                      );
                    },
                  );
                },
              ),
            ),
            RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.slowMovingProducts(days: _slowDays),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                        message: snapshot.error.toString(), onRetry: _refresh);
                  }
                  final items = snapshot.data ?? const <Map<String, Object?>>[];
                  if (items.isEmpty) {
                    return _EmptyState(
                      icon: Icons.hourglass_empty,
                      message:
                          'لا توجد أصناف بطيئة الحركة خلال آخر $_slowDays يوماً',
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final name = p['name']?.toString() ?? '';
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.trending_down)),
                        title: Text(name, textAlign: TextAlign.right),
                        subtitle: Text('لا توجد مبيعات خلال $_slowDays يوماً',
                            textAlign: TextAlign.right),
                        trailing: _StatusChip(
                            label: 'بطيء',
                            color: Colors.orange.shade100,
                            textColor: Colors.orange.shade800),
                      );
                    },
                  );
                },
              ),
            ),
            RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.getOutOfStock(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                        message: snapshot.error.toString(), onRetry: _refresh);
                  }
                  final items = snapshot.data ?? const <Map<String, Object?>>[];
                  if (items.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.inventory_outlined,
                      message: 'لا توجد أصناف نافدة من المخزون',
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final name = p['name']?.toString() ?? '';
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.report_gmailerrorred_outlined)),
                        title: Text(name, textAlign: TextAlign.right),
                        subtitle:
                            const Text('الكمية: 0', textAlign: TextAlign.right),
                        trailing: _StatusChip(
                            label: 'نفاد',
                            color: Colors.grey.shade200,
                            textColor: Colors.grey.shade800),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on _InventoryScreenState {
  Future<void> _exportInventory(DatabaseService db) async {
    try {
      // اجلب كل القوائم مرة واحدة
      final results = await Future.wait<List<Map<String, Object?>>>([
        db.getLowStock(),
        db.slowMovingProducts(days: _slowDays),
        db.getOutOfStock(),
      ]);

      final low = results[0];
      final slow = results[1];
      final out = results[2];

      // ابنِ أسطر الجدول (مقلوبة RTL عبر PdfExporter)
      final rows = <List<String>>[
        ['القسم', 'المنتج', 'الكمية', 'الحد الأدنى/ملاحظة'],
        ...low.map((p) => [
              'منخفض',
              (p['name'] ?? '').toString(),
              (p['quantity'] ?? 0).toString(),
              (p['min_quantity'] ?? 0).toString(),
            ]),
        ...slow.map((p) => [
              'بطيء',
              (p['name'] ?? '').toString(),
              (p['quantity'] ?? 0).toString(),
              'لا مبيعات خلال $_slowDays يوماً',
            ]),
        ...out.map((p) => [
              'نفاد',
              (p['name'] ?? '').toString(),
              '0',
              '-',
            ]),
      ];

      final saved = await PdfExporter.exportSimpleTable(
        filename: 'inventory_report.pdf',
        title: 'تقرير المخزون',
        rows: rows,
      );
      if (!mounted) return;
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ التقرير في: $saved')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير تقرير المخزون: $e')),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 56, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          )
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatusChip(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
    );
  }
}
