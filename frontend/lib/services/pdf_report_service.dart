import 'dart:html' as html;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/app_config.dart';

class PdfReportService {
  Future<void> generatePaymentReport({
    required String landlordName,
    required String landlordEmail,
    required String landlordPhone,
    required int propertyCount,
    required int totalExpected,
    required int totalCollected,
    required int totalPending,
    required String period,
    required List<Map<String, String>> payments,
    required List<Map<String, String>> propertyBreakdown,
    required List<Map<String, String>> arrears,
    List<Map<String, dynamic>>? barChartData,
    int? pieCollected,
    int? piePending,
  }) async {
    final pdf = pw.Document();
    final collectionRate = totalExpected > 0
        ? ((totalCollected / totalExpected) * 100).toStringAsFixed(1)
        : '0.0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(period),
        footer: (context) => _buildFooter(),
        build: (context) => [
          _buildLandlordInfo(landlordName, landlordEmail, landlordPhone, propertyCount),
          pw.SizedBox(height: 20),
          _buildSummary(totalExpected, totalCollected, totalPending, collectionRate),
          pw.SizedBox(height: 20),
          _buildCharts(barChartData, pieCollected, piePending),
          pw.SizedBox(height: 20),
          _buildPropertyBreakdown(propertyBreakdown),
          pw.SizedBox(height: 20),
          _buildPaymentTable(payments),
          pw.SizedBox(height: 20),
          _buildArrears(arrears),
        ],
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'payment_report_$period.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  pw.Widget _buildHeader(String period) {
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
                pw.Text('Pay Rent. Stay Worry-Free.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Payment Report', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Generated: ${_currentDate()}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text('Period: $period', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.green800),
      ],
    );
  }

  pw.Widget _buildLandlordInfo(String name, String email, String phone, int propertyCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Landlord Information', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Text('Name: $name', style: pw.TextStyle(fontSize: 10)),
          pw.Text('Email: $email', style: pw.TextStyle(fontSize: 10)),
          pw.Text('Phone: $phone', style: pw.TextStyle(fontSize: 10)),
          pw.Text('Properties: $propertyCount', style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(int expected, int collected, int pending, String rate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard('Total Expected', 'KSh ${_formatAmount(expected)}', PdfColors.blue),
              _summaryCard('Total Collected', 'KSh ${_formatAmount(collected)}', PdfColors.green),
              _summaryCard('Total Pending', 'KSh ${_formatAmount(pending)}', PdfColors.deepOrange),
              _summaryCard('Collection Rate', '$rate%', PdfColors.blue),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCharts(List<Map<String, dynamic>>? barData, int? pieCollected, int? piePending) {
    if (barData == null && (pieCollected == null || piePending == null)) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Charts', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 12),
          if (barData != null) ...[
            pw.Text('Collection per Property', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 8),
            _buildBarChart(barData),
          ],
          if (pieCollected != null && piePending != null) ...[
            pw.SizedBox(height: 16),
            pw.Text('Paid vs Pending', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 8),
            _buildPieChart(pieCollected, piePending),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildBarChart(List<Map<String, dynamic>> data) {
    final maxVal = data.fold<double>(0, (max, d) => (d['value'] as num).toDouble() > max ? (d['value'] as num).toDouble() : max);
    return pw.Column(
      children: data.map((item) {
        final label = item['label'] as String;
        final value = (item['value'] as num).toDouble();
        final ratio = maxVal > 0 ? value / maxVal : 0.0;
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            children: [
              pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontSize: 8))),
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    pw.Container(
                      height: 14,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                    ),
                    pw.Container(
                      height: 14,
                      width: ratio * 240,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text('KSh ${_formatAmount(value.round())}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildPieChart(int collected, int pending) {
    final total = collected + pending;
    final collectedRatio = total > 0 ? collected / total : 0.0;
    return pw.Column(
      children: [
        pw.Row(
          children: [
            _pieLegend('Collected', 'KSh ${_formatAmount(collected)}', PdfColors.green),
            pw.SizedBox(width: 24),
            _pieLegend('Pending', 'KSh ${_formatAmount(pending)}', PdfColors.deepOrange),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Stack(
          children: [
            pw.Container(
              height: 20,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
            ),
            pw.Container(
              height: 20,
              width: collectedRatio * 280,
              decoration: pw.BoxDecoration(
                color: PdfColors.green,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('${(collectedRatio * 100).toStringAsFixed(0)}% collected',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
      ],
    );
  }

  pw.Widget _pieLegend(String label, String value, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 6),
        pw.Text(label, style: pw.TextStyle(fontSize: 9)),
        pw.SizedBox(width: 8),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey200)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        ],
      ),
    );
  }

  pw.Widget _buildPropertyBreakdown(List<Map<String, String>> rows) {
    return _buildTableSection(
      title: 'Property Breakdown',
      columns: ['Property', 'Units', 'Collected', 'Pending'],
      rows: rows.map((r) => [r['name']!, r['units']!, r['collected']!, r['pending']!]).toList(),
    );
  }

  pw.Widget _buildPaymentTable(List<Map<String, String>> payments) {
    return _buildTableSection(
      title: 'Detailed Payment Table',
      columns: ['Tenant', 'Unit', 'Property', 'Amount', 'Status', 'Date'],
      rows: payments.map((p) => [p['tenant']!, p['unit']!, p['property']!, p['amount']!, p['status']!, p['date']!]).toList(),
    );
  }

  pw.Widget _buildArrears(List<Map<String, String>> arrears) {
    return _buildTableSection(
      title: 'Arrears Section',
      columns: ['Tenant', 'Unit', 'Amount Owed', 'Days Late'],
      rows: arrears.isEmpty
          ? [['No arrears for this period.', '', '', '']]
          : arrears.map((a) => [a['tenant']!, a['unit']!, a['amount']!, a['days']!]).toList(),
    );
  }

  pw.Widget _buildTableSection({
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: columns.map((col) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(col, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              )).toList(),
            ),
            ...rows.map((row) => pw.TableRow(
              children: row.map((cell) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(cell, style: pw.TextStyle(fontSize: 8)),
              )).toList(),
            )),
          ],
        ),
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
            pw.Text('Generated by KodiPay', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text('support@kodipay.co.ke', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  String _currentDate() {
    final now = DateTime.now();
    return '${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}
