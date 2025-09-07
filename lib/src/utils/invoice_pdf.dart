import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'strings.dart';

class InvoicePdf {
  // دعم أنواع مختلفة من الطابعات والأوراق
  static final Map<String, PdfPageFormat> _pageFormats = {
    'thermal_58': const PdfPageFormat(
        58 * PdfPageFormat.mm, 200 * PdfPageFormat.mm), // طابعة حرارية 58mm
    'thermal_80': const PdfPageFormat(80 * PdfPageFormat.mm,
        200 * PdfPageFormat.mm), // طابعة حرارية 80mm (مخصص)
    'a4': PdfPageFormat.a4, // ورقة A4
    'a5': PdfPageFormat.a5, // ورقة A5
    'letter': PdfPageFormat.letter, // ورقة Letter
    'receipt': const PdfPageFormat(200, 300), // فاتورة صغيرة
    'invoice': const PdfPageFormat(210, 297), // فاتورة عادية
  };

  // تحميل الخط العربي
  static Future<pw.Font> _loadArabicFont() async {
    try {
      final fontData = await rootBundle
          .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      // إذا فشل تحميل الخط العربي، استخدم الخط الافتراضي
      print('خطأ في تحميل الخط العربي: $e');
      return pw.Font.helvetica();
    }
  }

  // دالة مساعدة لإنشاء نص مع الخط العربي
  static pw.TextStyle _getArabicTextStyle(pw.Font arabicFont, double fontSize,
      {pw.FontWeight? fontWeight, PdfColor? color}) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      font: arabicFont,
    );
  }

  // دالة مساعدة للتحقق من صحة القيم الرقمية
  static bool _isValidNumber(num value) {
    return !value.isNaN && !value.isInfinite;
  }

  // دالة مساعدة لتنظيف القيم الرقمية
  static double _cleanNumber(num value, {double defaultValue = 0.0}) {
    if (!_isValidNumber(value)) {
      print(
          'تحذير: قيمة غير صحيحة $value (isNaN: ${value.isNaN}, isInfinite: ${value.isInfinite})، استخدام القيمة الافتراضية $defaultValue');
      return defaultValue;
    }
    return value.toDouble();
  }

  static Future<Uint8List> generate({
    required String shopName,
    required String? phone,
    required String? address,
    required List<Map<String, Object?>> items,
    required String paymentType,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    DateTime? dueDate,
    String pageFormat = 'thermal_80', // افتراضي طابعة حرارية 80mm
    bool showLogo = true,
    bool showBarcode = true,
  }) async {
    print('=== بدء إنشاء PDF ===');
    print('عدد المنتجات: ${items.length}');

    // فحص البيانات قبل المعالجة (للتشخيص فقط)
    // يمكن إزالة هذا الجزء بعد التأكد من استقرار النظام

    final doc = pw.Document();
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final invoiceNumber = _generateInvoiceNumber();

    // تحميل الخط العربي
    final arabicFont = await _loadArabicFont();

    double total = 0;
    for (final it in items) {
      final price = _cleanNumber(it['price'] as num, defaultValue: 0.0);
      final quantity = _cleanNumber(it['quantity'] as num, defaultValue: 0.0);

      total += price * quantity;
    }

    // تحديد نوع الورق
    final format = _pageFormats[pageFormat] ?? PdfPageFormat.roll80;
    print('نوع الورق المحدد: $pageFormat');
    print('أبعاد الورق: عرض=${format.width}, ارتفاع=${format.height}');

    // إضافة الصفحات مع دعم التقسيم
    _addPagesWithPagination(
        doc,
        items,
        shopName,
        phone,
        address,
        invoiceNumber,
        date,
        paymentType,
        dueDate,
        customerName,
        customerPhone,
        customerAddress,
        total,
        format,
        arabicFont);

    return doc.save();
  }

  // إضافة الصفحات مع دعم التقسيم
  static void _addPagesWithPagination(
      pw.Document doc,
      List<Map<String, Object?>> items,
      String shopName,
      String? phone,
      String? address,
      String invoiceNumber,
      String date,
      String paymentType,
      DateTime? dueDate,
      String? customerName,
      String? customerPhone,
      String? customerAddress,
      double total,
      PdfPageFormat format,
      pw.Font arabicFont) {
    // حساب عدد المنتجات التي يمكن عرضها في الصفحة الواحدة
    final maxItemsPerPage = _calculateMaxItemsPerPage(format);
    print('الحد الأقصى للمنتجات في الصفحة: $maxItemsPerPage');

    // فحص أن maxItemsPerPage صحيح
    if (maxItemsPerPage <= 0) {
      print('تحذير: عدد المنتجات غير صحيح، استخدام قيمة افتراضية');
      final safeMaxItems = 10;
      // تقسيم المنتجات على الصفحات بقيمة آمنة
      final pages = <List<Map<String, Object?>>>[];
      for (int i = 0; i < items.length; i += safeMaxItems) {
        final end =
            (i + safeMaxItems < items.length) ? i + safeMaxItems : items.length;
        pages.add(items.sublist(i, end));
      }
      // معالجة الصفحات بقيمة آمنة
      for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
        final isFirstPage = pageIndex == 0;
        final isLastPage = pageIndex == pages.length - 1;
        final pageItems = pages[pageIndex];

        doc.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(8),
            build: (context) {
              return pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Center(
                  child: pw.Container(
                    width: format.width * 0.8,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Header Section
                        if (isFirstPage) ...[
                          _buildHeader(shopName, phone, address, invoiceNumber,
                              date, format, arabicFont),
                          pw.SizedBox(height: 8),
                        ] else ...[
                          _buildPageHeader(invoiceNumber, pageIndex + 1,
                              pages.length, format, arabicFont),
                          pw.SizedBox(height: 8),
                        ],

                        // Customer Info & Payment Type
                        if (isFirstPage) ...[
                          _buildCustomerAndPaymentInfo(
                              customerName,
                              customerPhone,
                              customerAddress,
                              paymentType,
                              dueDate,
                              arabicFont),
                          pw.SizedBox(height: 8),
                        ],

                        // Items Table
                        _buildItemsTable(pageItems, format, arabicFont),

                        // Footer
                        if (isLastPage) ...[
                          pw.SizedBox(height: 8),
                          _buildFooter(format, arabicFont),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
      return;
    }

    // تقسيم المنتجات على الصفحات
    final pages = <List<Map<String, Object?>>>[];
    for (int i = 0; i < items.length; i += maxItemsPerPage) {
      final end = (i + maxItemsPerPage < items.length)
          ? i + maxItemsPerPage
          : items.length;
      pages.add(items.sublist(i, end));
    }

    // إضافة كل صفحة
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final isFirstPage = pageIndex == 0;
      final isLastPage = pageIndex == pages.length - 1;
      final pageItems = pages[pageIndex];

      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(8),
          build: (context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                child: pw.Container(
                  width: format.width * 0.8,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Header Section - رأس الفاتورة (في الصفحة الأولى فقط)
                      if (isFirstPage) ...[
                        _buildHeader(shopName, phone, address, invoiceNumber,
                            date, format, arabicFont),
                        pw.SizedBox(height: 8),
                      ] else ...[
                        // رأس مبسط للصفحات الإضافية
                        _buildPageHeader(invoiceNumber, pageIndex + 1,
                            pages.length, format, arabicFont),
                        pw.SizedBox(height: 8),
                      ],

                      // Customer Info & Payment Type - معلومات العميل ونوع الدفع (في الصفحة الأولى فقط)
                      if (isFirstPage) ...[
                        _buildCustomerAndPaymentInfo(
                            customerName,
                            customerPhone,
                            customerAddress,
                            paymentType,
                            dueDate,
                            arabicFont),
                        pw.SizedBox(height: 8),
                      ],

                      // Items Table - جدول المنتجات
                      _buildItemsTable(pageItems, format, arabicFont),

                      pw.SizedBox(height: 8),

                      // Total Section - قسم المجموع (في الصفحة الأخيرة فقط)
                      if (isLastPage) ...[
                        _buildTotalSection(total, arabicFont),
                        pw.SizedBox(height: 12),
                      ],

                      // Footer - تذييل الفاتورة
                      _buildFooter(format, arabicFont),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  // بناء رأس مبسط للصفحات الإضافية
  static pw.Widget _buildPageHeader(String invoiceNumber, int currentPage,
      int totalPages, PdfPageFormat format, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'فاتورة رقم: $invoiceNumber',
            style: _getArabicTextStyle(arabicFont, _getFontSize(format, 14),
                fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'صفحة $currentPage من $totalPages',
            style: _getArabicTextStyle(arabicFont, _getFontSize(format, 10)),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // بناء رأس الفاتورة
  static pw.Widget _buildHeader(
      String shopName,
      String? phone,
      String? address,
      String invoiceNumber,
      String date,
      PdfPageFormat format,
      pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // اسم المحل
          pw.Text(
            shopName,
            style: _getArabicTextStyle(arabicFont, _getFontSize(format, 18),
                fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),

          // خط فاصل
          pw.Container(
            height: 1,
            color: PdfColors.black,
            margin: const pw.EdgeInsets.symmetric(horizontal: 20),
          ),

          pw.SizedBox(height: 4),

          // معلومات المحل
          if (address != null && address.isNotEmpty)
            pw.Text(
              address,
              style: _getArabicTextStyle(arabicFont, _getFontSize(format, 10)),
              textAlign: pw.TextAlign.center,
            ),

          if (phone != null && phone.isNotEmpty)
            pw.Text(
              '${AppStrings.phonePrefix} $phone',
              style: _getArabicTextStyle(arabicFont, _getFontSize(format, 10)),
              textAlign: pw.TextAlign.center,
            ),

          pw.SizedBox(height: 4),

          // رقم الفاتورة والتاريخ
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'رقم الفاتورة: $invoiceNumber',
                style: _getArabicTextStyle(arabicFont, _getFontSize(format, 9),
                    fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'التاريخ: $date',
                style: _getArabicTextStyle(arabicFont, _getFontSize(format, 9)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء معلومات العميل ونوع الدفع في صف واحد
  static pw.Widget _buildCustomerAndPaymentInfo(
      String? customerName,
      String? customerPhone,
      String? customerAddress,
      String paymentType,
      DateTime? dueDate,
      pw.Font arabicFont) {
    // تحديد نوع الدفع
    String paymentText = '';
    PdfColor paymentColor = PdfColors.black;
    switch (paymentType) {
      case 'cash':
        paymentText = 'نقداً';
        paymentColor = PdfColors.green;
        break;
      case 'credit':
        paymentText = 'آجل';
        paymentColor = PdfColors.orange;
        break;
      case 'installment':
        paymentText = 'تقسيط';
        paymentColor = PdfColors.blue;
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // معلومات العميل
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'معلومات العميل',
                  style: _getArabicTextStyle(arabicFont, 10,
                      fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                if (customerName != null && customerName.isNotEmpty)
                  pw.Text('الاسم : $customerName',
                      style: _getArabicTextStyle(arabicFont, 9)),
                if (customerPhone != null && customerPhone.isNotEmpty)
                  pw.Text('الهاتف : $customerPhone',
                      style: _getArabicTextStyle(arabicFont, 9)),
                if (customerAddress != null && customerAddress.isNotEmpty)
                  pw.Text('العنوان : $customerAddress',
                      style: _getArabicTextStyle(arabicFont, 9)),
              ],
            ),
          ),

          pw.SizedBox(width: 8),

          // نوع الدفع
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: paymentColor, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'نوع الدفع',
                    style: _getArabicTextStyle(arabicFont, 9,
                        fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    paymentText,
                    style: _getArabicTextStyle(arabicFont, 10,
                        fontWeight: pw.FontWeight.bold, color: paymentColor),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (dueDate != null && paymentType != 'cash') ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'تاريخ الاستحقاق:',
                      style: _getArabicTextStyle(arabicFont, 8),
                    ),
                    pw.Text(
                      DateFormat('yyyy-MM-dd').format(dueDate),
                      style: _getArabicTextStyle(arabicFont, 8,
                          color: paymentColor),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // حساب الحد الأقصى لعدد المنتجات في الصفحة الواحدة
  static int _calculateMaxItemsPerPage(PdfPageFormat format) {
    print(
        'حساب عدد المنتجات - عرض الصفحة: ${format.width}, ارتفاع الصفحة: ${format.height}');

    // حساب المساحة المتاحة للجدول
    final availableHeight = format.height - 200; // طرح مساحة الرأس والذيل
    final itemHeight = 30; // ارتفاع كل منتج

    print('الارتفاع المتاح: $availableHeight, ارتفاع المنتج: $itemHeight');

    // فحص القيم للتأكد من صحتها
    if (availableHeight.isNaN ||
        availableHeight.isInfinite ||
        itemHeight.isNaN ||
        itemHeight.isInfinite ||
        itemHeight <= 0) {
      print('تحذير: قيم غير صحيحة في حساب عدد المنتجات، استخدام قيمة افتراضية');
      return 10; // قيمة افتراضية آمنة
    }

    final result = (availableHeight / itemHeight).floor();
    print('عدد المنتجات المحسوب: $result');

    // التأكد من أن النتيجة صحيحة
    if (result.isNaN || result.isInfinite || result < 0) {
      print('تحذير: نتيجة غير صحيحة، استخدام قيمة افتراضية');
      return 10;
    }

    return result;
  }

  // بناء جدول المنتجات العادي
  static pw.Widget _buildItemsTable(List<Map<String, Object?>> items,
      PdfPageFormat format, pw.Font arabicFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(width: 0.3),
        columnWidths: {
          0: pw.FlexColumnWidth(2), // المجموع (أول عمود من اليمين)
          1: pw.FlexColumnWidth(1.5), // السعر
          2: pw.FlexColumnWidth(1), // الكمية
          3: pw.FlexColumnWidth(3), // اسم المنتج (آخر عمود من اليمين)
        },
        children: [
          // Header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              // المجموع (أول عمود من اليمين)
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  AppStrings.total,
                  style: _getArabicTextStyle(
                      arabicFont, _getFontSize(format, 9),
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // السعر
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  'السعر',
                  style: _getArabicTextStyle(
                      arabicFont, _getFontSize(format, 9),
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // الكمية
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  AppStrings.quantity,
                  style: _getArabicTextStyle(
                      arabicFont, _getFontSize(format, 9),
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // اسم المنتج (آخر عمود من اليمين)
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  AppStrings.product,
                  style: _getArabicTextStyle(
                      arabicFont, _getFontSize(format, 9),
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),

          // Items
          ...items.map((e) {
            final name = e['name']?.toString() ?? '';
            final quantity =
                _cleanNumber(e['quantity'] as num, defaultValue: 0.0);
            final price = _cleanNumber(e['price'] as num, defaultValue: 0.0);

            final qty = quantity.isFinite ? quantity.toInt() : 0;
            final lineTotal = price * qty;

            return pw.TableRow(
              children: [
                // المجموع (أول عمود من اليمين)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    NumberFormat.currency(
                      locale: 'ar_IQ',
                      symbol: AppStrings.currency,
                      decimalDigits: 0,
                    ).format(lineTotal),
                    style: _getArabicTextStyle(
                        arabicFont, _getFontSize(format, 8),
                        fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // السعر
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    NumberFormat.currency(
                      locale: 'ar_IQ',
                      symbol: AppStrings.currency,
                      decimalDigits: 0,
                    ).format(price),
                    style: _getArabicTextStyle(
                        arabicFont, _getFontSize(format, 8)),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // الكمية
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    qty.toString(),
                    style: _getArabicTextStyle(
                        arabicFont, _getFontSize(format, 8)),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // اسم المنتج (آخر عمود من اليمين)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    name,
                    style: _getArabicTextStyle(
                        arabicFont, _getFontSize(format, 8)),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // بناء قسم المجموع
  static pw.Widget _buildTotalSection(double total, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'المجموع الكلي:',
            style: _getArabicTextStyle(arabicFont, 12,
                fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            NumberFormat.currency(
              locale: 'ar_IQ',
              symbol: AppStrings.currency,
              decimalDigits: 0,
            ).format(total),
            style: _getArabicTextStyle(arabicFont, 14,
                fontWeight: pw.FontWeight.bold, color: PdfColors.red),
          ),
        ],
      ),
    );
  }

  // بناء تذييل الفاتورة
  static pw.Widget _buildFooter(PdfPageFormat format, pw.Font arabicFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // خط فاصل
        pw.Container(
          height: 1,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20),
        ),

        pw.SizedBox(height: 8),

        // رسالة شكر
        pw.Text(
          AppStrings.thankYou,
          style: _getArabicTextStyle(arabicFont, _getFontSize(format, 10),
              fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 4),

        // معلومات إضافية
        pw.Text(
          'نشكركم لاختياركم خدماتنا',
          style: _getArabicTextStyle(arabicFont, _getFontSize(format, 8)),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 4),

        // رقم الفاتورة في التذييل
        pw.Text(
          'رقم الفاتورة: ${_generateInvoiceNumber()}',
          style: _getArabicTextStyle(arabicFont, _getFontSize(format, 7),
              color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // تحديد حجم الخط حسب نوع الورق
  static double _getFontSize(PdfPageFormat format, double baseSize) {
    if (format.width <= 60 * PdfPageFormat.mm) {
      return baseSize * 0.8; // خط أصغر للطابعة الحرارية الصغيرة
    } else if (format.width <= 85 * PdfPageFormat.mm) {
      return baseSize; // حجم عادي للطابعة الحرارية 80mm
    } else {
      return baseSize * 1.2; // خط أكبر للأوراق العادية
    }
  }

  // توليد رقم فاتورة فريد
  static String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  // الحصول على أنواع الأوراق المتاحة
  static List<String> getAvailablePageFormats() {
    return _pageFormats.keys.toList();
  }

  // الحصول على معلومات نوع الورق
  static Map<String, dynamic> getPageFormatInfo(String formatName) {
    final format = _pageFormats[formatName];
    if (format == null) return {};

    return {
      'name': formatName,
      'width': format.width,
      'height': format.height,
      'description': _getFormatDescription(formatName),
    };
  }

  // وصف أنواع الأوراق
  static String _getFormatDescription(String formatName) {
    switch (formatName) {
      case 'thermal_58':
        return 'طابعة حرارية 58mm - مناسبة للفواتير الصغيرة';
      case 'thermal_80':
        return 'طابعة حرارية 80mm - مناسبة للفواتير العادية';
      case 'a4':
        return 'ورقة A4 - مناسبة للفواتير التفصيلية';
      case 'a5':
        return 'ورقة A5 - مناسبة للفواتير المتوسطة';
      case 'letter':
        return 'ورقة Letter - مناسبة للفواتير الأمريكية';
      case 'receipt':
        return 'فاتورة صغيرة - مناسبة للفواتير السريعة';
      case 'invoice':
        return 'فاتورة عادية - مناسبة للفواتير الرسمية';
      default:
        return 'نوع غير معروف';
    }
  }
}
