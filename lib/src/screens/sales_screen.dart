// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../services/print_service.dart';
import '../utils/format.dart';
import '../utils/strings.dart';

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
  int? _lastInvoiceId; // رقم آخر فاتورة تم إنشاؤها
  final Set<int> _addedToCartProducts = {}; // Track products added to cart
  final TextEditingController _searchController = TextEditingController();

  // Customer information controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();

  // Credit system variables
  DateTime? _dueDate;
  String _customerName = '';
  String _customerPhone = '';
  String _customerAddress = '';

  // Installment system variables
  int? _installmentCount;
  double? _downPayment;
  DateTime? _firstInstallmentDate;

  // Last invoice credit info
  DateTime? _lastDueDate;
  String _lastCustomerName = '';
  String _lastCustomerPhone = '';
  String _lastCustomerAddress = '';

  // Last invoice installment info
  List<Map<String, Object?>>? _lastInstallments;
  double? _lastTotalDebt;
  double? _lastDownPayment;

  // Print settings
  String _selectedPrintType = '80'; // نوع الطباعة المختار

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final total = _cart
        .fold<num>(
            0, (p, e) => p + ((e['price'] as num) * (e['quantity'] as num)))
        .toDouble();

    InputDecoration pill(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11),
          labelStyle: const TextStyle(fontSize: 11),
          isDense: true,
          prefixIcon: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.25),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.4),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              // Header Section - Compact
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    // Title and Icon
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.point_of_sale,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'نظام المبيعات',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const Spacer(),
                    // Total Amount
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.currencyIQD(total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Controls Row - Compact
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '🔍 ابحث عن منتج...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.25),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.5),
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
                                Icon(Icons.money, size: 16),
                                SizedBox(width: 6),
                                Text('نقدي'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'installment',
                            child: Row(
                              children: [
                                Icon(Icons.credit_card, size: 16),
                                SizedBox(width: 6),
                                Text('أقساط'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'credit',
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 16),
                                SizedBox(width: 6),
                                Text('أجل'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _type = v ?? 'cash';
                            // Clear due date only when changing from credit to other types
                            if (_type != 'credit') {
                              _dueDate = null;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer information fields - compact version with dynamic colors
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCustomerInfoBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getCustomerInfoBorderColor(),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getCustomerInfoShadowColor(),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Customer Name (default)
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _customerNameController,
                        decoration: pill('👤 اسم العميل', Icons.person),
                        onChanged: (v) => _customerName = v,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Customer Phone (default)
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _customerPhoneController,
                        decoration: pill('📱 الهاتف', Icons.phone),
                        onChanged: (v) => _customerPhone = v,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Customer Address (default)
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _customerAddressController,
                        decoration: pill('📍 العنوان', Icons.location_on),
                        onChanged: (v) => _customerAddress = v,
                      ),
                    ),
                    // ملاحظة توضيحية لمعلومات العميل
                    if (_type == 'cash') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.blue.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'اختياري',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // ملاحظة توضيحية للبيع الآجل
                    if (_type == 'credit' || _type == 'installment') ...[],
                    // Due Date field - only show for credit payments (default)
                    if (_type == 'credit') ...[
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
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
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
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
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Installment fields - only show for installment payments (default)
                    if (_type == 'installment') ...[
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          decoration: pill('🔢 عدد الأقساط', Icons.numbers),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _installmentCount =
                              v.isEmpty ? null : int.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          decoration: pill('💰 المقدم (د.ع)', Icons.money),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _downPayment =
                              v.isEmpty ? null : double.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
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
                              setState(() => _firstInstallmentDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _firstInstallmentDate != null
                                        ? '${_firstInstallmentDate!.day}/${_firstInstallmentDate!.month}/${_firstInstallmentDate!.year}'
                                        : '📅 تاريخ أول قسط',
                                    style: TextStyle(
                                      color: _firstInstallmentDate != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Address remains in default position above
                    ],
                  ],
                ),
              ),
              Divider(),
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
                                            color:
                                                Colors.white.withOpacity(0.9),
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
                                    child: FutureBuilder<
                                        List<Map<String, Object?>>>(
                                      future: db.getAllProducts(query: _query),
                                      builder: (context, snapshot) {
                                        final count =
                                            snapshot.data?.length ?? 0;
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
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isOutOfStock
                                                ? Colors.grey.shade300
                                                : Theme.of(context)
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
                                        child: Material(
                                          color: Colors.transparent,
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
                                                GestureDetector(
                                                  onTap: isOutOfStock
                                                      ? null
                                                      : () => _addToCart(p),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: isOutOfStock
                                                          ? Colors.grey.shade300
                                                          : (_addedToCartProducts
                                                                  .contains(
                                                                      p['id'])
                                                              ? Colors.purple
                                                                  .shade600
                                                              : Colors.green
                                                                  .shade600),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      boxShadow: isOutOfStock
                                                          ? null
                                                          : [
                                                              BoxShadow(
                                                                color: (_addedToCartProducts
                                                                        .contains(p[
                                                                            'id'])
                                                                    ? Colors
                                                                        .purple
                                                                        .shade200
                                                                    : Colors
                                                                        .green
                                                                        .shade200),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
                                                              ),
                                                            ],
                                                    ),
                                                    child: Icon(
                                                      isOutOfStock
                                                          ? Icons.block
                                                          : _addedToCartProducts
                                                                  .contains(
                                                                      p['id'])
                                                              ? Icons.check
                                                              : Icons.add,
                                                      color: isOutOfStock
                                                          ? Colors.grey.shade600
                                                          : Colors.white,
                                                      size: 15,
                                                    ),
                                                  ),
                                                ),
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
                          mainAxisSize: MainAxisSize.min,
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
                                            color:
                                                Colors.white.withOpacity(0.9),
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
                                                        BorderRadius.circular(
                                                            6),
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
                                                        CrossAxisAlignment
                                                            .start,
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
                                                          color: Theme.of(
                                                                  context)
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
                                                            color: Colors.purple
                                                                .shade600,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),

                                                // Quantity Controls
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'إنقاص',
                                                      icon: const Icon(Icons
                                                          .remove_circle_outline),
                                                      onPressed: () =>
                                                          _decrementQty(i),
                                                      style:
                                                          IconButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red.shade50,
                                                        foregroundColor:
                                                            Colors.red.shade600,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
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
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: Theme.of(
                                                                  context)
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
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    IconButton(
                                                      tooltip: 'زيادة',
                                                      icon: const Icon(Icons
                                                          .add_circle_outline),
                                                      onPressed: () =>
                                                          _incrementQty(i),
                                                      style:
                                                          IconButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .green.shade50,
                                                        foregroundColor: Colors
                                                            .green.shade600,
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
                                                        Icons.delete_outline,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () {
                                                        final qty = (_cart[i]
                                                                ['quantity']
                                                            as int);
                                                        final productId = _cart[
                                                                i]['product_id']
                                                            as int;
                                                        context
                                                            .read<
                                                                DatabaseService>()
                                                            .adjustProductQuantity(
                                                                productId, qty);
                                                        setState(() {
                                                          _cart.removeAt(i);
                                                          _addedToCartProducts
                                                              .remove(
                                                                  productId);
                                                        });
                                                      },
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
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
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'الإجمالي:',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
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
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontSize: 14,
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
                                                        item['product_id']
                                                            as int;
                                                    context
                                                        .read<DatabaseService>()
                                                        .adjustProductQuantity(
                                                            productId, qty);
                                                  }
                                                  // Don't clear cart or customer fields here - they will be cleared when dialog is closed
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
                                        child: FilledButton.icon(
                                          onPressed: _cart.isEmpty
                                              ? null
                                              : () async {
                                                  // Validate customer information requirements for credit and installment
                                                  if (_type == 'credit' ||
                                                      _type == 'installment') {
                                                    if (_customerName
                                                            .trim()
                                                            .isEmpty ||
                                                        _customerPhone
                                                            .trim()
                                                            .isEmpty ||
                                                        _customerAddress
                                                            .trim()
                                                            .isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(_type ==
                                                                'installment'
                                                            ? 'يرجى ملء جميع معلومات العميل للبيع بالأقساط'
                                                            : 'يرجى ملء جميع معلومات العميل للبيع بالأجل'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ));
                                                      return;
                                                    }
                                                  }

                                                  // Additional validation for credit sales
                                                  if (_type == 'credit' &&
                                                      _dueDate == null) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                      content: Text(
                                                          'يرجى تحديد تاريخ الاستحقاق للبيع بالأجل'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ));
                                                    return;
                                                  }

                                                  // التحقق من صحة بيانات الأقساط
                                                  if (_type == 'installment') {
                                                    if (_installmentCount ==
                                                            null ||
                                                        _installmentCount! <=
                                                            0) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'يرجى إدخال عدد الأقساط صحيح'),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    final totalAmount = _cart
                                                        .fold<double>(0,
                                                            (sum, item) {
                                                      return sum +
                                                          ((item['price']
                                                                      as num)
                                                                  .toDouble() *
                                                              (item['quantity']
                                                                      as num)
                                                                  .toDouble());
                                                    });

                                                    if (_downPayment != null &&
                                                        _downPayment! >=
                                                            totalAmount) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'المقدم يجب أن يكون أقل من إجمالي المبلغ'),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                  }

                                                  final saleId =
                                                      await db.createSale(
                                                    type: _type == 'cash'
                                                        ? 'cash'
                                                        : _type == 'installment'
                                                            ? 'installment'
                                                            : 'credit',
                                                    items: _cart,
                                                    decrementStock: false,
                                                    customerName: (_type ==
                                                                'credit' ||
                                                            _type ==
                                                                'installment')
                                                        ? _customerName
                                                        : _customerName
                                                                .trim()
                                                                .isNotEmpty
                                                            ? _customerName
                                                            : null,
                                                    customerPhone: (_type ==
                                                                'credit' ||
                                                            _type ==
                                                                'installment')
                                                        ? _customerPhone
                                                        : _customerPhone
                                                                .trim()
                                                                .isNotEmpty
                                                            ? _customerPhone
                                                            : null,
                                                    customerAddress: (_type ==
                                                                'credit' ||
                                                            _type ==
                                                                'installment')
                                                        ? _customerAddress
                                                        : _customerAddress
                                                                .trim()
                                                                .isNotEmpty
                                                            ? _customerAddress
                                                            : null,
                                                    dueDate: _type == 'credit'
                                                        ? _dueDate
                                                        : null,
                                                    // إضافة معاملات الأقساط
                                                    installmentCount:
                                                        _type == 'installment'
                                                            ? _installmentCount
                                                            : null,
                                                    downPayment:
                                                        _type == 'installment'
                                                            ? _downPayment
                                                            : null,
                                                    firstInstallmentDate: _type ==
                                                            'installment'
                                                        ? _firstInstallmentDate
                                                        : null,
                                                  );
                                                  if (!mounted) return;

                                                  // Save installment info for last invoice
                                                  if (_type == 'installment') {
                                                    _lastInstallments = await db
                                                        .getInstallments(
                                                            saleId: saleId);
                                                    final installmentSummary =
                                                        await db
                                                            .getSaleInstallmentSummary(
                                                                saleId);
                                                    _lastTotalDebt =
                                                        installmentSummary[
                                                                'totalDebt']
                                                            as double?;
                                                    _lastDownPayment =
                                                        _downPayment;
                                                  } else {
                                                    _lastInstallments = null;
                                                    _lastTotalDebt = null;
                                                    _lastDownPayment = null;
                                                  }

                                                  setState(() {
                                                    _lastInvoiceItems = _cart
                                                        .map((e) => Map<String,
                                                            Object?>.from(e))
                                                        .toList();
                                                    _lastType = _type;
                                                    _lastInvoiceId =
                                                        saleId; // حفظ رقم الفاتورة

                                                    // Save customer info for last invoice
                                                    _lastDueDate = _dueDate;
                                                    _lastCustomerName =
                                                        _customerName;
                                                    _lastCustomerPhone =
                                                        _customerPhone;
                                                    _lastCustomerAddress =
                                                        _customerAddress;

                                                    // Don't clear cart or customer fields here - they will be cleared when dialog is closed
                                                  });

                                                  // Success message no longer needed as we show detailed dialog

                                                  // Show success dialog with invoice details in center of screen
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder:
                                                        (BuildContext context) {
                                                      return StatefulBuilder(
                                                        builder: (context,
                                                            setDialogState) {
                                                          final totalAmount =
                                                              _lastInvoiceItems
                                                                  .fold<num>(
                                                            0,
                                                            (sum, item) =>
                                                                sum +
                                                                ((item['price']
                                                                        as num) *
                                                                    (item['quantity']
                                                                        as num)),
                                                          );

                                                          return Dialog(
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            child: Container(
                                                              constraints:
                                                                  const BoxConstraints(
                                                                      maxWidth:
                                                                          500,
                                                                      maxHeight:
                                                                          600),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  // Header
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            20),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      gradient:
                                                                          LinearGradient(
                                                                        colors: _lastType ==
                                                                                'credit'
                                                                            ? [
                                                                                Colors.orange.shade600,
                                                                                Colors.orange.shade700
                                                                              ]
                                                                            : _lastType ==
                                                                                    'installment'
                                                                                ? [
                                                                                    Colors.blue.shade600,
                                                                                    Colors.blue.shade700
                                                                                  ]
                                                                                : [
                                                                                    Colors.green.shade600,
                                                                                    Colors.green.shade700
                                                                                  ],
                                                                      ),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        topLeft:
                                                                            Radius.circular(20),
                                                                        topRight:
                                                                            Radius.circular(20),
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .check_circle,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              32,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                12),
                                                                        Expanded(
                                                                          child:
                                                                              Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              const Text(
                                                                                'تم إنجاز البيع بنجاح',
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 20,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                _lastType == 'credit'
                                                                                    ? 'بيع آجل'
                                                                                    : _lastType == 'installment'
                                                                                        ? 'بيع بالتقسيط'
                                                                                        : 'بيع نقدي',
                                                                                style: TextStyle(
                                                                                  color: Colors.white.withOpacity(0.9),
                                                                                  fontSize: 14,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          padding: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 12,
                                                                              vertical: 6),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Colors.white.withOpacity(0.2),
                                                                            borderRadius:
                                                                                BorderRadius.circular(12),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            Formatters.currencyIQD(totalAmount),
                                                                            style:
                                                                                const TextStyle(
                                                                              color: Colors.white,
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 16,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),

                                                                  // Items List
                                                                  Flexible(
                                                                    child:
                                                                        Container(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          16),
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Text(
                                                                                'المنتجات (${_lastInvoiceItems.length})',
                                                                                style: TextStyle(
                                                                                  fontWeight: FontWeight.bold,
                                                                                  fontSize: 16,
                                                                                  color: _lastType == 'credit'
                                                                                      ? Colors.orange.shade700
                                                                                      : _lastType == 'installment'
                                                                                          ? Colors.blue.shade700
                                                                                          : Colors.green.shade700,
                                                                                ),
                                                                              ),
                                                                              if (_lastType == 'credit' && _lastDueDate != null)
                                                                                Container(
                                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                                  decoration: BoxDecoration(
                                                                                    color: Colors.orange.shade100,
                                                                                    borderRadius: BorderRadius.circular(8),
                                                                                  ),
                                                                                  child: Text(
                                                                                    'تاريخ الاستحقاق: ${_lastDueDate!.day}/${_lastDueDate!.month}/${_lastDueDate!.year}',
                                                                                    style: TextStyle(
                                                                                      fontSize: 10,
                                                                                      color: Colors.orange.shade700,
                                                                                      fontWeight: FontWeight.w600,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                            ],
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 12),
                                                                          Flexible(
                                                                            child:
                                                                                ListView.builder(
                                                                              shrinkWrap: true,
                                                                              itemCount: _lastInvoiceItems.length,
                                                                              itemBuilder: (context, index) {
                                                                                final item = _lastInvoiceItems[index];
                                                                                return Container(
                                                                                  margin: const EdgeInsets.only(bottom: 8),
                                                                                  padding: const EdgeInsets.all(12),
                                                                                  decoration: BoxDecoration(
                                                                                    color: Colors.grey.shade50,
                                                                                    borderRadius: BorderRadius.circular(8),
                                                                                    border: Border.all(
                                                                                      color: _lastType == 'credit'
                                                                                          ? Colors.orange.shade200
                                                                                          : _lastType == 'installment'
                                                                                              ? Colors.blue.shade200
                                                                                              : Colors.green.shade200,
                                                                                    ),
                                                                                  ),
                                                                                  child: Row(
                                                                                    children: [
                                                                                      Expanded(
                                                                                        child: Text(
                                                                                          item['name']?.toString() ?? '',
                                                                                          style: const TextStyle(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontSize: 14,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      Text(
                                                                                        '${item['quantity']} × ${Formatters.currencyIQD(item['price'] as num)}',
                                                                                        style: TextStyle(
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontSize: 12,
                                                                                          color: _lastType == 'credit'
                                                                                              ? Colors.orange.shade700
                                                                                              : _lastType == 'installment'
                                                                                                  ? Colors.blue.shade700
                                                                                                  : Colors.green.shade700,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                );
                                                                              },
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),

                                                                  // Customer Information Section
                                                                  if (_lastCustomerName
                                                                      .isNotEmpty) ...[
                                                                    Container(
                                                                      margin: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              16),
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .all(
                                                                              6),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: _lastType ==
                                                                                'credit'
                                                                            ? Colors.orange.shade50
                                                                            : _lastType == 'installment'
                                                                                ? Colors.blue.shade50
                                                                                : Colors.green.shade50,
                                                                        borderRadius:
                                                                            BorderRadius.circular(6),
                                                                        border:
                                                                            Border.all(
                                                                          color: _lastType == 'credit'
                                                                              ? Colors.orange.shade200
                                                                              : _lastType == 'installment'
                                                                                  ? Colors.blue.shade200
                                                                                  : Colors.green.shade200,
                                                                          width:
                                                                              1,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              Icon(
                                                                                Icons.person,
                                                                                color: _lastType == 'credit'
                                                                                    ? Colors.orange.shade700
                                                                                    : _lastType == 'installment'
                                                                                        ? Colors.blue.shade700
                                                                                        : Colors.green.shade700,
                                                                                size: 14,
                                                                              ),
                                                                              const SizedBox(width: 4),
                                                                              Text(
                                                                                'معلومات العميل',
                                                                                style: TextStyle(
                                                                                  fontWeight: FontWeight.bold,
                                                                                  fontSize: 10,
                                                                                  color: _lastType == 'credit'
                                                                                      ? Colors.orange.shade700
                                                                                      : _lastType == 'installment'
                                                                                          ? Colors.blue.shade700
                                                                                          : Colors.green.shade700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 6),
                                                                          if (_lastCustomerName
                                                                              .isNotEmpty) ...[
                                                                            _buildCustomerInfoRow('الاسم',
                                                                                _lastCustomerName),
                                                                            const SizedBox(height: 4),
                                                                          ],
                                                                          if (_lastCustomerPhone
                                                                              .isNotEmpty) ...[
                                                                            _buildCustomerInfoRow('الهاتف',
                                                                                _lastCustomerPhone),
                                                                            const SizedBox(height: 4),
                                                                          ],
                                                                          if (_lastCustomerAddress
                                                                              .isNotEmpty) ...[
                                                                            _buildCustomerInfoRow('العنوان',
                                                                                _lastCustomerAddress),
                                                                            const SizedBox(height: 4),
                                                                          ],
                                                                          if (_lastType == 'credit' &&
                                                                              _lastDueDate != null) ...[
                                                                            _buildCustomerInfoRow('تاريخ الاستحقاق',
                                                                                '${_lastDueDate!.day}/${_lastDueDate!.month}/${_lastDueDate!.year}'),
                                                                          ],
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            6),
                                                                  ],

                                                                  // Actions - Simplified and organized buttons
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            20),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .grey
                                                                          .shade50,
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        bottomLeft:
                                                                            Radius.circular(20),
                                                                        bottomRight:
                                                                            Radius.circular(20),
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        // Primary action buttons row
                                                                        Row(
                                                                          children: [
                                                                            // زر اختيار نوع الطباعة
                                                                            Expanded(
                                                                              child: ElevatedButton.icon(
                                                                                onPressed: () async {
                                                                                  // عرض حوار اختيار نوع الطباعة
                                                                                  final result = await _showPrintTypeDialog(context);
                                                                                  if (result != null) {
                                                                                    setDialogState(() {
                                                                                      _selectedPrintType = result;
                                                                                    });
                                                                                    if (context.mounted) {
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text('تم اختيار طابعة: ${_getPrintTypeDisplayName(result)}'),
                                                                                          backgroundColor: Colors.blue,
                                                                                          duration: const Duration(seconds: 2),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  }
                                                                                },
                                                                                icon: const Icon(Icons.settings, size: 20),
                                                                                label: Text(
                                                                                  _getPrintTypeDisplayName(_selectedPrintType),
                                                                                  style: const TextStyle(
                                                                                    fontSize: 12,
                                                                                    fontWeight: FontWeight.w600,
                                                                                  ),
                                                                                ),
                                                                                style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: Colors.blue.shade600,
                                                                                  foregroundColor: Colors.white,
                                                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(12),
                                                                                  ),
                                                                                  elevation: 2,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(width: 8),
                                                                            // زر طباعة فقط
                                                                            Expanded(
                                                                              child: ElevatedButton.icon(
                                                                                onPressed: () async {
                                                                                  try {
                                                                                    // طباعة بالإعدادات المختارة
                                                                                    await _printInvoice(context);

                                                                                    if (context.mounted) {
                                                                                      // عرض رسالة النجاح
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        const SnackBar(
                                                                                          content: Text('تم طباعة الفاتورة بنجاح'),
                                                                                          backgroundColor: Colors.green,
                                                                                          duration: Duration(seconds: 2),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  } catch (e) {
                                                                                    if (context.mounted) {
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text('خطأ في الطباعة: ${e.toString()}'),
                                                                                          backgroundColor: Colors.red,
                                                                                          duration: const Duration(seconds: 3),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  }
                                                                                },
                                                                                icon: const Icon(Icons.print, size: 20),
                                                                                label: const Text('طباعة'),
                                                                                style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: _lastType == 'credit'
                                                                                      ? Colors.orange.shade600
                                                                                      : _lastType == 'installment'
                                                                                          ? Colors.blue.shade600
                                                                                          : Colors.green.shade600,
                                                                                  foregroundColor: Colors.white,
                                                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(12),
                                                                                  ),
                                                                                  elevation: 2,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(width: 8),
                                                                            // زر موافق
                                                                            Expanded(
                                                                              child: ElevatedButton.icon(
                                                                                onPressed: () async {
                                                                                  if (context.mounted) {
                                                                                    // Clear everything when closing dialog
                                                                                    setState(() {
                                                                                      // Clear cart
                                                                                      _cart.clear();
                                                                                      _addedToCartProducts.clear();
                                                                                      // Clear customer fields
                                                                                      _customerName = '';
                                                                                      _customerPhone = '';
                                                                                      _customerAddress = '';
                                                                                      _dueDate = null;
                                                                                      // Clear controllers
                                                                                      _customerNameController.clear();
                                                                                      _customerPhoneController.clear();
                                                                                      _customerAddressController.clear();
                                                                                    });

                                                                                    // إغلاق الحوار
                                                                                    Navigator.of(context).pop();

                                                                                    // عرض رسالة النجاح
                                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                                      const SnackBar(
                                                                                        content: Text('تم حفظ الطلب بنجاح'),
                                                                                        backgroundColor: Colors.green,
                                                                                        duration: Duration(seconds: 2),
                                                                                      ),
                                                                                    );
                                                                                  }
                                                                                },
                                                                                icon: const Icon(Icons.check, size: 20),
                                                                                label: const Text('موافق'),
                                                                                style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: Colors.green.shade600,
                                                                                  foregroundColor: Colors.white,
                                                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(12),
                                                                                  ),
                                                                                  elevation: 2,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),

                                                                        const SizedBox(
                                                                            height:
                                                                                12),

                                                                        // Back to cart button (full width)
                                                                        SizedBox(
                                                                          width:
                                                                              double.infinity,
                                                                          child:
                                                                              ElevatedButton.icon(
                                                                            onPressed:
                                                                                () {
                                                                              // Return to cart for adding more products
                                                                              setDialogState(() {
                                                                                // Move last invoice items back to cart
                                                                                _cart.clear();
                                                                                _addedToCartProducts.clear();

                                                                                // Add last invoice items back to cart
                                                                                for (final item in _lastInvoiceItems) {
                                                                                  _cart.add(Map<String, Object?>.from(item));
                                                                                  _addedToCartProducts.add(item['product_id'] as int);
                                                                                }

                                                                                // Clear last invoice items
                                                                                _lastInvoiceItems.clear();
                                                                                _lastInvoiceId = null;
                                                                              });

                                                                              // Close the dialog
                                                                              Navigator.of(context).pop();

                                                                              // Show success message
                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                const SnackBar(
                                                                                  content: Text('تم العودة إلى السلة - يمكنك إضافة منتجات جديدة أو تعديل الكميات'),
                                                                                  backgroundColor: Colors.blue,
                                                                                  duration: Duration(seconds: 3),
                                                                                ),
                                                                              );
                                                                            },
                                                                            icon:
                                                                                const Icon(Icons.shopping_cart, size: 20),
                                                                            label:
                                                                                const Text('العودة إلى السلة'),
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              backgroundColor: Colors.orange.shade600,
                                                                              foregroundColor: Colors.white,
                                                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(12),
                                                                              ),
                                                                              elevation: 2,
                                                                            ),
                                                                          ),
                                                                        ),

                                                                        const SizedBox(
                                                                            height:
                                                                                8),

                                                                        // Cancel order button (full width)
                                                                        SizedBox(
                                                                          width:
                                                                              double.infinity,
                                                                          child:
                                                                              OutlinedButton.icon(
                                                                            onPressed:
                                                                                () async {
                                                                              // Show confirmation dialog
                                                                              final shouldCancel = await showDialog<bool>(
                                                                                context: context,
                                                                                builder: (BuildContext context) {
                                                                                  return AlertDialog(
                                                                                    shape: RoundedRectangleBorder(
                                                                                      borderRadius: BorderRadius.circular(16),
                                                                                    ),
                                                                                    title: Row(
                                                                                      children: [
                                                                                        Icon(
                                                                                          Icons.warning_amber_rounded,
                                                                                          color: Colors.red.shade600,
                                                                                          size: 28,
                                                                                        ),
                                                                                        const SizedBox(width: 12),
                                                                                        const Text(
                                                                                          'إلغاء العملية بالكامل',
                                                                                          style: TextStyle(
                                                                                            fontSize: 18,
                                                                                            fontWeight: FontWeight.bold,
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    content: const Text(
                                                                                      'هل أنت متأكد من إلغاء العملية بالكامل؟\nسيتم:\n• إرجاع جميع المنتجات إلى المخزن\n• مسح السلة\n• إلغاء جميع البيانات',
                                                                                      style: TextStyle(fontSize: 16),
                                                                                      textAlign: TextAlign.center,
                                                                                    ),
                                                                                    actions: [
                                                                                      Row(
                                                                                        children: [
                                                                                          Expanded(
                                                                                            child: OutlinedButton(
                                                                                              onPressed: () {
                                                                                                Navigator.of(context).pop(false);
                                                                                              },
                                                                                              style: OutlinedButton.styleFrom(
                                                                                                foregroundColor: Colors.grey.shade600,
                                                                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                                                                side: BorderSide(color: Colors.grey.shade400),
                                                                                                shape: RoundedRectangleBorder(
                                                                                                  borderRadius: BorderRadius.circular(8),
                                                                                                ),
                                                                                              ),
                                                                                              child: const Text('لا'),
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(width: 12),
                                                                                          Expanded(
                                                                                            child: ElevatedButton(
                                                                                              onPressed: () {
                                                                                                Navigator.of(context).pop(true);
                                                                                              },
                                                                                              style: ElevatedButton.styleFrom(
                                                                                                backgroundColor: Colors.red.shade600,
                                                                                                foregroundColor: Colors.white,
                                                                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                                                                shape: RoundedRectangleBorder(
                                                                                                  borderRadius: BorderRadius.circular(8),
                                                                                                ),
                                                                                              ),
                                                                                              child: const Text('نعم، ألغِ الكل'),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ],
                                                                                  );
                                                                                },
                                                                              );

                                                                              if (shouldCancel == true) {
                                                                                // Cancel the entire sale process
                                                                                try {
                                                                                  // Return products to stock - only from last invoice if it exists
                                                                                  // If there's a last invoice, return those products
                                                                                  // If no last invoice, return products from current cart
                                                                                  print('إلغاء العملية - عدد منتجات الفاتورة الأخيرة: ${_lastInvoiceItems.length}');
                                                                                  print('إلغاء العملية - عدد منتجات السلة: ${_cart.length}');

                                                                                  if (_lastInvoiceItems.isNotEmpty) {
                                                                                    // Return products from last invoice to stock
                                                                                    print('إرجاع منتجات من الفاتورة الأخيرة إلى المخزن');
                                                                                    for (final item in _lastInvoiceItems) {
                                                                                      final productId = item['product_id'] as int;
                                                                                      final quantity = item['quantity'] as int;
                                                                                      print('إرجاع منتج ID: $productId, الكمية: $quantity');
                                                                                      await context.read<DatabaseService>().adjustProductQuantity(productId, quantity);
                                                                                    }
                                                                                  } else if (_cart.isNotEmpty) {
                                                                                    // Return products from current cart to stock (if no last invoice)
                                                                                    print('إرجاع منتجات من السلة الحالية إلى المخزن');
                                                                                    for (final item in _cart) {
                                                                                      final productId = item['product_id'] as int;
                                                                                      final quantity = item['quantity'] as int;
                                                                                      print('إرجاع منتج ID: $productId, الكمية: $quantity');
                                                                                      await context.read<DatabaseService>().adjustProductQuantity(productId, quantity);
                                                                                    }
                                                                                  }

                                                                                  // Clear everything - complete reset
                                                                                  setState(() {
                                                                                    // Clear cart
                                                                                    _cart.clear();
                                                                                    _addedToCartProducts.clear();

                                                                                    // Clear last invoice items
                                                                                    _lastInvoiceItems.clear();
                                                                                    _lastInvoiceId = null;

                                                                                    // Reset payment type
                                                                                    _lastType = 'cash';
                                                                                    _type = 'cash';

                                                                                    // Clear due date
                                                                                    _lastDueDate = null;
                                                                                    _dueDate = null;

                                                                                    // Clear customer information
                                                                                    _lastCustomerName = '';
                                                                                    _lastCustomerPhone = '';
                                                                                    _lastCustomerAddress = '';
                                                                                    _customerName = '';
                                                                                    _customerPhone = '';
                                                                                    _customerAddress = '';

                                                                                    // Clear controllers
                                                                                    _customerNameController.clear();
                                                                                    _customerPhoneController.clear();
                                                                                    _customerAddressController.clear();

                                                                                    // Clear installment info
                                                                                    _installmentCount = null;
                                                                                    _downPayment = null;
                                                                                    _firstInstallmentDate = null;
                                                                                  });

                                                                                  Navigator.of(context).pop(); // Close the success dialog

                                                                                  // Show success message
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    const SnackBar(
                                                                                      content: Text('تم إلغاء العملية بالكامل وإرجاع جميع المنتجات إلى المخزن'),
                                                                                      backgroundColor: Colors.green,
                                                                                      duration: Duration(seconds: 3),
                                                                                    ),
                                                                                  );
                                                                                } catch (e) {
                                                                                  Navigator.of(context).pop(); // Close the success dialog
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    SnackBar(
                                                                                      content: Text('خطأ في إلغاء العملية: $e'),
                                                                                      backgroundColor: Colors.red,
                                                                                      duration: Duration(seconds: 3),
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              }
                                                                            },
                                                                            icon:
                                                                                const Icon(Icons.cancel_outlined, size: 20),
                                                                            label:
                                                                                const Text('إلغاء الطلب'),
                                                                            style:
                                                                                OutlinedButton.styleFrom(
                                                                              foregroundColor: Colors.red.shade600,
                                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                                              side: BorderSide(color: Colors.red.shade300),
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(12),
                                                                              ),
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
                                                        },
                                                      );
                                                    },
                                                  );
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
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Last Invoice Display - Removed to show in center dialog instead
                            if (false && _lastInvoiceItems.isNotEmpty) ...[
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
                                                      : _lastType ==
                                                              'installment'
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
                                                          'تاريخ الاستحقاق',
                                                          _lastDueDate != null
                                                              ? '${_lastDueDate!.day}/${_lastDueDate!.month}/${_lastDueDate!.year}'
                                                              : '—',
                                                          Icons.event),
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
                                                      : _lastType ==
                                                              'installment'
                                                          ? Colors.blue.shade700
                                                          : Colors
                                                              .green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          ..._lastInvoiceItems.map((item) =>
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
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
                                                            ? Colors
                                                                .blue.shade100
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
                                                                ? Colors.blue
                                                                    .shade100
                                                                : Colors.green
                                                                    .shade100,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
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
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 12,
                                                              color: _lastType ==
                                                                      'credit'
                                                                  ? Colors
                                                                      .orange
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
        ));
  }

  void _addToCart(Map<String, Object?> p) {
    // Check if product is already in cart
    final existing = _cart.indexWhere((e) => e['product_id'] == p['id']);
    if (existing >= 0) {
      // Product already in cart, don't add again
      // User can adjust quantity using +/- buttons in cart
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'المنتج موجود بالفعل في السلة. استخدم أزرار الزيادة والنقصان لتعديل الكمية')));
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
    setState(() {
      _cart.add({
        'product_id': p['id'],
        'name': p['name'],
        'price': p['price'],
        'cost': p['cost'],
        'quantity': 1,
        'available': currentStock - 1,
        'barcode': p['barcode'],
      });
      _addedToCartProducts.add(p['id'] as int);
    });
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

  // دالة للحصول على اسم نوع الطابعة للعرض
  String _getPrintTypeDisplayName(String printType) {
    switch (printType) {
      case '58':
        return '58mm';
      case '80':
        return '80mm';
      case 'A5':
        return 'A5';
      case 'A4':
        return 'A4';
      default:
        return 'نوع الطباعة';
    }
  }

  // دالة عرض حوار اختيار نوع الطباعة
  Future<String?> _showPrintTypeDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.print,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('اختيار نوع الطباعة'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر نوع الورق المناسب للطباعة:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // طابعة حرارية 58mm
              Container(
                decoration: BoxDecoration(
                  color: _selectedPrintType == '58'
                      ? Colors.orange.shade50
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _selectedPrintType == '58'
                      ? Border.all(color: Colors.orange.shade300, width: 2)
                      : null,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.receipt,
                    color: _selectedPrintType == '58'
                        ? Colors.orange.shade700
                        : Colors.orange,
                  ),
                  title: Text(
                    'طابعة حرارية 58mm',
                    style: TextStyle(
                      fontWeight: _selectedPrintType == '58'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedPrintType == '58'
                          ? Colors.orange.shade700
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    'فواتير صغيرة ومضغوطة',
                    style: TextStyle(
                      color: _selectedPrintType == '58'
                          ? Colors.orange.shade600
                          : null,
                    ),
                  ),
                  trailing: _selectedPrintType == '58'
                      ? Icon(Icons.check_circle, color: Colors.orange.shade700)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop('58');
                  },
                ),
              ),

              const SizedBox(height: 8),

              // طابعة حرارية 80mm
              Container(
                decoration: BoxDecoration(
                  color: _selectedPrintType == '80'
                      ? Colors.blue.shade50
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _selectedPrintType == '80'
                      ? Border.all(color: Colors.blue.shade300, width: 2)
                      : null,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.receipt_long,
                    color: _selectedPrintType == '80'
                        ? Colors.blue.shade700
                        : Colors.blue,
                  ),
                  title: Text(
                    'طابعة حرارية 80mm',
                    style: TextStyle(
                      fontWeight: _selectedPrintType == '80'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedPrintType == '80'
                          ? Colors.blue.shade700
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    'فواتير عادية ومقروءة',
                    style: TextStyle(
                      color: _selectedPrintType == '80'
                          ? Colors.blue.shade600
                          : null,
                    ),
                  ),
                  trailing: _selectedPrintType == '80'
                      ? Icon(Icons.check_circle, color: Colors.blue.shade700)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop('80');
                  },
                ),
              ),

              const SizedBox(height: 8),

              // ورقة A5
              Container(
                decoration: BoxDecoration(
                  color: _selectedPrintType == 'A5'
                      ? Colors.green.shade50
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _selectedPrintType == 'A5'
                      ? Border.all(color: Colors.green.shade300, width: 2)
                      : null,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.description,
                    color: _selectedPrintType == 'A5'
                        ? Colors.green.shade700
                        : Colors.green,
                  ),
                  title: Text(
                    'ورقة A5',
                    style: TextStyle(
                      fontWeight: _selectedPrintType == 'A5'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedPrintType == 'A5'
                          ? Colors.green.shade700
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    'فواتير متوسطة الحجم',
                    style: TextStyle(
                      color: _selectedPrintType == 'A5'
                          ? Colors.green.shade600
                          : null,
                    ),
                  ),
                  trailing: _selectedPrintType == 'A5'
                      ? Icon(Icons.check_circle, color: Colors.green.shade700)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop('A5');
                  },
                ),
              ),

              const SizedBox(height: 8),

              // ورقة A4
              Container(
                decoration: BoxDecoration(
                  color: _selectedPrintType == 'A4'
                      ? Colors.purple.shade50
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _selectedPrintType == 'A4'
                      ? Border.all(color: Colors.purple.shade300, width: 2)
                      : null,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.picture_as_pdf,
                    color: _selectedPrintType == 'A4'
                        ? Colors.purple.shade700
                        : Colors.purple,
                  ),
                  title: Text(
                    'ورقة A4',
                    style: TextStyle(
                      fontWeight: _selectedPrintType == 'A4'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedPrintType == 'A4'
                          ? Colors.purple.shade700
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    'فواتير تفصيلية ومهنية',
                    style: TextStyle(
                      color: _selectedPrintType == 'A4'
                          ? Colors.purple.shade600
                          : null,
                    ),
                  ),
                  trailing: _selectedPrintType == 'A4'
                      ? Icon(Icons.check_circle, color: Colors.purple.shade700)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop('A4');
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    print('=== بدء عملية طباعة الفاتورة ===');
    print('عدد المنتجات في آخر فاتورة: ${_lastInvoiceItems.length}');
    print('نوع الدفع: $_lastType');
    print('نوع الطباعة المختار: $_selectedPrintType');

    final db = context.read<DatabaseService>();
    final settings = await db.database.query('settings', limit: 1);
    final shopName = (settings.isNotEmpty
        ? (settings.first['shop_name']?.toString() ??
            AppStrings.defaultShopName)
        : AppStrings.defaultShopName);
    final phone =
        (settings.isNotEmpty ? settings.first['phone']?.toString() : null);
    final address =
        (settings.isNotEmpty ? settings.first['address']?.toString() : null);

    // استخدام خدمة الطباعة مع نوع الطباعة المختار
    final success = await PrintService.printInvoice(
      shopName: shopName,
      phone: phone,
      address: address,
      items: _lastInvoiceItems,
      paymentType: _lastType,
      customerName: _lastCustomerName.isNotEmpty ? _lastCustomerName : null,
      customerPhone: _lastCustomerPhone.isNotEmpty ? _lastCustomerPhone : null,
      customerAddress:
          _lastCustomerAddress.isNotEmpty ? _lastCustomerAddress : null,
      dueDate: _lastDueDate,
      pageFormat: _selectedPrintType, // استخدام نوع الطباعة المختار
      showLogo: true, // إظهار الشعار
      showBarcode: true, // إظهار الباركود
      invoiceNumber: _lastInvoiceId?.toString(), // تمرير رقم الفاتورة
      installments: _lastInstallments, // معلومات الأقساط
      totalDebt: _lastTotalDebt, // إجمالي الدين
      downPayment: _lastDownPayment, // المبلغ المقدم
      context: context,
    );

    if (success && context.mounted) {
      print('تمت عملية الطباعة بنجاح');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم طباعة الفاتورة بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      print('فشلت عملية الطباعة');
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

  Widget _buildCustomerInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 8,
              color: _lastType == 'credit'
                  ? Colors.orange.shade700
                  : Colors.blue.shade700,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for dynamic colors based on payment type
  Color _getCustomerInfoBackgroundColor() {
    switch (_type) {
      case 'cash':
        return Colors.green.shade50;
      case 'installment':
        return Colors.blue.shade50;
      case 'credit':
        return Colors.orange.shade50;
      default:
        return Colors.white;
    }
  }

  Color _getCustomerInfoBorderColor() {
    switch (_type) {
      case 'cash':
        return Colors.green.shade200;
      case 'installment':
        return Colors.blue.shade200;
      case 'credit':
        return Colors.orange.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getCustomerInfoShadowColor() {
    switch (_type) {
      case 'cash':
        return Colors.green.withOpacity(0.05);
      case 'installment':
        return Colors.blue.withOpacity(0.05);
      case 'credit':
        return Colors.orange.withOpacity(0.05);
      default:
        return Colors.grey.withOpacity(0.05);
    }
  }
}
