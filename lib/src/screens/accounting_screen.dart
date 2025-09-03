import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
import '../utils/format.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  DateTimeRange? _range;
  final _title = TextEditingController();
  final _amount = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            FilledButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 1),
                  initialDateRange: _range ??
                      DateTimeRange(
                          start: now.subtract(const Duration(days: 30)),
                          end: now),
                );
                if (picked != null) setState(() => _range = picked);
              },
              icon: const Icon(Icons.date_range),
              label: Text(_range == null
                  ? 'الفترة: آخر 30 يوم'
                  : 'الفترة: ${_range!.start.toString().substring(0, 10)} - ${_range!.end.toString().substring(0, 10)}'),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _addExpense(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة مصروف'),
            )
          ]),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, double>>(
            future: db.profitAndLoss(from: _range?.start, to: _range?.end),
            builder: (context, snap) {
              final data = snap.data ??
                  {'sales': 0, 'profit': 0, 'expenses': 0, 'net': 0};
              return Wrap(spacing: 12, runSpacing: 12, children: [
                _tile('المبيعات', Formatters.currencyIQD(data['sales'] ?? 0),
                    Colors.blue),
                _tile('الربح الإجمالي',
                    Formatters.currencyIQD(data['profit'] ?? 0), Colors.green),
                _tile('المصاريف', Formatters.currencyIQD(data['expenses'] ?? 0),
                    Colors.orange),
                _tile('الصافي', Formatters.currencyIQD(data['net'] ?? 0),
                    (data['net'] ?? 0) >= 0 ? Colors.teal : Colors.red),
              ]);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: db.getExpenses(from: _range?.start, to: _range?.end),
              builder: (context, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final items = snap.data!;
                return Card(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = items[i];
                      return ListTile(
                        title: Text(e['title']?.toString() ?? ''),
                        subtitle: Text(
                            e['created_at']?.toString().substring(0, 16) ?? ''),
                        trailing: Text(
                            Formatters.currencyIQD((e['amount'] as num?) ?? 0)),
                        leading: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await db.deleteExpense(e['id'] as int);
                            if (!mounted) return;
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
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

  Future<void> _addExpense(BuildContext context) async {
    final db = context.read<DatabaseService>();
    _title.clear();
    _amount.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة مصروف'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'العنوان')),
            const SizedBox(height: 8),
            TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true) {
      final amount = double.tryParse(_amount.text) ?? 0;
      await db.addExpense(_title.text.trim(), amount);
      if (!mounted) return;
      setState(() {});
    }
  }
}
