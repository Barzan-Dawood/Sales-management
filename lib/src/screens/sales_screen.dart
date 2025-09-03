import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
import '../utils/format.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../utils/invoice_pdf.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _query = '';
  final List<Map<String, Object?>> _cart = [];
  String _type = 'cash';
  List<Map<String, Object?>> _lastInvoiceItems = [];
  String _lastType = 'cash';

  // Credit system variables
  DateTime? _dueDate;
  String _customerName = '';
  String _customerPhone = '';
  String _customerAddress = '';
  String _guarantorName = '';
  String _guarantorPhone = '';

  // Last invoice credit info
  DateTime? _lastDueDate;
  String _lastCustomerName = '';
  String _lastCustomerPhone = '';
  String _lastCustomerAddress = '';
  String _lastGuarantorName = '';
  String _lastGuarantorPhone = '';

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final total = _cart
        .fold<num>(
            0, (p, e) => p + ((e['price'] as num) * (e['quantity'] as num)))
        .toDouble();

    InputDecoration pill(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Top controls bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: pill('بحث عن منتج', Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: pill('نوع الدفع', Icons.payments_outlined),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                    DropdownMenuItem(
                        value: 'installment', child: Text('أقساط')),
                    DropdownMenuItem(value: 'credit', child: Text('أجل')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _type = v ?? 'cash';
                      // Clear credit fields when changing payment type
                      if (_type != 'credit') {
                        _customerName = '';
                        _customerPhone = '';
                        _customerAddress = '';
                        _guarantorName = '';
                        _guarantorPhone = '';
                        _dueDate = null;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                avatar: const Icon(Icons.attach_money, size: 18),
                label: Text(Formatters.currencyIQD(total)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Credit system fields - show only when credit is selected
          if (_type == 'credit') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'معلومات البيع بالأجل',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // Customer Name
                      SizedBox(
                        width: 200,
                        child: TextField(
                          decoration: pill('اسم العميل', Icons.person),
                          onChanged: (v) => _customerName = v,
                        ),
                      ),
                      // Customer Phone
                      SizedBox(
                        width: 200,
                        child: TextField(
                          decoration: pill('رقم الهاتف', Icons.phone),
                          onChanged: (v) => _customerPhone = v,
                        ),
                      ),
                      // Customer Address
                      SizedBox(
                        width: 300,
                        child: TextField(
                          decoration: pill('العنوان', Icons.location_on),
                          onChanged: (v) => _customerAddress = v,
                        ),
                      ),
                      // Due Date
                      SizedBox(
                        width: 200,
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => _dueDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _dueDate != null
                                      ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                      : 'تاريخ الاستحقاق',
                                  style: TextStyle(
                                    color: _dueDate != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Guarantor Information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security,
                                color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'معلومات الضامن',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 200,
                              child: TextField(
                                decoration:
                                    pill('اسم الضامن', Icons.person_outline),
                                onChanged: (v) => _guarantorName = v,
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              child: TextField(
                                decoration:
                                    pill('هاتف الضامن', Icons.phone_outlined),
                                onChanged: (v) => _guarantorPhone = v,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Expanded(
            child: Row(
              children: [
                // Products side
                Expanded(
                  child: Card(
                    child: Column(
                      children: [
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.06),
                          child: Row(
                            children: const [
                              Icon(Icons.inventory_2),
                              SizedBox(width: 8),
                              Text('المنتجات'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: FutureBuilder<List<Map<String, Object?>>>(
                            future: db.getAllProducts(query: _query),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final items = snapshot.data!;
                              return ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, i) {
                                  final p = items[i];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () => _addToCart(p),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(p['name']?.toString() ??
                                                      ''),
                                                  const SizedBox(height: 6),
                                                  Wrap(
                                                    spacing: 6,
                                                    children: [
                                                      Chip(
                                                        label: Text(Formatters
                                                            .currencyIQD(
                                                                p['price']
                                                                    as num)),
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      ),
                                                      Chip(
                                                        label: Text(
                                                            'المتاح: ${p['quantity']}'),
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.add_shopping_cart),
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
                  ),
                ),
                const SizedBox(width: 12),
                // Cart side
                Expanded(
                  child: Card(
                    child: Column(
                      children: [
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.06),
                          child: Row(
                            children: const [
                              Icon(Icons.shopping_cart_checkout),
                              SizedBox(width: 8),
                              Text('السلة'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _cart.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, i) {
                              final c = _cart[i];
                              final lineTotal =
                                  (c['price'] as num) * (c['quantity'] as num);
                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(c['name']?.toString() ?? ''),
                                  subtitle: Text('الكمية: ${c['quantity']}'),
                                  leading: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      final qty = (_cart[i]['quantity'] as int);
                                      final productId =
                                          _cart[i]['product_id'] as int;
                                      context
                                          .read<DatabaseService>()
                                          .adjustProductQuantity(
                                              productId, qty);
                                      setState(() => _cart.removeAt(i));
                                    },
                                  ),
                                  trailing: SizedBox(
                                    width: 240,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          tooltip: 'إنقاص',
                                          icon: const Icon(
                                              Icons.remove_circle_outline),
                                          onPressed: () => _decrementQty(i),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Theme.of(context)
                                                    .dividerColor),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text((c['quantity'] as int)
                                              .toString()),
                                        ),
                                        IconButton(
                                          tooltip: 'زيادة',
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          onPressed: () => _incrementQty(i),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(Formatters.currencyIQD(lineTotal)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Text('الإجمالي:',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(width: 8),
                              Text(Formatters.currencyIQD(total),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              TextButton(
                                onPressed: _cart.clear,
                                child: const Text('تفريغ'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _cart.isEmpty
                                    ? null
                                    : () async {
                                        // Validate credit sale requirements
                                        if (_type == 'credit') {
                                          if (_customerName.trim().isEmpty ||
                                              _customerPhone.trim().isEmpty ||
                                              _customerAddress.trim().isEmpty ||
                                              _guarantorName.trim().isEmpty ||
                                              _guarantorPhone.trim().isEmpty ||
                                              _dueDate == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'يرجى ملء جميع حقول البيع بالأجل'),
                                              backgroundColor: Colors.red,
                                            ));
                                            return;
                                          }
                                        }

                                        await db.createSale(
                                          type: _type == 'cash'
                                              ? 'cash'
                                              : _type == 'installment'
                                                  ? 'installment'
                                                  : 'credit',
                                          items: _cart,
                                          decrementStock: false,
                                        );
                                        if (!mounted) return;
                                        setState(() {
                                          _lastInvoiceItems = _cart
                                              .map((e) =>
                                                  Map<String, Object?>.from(e))
                                              .toList();
                                          _lastType = _type;

                                          // Save credit info for last invoice
                                          if (_type == 'credit') {
                                            _lastDueDate = _dueDate;
                                            _lastCustomerName = _customerName;
                                            _lastCustomerPhone = _customerPhone;
                                            _lastCustomerAddress =
                                                _customerAddress;
                                            _lastGuarantorName = _guarantorName;
                                            _lastGuarantorPhone =
                                                _guarantorPhone;
                                          }

                                          _cart.clear();
                                          // Clear credit fields
                                          if (_type == 'credit') {
                                            _customerName = '';
                                            _customerPhone = '';
                                            _customerAddress = '';
                                            _guarantorName = '';
                                            _guarantorPhone = '';
                                            _dueDate = null;
                                          }
                                        });

                                        String successMessage =
                                            'تم تسجيل الفاتورة';
                                        if (_type == 'credit') {
                                          successMessage =
                                              'تم تسجيل الفاتورة بالأجل - تاريخ الاستحقاق: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}';
                                        }

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(successMessage),
                                          backgroundColor: _type == 'credit'
                                              ? Colors.orange
                                              : Colors.green,
                                        ));
                                      },
                                icon: const Icon(Icons.check),
                                label: const Text('إتمام البيع'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _lastInvoiceItems.isEmpty
                                    ? null
                                    : () async {
                                        await _printInvoice(context);
                                      },
                                icon: const Icon(Icons.print),
                                label: const Text('طباعة الفاتورة'),
                              ),
                            ],
                          ),
                        ),

                        // Last Invoice Display
                        if (_lastInvoiceItems.isNotEmpty) ...[
                          const Divider(height: 1),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _lastType == 'credit'
                                  ? Colors.orange.shade50
                                  : _lastType == 'installment'
                                      ? Colors.blue.shade50
                                      : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _lastType == 'credit'
                                          ? Icons.schedule
                                          : _lastType == 'installment'
                                              ? Icons.credit_card
                                              : Icons.money,
                                      color: _lastType == 'credit'
                                          ? Colors.orange.shade700
                                          : _lastType == 'installment'
                                              ? Colors.blue.shade700
                                              : Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'آخر فاتورة - ${_lastType == 'credit' ? 'أجل' : _lastType == 'installment' ? 'أقساط' : 'نقدي'}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _lastType == 'credit'
                                            ? Colors.orange.shade700
                                            : _lastType == 'installment'
                                                ? Colors.blue.shade700
                                                : Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Credit information display
                                if (_lastType == 'credit' &&
                                    _lastCustomerName.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.orange.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'معلومات العميل',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 8,
                                          children: [
                                            _buildInfoChip(
                                                'الاسم',
                                                _lastCustomerName,
                                                Icons.person),
                                            _buildInfoChip(
                                                'الهاتف',
                                                _lastCustomerPhone,
                                                Icons.phone),
                                            _buildInfoChip(
                                                'العنوان',
                                                _lastCustomerAddress,
                                                Icons.location_on),
                                            _buildInfoChip(
                                                'تاريخ الاستحقاق',
                                                '${_lastDueDate?.day}/${_lastDueDate?.month}/${_lastDueDate?.year}',
                                                Icons.calendar_today),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'معلومات الضامن',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 8,
                                          children: [
                                            _buildInfoChip(
                                                'اسم الضامن',
                                                _lastGuarantorName,
                                                Icons.person_outline),
                                            _buildInfoChip(
                                                'هاتف الضامن',
                                                _lastGuarantorPhone,
                                                Icons.security),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Invoice items summary
                                Text(
                                  'المنتجات:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._lastInvoiceItems.map((item) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['name']?.toString() ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Text(
                                            '${item['quantity']} × ${Formatters.currencyIQD(item['price'] as num)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    )),

                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'الإجمالي:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _lastType == 'credit'
                                            ? Colors.orange.shade700
                                            : _lastType == 'installment'
                                                ? Colors.blue.shade700
                                                : Colors.green.shade700,
                                      ),
                                    ),
                                    Text(
                                      Formatters.currencyIQD(
                                        _lastInvoiceItems.fold<num>(
                                          0,
                                          (sum, item) =>
                                              sum +
                                              ((item['price'] as num) *
                                                  (item['quantity'] as num)),
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _lastType == 'credit'
                                            ? Colors.orange.shade700
                                            : _lastType == 'installment'
                                                ? Colors.blue.shade700
                                                : Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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

  void _addToCart(Map<String, Object?> p) {
    final existing = _cart.indexWhere((e) => e['product_id'] == p['id']);
    if (existing >= 0) {
      _incrementQty(existing);
      return;
    }
    final currentStock = (p['quantity'] as int? ?? 0);
    if (currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('المنتج غير متوفر في المخزون')));
      return;
    }
    // Reserve one immediately
    context.read<DatabaseService>().adjustProductQuantity(p['id'] as int, -1);
    setState(() => _cart.add({
          'product_id': p['id'],
          'name': p['name'],
          'price': p['price'],
          'cost': p['cost'],
          'quantity': 1,
          'available': currentStock - 1,
        }));
  }

  Future<void> _editQty(int index) async {
    final qty = TextEditingController(
        text: (_cart[index]['quantity'] as int).toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل الكمية'),
        content: TextField(
            controller: qty,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'الكمية')),
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
      setState(() => _cart[index]['quantity'] = int.tryParse(qty.text) ?? 1);
    }
  }

  void _incrementQty(int index) {
    final available = (_cart[index]['available'] as int?);
    final current = (_cart[index]['quantity'] as int);
    if (available != null && available <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('لا توجد كمية متاحة')));
      return;
    }
    setState(() {
      _cart[index]['quantity'] = current + 1;
      if (_cart[index]['available'] != null) {
        _cart[index]['available'] = (_cart[index]['available'] as int) - 1;
      }
    });
    // Reserve from stock
    final productId = _cart[index]['product_id'] as int;
    context.read<DatabaseService>().adjustProductQuantity(productId, -1);
  }

  void _decrementQty(int index) {
    final current = (_cart[index]['quantity'] as int);
    if (current <= 1) return;
    setState(() {
      _cart[index]['quantity'] = current - 1;
      if (_cart[index]['available'] != null) {
        _cart[index]['available'] = (_cart[index]['available'] as int) + 1;
      }
    });
    // Return to stock
    final productId = _cart[index]['product_id'] as int;
    context.read<DatabaseService>().adjustProductQuantity(productId, 1);
  }

  Future<void> _printInvoice(BuildContext context) async {
    final db = context.read<DatabaseService>();
    final settings = await db.database.query('settings', limit: 1);
    final shopName = (settings.isNotEmpty
        ? (settings.first['shop_name']?.toString() ?? 'المحل')
        : 'المحل');
    final phone =
        (settings.isNotEmpty ? settings.first['phone']?.toString() : null);
    final pdfData = await InvoicePdf.generate(
      shopName: shopName,
      phone: phone,
      items: _lastInvoiceItems,
      paymentType: _lastType,
    );
    try {
      await Printing.layoutPdf(onLayout: (format) async => pdfData);
    } catch (_) {
      // ignore printing fallback here to keep UI responsive
    }
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
