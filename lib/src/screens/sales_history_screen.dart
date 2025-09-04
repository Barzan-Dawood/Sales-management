import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
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
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadSales();
    }
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _selectedType = '';
      _fromDate = null;
      _toDate = null;
    });
    _loadSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاريخ المبيعات'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
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
                        hintText: 'البحث في المبيعات...',
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
                          child: Text('أقساط', style: TextStyle(fontSize: 12)),
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
                        padding: const EdgeInsets.all(16),
                        itemCount: _sales.length,
                        itemBuilder: (context, index) {
                          final sale = _sales[index];
                          return _buildCompactSaleCard(sale);
                        },
                      ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: typeColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: typeColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSaleDetails(saleId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        typeIcon,
                        color: typeColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Sale info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'فاتورة #$saleId',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MM/dd - HH:mm').format(createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        typeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Info Row
                Row(
                  children: [
                    // Customer
                    if (customerName != null) ...[
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customerName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currencyIQD(total),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'ربح: ${Formatters.currencyIQD(profit)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: profit > 0 ? Colors.blue : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: typeColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showSaleDetails(saleId),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  color: typeColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'التفاصيل',
                                  style: TextStyle(
                                    color: typeColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _confirmDeleteSale(saleId),
                          borderRadius: BorderRadius.circular(8),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                        child: Text(
                          'تفاصيل الفاتورة #$saleId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
}
