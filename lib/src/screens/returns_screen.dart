// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/format.dart';

/// صفحة المرتجعات - تصميم مبسط وسهل الاستخدام
class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.hasPermission(UserPermission.manageSales)) {
      return Scaffold(
        appBar: AppBar(title: const Text('المرتجعات')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('ليس لديك صلاحية للوصول إلى هذه الصفحة'),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المرتجعات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Column(
            children: [
              _buildStatsCard(),
              _buildSearchSection(),
              Expanded(child: _buildReturnsList()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddReturnDialog(),
          icon: const Icon(Icons.add),
          label: const Text('إرجاع منتج'),
          backgroundColor: Colors.orange,
        ),
      ),
    );
  }

  /// بطاقة الإحصائيات
  Widget _buildStatsCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<DatabaseService>().getReturns(
            from: _fromDate,
            to: _toDate,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final returns = snapshot.data ?? [];
        final filteredReturns = _filterReturns(returns);

        double totalAmount = 0;
        for (final r in filteredReturns) {
          totalAmount += (r['total_amount'] as num?)?.toDouble() ?? 0;
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_return,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي المرتجعات',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.currencyIQD(totalAmount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '${filteredReturns.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'مرتجع',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// قسم البحث والفلترة
  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'بحث (رقم الفاتورة، اسم العميل...)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _fromDate != null && _toDate != null
                        ? '${DateFormat('yyyy-MM-dd').format(_fromDate!)} - ${DateFormat('yyyy-MM-dd').format(_toDate!)}'
                        : 'فلترة حسب التاريخ',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (_fromDate != null ||
                  _toDate != null ||
                  _searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                      _searchQuery = '';
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// قائمة المرتجعات
  Widget _buildReturnsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<DatabaseService>().getReturns(
            from: _fromDate,
            to: _toDate,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final returns = snapshot.data ?? [];
        final filteredReturns = _filterReturns(returns);

        if (filteredReturns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_return,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد مرتجعات',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddReturnDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مرتجع جديد'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredReturns.length,
          itemBuilder: (context, index) {
            return _ReturnItemCard(
              returnItem: filteredReturns[index],
              onTap: () => _showReturnDetails(filteredReturns[index]),
              onDelete: () => _deleteReturn(filteredReturns[index]),
            );
          },
        );
      },
    );
  }

  /// فلترة المرتجعات
  List<Map<String, dynamic>> _filterReturns(
      List<Map<String, dynamic>> returns) {
    if (_searchQuery.isEmpty) return returns;

    final query = _searchQuery.toLowerCase();
    return returns.where((r) {
      final saleId = r['sale_id']?.toString().toLowerCase() ?? '';
      final customerName = r['customer_name']?.toString().toLowerCase() ?? '';
      return saleId.contains(query) || customerName.contains(query);
    }).toList();
  }

  /// اختيار نطاق التاريخ
  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (context, child) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
      });
    }
  }

  /// حوار إضافة مرتجع
  Future<void> _showAddReturnDialog() async {
    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: _AddReturnDialog(
              onReturnCreated: () {
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  /// عرض تفاصيل المرتجع
  Future<void> _showReturnDetails(Map<String, dynamic> returnItem) async {
    final saleId = returnItem['sale_id'] as int?;
    if (saleId == null) return;

    try {
      final db = context.read<DatabaseService>();
      final saleItems = await db.getSaleItems(saleId);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: Text('تفاصيل المرتجع #${returnItem['id']}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow('الفاتورة', '#$saleId', Icons.receipt),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'العميل',
                      returnItem['customer_name']?.toString() ?? 'عميل عام',
                      Icons.person,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'المبلغ',
                      Formatters.currencyIQD(
                        (returnItem['total_amount'] as num?)?.toDouble() ?? 0,
                      ),
                      Icons.attach_money,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'التاريخ',
                      returnItem['return_date']?.toString().substring(0, 10) ??
                          '',
                      Icons.calendar_today,
                    ),
                    if (returnItem['notes'] != null &&
                        returnItem['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'ملاحظات',
                        returnItem['notes'].toString(),
                        Icons.note,
                      ),
                    ],
                    const Divider(height: 24),
                    Text(
                      'المنتجات',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...saleItems.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['product_name']?.toString() ?? 'منتج',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${item['quantity']} × ${Formatters.currencyIQD((item['price'] as num?)?.toDouble() ?? 0)}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      [Color? color]) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    );
  }

  /// حذف مرتجع
  Future<void> _deleteReturn(Map<String, dynamic> returnItem) async {
    final id = returnItem['id'] as int?;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المرتجع'),
        content: const Text('هل أنت متأكد من حذف هذا المرتجع؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<DatabaseService>().deleteReturn(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحذف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// بطاقة عنصر المرتجع
class _ReturnItemCard extends StatelessWidget {
  final Map<String, dynamic> returnItem;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReturnItemCard({
    required this.returnItem,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final id = returnItem['id'] as int?;
    final saleId = returnItem['sale_id'] as int?;
    final amount = (returnItem['total_amount'] as num?)?.toDouble() ?? 0;
    final dateStr = returnItem['return_date']?.toString() ?? '';
    final customerName = returnItem['customer_name']?.toString() ?? 'عميل عام';
    final date = dateStr.isNotEmpty && dateStr.length > 10
        ? dateStr.substring(0, 10)
        : dateStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.assignment_return,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'فاتورة #$saleId',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currencyIQD(amount),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#$id',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('التفاصيل'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('حذف'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
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
}

/// حوار إضافة مرتجع جديد
class _AddReturnDialog extends StatefulWidget {
  final VoidCallback onReturnCreated;

  const _AddReturnDialog({required this.onReturnCreated});

  @override
  State<_AddReturnDialog> createState() => _AddReturnDialogState();
}

class _AddReturnDialogState extends State<_AddReturnDialog> {
  int? _selectedSaleId;
  List<Map<String, dynamic>> _saleItems = [];
  final Map<int, int> _returnQuantities = {};
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment_return,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'إرجاع منتجات من فاتورة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSaleSelector(),
                if (_saleItems.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildProductsList(),
                  const SizedBox(height: 20),
                  _buildTotalCard(),
                  const SizedBox(height: 20),
                ],
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        // Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _canCreateReturn() ? _createReturn : null,
                icon: const Icon(Icons.check),
                label: const Text('إنشاء المرتجع'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaleSelector() {
    return FutureBuilder<List<Map<String, Object?>>>(
      future:
          context.read<DatabaseService>().getSalesHistory(sortDescending: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Text('خطأ في تحميل الفواتير');
        }

        final sales = snapshot.data!;
        if (sales.isEmpty) {
          return const Text('لا توجد فواتير متاحة');
        }

        return DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'اختر الفاتورة',
            prefixIcon: const Icon(Icons.receipt),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: sales.map((sale) {
            final id = sale['id'] as int;
            final customerName =
                sale['customer_name']?.toString() ?? 'عميل عام';
            final total = (sale['total'] as num?)?.toDouble() ?? 0;
            return DropdownMenuItem(
              value: id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'فاتورة #$id - $customerName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    Formatters.currencyIQD(total),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (saleId) async {
            if (saleId != null) {
              await _loadSaleItems(saleId);
            }
          },
        );
      },
    );
  }

  Future<void> _loadSaleItems(int saleId) async {
    setState(() {
      _isLoading = true;
      _selectedSaleId = saleId;
      _returnQuantities.clear();
    });

    try {
      final items = await context.read<DatabaseService>().getSaleItems(saleId);
      setState(() {
        _saleItems = items;
        for (final item in items) {
          _returnQuantities[item['product_id'] as int] = 0;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildProductsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المنتجات',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ..._saleItems.map((item) {
          final productId = item['product_id'] as int;
          final productName = item['product_name']?.toString() ?? 'منتج';
          final quantity = item['quantity'] as int;
          final price = (item['price'] as num?)?.toDouble() ?? 0;
          final returnQty = _returnQuantities[productId] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: returnQty > 0
                  ? Colors.orange.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: returnQty > 0
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'المباع: $quantity | السعر: ${Formatters.currencyIQD(price)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('الكمية المرجعة: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: returnQty > 0 ? Colors.red : Colors.grey,
                            onPressed: returnQty > 0
                                ? () {
                                    setState(() {
                                      _returnQuantities[productId] =
                                          returnQty - 1;
                                    });
                                  }
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '$returnQty / $quantity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    returnQty > 0 ? Colors.orange : Colors.grey,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: returnQty < quantity
                                ? Colors.green
                                : Colors.grey,
                            onPressed: returnQty < quantity
                                ? () {
                                    setState(() {
                                      _returnQuantities[productId] =
                                          returnQty + 1;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (returnQty > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('مبلغ الإرجاع:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          Formatters.currencyIQD(returnQty * price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTotalCard() {
    final total = _calculateTotal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            total > 0 ? Colors.orange.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: total > 0 ? Colors.orange : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money,
              color: total > 0 ? Colors.orange : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ الإجمالي للمرتجع',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  Formatters.currencyIQD(total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: total > 0 ? Colors.orange : Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (final item in _saleItems) {
      final productId = item['product_id'] as int;
      final returnQty = _returnQuantities[productId] ?? 0;
      if (returnQty > 0) {
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        total += returnQty * price;
      }
    }
    return total;
  }

  bool _canCreateReturn() {
    if (_selectedSaleId == null || _saleItems.isEmpty) return false;
    return _returnQuantities.values.any((qty) => qty > 0);
  }

  Future<void> _createReturn() async {
    if (!_canCreateReturn()) return;

    final total = _calculateTotal();
    if (total <= 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد المرتجع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المبلغ الإجمالي: ${Formatters.currencyIQD(total)}'),
            const SizedBox(height: 8),
            Text(
                'عدد المنتجات: ${_returnQuantities.values.where((q) => q > 0).length}'),
            const SizedBox(height: 16),
            const Text('سيتم:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• إرجاع المنتجات للمخزون'),
            const Text('• تحديث ديون العميل (إن وجدت)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final db = context.read<DatabaseService>();
      final auth = context.read<AuthProvider>();

      final returnItems = <Map<String, dynamic>>[];
      for (final item in _saleItems) {
        final productId = item['product_id'] as int;
        final returnQty = _returnQuantities[productId] ?? 0;
        if (returnQty > 0) {
          returnItems.add({
            'product_id': productId,
            'quantity': returnQty,
            'price': (item['price'] as num?)?.toDouble() ?? 0,
          });
        }
      }

      await db.createReturn(
        saleId: _selectedSaleId!,
        totalAmount: total,
        returnItems: returnItems,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        userId: auth.currentUser?.id,
        username: auth.currentUser?.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء المرتجع بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onReturnCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
