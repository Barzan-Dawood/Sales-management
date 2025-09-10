import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/invoice_pdf.dart';

class PrintService {
  static const String _defaultPageFormat = '80';
  static const bool _defaultShowLogo = true;
  static const bool _defaultShowBarcode = true;

  // إعدادات الطباعة المحفوظة
  static String _savedPageFormat = _defaultPageFormat;
  static bool _savedShowLogo = _defaultShowLogo;
  static bool _savedShowBarcode = _defaultShowBarcode;

  // طباعة كشف حساب العميل
  static Future<bool> printCustomerStatement({
    required String shopName,
    required String? phone,
    required String? address,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> payments,
    required Map<String, dynamic> debtData,
    String? pageFormat,
    BuildContext? context,
  }) async {
    try {
      print('=== بدء طباعة كشف الحساب ===');
      print('اسم العميل: ${customer['name']}');
      print('عدد المدفوعات: ${payments.length}');

      // إنشاء PDF لكشف الحساب
      final pdfBytes = await _generateStatementPDF(
        shopName: shopName,
        phone: phone,
        address: address,
        customer: customer,
        payments: payments,
        debtData: debtData,
        pageFormat: pageFormat ?? _savedPageFormat,
      );

      // طباعة PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name:
            'كشف_حساب_${customer['name']}_${DateTime.now().millisecondsSinceEpoch}',
      );

      print('تم طباعة كشف الحساب بنجاح');
      return true;
    } catch (e) {
      print('خطأ في طباعة كشف الحساب: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في طباعة كشف الحساب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // إنشاء PDF لكشف الحساب
  static Future<Uint8List> _generateStatementPDF({
    required String shopName,
    required String? phone,
    required String? address,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> payments,
    required Map<String, dynamic> debtData,
    required String pageFormat,
  }) async {
    final doc = pw.Document();
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // تحميل الخط العربي
    final arabicFont = await _loadArabicFont();

    // تحديد نوع الورق
    final format = _getPageFormat(pageFormat);

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // رأس كشف الحساب
                _buildStatementHeader(
                    shopName, phone, address, customer, date, arabicFont),
                pw.SizedBox(height: 20),

                // ملخص الحساب
                _buildAccountSummary(debtData, arabicFont),
                pw.SizedBox(height: 20),

                // تفاصيل المدفوعات
                _buildPaymentsTable(payments, arabicFont),
                pw.SizedBox(height: 20),

                // تذييل
                _buildStatementFooter(arabicFont),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  // بناء رأس كشف الحساب
  static pw.Widget _buildStatementHeader(
    String shopName,
    String? phone,
    String? address,
    Map<String, dynamic> customer,
    String date,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'كشف حساب العميل',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            shopName,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (phone != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'الهاتف: $phone',
              style: pw.TextStyle(fontSize: 10, font: arabicFont),
              textAlign: pw.TextAlign.center,
            ),
          ],
          if (address != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'العنوان: $address',
              style: pw.TextStyle(fontSize: 10, font: arabicFont),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'العميل: ${customer['name']}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (customer['phone'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'هاتف العميل: ${customer['phone']}',
              style: pw.TextStyle(fontSize: 10, font: arabicFont),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Text(
            'تاريخ الكشف: $date',
            style: pw.TextStyle(fontSize: 10, font: arabicFont),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // بناء ملخص الحساب
  static pw.Widget _buildAccountSummary(
    Map<String, dynamic> debtData,
    pw.Font arabicFont,
  ) {
    final totalDebt = debtData['totalDebt'] ?? 0.0;
    final totalPaid = debtData['totalPaid'] ?? 0.0;
    final remainingDebt = debtData['remainingDebt'] ?? 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص الحساب',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي الدين:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                '${totalDebt.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي المدفوع:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                '${totalPaid.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المتبقي:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
              ),
              pw.Text(
                '${remainingDebt.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: remainingDebt > 0 ? PdfColors.red : PdfColors.green,
                  font: arabicFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء جدول المدفوعات
  static pw.Widget _buildPaymentsTable(
    List<Map<String, dynamic>> payments,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'تفاصيل المدفوعات',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            font: arabicFont,
          ),
        ),
        pw.SizedBox(height: 8),
        if (payments.isEmpty)
          pw.Text(
            'لا توجد مدفوعات',
            style: pw.TextStyle(fontSize: 10, font: arabicFont),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(width: 1),
            columnWidths: {
              0: const pw.FixedColumnWidth(80),
              1: const pw.FixedColumnWidth(100),
              2: const pw.FixedColumnWidth(60),
            },
            children: [
              // رأس الجدول
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'التاريخ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'المبلغ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'الطريقة',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
              // صفوف المدفوعات
              ...payments.map((payment) {
                final date = DateTime.parse(payment['payment_date']);
                final amount = payment['amount'] ?? 0.0;
                final method = payment['payment_method'] ?? 'نقد';

                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${amount.toStringAsFixed(0)} د.ع',
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        method,
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  // بناء تذييل كشف الحساب
  static pw.Widget _buildStatementFooter(pw.Font arabicFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'شكراً لاختياركم خدماتنا',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            font: arabicFont,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'هذا الكشف صادر من نظام إدارة المكتب',
          style: pw.TextStyle(fontSize: 8, font: arabicFont),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // تحميل الخط العربي
  static Future<pw.Font> _loadArabicFont() async {
    try {
      final fontData = await rootBundle
          .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      print('خطأ في تحميل الخط العربي: $e');
      return pw.Font.helvetica();
    }
  }

  // الحصول على نوع الورق
  static PdfPageFormat _getPageFormat(String formatName) {
    switch (formatName) {
      case '58':
        return const PdfPageFormat(
            58 * PdfPageFormat.mm, 250 * PdfPageFormat.mm);
      case '80':
        return const PdfPageFormat(
            80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm);
      case 'A4':
        return PdfPageFormat.a4;
      case 'A5':
        return PdfPageFormat.a5;
      default:
        return PdfPageFormat.a4;
    }
  }

  // طباعة فاتورة مع خيارات متقدمة
  static Future<bool> printInvoice({
    required String shopName,
    required String? phone,
    required String? address,
    required List<Map<String, Object?>> items,
    required String paymentType,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    DateTime? dueDate,
    String? pageFormat,
    bool? showLogo,
    bool? showBarcode,
    String? invoiceNumber, // رقم الفاتورة من قاعدة البيانات
    List<Map<String, Object?>>? installments, // معلومات الأقساط
    double? totalDebt, // إجمالي الدين
    double? downPayment, // المبلغ المقدم
    BuildContext? context,
  }) async {
    try {
      // إضافة رسائل تشخيص
      print('=== بدء عملية الطباعة ===');
      print('عدد المنتجات: ${items.length}');
      print('نوع الدفع: $paymentType');
      print('اسم المحل: $shopName');
      print('نوع الورق: $pageFormat');

      // فحص أن هناك منتجات للطباعة
      if (items.isEmpty) {
        print('خطأ: لا توجد منتجات للطباعة');
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد منتجات للطباعة'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return false;
      }

      final pdfData = await InvoicePdf.generate(
        shopName: shopName,
        phone: phone,
        address: address,
        items: items,
        paymentType: paymentType,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        dueDate: dueDate,
        pageFormat: pageFormat ?? _savedPageFormat,
        showLogo: showLogo ?? _savedShowLogo,
        showBarcode: showBarcode ?? _savedShowBarcode,
        invoiceNumber: invoiceNumber,
        installments: installments,
        totalDebt: totalDebt,
        downPayment: downPayment,
      );

      print('تم إنشاء PDF بنجاح، حجم الملف: ${pdfData.length} بايت');

      try {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfData,
          name: 'فاتورة_${DateTime.now().millisecondsSinceEpoch}',
        );
        print('تم فتح نافذة الطباعة بنجاح');
      } catch (layoutError) {
        print('خطأ في فتح نافذة الطباعة: $layoutError');
        // محاولة بديلة - حفظ الملف وعرضه
        try {
          await Printing.sharePdf(
            bytes: pdfData,
            filename: 'فاتورة_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
          print('تم مشاركة ملف PDF بنجاح');
        } catch (shareError) {
          print('خطأ في مشاركة ملف PDF: $shareError');
          rethrow;
        }
      }

      return true;
    } catch (e) {
      print('خطأ في الطباعة: $e');
      print('تفاصيل الخطأ: ${e.toString()}');
      if (context != null) {
        String errorMessage = 'خطأ في الطباعة';

        // تحسين رسائل الخطأ
        if (e.toString().contains('No such file or directory')) {
          errorMessage = 'خطأ: ملف الخط العربي غير موجود';
        } else if (e.toString().contains('Permission denied')) {
          errorMessage = 'خطأ: لا توجد صلاحية للطباعة';
        } else if (e.toString().contains('Device not found')) {
          errorMessage = 'خطأ: الطابعة غير متصلة';
        } else if (e.toString().contains('Out of paper')) {
          errorMessage = 'خطأ: نفدت الورق من الطابعة';
        } else {
          errorMessage = 'خطأ في الطباعة: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }

  // عرض خيارات الطباعة
  static Future<Map<String, dynamic>?> showPrintOptionsDialog(
      BuildContext context) {
    String selectedFormat = _savedPageFormat;
    bool showLogo = _savedShowLogo;
    bool showBarcode = _savedShowBarcode;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.print, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('خيارات الطباعة'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 350,
              minWidth: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // اختيار نوع الورق
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نوع الورق والطابعة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFormat,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items:
                            InvoicePdf.getAvailablePageFormats().map((format) {
                          final info = InvoicePdf.getPageFormatInfo(format);
                          return DropdownMenuItem(
                            value: format,
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      info['description'] ?? format,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${info['width']?.toStringAsFixed(0)} x ${info['height']?.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedFormat = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // خيارات إضافية
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'خيارات إضافية:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('عرض الشعار'),
                        subtitle: const Text('إضافة شعار المحل للفاتورة'),
                        value: showLogo,
                        onChanged: (value) {
                          setState(() {
                            showLogo = value ?? true;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('عرض الباركود'),
                        subtitle: const Text('إضافة باركود للفاتورة'),
                        value: showBarcode,
                        onChanged: (value) {
                          setState(() {
                            showBarcode = value ?? true;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // معاينة سريعة
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيتم حفظ هذه الإعدادات للاستخدام في المستقبل',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // حفظ الإعدادات
                _savedPageFormat = selectedFormat;
                _savedShowLogo = showLogo;
                _savedShowBarcode = showBarcode;

                Navigator.of(context).pop({
                  'pageFormat': selectedFormat,
                  'showLogo': showLogo,
                  'showBarcode': showBarcode,
                });
              },
              icon: const Icon(Icons.print),
              label: const Text('طباعة'),
            ),
          ],
        ),
      ),
    );
  }

  // الحصول على الإعدادات المحفوظة
  static Map<String, dynamic> getSavedSettings() {
    return {
      'pageFormat': _savedPageFormat,
      'showLogo': _savedShowLogo,
      'showBarcode': _savedShowBarcode,
    };
  }

  // حفظ الإعدادات
  static void saveSettings({
    String? pageFormat,
    bool? showLogo,
    bool? showBarcode,
  }) {
    if (pageFormat != null) _savedPageFormat = pageFormat;
    if (showLogo != null) _savedShowLogo = showLogo;
    if (showBarcode != null) _savedShowBarcode = showBarcode;
  }

  // إعادة تعيين الإعدادات للافتراضية
  static void resetToDefaults() {
    _savedPageFormat = _defaultPageFormat;
    _savedShowLogo = _defaultShowLogo;
    _savedShowBarcode = _defaultShowBarcode;
  }

  // طباعة سريعة بالإعدادات المحفوظة
  static Future<bool> quickPrint({
    required String shopName,
    required String? phone,
    required String? address,
    required List<Map<String, Object?>> items,
    required String paymentType,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    DateTime? dueDate,
    String? invoiceNumber, // رقم الفاتورة من قاعدة البيانات
    BuildContext? context,
  }) async {
    print('=== بدء الطباعة السريعة ===');
    print('عدد المنتجات: ${items.length}');
    print('نوع الدفع: $paymentType');

    // فحص أن هناك منتجات للطباعة
    if (items.isEmpty) {
      print('خطأ: لا توجد منتجات للطباعة السريعة');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد منتجات للطباعة'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    return await printInvoice(
      shopName: shopName,
      phone: phone,
      address: address,
      items: items,
      paymentType: paymentType,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      dueDate: dueDate,
      pageFormat: _savedPageFormat,
      showLogo: _savedShowLogo,
      showBarcode: _savedShowBarcode,
      invoiceNumber: invoiceNumber,
      context: context,
    );
  }
}
