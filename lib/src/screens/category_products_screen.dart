import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../services/db/database_service.dart';
import '../utils/format.dart';

class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  final int categoryId;
  final String categoryName;
  final Color categoryColor;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: widget.categoryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openProductEditor({}),
            tooltip: 'إضافة منتج',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search field
            Container(
              margin: const EdgeInsets.all(16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: widget.categoryColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'البحث في منتجات القسم...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: widget.categoryColor,
                      size: 20,
                    ),
                  ),
                  prefixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            // Products grid
            Expanded(
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.getAllProducts(
                  query: _searchQuery,
                  categoryId: widget.categoryId,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final products = snapshot.data!;

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'لا توجد منتجات في هذا القسم'
                                : 'لا توجد منتجات تطابق البحث',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'قم بإضافة منتجات جديدة لهذا القسم'
                                : 'جرب البحث بكلمات مختلفة',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _ProductListTile(
                          product: product,
                          categoryColor: widget.categoryColor,
                          onEdit: () => _openProductEditor(product),
                          onDelete: () => _deleteProduct(product['id'] as int),
                          onShowBarcode: () => _showBarcode(
                            product['barcode']?.toString() ?? '',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ProductListTile({
    required Map<String, Object?> product,
    required Color categoryColor,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onShowBarcode,
  }) {
    final name = product['name']?.toString() ?? 'بدون اسم';
    final price = (product['price'] as num?) ?? 0;
    final cost = (product['cost'] as num?) ?? 0;
    final quantity = (product['quantity'] as num?) ?? 0;
    final barcode = product['barcode']?.toString() ?? '';
    final profit = price - cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: categoryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Action buttons - الجانب الأيسر
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.edit_rounded,
                    color: Colors.white,
                    backgroundColor: Colors.blue.shade500,
                    onTap: onEdit,
                    tooltip: 'تعديل',
                  ),
                  const SizedBox(height: 8),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.white,
                    backgroundColor: Colors.red.shade500,
                    onTap: onDelete,
                    tooltip: 'حذف',
                  ),
                  if (barcode.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ActionButton(
                      icon: Icons.qr_code_2_rounded,
                      color: Colors.white,
                      backgroundColor: Colors.green.shade500,
                      onTap: onShowBarcode,
                      tooltip: 'عرض الباركود',
                    ),
                  ],
                ],
              ),

              // Product details - الجانب الأيمن
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Product name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    // Barcode if exists
                    if (barcode.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              barcode,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 14,
                            color: Colors.blue.shade600,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Price, cost, profit and quantity row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'السعر: ${Formatters.currencyIQD(price)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cost
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purple.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag_rounded,
                                size: 14,
                                color: Colors.purple.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'التكلفة: ${Formatters.currencyIQD(cost)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Profit
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: categoryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 14,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'الربح: ${Formatters.currencyIQD(profit)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: categoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Quantity
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_rounded,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'الكمية: ${quantity.toString()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _ActionButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(int id) async {
    final db = context.read<DatabaseService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.deleteProduct(id);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف المنتج بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openProductEditor(Map<String, Object?> product) async {
    final db = context.read<DatabaseService>();
    final isEdit = product['id'] != null;

    final nameCtrl = TextEditingController(
      text: product['name']?.toString() ?? '',
    );
    final barcodeCtrl = TextEditingController(
      text: product['barcode']?.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: (product['price'] as num?)?.toString() ?? '0',
    );
    final costCtrl = TextEditingController(
      text: (product['cost'] as num?)?.toString() ?? '0',
    );
    final qtyCtrl = TextEditingController(
      text: (product['quantity'] as num?)?.toString() ?? '0',
    );
    final minQtyCtrl = TextEditingController(
      text: (product['min_quantity'] as num?)?.toString() ?? '1',
    );

    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            isEdit ? 'تعديل منتج' : 'إضافة منتج',
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'اسم المنتج مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: barcodeCtrl,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'الباركود (اختياري)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'السعر',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'السعر مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: costCtrl,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'التكلفة',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: qtyCtrl,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'الكمية',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: minQtyCtrl,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'الحد الأدنى',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                final values = <String, Object?>{
                  'name': nameCtrl.text.trim(),
                  'barcode': barcodeCtrl.text.trim().isEmpty
                      ? null
                      : barcodeCtrl.text.trim(),
                  'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
                  'cost': double.tryParse(costCtrl.text.trim()) ?? 0,
                  'quantity': int.tryParse(qtyCtrl.text.trim()) ?? 0,
                  'min_quantity': int.tryParse(minQtyCtrl.text.trim()) ?? 1,
                  'category_id': widget.categoryId,
                };

                if (isEdit) {
                  await db.updateProduct(product['id'] as int, values);
                } else {
                  await db.insertProduct(values);
                }

                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('حفظ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'تم تحديث المنتج' : 'تم إضافة المنتج'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showBarcode(String code) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: widget.categoryColor),
            const SizedBox(width: 8),
            const Text('باركود المنتج'),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.categoryColor.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (code.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: code,
                        width: 300,
                        height: 120,
                        color: Colors.black,
                        backgroundColor: Colors.white,
                        drawText: false,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          code,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'لا يوجد باركود لهذا المنتج',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
