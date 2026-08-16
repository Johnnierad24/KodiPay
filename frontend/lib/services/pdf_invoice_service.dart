import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfInvoiceService {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  Future<void> generateRentInvoice({
    required String tenantName,
    required String propertyName,
    required String unitNumber,
    required int rentAmount,
    required int paid,
    required int outstanding,
    required int dueDay,
    required String status,
  }) async {
    final now = DateTime.now();
    final period = '${_months[now.month - 1]} ${now.year}';
    final monthNum = now.month.toString().padLeft(2, '0');
    final unitTag = unitNumber.isEmpty ? 'UNIT' : unitNumber.replaceAll(' ', '');
    final invoiceNo = 'INV-$unitTag-${now.year}$monthNum';
    final dueLabel = '$dueDay${_ordinal(dueDay)} $period';

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('RENT INVOICE', 'Invoice No: $invoiceNo  •  Issued: ${_formatDate(now)}'),
        footer: (context) => _buildFooter(),
        build: (context) => [
          _buildBillTo(tenantName, propertyName, unitNumber, period, dueLabel, status),
          pw.SizedBox(height: 20),
          _buildAmountsTable(period, rentAmount, paid, outstanding),
          pw.SizedBox(height: 20),
          _buildBalanceBanner(outstanding, dueLabel),
        ],
      ),
    );

    final bytes = await pdf.save();
    _download(bytes, 'rent_invoice_${unitNumber.isEmpty ? 'unit' : unitNumber.replaceAll(' ', '_')}_${period.replaceAll(' ', '_')}.pdf');
  }

  Future<void> generatePaymentReceipt({
    required String tenantName,
    required String propertyName,
    required String unitNumber,
    required String paymentId,
    required int amount,
    required String methodLabel,
    required String transactionRef,
    required DateTime paymentDate,
  }) async {
    final receiptNo = 'RCP-${paymentId.padLeft(6, '0')}';

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('PAYMENT RECEIPT', 'Receipt No: $receiptNo'),
        footer: (context) => _buildFooter(),
        build: (context) => [
          _buildReceiptHero(amount),
          pw.SizedBox(height: 20),
          _buildReceiptDetails(tenantName, propertyName, unitNumber, _formatDate(paymentDate), methodLabel, transactionRef),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.green600),
            ),
            child: pw.Text('Payment received. Thank you for paying your rent on time!',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    _download(bytes, 'receipt_$receiptNo.pdf');
  }

  Future<void> generateRentStatement({
    required String tenantName,
    required String propertyName,
    required String unitNumber,
    required String period,
    required List<Map<String, String>> rows,
    required int totalPaid,
    required int outstanding,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('RENT STATEMENT', 'Period: $period'),
        footer: (context) => _buildFooter(),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Account Holder', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.SizedBox(height: 4),
                pw.Text(tenantName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('$propertyName • Unit $unitNumber', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('TRANSACTIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _cell('Date', bold: true),
                  _cell('Description', bold: true),
                  _cell('Method', bold: true),
                  _cell('Amount (KSh)', bold: true),
                  _cell('Status', bold: true),
                ],
              ),
              if (rows.isEmpty)
                pw.TableRow(children: [_cell('No transactions recorded for this period.'), _cell(''), _cell(''), _cell(''), _cell('')])
              else
                ...rows.map((r) => pw.TableRow(children: [
                      _cell(r['date'] ?? ''),
                      _cell(r['description'] ?? ''),
                      _cell(r['method'] ?? ''),
                      _cell(r['amount'] ?? ''),
                      _cell(r['status'] ?? ''),
                    ])),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total paid', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text('KSh ${_amount(totalPaid)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Balance outstanding', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text('KSh ${_amount(outstanding)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    _download(bytes, 'rent_statement_${period.replaceAll(' ', '_')}.pdf');
  }

  // ── PDF builders ────────────────────────────────────────
  pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('KodiPay', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                pw.Text('Pay Rent. Stay Worry-Free.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.green800),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated by KodiPay', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text('support@kodipay.co.ke', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBillTo(String tenant, String property, String unit, String period, String dueLabel, String status) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('BILLED TO', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
          pw.SizedBox(height: 6),
          pw.Text(tenant, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('$property • Unit $unit', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Billing period: $period', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Due date: $dueLabel', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('Status: ${status.toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildAmountsTable(String period, int rent, int paid, int outstanding) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('INVOICE SUMMARY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _cell('Item', bold: true),
                _cell('Details', bold: true),
                _cell('Amount (KSh)', bold: true),
              ],
            ),
            pw.TableRow(children: [_cell('Monthly Rent'), _cell(period), _cell(_amount(rent))]),
            pw.TableRow(children: [_cell('Amount Paid'), _cell('Payments received to date'), _cell(_amount(paid))]),
            pw.TableRow(children: [
              _cell('Balance Due', bold: true),
              _cell('Remaining to clear rent', bold: true),
              _cell(_amount(outstanding), bold: true, color: PdfColors.red),
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBalanceBanner(int outstanding, String dueLabel) {
    final cleared = outstanding <= 0;
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: cleared ? PdfColors.green100 : PdfColors.orange100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: cleared ? PdfColors.green600 : PdfColors.orange, width: 1),
      ),
      child: cleared
          ? pw.Text('RENT CLEARED — This invoice has been fully paid. Thank you!',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900))
          : pw.Text('BALANCE DUE: KSh ${_amount(outstanding)} — payable by $dueLabel',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
    );
  }

  pw.Widget _buildReceiptHero(int amount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: PdfColors.green800,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text('AMOUNT PAID', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green100)),
          pw.SizedBox(height: 6),
          pw.Text('KSh ${_amount(amount)}', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        ],
      ),
    );
  }

  pw.Widget _buildReceiptDetails(String tenant, String property, String unit, String date, String method, String txRef) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('RECEIPT DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            _kvRow('Received from', tenant),
            _kvRow('Property', '$property • Unit $unit'),
            _kvRow('Payment date', date),
            _kvRow('Payment method', method),
            _kvRow('Transaction ref', txRef.isEmpty ? '—' : txRef),
            _kvRow('Status', 'PAID'),
          ],
        ),
      ],
    );
  }

  pw.TableRow _kvRow(String k, String v) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(k, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(v, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ),
    ]);
  }

  pw.Widget _cell(String text, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────
  void _download(Uint8List bytes, String filename) {
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf'));
    final url = web.URL.createObjectURL(blob);
    web.HTMLAnchorElement()
      ..href = url
      ..setAttribute('download', filename)
      ..click();
    web.URL.revokeObjectURL(url);
  }

  String _amount(int value) {
    return value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}
