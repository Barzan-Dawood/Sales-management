// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/format.dart';
import '../utils/export.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _period = 'daily';
  DateTime _selected = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final auth = context.watch<AuthProvider>();

    // فحص صلاحية عرض التقارير
    if (!auth.hasPermission(UserPermission.viewReports)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('التقارير'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'ليس لديك صلاحية للوصول إلى هذه الصفحة',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'هذه الصفحة متاحة لجميع المستخدمين',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Tabs header
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.summarize), text: 'الملخص'),
              Tab(icon: Icon(Icons.bar_chart), text: 'المبيعات'),
              Tab(icon: Icon(Icons.inventory_2), text: 'المخزون'),
              Tab(icon: Icon(Icons.payments), text: 'الديون'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(db),
              _buildSalesTab(db),
              _buildInventoryTab(db),
              _buildDebtsTab(db),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSummaryTab(DatabaseService db) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        DropdownButton<String>(
          value: _period,
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('يومي')),
            DropdownMenuItem(value: 'monthly', child: Text('شهري')),
            DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
          ],
          onChanged: (v) => setState(() => _period = v ?? 'daily'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDate: _selected,
            );
            if (picked != null) setState(() => _selected = picked);
          },
          icon: const Icon(Icons.date_range),
          label: Text(_selected.toString().substring(0, 10)),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () async {
            final data = await (() async {
              DateTime from;
              DateTime to;
              if (_period == 'daily') {
                from = DateTime(_selected.year, _selected.month, _selected.day);
                to = from.add(const Duration(days: 1));
              } else if (_period == 'monthly') {
                from = DateTime(_selected.year, _selected.month, 1);
                to = DateTime(_selected.year, _selected.month + 1, 1);
              } else {
                from = DateTime(_selected.year, 1, 1);
                to = DateTime(_selected.year + 1, 1, 1);
              }
              return context
                  .read<DatabaseService>()
                  .profitAndLoss(from: from, to: to);
            })();
            final rows = <List<String>>[
              ['البند', 'القيمة'],
              ['المبيعات', Formatters.currencyIQD(data['sales'] ?? 0)],
              ['الربح الإجمالي', Formatters.currencyIQD(data['profit'] ?? 0)],
              ['المصاريف', Formatters.currencyIQD(data['expenses'] ?? 0)],
              ['الصافي', Formatters.currencyIQD(data['net'] ?? 0)],
            ];
            final saved = await PdfExporter.exportSimpleTable(
              filename: 'summary_report.pdf',
              title: 'تقرير الملخص',
              rows: rows,
            );
            if (!mounted) return;
            if (saved != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حفظ التقرير في: $saved')));
            }
          },
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('تصدير PDF'),
        )
      ]),
      const SizedBox(height: 12),
      FutureBuilder<Map<String, double>>(
        future: () async {
          DateTime from;
          DateTime to;
          if (_period == 'daily') {
            from = DateTime(_selected.year, _selected.month, _selected.day);
            to = from.add(const Duration(days: 1));
          } else if (_period == 'monthly') {
            from = DateTime(_selected.year, _selected.month, 1);
            to = DateTime(_selected.year, _selected.month + 1, 1);
          } else {
            from = DateTime(_selected.year, 1, 1);
            to = DateTime(_selected.year + 1, 1, 1);
          }
          return db.profitAndLoss(from: from, to: to);
        }(),
        builder: (context, snap) {
          final data =
              snap.data ?? {'sales': 0, 'profit': 0, 'expenses': 0, 'net': 0};
          return Wrap(spacing: 12, runSpacing: 12, children: [
            _tile('المبيعات', Formatters.currencyIQD(data['sales'] ?? 0),
                Colors.blue),
            _tile('الربح الإجمالي', Formatters.currencyIQD(data['profit'] ?? 0),
                Colors.green),
            _tile('المصاريف', Formatters.currencyIQD(data['expenses'] ?? 0),
                Colors.orange),
            _tile('الصافي', Formatters.currencyIQD(data['net'] ?? 0),
                (data['net'] ?? 0) >= 0 ? Colors.teal : Colors.red),
          ]);
        },
      ),
    ]);
  }

  // Sales tab
  Widget _buildSalesTab(DatabaseService db) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: db.getSalesHistory(sortDescending: true),
      builder: (context, snap) {
        final rows = snap.data ?? const [];
        final totals = <String, double>{};
        for (final r in rows) {
          final type = (r['type'] as String?) ?? '';
          final total = (r['total'] as num?)?.toDouble() ?? 0.0;
          final typeAr = _typeText(type);
          totals[typeAr] = (totals[typeAr] ?? 0) + total;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('تفصيل حسب نوع الدفع',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  final csv = <List<String>>[
                    ['النوع', 'القيمة'],
                    ...totals.entries.map((e) => [e.key, e.value.toString()])
                  ];
                  await PdfExporter.exportDataTable(
                    filename: 'sales_breakdown.pdf',
                    title: 'تفصيل المبيعات',
                    headers: ['النوع', 'القيمة'],
                    rows: csv.skip(1).toList(),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('تصدير PDF'),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: totals.entries
                  .map((e) => _tile(
                      e.key, Formatters.currencyIQD(e.value), Colors.indigo))
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('آخر 10 فواتير',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length.clamp(0, 10),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.receipt_long),
                    title: Text(
                        '#${r['id']} - ${_typeText((r['type'] as String?) ?? '')}'),
                    subtitle: Text(
                        (r['created_at'] as String?)?.substring(0, 16) ?? ''),
                    trailing: Text(
                      Formatters.currencyIQD(
                          ((r['total'] as num?)?.toDouble() ?? 0)),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _typeText(String type) {
    switch (type) {
      case 'cash':
        return 'نقدي';
      case 'credit':
        return 'أجل';
      case 'installment':
        return 'أقساط';
      default:
        return 'غير محدد';
    }
  }

  // Inventory tab
  Widget _buildInventoryTab(DatabaseService db) {
    return FutureBuilder<List<List<Map<String, Object?>>>>(
      future: Future.wait([
        db.getLowStock(),
        db.slowMovingProducts(days: 30),
      ]),
      builder: (context, snap) {
        final low = (snap.data != null && snap.data!.isNotEmpty)
            ? snap.data![0]
            : <Map<String, Object?>>[];
        final slow = (snap.data != null && snap.data!.length > 1)
            ? snap.data![1]
            : <Map<String, Object?>>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('المخزون المنخفض والبطيء',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  final rows = <List<String>>[
                    ['النوع', 'المنتج', 'الكمية'],
                    ...low.map((p) => [
                          'منخفض',
                          (p['name'] ?? '').toString(),
                          (p['quantity'] ?? 0).toString(),
                        ]),
                    ...slow.map((p) => [
                          'بطيء',
                          (p['name'] ?? '').toString(),
                          (p['quantity'] ?? 0).toString(),
                        ]),
                  ];
                  await PdfExporter.exportDataTable(
                    filename: 'inventory_overview.pdf',
                    title: 'تقارير المخزون',
                    headers: rows.first,
                    rows: rows.skip(1).toList(),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('تصدير PDF'),
              ),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _listBox('منخفض المخزون', low)),
                  const SizedBox(width: 12),
                  Expanded(child: _listBox('بطيء الحركة (30 يوم)', slow)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _listBox(String title, List<Map<String, Object?>> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('لا توجد بيانات'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final p = items[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.inventory_2),
                          title: Text((p['name'] ?? '').toString()),
                          trailing: Text('${p['quantity']}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Debts tab
  Widget _buildDebtsTab(DatabaseService db) {
    return FutureBuilder<Map<String, double>>(
      future: db.getDebtStatistics(),
      builder: (context, snap) {
        final stats = snap.data ??
            {
              'total_debt': 0,
              'overdue_debt': 0,
              'total_payments': 0,
              'customers_with_debt': 0,
            };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _tile(
                    'إجمالي الديون',
                    Formatters.currencyIQD(stats['total_debt'] ?? 0),
                    Colors.deepOrange),
                _tile(
                    'ديون متأخرة',
                    Formatters.currencyIQD(stats['overdue_debt'] ?? 0),
                    Colors.red),
                _tile(
                    'إجمالي المدفوعات',
                    Formatters.currencyIQD(stats['total_payments'] ?? 0),
                    Colors.green),
                _tile(
                    'عملاء مدينون',
                    (stats['customers_with_debt'] ?? 0).toString(),
                    Colors.indigo),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Text('فواتير متأخرة',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  final overdue = await db.creditSales(overdueOnly: true);
                  final rows = <List<String>>[
                    ['#', 'العميل', 'المبلغ', 'تاريخ الاستحقاق'],
                    ...overdue.map((r) => [
                          (r['id'] ?? '').toString(),
                          (r['customer_name'] ?? '').toString(),
                          (r['total'] ?? 0).toString(),
                          (r['due_date'] ?? '').toString().substring(0, 10),
                        ]),
                  ];
                  await PdfExporter.exportDataTable(
                    filename: 'overdue_invoices.pdf',
                    title: 'فواتير متأخرة',
                    headers: rows.first,
                    rows: rows.skip(1).toList(),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('تصدير PDF'),
              ),
            ]),
            const SizedBox(height: 6),
            Expanded(
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.creditSales(overdueOnly: true),
                builder: (context, snap) {
                  final rows = snap.data ?? const [];
                  if (rows.isEmpty) {
                    return const Center(child: Text('لا توجد فواتير متأخرة'));
                  }
                  return ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(
                            '#${r['id']} - ${(r['customer_name'] ?? '').toString()}'),
                        subtitle: Text(
                            'استحقاق: ${(r['due_date'] ?? '').toString().substring(0, 10)}'),
                        trailing: Text(
                          Formatters.currencyIQD(
                              ((r['total'] as num?)?.toDouble() ?? 0)),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tile(String title, String value, Color color) {
    return SizedBox(
      width: 240,
      height: 100,
      child: Card(
        color: color.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
        ),
      ),
    );
  }
}
