import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Tabs header
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue.shade800,
            unselectedLabelColor: Colors.grey.shade700,
            indicatorColor: Colors.blue.shade600,
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
              _buildSalesPlaceholder(),
              _buildInventoryPlaceholder(),
              _buildDebtsPlaceholder(),
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

  // Placeholders to be replaced with full implementations next
  Widget _buildSalesPlaceholder() => Center(child: Text('تقارير المبيعات'));
  Widget _buildInventoryPlaceholder() => Center(child: Text('تقارير المخزون'));
  Widget _buildDebtsPlaceholder() => Center(child: Text('تقارير الديون'));

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
