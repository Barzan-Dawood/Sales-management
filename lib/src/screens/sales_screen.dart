import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db/database_service.dart';
import '../utils/format.dart';
import 'package:printing/printing.dart';
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
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.1),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.point_of_sale,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نظام المبيعات',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            Text(
                              'إدارة المبيعات والفواتير',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Total Amount Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.attach_money,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.currencyIQD(total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Controls Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: pill('🔍 ابحث عن منتج...', Icons.search),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.5),
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _type,
                            decoration:
                                pill('💳 نوع الدفع', Icons.payments_outlined),
                            items: const [
                              DropdownMenuItem(
                                value: 'cash',
                                child: Row(
                                  children: [
                                    Icon(Icons.money, size: 18),
                                    SizedBox(width: 8),
                                    Text('نقدي'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'installment',
                                child: Row(
                                  children: [
                                    Icon(Icons.credit_card, size: 18),
                                    SizedBox(width: 8),
                                    Text('أقساط'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'credit',
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule, size: 18),
                                    SizedBox(width: 8),
                                    Text('أجل'),
                                  ],
                                ),
                              ),
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Credit system fields - show only when credit is selected
            if (_type == 'credit') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.shade50,
                      Colors.orange.shade100.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade600,
                            Colors.orange.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'معلومات البيع بالأجل',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'يرجى ملء جميع البيانات المطلوبة',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer Information Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'معلومات العميل',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              // Customer Name
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  decoration:
                                      pill('👤 اسم العميل', Icons.person),
                                  onChanged: (v) => _customerName = v,
                                ),
                              ),
                              // Customer Phone
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  decoration:
                                      pill('📱 رقم الهاتف', Icons.phone),
                                  onChanged: (v) => _customerPhone = v,
                                ),
                              ),
                              // Customer Address
                              SizedBox(
                                width: 280,
                                child: TextField(
                                  decoration:
                                      pill('📍 العنوان', Icons.location_on),
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
                                      initialDate: DateTime.now()
                                          .add(const Duration(days: 30)),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setState(() => _dueDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .dividerColor
                                            .withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _dueDate != null
                                                ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                                : '📅 تاريخ الاستحقاق',
                                            style: TextStyle(
                                              color: _dueDate != null
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Guarantor Information Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade50,
                            Colors.amber.shade100.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.security,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'معلومات الضامن',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  decoration: pill(
                                      '👤 اسم الضامن', Icons.person_outline),
                                  onChanged: (v) => _guarantorName = v,
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  decoration: pill(
                                      '📱 هاتف الضامن', Icons.phone_outlined),
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
              const SizedBox(height: 20),
            ],

            Expanded(
              child: Row(
                children: [
                  // Products side
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.8),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'المنتجات المتاحة',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'اختر المنتجات لإضافتها للسلة',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child:
                                      FutureBuilder<List<Map<String, Object?>>>(
                                    future: db.getAllProducts(query: _query),
                                    builder: (context, snapshot) {
                                      final count = snapshot.data?.length ?? 0;
                                      return Text(
                                        '$count منتج',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Products List
                          Expanded(
                            child: FutureBuilder<List<Map<String, Object?>>>(
                              future: db.getAllProducts(query: _query),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('جاري تحميل المنتجات...'),
                                      ],
                                    ),
                                  );
                                }
                                final items = snapshot.data!;
                                if (items.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'لا توجد منتجات',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.5),
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'جرب البحث بكلمات مختلفة',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.4),
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, i) {
                                    final p = items[i];
                                    final stock = p['quantity'] as int? ?? 0;
                                    final isOutOfStock = stock <= 0;

                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: isOutOfStock
                                            ? LinearGradient(
                                                colors: [
                                                  Colors.grey.shade100,
                                                  Colors.grey.shade50,
                                                ],
                                              )
                                            : LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                      .withOpacity(0.1),
                                                ],
                                              ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isOutOfStock
                                              ? Colors.grey.shade300
                                              : Theme.of(context)
                                                  .dividerColor
                                                  .withOpacity(0.3),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: isOutOfStock
                                              ? null
                                              : () => _addToCart(p),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                // Product Icon
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: isOutOfStock
                                                        ? Colors.grey.shade300
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    Icons.inventory,
                                                    color: isOutOfStock
                                                        ? Colors.grey.shade600
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                // Product Info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        p['name']?.toString() ??
                                                            '',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isOutOfStock
                                                              ? Colors
                                                                  .grey.shade600
                                                              : Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 4,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isOutOfStock
                                                                  ? Colors.grey
                                                                      .shade200
                                                                  : Colors.green
                                                                      .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Text(
                                                              Formatters
                                                                  .currencyIQD(
                                                                      p['price']
                                                                          as num),
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: isOutOfStock
                                                                    ? Colors
                                                                        .grey
                                                                        .shade600
                                                                    : Colors
                                                                        .green
                                                                        .shade700,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isOutOfStock
                                                                  ? Colors.red
                                                                      .shade100
                                                                  : Colors.blue
                                                                      .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Text(
                                                              'المتاح: $stock',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: isOutOfStock
                                                                    ? Colors.red
                                                                        .shade700
                                                                    : Colors
                                                                        .blue
                                                                        .shade700,
                                                              ),
                                                            ),
                                                          ),
                                                          // Code/Barcode Display
                                                          if (p['barcode']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          2),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .purple
                                                                    .shade100,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: Text(
                                                                'باركود: ${p['barcode']}',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .purple
                                                                      .shade700,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Add to Cart Button
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: isOutOfStock
                                                        ? Colors.grey.shade300
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Icon(
                                                    isOutOfStock
                                                        ? Icons.block
                                                        : Icons
                                                            .add_shopping_cart,
                                                    color: isOutOfStock
                                                        ? Colors.grey.shade600
                                                        : Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Cart side
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.secondary,
                                  Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withOpacity(0.8),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart_checkout,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'سلة المشتريات',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_cart.length} منتج في السلة',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    Formatters.currencyIQD(total),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Cart Items
                          Expanded(
                            child: _cart.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 64,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'السلة فارغة',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.5),
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'أضف منتجات من القائمة',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.4),
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _cart.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, i) {
                                      final c = _cart[i];
                                      final lineTotal = (c['price'] as num) *
                                          (c['quantity'] as num);

                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .dividerColor
                                                .withOpacity(0.3),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.03),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            children: [
                                              // Product Icon
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.inventory,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              // Product Info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      c['name']?.toString() ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'الكمية: ${c['quantity']}',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.6),
                                                      ),
                                                    ),
                                                    // Code/Barcode in Cart
                                                    if (c['barcode']
                                                            ?.toString()
                                                            .isNotEmpty ==
                                                        true)
                                                      Text(
                                                        'باركود: ${c['barcode']}',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          color: Colors
                                                              .purple.shade600,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),

                                              // Quantity Controls
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    tooltip: 'إنقاص',
                                                    icon: const Icon(Icons
                                                        .remove_circle_outline),
                                                    onPressed: () =>
                                                        _decrementQty(i),
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.red.shade50,
                                                      foregroundColor:
                                                          Colors.red.shade600,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      (c['quantity'] as int)
                                                          .toString(),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'زيادة',
                                                    icon: const Icon(Icons
                                                        .add_circle_outline),
                                                    onPressed: () =>
                                                        _incrementQty(i),
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.green.shade50,
                                                      foregroundColor:
                                                          Colors.green.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(width: 12),

                                              // Price and Delete
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    Formatters.currencyIQD(
                                                        lineTotal),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'حذف',
                                                    icon: const Icon(
                                                        Icons.delete_outline),
                                                    onPressed: () {
                                                      final qty = (_cart[i]
                                                          ['quantity'] as int);
                                                      final productId = _cart[i]
                                                          ['product_id'] as int;
                                                      context
                                                          .read<
                                                              DatabaseService>()
                                                          .adjustProductQuantity(
                                                              productId, qty);
                                                      setState(() =>
                                                          _cart.removeAt(i));
                                                    },
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.red.shade50,
                                                      foregroundColor:
                                                          Colors.red.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          // Footer with controls
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.3),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Total Amount
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calculate,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'الإجمالي:',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        Formatters.currencyIQD(total),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontSize: 16,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _cart.isEmpty
                                            ? null
                                            : () {
                                                // Return all items to stock before clearing cart
                                                for (final item in _cart) {
                                                  final qty =
                                                      item['quantity'] as int;
                                                  final productId =
                                                      item['product_id'] as int;
                                                  context
                                                      .read<DatabaseService>()
                                                      .adjustProductQuantity(
                                                          productId, qty);
                                                }
                                                setState(() => _cart.clear());
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'تم تفريغ السلة وإرجاع المنتجات للمخزون'),
                                                    backgroundColor:
                                                        Colors.orange,
                                                  ),
                                                );
                                              },
                                        icon: const Icon(Icons.clear_all),
                                        label: const Text('تفريغ السلة'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          side: BorderSide(
                                              color: Colors.orange.shade300),
                                          foregroundColor:
                                              Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: FilledButton.icon(
                                        onPressed: _cart.isEmpty
                                            ? null
                                            : () async {
                                                // Validate credit sale requirements
                                                if (_type == 'credit') {
                                                  if (_customerName
                                                          .trim()
                                                          .isEmpty ||
                                                      _customerPhone
                                                          .trim()
                                                          .isEmpty ||
                                                      _customerAddress
                                                          .trim()
                                                          .isEmpty ||
                                                      _guarantorName
                                                          .trim()
                                                          .isEmpty ||
                                                      _guarantorPhone
                                                          .trim()
                                                          .isEmpty ||
                                                      _dueDate == null) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                      content: Text(
                                                          'يرجى ملء جميع حقول البيع بالأجل'),
                                                      backgroundColor:
                                                          Colors.red,
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
                                                      .map((e) => Map<String,
                                                          Object?>.from(e))
                                                      .toList();
                                                  _lastType = _type;

                                                  // Save credit info for last invoice
                                                  if (_type == 'credit') {
                                                    _lastDueDate = _dueDate;
                                                    _lastCustomerName =
                                                        _customerName;
                                                    _lastCustomerPhone =
                                                        _customerPhone;
                                                    _lastCustomerAddress =
                                                        _customerAddress;
                                                    _lastGuarantorName =
                                                        _guarantorName;
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
                                                  backgroundColor:
                                                      _type == 'credit'
                                                          ? Colors.orange
                                                          : Colors.green,
                                                ));
                                              },
                                        icon: const Icon(Icons.check_circle),
                                        label: const Text('إتمام البيع'),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _lastInvoiceItems.isEmpty
                                            ? null
                                            : () async {
                                                await _printInvoice(context);
                                              },
                                        icon: const Icon(Icons.print),
                                        label: const Text('طباعة'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          side: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Last Invoice Display
                          if (_lastInvoiceItems.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _lastType == 'credit'
                                      ? [
                                          Colors.orange.shade50,
                                          Colors.orange.shade100
                                              .withOpacity(0.3)
                                        ]
                                      : _lastType == 'installment'
                                          ? [
                                              Colors.blue.shade50,
                                              Colors.blue.shade100
                                                  .withOpacity(0.3)
                                            ]
                                          : [
                                              Colors.green.shade50,
                                              Colors.green.shade100
                                                  .withOpacity(0.3)
                                            ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _lastType == 'credit'
                                      ? Colors.orange.shade200
                                      : _lastType == 'installment'
                                          ? Colors.blue.shade200
                                          : Colors.green.shade200,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_lastType == 'credit'
                                            ? Colors.orange
                                            : _lastType == 'installment'
                                                ? Colors.blue
                                                : Colors.green)
                                        .withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Header
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _lastType == 'credit'
                                            ? [
                                                Colors.orange.shade600,
                                                Colors.orange.shade700
                                              ]
                                            : _lastType == 'installment'
                                                ? [
                                                    Colors.blue.shade600,
                                                    Colors.blue.shade700
                                                  ]
                                                : [
                                                    Colors.green.shade600,
                                                    Colors.green.shade700
                                                  ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(18),
                                        topRight: Radius.circular(18),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            _lastType == 'credit'
                                                ? Icons.schedule
                                                : _lastType == 'installment'
                                                    ? Icons.credit_card
                                                    : Icons.money,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'آخر فاتورة',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _lastType == 'credit'
                                                    ? 'بيع بالأجل'
                                                    : _lastType == 'installment'
                                                        ? 'بيع بالأقساط'
                                                        : 'بيع نقدي',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            Formatters.currencyIQD(
                                              _lastInvoiceItems.fold<num>(
                                                0,
                                                (sum, item) =>
                                                    sum +
                                                    ((item['price'] as num) *
                                                        (item['quantity']
                                                            as num)),
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Credit information display
                                        if (_lastType == 'credit' &&
                                            _lastCustomerName.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                  color:
                                                      Colors.orange.shade200),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      color: Colors
                                                          .orange.shade600,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'معلومات العميل',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .orange.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Wrap(
                                                  spacing: 12,
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
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.security,
                                                      color: Colors
                                                          .orange.shade600,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'معلومات الضامن',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .orange.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Wrap(
                                                  spacing: 12,
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
                                          const SizedBox(height: 20),
                                        ],

                                        // Invoice items summary
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.inventory,
                                              color: _lastType == 'credit'
                                                  ? Colors.orange.shade600
                                                  : _lastType == 'installment'
                                                      ? Colors.blue.shade600
                                                      : Colors.green.shade600,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'المنتجات:',
                                              style: TextStyle(
                                                fontSize: 16,
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
                                        const SizedBox(height: 12),
                                        ..._lastInvoiceItems.map((item) =>
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _lastType == 'credit'
                                                      ? Colors.orange.shade100
                                                      : _lastType ==
                                                              'installment'
                                                          ? Colors.blue.shade100
                                                          : Colors
                                                              .green.shade100,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item['name']
                                                              ?.toString() ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _lastType ==
                                                              'credit'
                                                          ? Colors
                                                              .orange.shade100
                                                          : _lastType ==
                                                                  'installment'
                                                              ? Colors
                                                                  .blue.shade100
                                                              : Colors.green
                                                                  .shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          '${item['quantity']} × ${Formatters.currencyIQD(item['price'] as num)}',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 12,
                                                            color: _lastType ==
                                                                    'credit'
                                                                ? Colors.orange
                                                                    .shade700
                                                                : _lastType ==
                                                                        'installment'
                                                                    ? Colors
                                                                        .blue
                                                                        .shade700
                                                                    : Colors
                                                                        .green
                                                                        .shade700,
                                                          ),
                                                        ),
                                                        // Code/Barcode in Invoice
                                                        if (item['barcode']
                                                                ?.toString()
                                                                .isNotEmpty ==
                                                            true)
                                                          Text(
                                                            'باركود: ${item['barcode']}',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors
                                                                  .purple
                                                                  .shade600,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                      ],
                                    ),
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
          'barcode': p['barcode'],
        }));
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade100,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
