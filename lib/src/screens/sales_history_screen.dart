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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Filters Section - محسن
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() => _query = value);
                          _loadSales();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Payment Type Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            _selectedType.isEmpty ? null : _selectedType,
                        decoration: InputDecoration(
                          hintText: 'نوع الدفع',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'cash',
                            child: Text('نقدي', style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: 'credit',
                            child: Text('أجل', style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: 'installment',
                            child:
                                Text('أقساط', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedType = value ?? '');
                          _loadSales();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Date Range Filter
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range, size: 16),
                        label: Text(
                          _fromDate != null && _toDate != null
                              ? '${DateFormat('MM/dd').format(_fromDate!)} - ${DateFormat('MM/dd').format(_toDate!)}'
                              : 'الفترة',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildCompactSaleCard(Map<String, Object?> sale) {
    final saleId = sale['id'] as int;
    final total = (sale['total'] as num).toDouble();
    final profit = (sale['profit'] as num).toDouble();
    final type = sale['type'] as String;
    final createdAt = DateTime.parse(sale['created_at'] as String);
    final customerName = sale['customer_name'] as String?;
    final isSelected = _selectedSales.contains(saleId);

    Color typeColor;
    IconData typeIcon;
    String typeText;

    switch (type) {
      case 'cash':
        typeColor = Colors.green;
        typeIcon = Icons.money;
        typeText = 'نقدي';
        break;
      case 'credit':
        typeColor = Colors.orange;
        typeIcon = Icons.schedule;
        typeText = 'أجل';
        break;
      case 'installment':
        typeColor = Colors.blue;
        typeIcon = Icons.credit_card;
        typeText = 'أقساط';
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.receipt;
        typeText = 'غير محدد';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? typeColor.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? typeColor.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: isSelected ? typeColor : Colors.grey.shade200,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSelectionMode ? () => _toggleSaleSelection(saleId) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Header Row - Compact
                Row(
                  children: [
                    // Checkbox في وضع التحديد
                    if (_isSelectionMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleSaleSelection(saleId),
                        activeColor: typeColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Icon - أصغر
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        typeIcon,
                        color: typeColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sale info - مضغوط
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$saleId',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                          Text(
                            DateFormat('MM/dd HH:mm').format(createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Type badge - أصغر
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        typeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Info Row - Compact
                Row(
                  children: [
                    // Customer - مضغوط
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 11,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              customerName ?? 'عميل عام',
                              style: TextStyle(
                                fontSize: 10,
                                color: customerName != null
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Amount - مضغوط
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.currencyIQD(total),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'ربح: ${Formatters.currencyIQD(profit)}',
                            style: TextStyle(
                              fontSize: 9,
                              color: profit > 0 ? Colors.blue : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Action Buttons - Compact (تظهر فقط في الوضع العادي)
                if (!_isSelectionMode) ...[
                  Row(
                    children: [
                      // زر التفاصيل - مضغوط
                      Expanded(
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: typeColor.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showSaleDetails(saleId),
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    color: typeColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'التفاصيل',
                                    style: TextStyle(
                                      color: typeColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // زر الطباعة - مضغوط
                      Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _printInvoice(saleId),
                            borderRadius: BorderRadius.circular(6),
                            child: const Icon(
                              Icons.print_outlined,
                              color: Colors.blue,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // زر الحذف - مضغوط
                      Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _confirmDeleteSale(saleId),
                            borderRadius: BorderRadius.circular(6),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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

      // تحويل عناصر المبيعات إلى تنسيق مناسب للطباعة
      final items = saleItems
          .map((item) => {
                'name': item['product_name'],
                'price': item['price'],
                'quantity': item['quantity'],
                'cost': item['cost'] ?? 0,
              })
          .toList();

      // طباعة الفاتورة مع رقم الفاتورة الصحيح
      final store = context.read<StoreConfig>();
      final success = await PrintService.quickPrint(
        shopName: store.shopName,
        phone: store.phone,
        address: store.address,
        items: items,
        paymentType: saleDetails['type'] as String,
        customerName: saleDetails['customer_name'] as String?,
        customerPhone: saleDetails['customer_phone'] as String?,
        customerAddress: null,
        dueDate: saleDetails['due_date'] != null
            ? DateTime.parse(saleDetails['due_date'] as String)
            : null,
        invoiceNumber:
            saleId.toString(), // استخدام رقم الفاتورة من قاعدة البيانات
        context: context,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم طباعة الفاتورة #$saleId بنجاح'),
            backgroundColor: Colors.green,
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
          print('خطأ في حذف الفاتورة $saleId: $e');
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
