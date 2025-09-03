import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePdf {
  static Future<Uint8List> generate({
    required String shopName,
    required String? phone,
    required List<Map<String, Object?>> items,
    required String paymentType,
  }) async {
    final doc = pw.Document();
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    double total = 0;
    for (final it in items) {
      total +=
          (it['price'] as num).toDouble() * (it['quantity'] as num).toDouble();
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(shopName,
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center),
                if (phone != null && phone.isNotEmpty)
                  pw.Text('هاتف: $phone', textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('التاريخ: $date'),
                    pw.Text(
                        'الدفع: ${paymentType == 'cash' ? 'نقدي' : 'أقساط'}')
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('المنتج')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('الكمية')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('الإجمالي')),
                    ]),
                    ...items.map((e) {
                      final name = e['name']?.toString() ?? '';
                      final qty = (e['quantity'] as num).toInt();
                      final lineTotal = (e['price'] as num).toDouble() * qty;
                      return pw.TableRow(children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(name)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(qty.toString())),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(NumberFormat.currency(
                                    locale: 'ar_IQ',
                                    symbol: 'د.ع',
                                    decimalDigits: 0)
                                .format(lineTotal))),
                      ]);
                    })
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الإجمالي',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        NumberFormat.currency(
                                locale: 'ar_IQ',
                                symbol: 'د.ع',
                                decimalDigits: 0)
                            .format(total),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text('شكراً لتعاملكم معنا', textAlign: pw.TextAlign.center),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }
}
