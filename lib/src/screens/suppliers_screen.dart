import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
import '../utils/format.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'بحث بالاسم أو الهاتف'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('إضافة مورد')),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<Map<String, Object?>>>(
            future: db.getSuppliers(query: _query),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final items = snapshot.data!;
              return Card(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = items[i];
                    return ListTile(
                      title: Text(s['name']?.toString() ?? ''),
                      subtitle: Text(s['phone']?.toString() ?? ''),
                      trailing: Text(Formatters.currencyIQD(
                          (s['total_payable'] as num?) ?? 0)),
                      onTap: () => _openEditor(supplier: s),
                      leading: IconButton(
                        tooltip: 'حذف',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(s['id'] as int),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _delete(int id) async {
    final db = context.read<DatabaseService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المورد'),
        content: const Text('هل تريد حذف هذا المورد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    await db.deleteSupplier(id);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openEditor({Map<String, Object?>? supplier}) async {
    final db = context.read<DatabaseService>();
    final name =
        TextEditingController(text: supplier?['name']?.toString() ?? '');
    final phone =
        TextEditingController(text: supplier?['phone']?.toString() ?? '');
    final address =
        TextEditingController(text: supplier?['address']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(supplier == null ? 'إضافة مورد' : 'تعديل مورد'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'الاسم')),
              const SizedBox(height: 8),
              TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'الهاتف')),
              const SizedBox(height: 8),
              TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'العنوان')),
            ],
          ),
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
      await db.upsertSupplier({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim()
      }, id: supplier?['id'] as int?);
      if (!mounted) return;
      setState(() {});
    }
  }
}
