import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../utils/invoice_pdf.dart';

class PrintService {
  static const String _defaultPageFormat = 'thermal_80';
  static const bool _defaultShowLogo = true;
  static const bool _defaultShowBarcode = true;

  // إعدادات الطباعة المحفوظة
  static String _savedPageFormat = _defaultPageFormat;
  static bool _savedShowLogo = _defaultShowLogo;
  static bool _savedShowBarcode = _defaultShowBarcode;

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

  // اختبار إنشاء PDF
  static Future<bool> testPdfGeneration({
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
    BuildContext? context,
  }) async {
    try {
      print('=== اختبار إنشاء PDF ===');
      print('عدد المنتجات: ${items.length}');

      if (items.isEmpty) {
        print('خطأ: لا توجد منتجات لإنشاء PDF');
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
      );

      print('تم إنشاء PDF بنجاح، حجم الملف: ${pdfData.length} بايت');
      return true;
    } catch (e) {
      print('خطأ في إنشاء PDF: $e');
      return false;
    }
  }

  // معاينة الفاتورة
  static Future<void> previewInvoice({
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
    required BuildContext context,
  }) async {
    try {
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
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'معاينة_فاتورة_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في المعاينة: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
