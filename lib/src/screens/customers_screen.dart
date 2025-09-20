// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
import '../utils/format.dart';
import '../utils/dark_mode_utils.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DarkModeUtils.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DarkModeUtils.getBorderColor(context)),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('إضافة عميل'),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // ملاحظة توضيحية
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DarkModeUtils.getInfoColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: DarkModeUtils.getInfoColor(context).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: DarkModeUtils.getInfoColor(context), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الدين: هو المبلغ المستحق استلامه من العميل. تظهر القيمة باللون الأحمر إن كان عليه دين وبالأخضر إذا لا يوجد دين.',
                    style: TextStyle(
                        fontSize: 12,
                        color: DarkModeUtils.getInfoColor(context)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: db.getCustomers(query: _query),
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
                            color: DarkModeUtils.getBackgroundColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: DarkModeUtils.getBorderColor(context),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 64,
                                color: DarkModeUtils.getSecondaryTextColor(
                                    context),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا يوجد عملاء',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: DarkModeUtils.getSecondaryTextColor(
                                      context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _query.isEmpty
                                    ? 'قم بإضافة عملاء جدد للبدء'
                                    : 'لم يتم العثور على عملاء مطابقين للبحث',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: DarkModeUtils.getSecondaryTextColor(
                                      context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _openEditor(),
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة عميل جديد'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      DarkModeUtils.getInfoColor(context),
                                  foregroundColor:
                                      DarkModeUtils.getCardColor(context),
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
                    final c = items[i];
                    final name = c['name']?.toString() ?? '';
                    final phone = c['phone']?.toString() ?? '';
                    final debt = (c['total_debt'] as num?)?.toDouble() ?? 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: DarkModeUtils.getCardColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: DarkModeUtils.getBorderColor(context)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Avatar circle
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    DarkModeUtils.getInfoColor(context)
                                        .withOpacity(0.1),
                                child: Icon(Icons.person,
                                    color: DarkModeUtils.getInfoColor(context),
                                    size: 18),
                              ),
                              const SizedBox(width: 10),
                              // Name & phone
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.phone,
                                            size: 14,
                                            color: DarkModeUtils
                                                .getSecondaryTextColor(
                                                    context)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            phone.isEmpty ? '-' : phone,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: DarkModeUtils
                                                    .getSecondaryTextColor(
                                                        context)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Debt with label
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('الدين',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: DarkModeUtils
                                              .getSecondaryTextColor(context),
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text(
                                    Formatters.currencyIQD(debt),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: debt > 0
                                          ? DarkModeUtils.getErrorColor(context)
                                          : DarkModeUtils.getSuccessColor(
                                              context),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'تعديل',
                                        onPressed: () =>
                                            _openEditor(customer: c),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'حذف',
                                        onPressed: () =>
                                            _delete(c['id'] as int),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red,
                                        ),
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
          )
        ],
      ),
    );
  }

  Future<void> _delete(int id) async {
    final db = context.read<DatabaseService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العميل'),
        content: const Text('هل تريد حذف هذا العميل؟'),
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
    
    try {
      final deletedRows = await db.deleteCustomer(id);
      if (!mounted) return;
      
      if (deletedRows > 0) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف العميل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على العميل أو حدث خطأ في الحذف'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'خطأ في حذف العميل';
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        errorMessage = 'لا يمكن حذف العميل لأنه مرتبط بفواتير أو مدفوعات';
      } else if (e.toString().contains('database is locked')) {
        errorMessage = 'قاعدة البيانات قيد الاستخدام، حاول مرة أخرى';
      } else {
        errorMessage = 'خطأ في حذف العميل: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openEditor({Map<String, Object?>? customer}) async {
    final db = context.read<DatabaseService>();
    final name =
        TextEditingController(text: customer?['name']?.toString() ?? '');
    final phone =
        TextEditingController(text: customer?['phone']?.toString() ?? '');
    final address =
        TextEditingController(text: customer?['address']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(customer == null ? 'إضافة عميل' : 'تعديل عميل'),
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
      await db.upsertCustomer({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim()
      }, id: customer?['id'] as int?);
      if (!mounted) return;
      setState(() {});
    }
  }
}
