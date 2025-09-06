import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'strings.dart';

class InvoicePdf {
  static Future<Uint8List> generate({
    required String shopName,
    required String? phone,
    required String? address,
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
                if (address != null && address.isNotEmpty)
                  pw.Text(address, textAlign: pw.TextAlign.center),
                if (phone != null && phone.isNotEmpty)
                  pw.Text('${AppStrings.phonePrefix} $phone',
                      textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${AppStrings.date}: $date'),
                    pw.Text(
                        '${AppStrings.payment}: ${paymentType == 'cash' ? AppStrings.cash : AppStrings.credit}')
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
                          child: pw.Text(AppStrings.product)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(AppStrings.quantity)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(AppStrings.total)),
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
                                    symbol: AppStrings.currency,
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
                    pw.Text(AppStrings.total,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        NumberFormat.currency(
                                locale: 'ar_IQ',
                                symbol: AppStrings.currency,
                                decimalDigits: 0)
                            .format(total),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text(AppStrings.thankYou, textAlign: pw.TextAlign.center),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }
}
