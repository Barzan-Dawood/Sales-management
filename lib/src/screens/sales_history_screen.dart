// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../services/print_service.dart';
import '../services/store_config.dart';
import '../utils/format.dart';
import 'package:intl/intl.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  String _query = '';
  String _selectedType = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  List<Map<String, Object?>> _sales = [];
  bool _isLoading = false;

  // متغيرات التحديد الجماعي
  bool _isSelectionMode = false;
  Set<int> _selectedSales = <int>{};

  // متغيرات الترتيب
  bool _sortDescending =
      true; // true = من الأحدث للأقدم، false = من الأقدم للأحدث

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<DatabaseService>();
      final sales = await db.getSalesHistory(
        from: _fromDate,
        to: _toDate,
        type: _selectedType.isEmpty ? null : _selectedType,
        query: _query.isEmpty ? null : _query,
        sortDescending: _sortDescending,
      );
      setState(() => _sales = sales);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل المبيعات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    DateTime? tempFrom = _fromDate;
    DateTime? tempTo = _toDate;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: StatefulBuilder(builder: (context, setModalState) {
              String formatDate(DateTime? d) =>
                  d == null ? '-' : DateFormat('yyyy/MM/dd').format(d);

              void applyQuickRange(String key) {
                final now = DateTime.now();
                DateTime start;
                DateTime end;
                if (key == 'today') {
                  start = DateTime(now.year, now.month, now.day);
                  end = start;
                } else if (key == '7') {
                  end = DateTime(now.year, now.month, now.day);
                  start = end.subtract(const Duration(days: 6));
                } else if (key == '30') {
                  end = DateTime(now.year, now.month, now.day);
                  start = end.subtract(const Duration(days: 29));
                } else if (key == 'month') {
                  start = DateTime(now.year, now.month, 1);
                  end = DateTime(now.year, now.month + 1, 0);
                } else {
                  start = DateTime(now.year, now.month, now.day);
                  end = start;
                }
                setModalState(() {
                  tempFrom = start;
                  tempTo = end;
                });
              }

              Future<void> pickFrom() async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDate: tempFrom ?? DateTime.now(),
                );
                if (picked != null) {
                  setModalState(() => tempFrom = picked);
                }
              }

              Future<void> pickTo() async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDate: tempTo ?? tempFrom ?? DateTime.now(),
                );
                if (picked != null) {
                  setModalState(() => tempTo = picked);
                }
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'اختيار الفترة',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('اليوم'),
                            selected: false,
                            onSelected: (_) => applyQuickRange('today'),
                          ),
                          ChoiceChip(
                            label: const Text('آخر 7 أيام'),
                            selected: false,
                            onSelected: (_) => applyQuickRange('7'),
                          ),
                          ChoiceChip(
                            label: const Text('آخر 30 يوم'),
                            selected: false,
                            onSelected: (_) => applyQuickRange('30'),
                          ),
                          ChoiceChip(
                            label: const Text('هذا الشهر'),
                            selected: false,
                            onSelected: (_) => applyQuickRange('month'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickFrom,
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text('من: ${formatDate(tempFrom)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickTo,
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text('إلى: ${formatDate(tempTo)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempFrom = null;
                                tempTo = null;
                              });
                            },
                            child: const Text('مسح'),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              if (tempFrom != null &&
                                  tempTo != null &&
                                  tempFrom!.isAfter(tempTo!)) {
                                final tmp = tempFrom;
                                tempFrom = tempTo;
                                tempTo = tmp;
                              }
                              setState(() {
                                _fromDate = tempFrom;
                                _toDate = tempTo;
                              });
                              Navigator.pop(context);
                              _loadSales();
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('تطبيق'),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedSales.clear();
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedSales = _sales.map((sale) => sale['id'] as int).toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedSales.clear();
    });
  }

  void _toggleSaleSelection(int saleId) {
    setState(() {
      if (_selectedSales.contains(saleId)) {
        _selectedSales.remove(saleId);
      } else {
        _selectedSales.add(saleId);
      }
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _sortDescending = !_sortDescending;
    });
    _loadSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? 'تم تحديد ${_selectedSales.length} من ${_sales.length}'
            : 'تاريخ المبيعات'),
        backgroundColor: _isSelectionMode
            ? Colors.red.shade600
            : Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: _isSelectionMode
            ? [
                // أزرار وضع التحديد
                if (_selectedSales.length < _sales.length)
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: _selectAll,
                    tooltip: 'تحديد الكل',
                  ),
                if (_selectedSales.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _deselectAll,
                    tooltip: 'إلغاء التحديد',
                  ),
                if (_selectedSales.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _confirmBulkDelete,
                    tooltip: 'حذف المحدد',
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                  tooltip: 'إلغاء وضع التحديد',
                ),
              ]
            : [
                // أزرار الوضع العادي
                IconButton(
                  icon: Icon(_sortDescending
                      ? Icons.arrow_downward
                      : Icons.arrow_upward),
                  onPressed: _toggleSortOrder,
                  tooltip: _sortDescending ? 'ترتيب تصاعدي' : 'ترتيب تنازلي',
                ),
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: _toggleSelectionMode,
                  tooltip: 'وضع التحديد',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSales,
                  tooltip: 'تحديث',
                ),
              ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            // Filters Section - محسن
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // Search Field
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'البحث في المبيعات والعملاء وأرقام الفواتير...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() => _query = value);
                          _loadSales();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Payment Type Filter (ChoiceChips for consistency)
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _typeChip('الكل', ''),
                            _typeChip('نقدي', 'cash'),
                            _typeChip('أجل', 'credit'),
                            _typeChip('أقساط', 'installment'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Date Range Filter
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _selectDateRange,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.date_range,
                                  size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _fromDate != null && _toDate != null
                                      ? '${DateFormat('MM/dd').format(_fromDate!)} - ${DateFormat('MM/dd').format(_toDate!)}'
                                      : 'الفترة',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (_fromDate != null || _toDate != null) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _fromDate = null;
                                      _toDate = null;
                                    });
                                    _loadSales();
                                  },
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.black45),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sales List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد مبيعات',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'لم يتم العثور على أي مبيعات تطابق المعايير المحددة',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _sales.length,
                          itemBuilder: (context, index) {
                            final sale = _sales[index];
                            return _buildCompactSaleCard(sale);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final bool selected =
        _selectedType == value || (_selectedType.isEmpty && value.isEmpty);
    final Color color =
        selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: color.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: color.withOpacity(0.4)),
      onSelected: (_) {
        setState(() => _selectedType = value);
        _loadSales();
      },
    );
  }

  Widget _buildCompactSaleCard(Map<String, Object?> sale) {
    final saleId = sale['id'] as int;
    final total = (sale['total'] as num).toDouble();
    final profit = (sale['profit'] as num).toDouble();
    final type = sale['type'] as String;
    final createdAt = DateTime.parse(sale['created_at'] as String);
    final customerName = sale['customer_name'] as String?;
    final isSelected = _selectedSales.contains(saleId);

    Color typeColor;
    // Removed unused icon variable to match simplified card design
    // Icon kept in switch for readability before, but no longer used
    // Keeping declaration removed to satisfy linter
    String typeText;

    switch (type) {
      case 'cash':
        typeColor = Colors.green;
        typeText = 'نقدي';
        break;
      case 'credit':
        typeColor = Colors.orange;
        typeText = 'أجل';
        break;
      case 'installment':
        typeColor = Colors.blue;
        typeText = 'أقساط';
        break;
      default:
        typeColor = Colors.grey;
        typeText = 'غير محدد';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isSelected ? typeColor : Colors.grey.shade200,
            width: isSelected ? 1.2 : 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSelectionMode ? () => _toggleSaleSelection(saleId) : null,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Accent bar
              Container(
                width: 4,
                height: 82,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_isSelectionMode) ...[
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) =>
                                  _toggleSaleSelection(saleId),
                              activeColor: typeColor,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text('#$saleId',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeText,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MM/dd HH:mm').format(createdAt),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade700),
                          ),
                          const Spacer(),
                          Text(
                            Formatters.currencyIQD(total),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16, color: Colors.blue.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customerName ?? 'عميل عام',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.blue.shade700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ربح: ${Formatters.currencyIQD(profit)}',
                            style: TextStyle(
                                fontSize: 10,
                                color: profit > 0 ? Colors.blue : Colors.red,
                                fontWeight: FontWeight.w600),
                          ),
                          if (!_isSelectionMode) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showSaleDetails(saleId),
                              child: Icon(Icons.visibility_outlined,
                                  size: 20, color: typeColor),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _printInvoice(saleId),
                              child: const Icon(Icons.print_outlined,
                                  size: 20, color: Colors.blue),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _confirmDeleteSale(saleId),
                              child: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSaleDetails(int saleId) async {
    try {
      final db = context.read<DatabaseService>();
      final saleDetails = await db.getSaleDetails(saleId);
      final saleItems = await db.getSaleItems(saleId);

      if (saleDetails == null) return;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تفاصيل الفاتورة #$saleId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (saleDetails['customer_name'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                saleDetails['customer_name'] as String,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sale Info
                        _buildDetailRow(
                            'التاريخ',
                            DateFormat('yyyy/MM/dd - HH:mm').format(
                              DateTime.parse(
                                  saleDetails['created_at'] as String),
                            )),
                        _buildDetailRow('نوع الدفع',
                            _getTypeText(saleDetails['type'] as String)),
                        if (saleDetails['customer_name'] != null)
                          _buildDetailRow(
                              'العميل', saleDetails['customer_name'] as String),
                        if (saleDetails['customer_phone'] != null)
                          _buildDetailRow('الهاتف',
                              saleDetails['customer_phone'] as String),
                        _buildDetailRow(
                            'الإجمالي',
                            Formatters.currencyIQD(
                                saleDetails['total'] as num)),
                        _buildDetailRow(
                            'الربح',
                            Formatters.currencyIQD(
                                saleDetails['profit'] as num)),
                        const SizedBox(height: 16),
                        // Items
                        const Text(
                          'المنتجات:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...saleItems.map((item) => Card(
                              child: ListTile(
                                title: Text(item['product_name'] as String),
                                subtitle: Text('الكمية: ${item['quantity']}'),
                                trailing: Text(
                                  Formatters.currencyIQD(
                                      (item['price'] as num) *
                                          (item['quantity'] as num)),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل تفاصيل الفاتورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getTypeText(String type) {
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

  Future<void> _confirmDeleteSale(int saleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
            'هل أنت متأكد من حذف الفاتورة #$saleId؟\n\nسيتم إرجاع المنتجات إلى المخزون.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSale(saleId);
    }
  }

  Future<void> _deleteSale(int saleId) async {
    try {
      final db = context.read<DatabaseService>();
      final success = await db.deleteSale(saleId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الفاتورة #$saleId بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the sales list
        _loadSales();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في حذف الفاتورة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حذف الفاتورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printInvoice(int saleId) async {
    try {
      final db = context.read<DatabaseService>();
      final saleDetails = await db.getSaleDetails(saleId);
      final saleItems = await db.getSaleItems(saleId);

      if (saleDetails == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على تفاصيل الفاتورة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // عرض خيارات الطباعة
      final printOptions = await PrintService.showPrintOptionsDialog(context);
      if (printOptions == null) {
        // المستخدم ألغى العملية
        return;
      }

      // تحويل عناصر المبيعات إلى تنسيق مناسب للطباعة مع جميع التفاصيل
      final items = saleItems
          .map((item) => {
                'name': item['product_name'] ?? 'منتج غير محدد',
                'price': item['price'] ?? 0,
                'quantity': item['quantity'] ?? 1,
                'cost': item['cost'] ?? 0,
                'barcode': item['barcode'] ?? '',
              })
          .toList();

      // الحصول على معلومات العميل الكاملة
      final customerName = saleDetails['customer_name'] as String?;
      final customerPhone = saleDetails['customer_phone'] as String?;
      final customerAddress = saleDetails['customer_address'] as String?;

      // الحصول على تاريخ الاستحقاق
      DateTime? dueDate;
      if (saleDetails['due_date'] != null) {
        try {
          dueDate = DateTime.parse(saleDetails['due_date'] as String);
        } catch (e) {
          debugPrint('خطأ في تحليل تاريخ الاستحقاق: $e');
        }
      }

      // الحصول على معلومات الأقساط إذا كانت متوفرة
      List<Map<String, Object?>>? installments;
      double? totalDebt;
      double? downPayment;

      if (saleDetails['type'] == 'installment') {
        try {
          installments = await db.getInstallments(saleId: saleId);
          totalDebt = saleDetails['total'] as double?;
          downPayment = saleDetails['down_payment'] as double?;
        } catch (e) {
          debugPrint('خطأ في الحصول على معلومات الأقساط: $e');
        }
      }

      // طباعة الفاتورة مع جميع التفاصيل والخيارات المختارة
      final store = context.read<StoreConfig>();
      final success = await PrintService.printInvoice(
        shopName: store.shopName,
        phone: store.phone,
        address: store.address,
        items: items,
        paymentType: saleDetails['type'] as String,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        dueDate: dueDate,
        invoiceNumber: saleId.toString(),
        installments: installments,
        totalDebt: totalDebt,
        downPayment: downPayment,
        pageFormat: printOptions['pageFormat'] as String,
        showLogo: printOptions['showLogo'] as bool,
        showBarcode: printOptions['showBarcode'] as bool,
        context: context,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم طباعة الفاتورة #$saleId بنجاح مع جميع التفاصيل'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في طباعة الفاتورة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في طباعة الفاتورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmBulkDelete() async {
    if (_selectedSales.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف الجماعي'),
        content: Text(
            'هل أنت متأكد من حذف ${_selectedSales.length} فاتورة؟\n\nسيتم إرجاع المنتجات إلى المخزون.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bulkDeleteSales();
    }
  }

  Future<void> _bulkDeleteSales() async {
    if (_selectedSales.isEmpty) return;

    try {
      final db = context.read<DatabaseService>();
      int successCount = 0;
      int failCount = 0;

      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جاري حذف الفواتير...'),
            ],
          ),
        ),
      );

      // حذف كل فاتورة على حدة
      for (final saleId in _selectedSales) {
        try {
          final success = await db.deleteSale(saleId);
          if (success) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
        }
      }

      // إغلاق مؤشر التحميل
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      // إظهار النتيجة
      String message;
      if (failCount == 0) {
        message = 'تم حذف $successCount فاتورة بنجاح';
      } else if (successCount == 0) {
        message = 'فشل في حذف جميع الفواتير';
      } else {
        message = 'تم حذف $successCount فاتورة، فشل في حذف $failCount فاتورة';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

      // إعادة تحميل القائمة وإلغاء وضع التحديد
      setState(() {
        _selectedSales.clear();
        _isSelectionMode = false;
      });
      _loadSales();
    } catch (e) {
      // إغلاق مؤشر التحميل إذا كان مفتوحاً
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحذف الجماعي: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
