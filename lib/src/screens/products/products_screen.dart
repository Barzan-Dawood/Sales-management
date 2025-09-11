import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../services/db/database_service.dart';
import '../../utils/format.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, this.initialCategoryId});

  final int? initialCategoryId;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';
  int? _selectedCategoryId;
  final ScrollController _tableHController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _tableHController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Fancy gradient header with search
              Container(
                margin: const EdgeInsets.fromLTRB(100, 2, 100, 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400,
                      Colors.purple.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.none,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'إدارة المنتجات',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              decoration: InputDecoration(
                                hintText: 'بحث بالاسم أو الباركود',
                                hintStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                suffixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                prefixIcon: _query.isNotEmpty
                                    ? IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _query = '');
                                        },
                                      )
                                    : null,
                                filled: false,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: FutureBuilder<List<Map<String, Object?>>>(
                              future: db.getCategories(),
                              builder: (context, catSnap) {
                                if (!catSnap.hasData) {
                                  return const SizedBox.shrink();
                                }
                                final cats = catSnap.data!;
                                return DropdownButtonFormField<int>(
                                  initialValue: _selectedCategoryId,
                                  isDense: true,
                                  iconEnabledColor: Colors.white,
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'القسم',
                                    hintStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.category_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    filled: false,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem<int>(
                                      value: null,
                                      child: Text('كل الأقسام'),
                                    ),
                                    ...cats.map((c) => DropdownMenuItem<int>(
                                          value: c['id'] as int,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                                c['name']?.toString() ?? ''),
                                          ),
                                        )),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _selectedCategoryId = val),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: FutureBuilder<List<Map<String, Object?>>>(
                    future: db.getAllProducts(
                      query: _query,
                      categoryId:
                          _selectedCategoryId ?? widget.initialCategoryId,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products = snapshot.data!;

                      return Column(
                        children: [
                          // Table body - منفصل عن الرأس
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(90, 0, 90, 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  // Fixed Header - رؤوس الأعمدة الثابتة
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      controller: _tableHController,
                                      child: Table(
                                        columnWidths: const {
                                          0: FixedColumnWidth(80), // المعرف
                                          1: FixedColumnWidth(260), // الاسم
                                          2: FixedColumnWidth(160), // الباركود
                                          3: FixedColumnWidth(90), // الكمية
                                          4: FixedColumnWidth(160), // التكلفة
                                          5: FixedColumnWidth(180), // السعر
                                          6: FixedColumnWidth(160), // الإجراءات
                                        },
                                        border: TableBorder.symmetric(
                                          inside: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        children: [
                                          TableRow(
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                            ),
                                            children: [
                                              // المعرف
                                              Container(
                                                height: 60,
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: Center(
                                                  child: Text(
                                                    'المعرف',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade800,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                              // الاسم
                                              Container(
                                                height: 60,
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Center(
                                                  child: Text(
                                                    'الاسم',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade800,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                              // الباركود
                                              Container(
                                                height: 60,
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Center(
                                                  child: Text(
                                                    'الباركود',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade800,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                              // الكمية
                                              Container(
                                                height: 60,
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Center(
                                                  child: Text(
                                                    'الكمية',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade800,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                              // التكلفة
                                              Container(
                                                height: 60,
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Center(
                                                  child: Text(
                                                    'التكلفة',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade800,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                              // السعر
                                              Container(
                                                height: 60,
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Center(
                                                  child: Text(
                                                    'السعر',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade800,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                              // الإجراءات
                                              Container(
                                                height: 60,
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Center(
                                                  child: Text(
                                                    'الإجراءات',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade800,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Scrollable Data - البيانات القابلة للتمرير
                                  Expanded(
                                    child: SingleChildScrollView(
                                      controller: ScrollController(),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        controller: _tableHController,
                                        child: Table(
                                          columnWidths: const {
                                            0: FixedColumnWidth(80), // المعرف
                                            1: FixedColumnWidth(260), // الاسم
                                            2: FixedColumnWidth(
                                                160), // الباركود
                                            3: FixedColumnWidth(90), // الكمية
                                            4: FixedColumnWidth(160), // التكلفة
                                            5: FixedColumnWidth(180), // السعر
                                            6: FixedColumnWidth(
                                                160), // الإجراءات
                                          },
                                          border: TableBorder.symmetric(
                                            inside: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          children: [
                                            // Data Rows - صفوف البيانات
                                            for (int i = 0;
                                                i < products.length;
                                                i++)
                                              TableRow(
                                                decoration: BoxDecoration(
                                                  color: i % 2 == 0
                                                      ? Colors.white
                                                      : Colors.grey.shade50,
                                                ),
                                                children: [
                                                  // المعرف
                                                  Container(
                                                    height: 80,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Center(
                                                      child: Text(
                                                        '${i + 1}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .grey.shade700,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // الاسم
                                                  Container(
                                                    height: 80,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Center(
                                                      child: Text(
                                                        products[i]['name']
                                                                ?.toString() ??
                                                            'بدون اسم',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15,
                                                          color: Colors.black87,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  // الباركود
                                                  Container(
                                                    height: 80,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Center(
                                                      child: Text(
                                                        products[i]['barcode']
                                                                ?.toString() ??
                                                            '—',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'monospace',
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                          color: Colors
                                                              .blue.shade700,
                                                          letterSpacing: 0.5,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  // الكمية
                                                  Container(
                                                    height: 80,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Center(
                                                      child: Text(
                                                        (products[i]['quantity']
                                                                    as num?)
                                                                ?.toString() ??
                                                            '0',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .green.shade700,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // التكلفة
                                                  Container(
                                                    height: 80,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Center(
                                                      child: Text(
                                                        Formatters.currencyIQD(
                                                          (products[i]['cost']
                                                                  as num?) ??
                                                              0,
                                                        ),
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .purple.shade700,
                                                          fontSize: 15,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                  // السعر
                                                  Container(
                                                    height: 80,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Center(
                                                      child: Text(
                                                        Formatters.currencyIQD(
                                                          (products[i]['price']
                                                                  as num?) ??
                                                              0,
                                                        ),
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .orange.shade700,
                                                          fontSize: 15,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                  // الإجراءات
                                                  Container(
                                                    height: 80,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        _iconGradButton(
                                                          tooltip: 'حذف',
                                                          colors: [
                                                            Colors.red.shade500,
                                                            Colors.red.shade600
                                                          ],
                                                          icon: Icons
                                                              .delete_outline_rounded,
                                                          onTap: () =>
                                                              _deleteProduct(
                                                            context,
                                                            products[i]['id']
                                                                as int,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        _iconGradButton(
                                                          tooltip: 'تعديل',
                                                          colors: [
                                                            Colors
                                                                .blue.shade500,
                                                            Colors.blue.shade600
                                                          ],
                                                          icon: Icons
                                                              .edit_rounded,
                                                          onTap: () =>
                                                              _openEditor(
                                                            context,
                                                            product:
                                                                products[i],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        _iconGradButton(
                                                          tooltip: 'باركود',
                                                          colors: [
                                                            Colors
                                                                .green.shade500,
                                                            Colors
                                                                .green.shade600
                                                          ],
                                                          icon: Icons
                                                              .qr_code_2_rounded,
                                                          onTap: () =>
                                                              _showBarcode(
                                                            context,
                                                            products[i]['barcode']
                                                                    ?.toString() ??
                                                                '',
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
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(context, product: const {}),
          icon: const Icon(Icons.add),
          label: const Text('إضافة منتج'),
        ),
      ),
    );
  }

  Widget _iconGradButton({
    required String tooltip,
    required List<Color> colors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(BuildContext context, int id) async {
    final db = context.read<DatabaseService>();

    // Simple confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text(
            'هل أنت متأكد من حذف هذا المنتج؟\nسيتم حذف المنتج فقط دون التأثير على المبيعات السابقة.'),
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
      try {
        await db.deleteProduct(id);
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المنتج بنجاح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        String errorMessage = 'خطأ في الحذف';
        if (e.toString().contains('FOREIGN KEY constraint failed')) {
          errorMessage = 'لا يمكن حذف هذا المنتج لأنه مرتبط بفواتير مبيعات';
        } else if (e.toString().contains('database is locked')) {
          errorMessage = 'قاعدة البيانات مقفلة، حاول مرة أخرى';
        } else {
          errorMessage = 'خطأ في الحذف: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _openEditor(BuildContext context,
      {required Map<String, Object?> product}) async {
    final db = context.read<DatabaseService>();
    final TextEditingController nameCtrl =
        TextEditingController(text: product['name']?.toString() ?? '');
    final TextEditingController barcodeCtrl =
        TextEditingController(text: product['barcode']?.toString() ?? '');
    final TextEditingController priceCtrl = TextEditingController(
        text: (product['price'] as num?)?.toString() ?? '');
    final TextEditingController costCtrl = TextEditingController(
        text: (product['cost'] as num?)?.toString() ?? '');
    final TextEditingController qtyCtrl = TextEditingController(
        text: (product['quantity'] as num?)?.toString() ?? '');
    int? categoryId = product['category_id'] as int?;

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool isEdit = product['id'] != null;

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
            height: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // قسم المعلومات الأساسية
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'المعلومات الأساسية',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nameCtrl,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              labelText: 'اسم المنتج',
                              hintText: 'مطلوب',
                              helperText: 'اسم المنتج كما سيظهر في الفواتير',
                              prefixIcon: Icon(Icons.inventory_2),
                              alignLabelWithHint: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'اسم المنتج مطلوب'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: barcodeCtrl,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  decoration: const InputDecoration(
                                    labelText: 'الباركود',
                                    hintText: 'اختياري',
                                    helperText: 'رقم الباركود للمنتج',
                                    prefixIcon: Icon(Icons.qr_code),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // توليد باركود عشوائي
                                  final random = DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString();
                                  barcodeCtrl.text =
                                      random.substring(random.length - 8);
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('توليد'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // قسم الأسعار والمخزون
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_money,
                                  color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'الأسعار والمخزون',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: priceCtrl,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'السعر',
                                    hintText: 'مطلوب',
                                    helperText: 'سعر البيع للعميل',
                                    prefixIcon: Icon(Icons.sell),
                                    alignLabelWithHint: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]')),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'السعر مطلوب';
                                    }
                                    final price = double.tryParse(v.trim());
                                    if (price == null || price < 0) {
                                      return 'يرجى إدخال سعر صحيح';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextFormField(
                                  controller: costCtrl,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'الكلفة',
                                    hintText: 'اختياري',
                                    helperText: 'تكلفة الشراء',
                                    prefixIcon: Icon(Icons.shopping_cart),
                                    alignLabelWithHint: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]')),
                                  ],
                                  validator: (v) {
                                    if (v != null && v.trim().isNotEmpty) {
                                      final cost = double.tryParse(v.trim());
                                      if (cost == null || cost < 0) {
                                        return 'يرجى إدخال كلفة صحيحة';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: qtyCtrl,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          signed: false),
                                  decoration: const InputDecoration(
                                    labelText: 'الكمية',
                                    hintText: 'مطلوب',
                                    helperText: 'الكمية المتوفرة في المخزون',
                                    prefixIcon: Icon(Icons.inventory),
                                    alignLabelWithHint: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'الكمية مطلوبة';
                                    }
                                    final qty = int.tryParse(v.trim());
                                    if (qty == null || qty < 1) {
                                      return 'الكمية يجب أن تكون 1 أو أكثر';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 2,
                                child:
                                    FutureBuilder<List<Map<String, Object?>>>(
                                  future: db.getCategories(),
                                  builder: (context, snap) {
                                    final cats = snap.data ??
                                        const <Map<String, Object?>>[];
                                    final ids = cats
                                        .map<int>((c) => c['id'] as int)
                                        .toSet();
                                    final int? effectiveCategoryId =
                                        (categoryId != null &&
                                                ids.contains(categoryId))
                                            ? categoryId
                                            : null;
                                    return DropdownButtonFormField<int>(
                                      initialValue: effectiveCategoryId,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'اختر القسم',
                                        hintText: 'اختياري',
                                        helperText: 'اختر قسم المنتج',
                                        prefixIcon: Icon(Icons.category),
                                        alignLabelWithHint: true,
                                      ),
                                      items: [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text('بدون قسم'),
                                        ),
                                        ...cats.map((c) =>
                                            DropdownMenuItem<int>(
                                              value: c['id'] as int,
                                              child: Text(
                                                  c['name']?.toString() ?? ''),
                                            )),
                                      ],
                                      onChanged: (v) => categoryId = v,
                                    );
                                  },
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final values = <String, Object?>{
                  'name': nameCtrl.text.trim(),
                  'barcode': barcodeCtrl.text.trim().isEmpty
                      ? null
                      : barcodeCtrl.text.trim(),
                  'price': priceCtrl.text.trim().isEmpty
                      ? 0.0
                      : double.parse(priceCtrl.text.trim()),
                  'cost': costCtrl.text.trim().isEmpty
                      ? 0.0
                      : double.parse(costCtrl.text.trim()),
                  'quantity': (int.tryParse(qtyCtrl.text.trim()) ?? 1)
                      .clamp(1, double.infinity)
                      .toInt(),
                  'min_quantity': 1, // قيمة افتراضية
                  'category_id': categoryId,
                };
                try {
                  if (isEdit) {
                    await db.updateProduct(product['id'] as int, values);
                  } else {
                    // التحقق من وجود الباركود قبل الإدراج
                    if (values['barcode'] != null) {
                      final barcodeExists =
                          await db.isBarcodeExists(values['barcode'] as String);
                      if (barcodeExists) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'الباركود موجود بالفعل، يرجى استخدام باركود آخر'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return; // منع إغلاق الحوار
                      }
                    }
                    await db.insertProduct(values);
                  }
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'حفظ التعديل' : 'إضافة المنتج'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) setState(() {});
  }

  Future<void> _showBarcode(BuildContext context, String code) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('الباركود'),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
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
                      // Real Barcode with black bars
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
                      // Barcode number below
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
                      const SizedBox(height: 12),
                      Text(
                        'باركود المنتج',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
          if (code.isNotEmpty)
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ الباركود'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('نسخ'),
            ),
        ],
      ),
    );
  }
}
