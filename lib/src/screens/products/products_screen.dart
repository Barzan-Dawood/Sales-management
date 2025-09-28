// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../utils/dark_mode_utils.dart';
import '../../utils/app_themes.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../services/db/database_service.dart';
import '../../services/auth/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/format.dart';
import '../../utils/export.dart';
import 'package:intl/intl.dart';

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
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd_HH-mm');

  @override
  void dispose() {
    _tableHController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final auth = context.watch<AuthProvider>();

    // فحص صلاحية إدارة المنتجات
    if (!auth.hasPermission(UserPermission.manageProducts)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المنتجات'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'ليس لديك صلاحية للوصول إلى هذه الصفحة',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'هذه الصفحة متاحة للمديرين والمشرفين فقط',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header with adaptive colors
              Container(
                margin: const EdgeInsets.fromLTRB(100, 2, 100, 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: () {
                    final gradients =
                        Theme.of(context).extension<AppGradients>();
                    if (gradients != null) {
                      return LinearGradient(
                        colors: [
                          gradients.sidebarStart,
                          gradients.sidebarMiddle,
                          gradients.sidebarEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      );
                    }
                    return LinearGradient(
                      colors: DarkModeUtils.getPrimaryGradientColors(context),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );
                  }(),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: DarkModeUtils.getShadowColor(context),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.none,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title centered, small export button at the top-right corner
                    SizedBox(
                      height: 56,
                      child: Stack(
                        children: [
                          // Centered title with icon
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'إدارة المنتجات',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.35),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Clear, labeled export button in the top-left corner
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              color: Colors.transparent,
                              child: Tooltip(
                                message: 'تصدير Excel (CSV)',
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.25),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await _exportProductsCsv(context);
                                  },
                                  icon: const Icon(Icons.grid_on_rounded,
                                      size: 16),
                                  label: const Text('تصدير Excel'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _searchController,
                            textAlign: TextAlign.right,
                            textDirection: ui.TextDirection.rtl,
                            decoration: InputDecoration(
                              hintText: 'بحث بالاسم أو الباركود',
                              hintStyle: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
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
                                          color: Colors.white.withOpacity(0.2),
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
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
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
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
                                iconEnabledColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                dropdownColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).colorScheme.surface
                                    : Colors.white,
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'القسم',
                                  hintStyle: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
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
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
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
                                          child:
                                              Text(c['name']?.toString() ?? ''),
                                        ),
                                      )),
                                ],
                                onChanged: (val) =>
                                    setState(() => _selectedCategoryId = val),
                              );
                            },
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

                      // فحص إذا كانت القائمة فارغة
                      if (products.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(40),
                                decoration:
                                    DarkModeUtils.createCardDecoration(context),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 80,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'لا توجد منتجات',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'لم يتم العثور على أي منتجات في النظام',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () => _openEditor(context,
                                          product: const {}),
                                      icon: const Icon(Icons.add),
                                      label: const Text('إضافة منتج جديد'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
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

                      return Column(
                        children: [
                          // Table body - منفصل عن الرأس
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(90, 0, 90, 20),
                              decoration: BoxDecoration(
                                color: DarkModeUtils.getSurfaceColor(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: DarkModeUtils.getBorderColor(context),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        DarkModeUtils.getShadowColor(context),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? 0.12
                                                : 0.15,
                                          ),
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
                                            color: DarkModeUtils.getBorderColor(
                                                context),
                                            width: 1,
                                          ),
                                        ),
                                        children: [
                                          TableRow(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(
                                                    Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? 0.12
                                                        : 0.15,
                                                  ),
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
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
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
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
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
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
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
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
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
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
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
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
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
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
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
                                              color:
                                                  DarkModeUtils.getBorderColor(
                                                      context),
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
                                                      ? DarkModeUtils
                                                          .getSurfaceColor(
                                                              context)
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .surface
                                                          .withOpacity(
                                                            Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? 0.9
                                                                : 0.98,
                                                          ),
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
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface,
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
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface,
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
                                                      child: Builder(
                                                        builder: (context) {
                                                          final String
                                                              fullBarcode =
                                                              products[i]['barcode']
                                                                      ?.toString() ??
                                                                  '—';
                                                          final String
                                                              shortBarcode =
                                                              _abbreviateMiddle(
                                                                  fullBarcode,
                                                                  head: 6,
                                                                  tail: 4,
                                                                  minLength:
                                                                      14);
                                                          return Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Flexible(
                                                                child: Tooltip(
                                                                  message:
                                                                      fullBarcode,
                                                                  child: Text(
                                                                    shortBarcode,
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'monospace',
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          14,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .primary,
                                                                      letterSpacing:
                                                                          0.5,
                                                                    ),
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 6),
                                                              InkWell(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6),
                                                                onTap:
                                                                    () async {
                                                                  if (fullBarcode !=
                                                                      '—') {
                                                                    await Clipboard.setData(
                                                                        ClipboardData(
                                                                            text:
                                                                                fullBarcode));
                                                                    if (!mounted)
                                                                      return;
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      const SnackBar(
                                                                        content:
                                                                            Text('تم نسخ الباركود'),
                                                                        behavior:
                                                                            SnackBarBehavior.floating,
                                                                        duration:
                                                                            Duration(seconds: 2),
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                                child: Icon(
                                                                  Icons.copy,
                                                                  size: 16,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withOpacity(
                                                                          0.8),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
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
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .tertiary,
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
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary,
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
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
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
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'إضافة منتج',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF1976D2), // Professional Blue
          foregroundColor: Colors.white,
          elevation: 8,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  Future<void> _exportProductsCsv(BuildContext context) async {
    final db = context.read<DatabaseService>();
    final products = await db.getAllProducts(
      query: _query,
      categoryId: _selectedCategoryId ?? widget.initialCategoryId,
    );

    final headers = ['#', 'الاسم', 'الباركود', 'الكمية', 'الكلفة', 'السعر'];
    final rows = <List<String>>[
      headers,
      ...List<List<String>>.generate(products.length, (i) {
        final p = products[i];
        return [
          '${i + 1}',
          p['name']?.toString() ?? '',
          p['barcode']?.toString() ?? '',
          (p['quantity'] as num?)?.toString() ?? '0',
          ((p['cost'] as num?) ?? 0).toString(),
          ((p['price'] as num?) ?? 0).toString(),
        ];
      })
    ];

    final filename = 'products_${_dateFormat.format(DateTime.now())}.csv';
    final savedPath = await CsvExporter.exportRows(filename, rows);
    if (savedPath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ الملف: $savedPath'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

  String _abbreviateMiddle(
    String input, {
    int head = 6,
    int tail = 4,
    int minLength = 14,
  }) {
    if (input.isEmpty || input == '—') return input;
    if (head < 0) head = 0;
    if (tail < 0) tail = 0;
    final int totalKeep = head + tail;
    if (input.length <= minLength || input.length <= totalKeep + 1) {
      return input;
    }
    final String start = input.substring(0, head);
    final String end = input.substring(input.length - tail);
    return '$start…$end';
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
            backgroundColor: Color(0xFFDC2626), // Professional Red
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
        textDirection: ui.TextDirection.rtl,
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3)
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.blue.shade700,
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'المعلومات الأساسية',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.blue.shade800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nameCtrl,
                            textAlign: TextAlign.right,
                            textDirection: ui.TextDirection.rtl,
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
                                  textDirection: ui.TextDirection.rtl,
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.1)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.3)
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_money,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.green.shade700,
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'الأسعار والمخزون',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.green.shade800,
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
                                  textDirection: ui.TextDirection.rtl,
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
                                  textDirection: ui.TextDirection.rtl,
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
                                  textDirection: ui.TextDirection.rtl,
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
                    // عرض رسالة نجاح التعديل
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('تم حفظ التعديل بنجاح'),
                            ],
                          ),
                          backgroundColor:
                              Color(0xFF059669), // Professional Green
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
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
                              backgroundColor:
                                  Color(0xFFDC2626), // Professional Red
                            ),
                          );
                        }
                        return; // منع إغلاق الحوار
                      }
                    }
                    await db.insertProduct(values);
                    // عرض رسالة نجاح الإضافة
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('تم إضافة المنتج بنجاح'),
                            ],
                          ),
                          backgroundColor:
                              Color(0xFF059669), // Professional Green
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: ${e.toString()}'),
                        backgroundColor: Color(0xFFDC2626), // Professional Red
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.outline
                  : Colors.blue.shade200,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (code.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surface
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.outline
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
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
                        backgroundColor:
                            Color(0xFFFFFFFF), // Professional White
                        drawText: false,
                      ),
                      const SizedBox(height: 16),
                      // Barcode number below
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.outline
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          code,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.grey.shade800,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'باركود المنتج',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7)
                              : Colors.grey.shade600,
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      : Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'لا يوجد باركود لهذا المنتج',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7)
                        : Colors.grey.shade600,
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
