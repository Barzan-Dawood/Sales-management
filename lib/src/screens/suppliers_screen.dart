// ignore_for_file: curly_braces_in_flow_control_structures

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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'بحث بالاسم أو الهاتف',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('إضافة مورد')),
          ]),
        ),
        const SizedBox(height: 12),
        // ملاحظة توضيحية
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'المستحق: هو المبلغ الواجب دفعه للمورد (الحسابات الدائنة). يظهر بالبرتقالي إن كان عليك مستحقات وبالأخضر إن لم يكن.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<Map<String, Object?>>>(
            future: db.getSuppliers(query: _query),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final items = snapshot.data!;

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا يوجد موردين',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _query.isEmpty
                                  ? 'قم بإضافة موردين جدد للبدء'
                                  : 'لم يتم العثور على موردين مطابقين للبحث',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _openEditor(),
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة مورد جديد'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.only(bottom: 12),
                itemBuilder: (context, i) {
                  final s = items[i];
                  final name = s['name']?.toString() ?? '';
                  final phone = s['phone']?.toString() ?? '';
                  final payable =
                      (s['total_payable'] as num?)?.toDouble() ?? 0.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.purple.shade50,
                              child: const Icon(Icons.business,
                                  color: Colors.purple, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          phone.isEmpty ? '-' : phone,
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('المستحق',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.currencyIQD(payable),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: payable > 0
                                        ? Colors.orange.shade700
                                        : Colors.green.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'تعديل',
                                      onPressed: () => _openEditor(supplier: s),
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18),
                                    ),
                                    IconButton(
                                      tooltip: 'حذف',
                                      onPressed: () => _delete(s['id'] as int),
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
