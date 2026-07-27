import 'package:flutter/material.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:fl_chart/fl_chart.dart';
import '../services/pdf_report_service.dart';
import '../utils/constants.dart';

class LandlordReportsScreen extends StatefulWidget {
  const LandlordReportsScreen({super.key});

  @override
  State<LandlordReportsScreen> createState() => _LandlordReportsScreenState();
}

class _LandlordReportsScreenState extends State<LandlordReportsScreen> {
  String _period = 'This Month';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        Row(
          children: [
            const Expanded(child: Text('Reports & Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.onSurface))),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _period,
                  icon: const Icon(Icons.expand_more, size: 18),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  items: ['This Week', 'This Month', 'This Quarter', 'This Year', 'All Time'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _period = v); },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Summary cards row
        const Wrap(
          spacing: 14, runSpacing: 14,
          children: [
            _SummaryCard(title: 'Total Properties', value: '3', icon: Icons.domain, color: AppColors.kodiBlue),
            _SummaryCard(title: 'Total Units', value: '9', icon: Icons.meeting_room, color: AppColors.tertiaryFixed),
            _SummaryCard(title: 'Occupancy', value: '89%', icon: Icons.people, color: AppColors.kodiGreen),
            _SummaryCard(title: 'Monthly Revenue', value: 'KSh 195,000', icon: Icons.trending_up, color: AppColors.kodiOrange),
          ],
        ),
        const SizedBox(height: 20),

        // Chart + Overview
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            return isNarrow
                ? Column(
                    children: [
                      _buildChart(),
                      const SizedBox(height: 16),
                      _buildOverview(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildChart()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildOverview()),
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),

        // Recent Payments
        _buildPaymentsTable(),
        const SizedBox(height: 20),

        // Export actions
        Wrap(
          spacing: 14, runSpacing: 14,
          children: [
            SizedBox(
              width: 220,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final pdf = PdfReportService();
                  await pdf.generatePaymentReport(
                    landlordName: 'Johnnie Njenga',
                    landlordEmail: 'njengajohnnie@gmail.com',
                    landlordPhone: '+254 700 000 000',
                    propertyCount: 3, totalExpected: 245000, totalCollected: 195000, totalPending: 50000,
                    period: _period,
                    payments: _payments.map((p) => {'tenant': p['tenant']!, 'unit': p['unit']!, 'property': p['property']!, 'amount': p['amount']!, 'status': p['status']!, 'date': p['date']!}).toList(),
                    propertyBreakdown: [
                      {'name': 'Sunview Apartments', 'units': '3', 'collected': 'KSh 75,000', 'pending': 'KSh 0'},
                      {'name': 'Greenfield Heights', 'units': '3', 'collected': 'KSh 60,000', 'pending': 'KSh 25,000'},
                      {'name': 'Lakeview Villas', 'units': '3', 'collected': 'KSh 60,000', 'pending': 'KSh 25,000'},
                    ],
                    arrears: [{'tenant': 'Peter Ochieng', 'unit': 'C3', 'amount': 'KSh 25,000', 'days': '5 days'}],
                    barChartData: [
                      {'label': 'Sunview Apartments', 'value': 75000},
                      {'label': 'Greenfield Heights', 'value': 60000},
                      {'label': 'Lakeview Villas', 'value': 60000},
                    ],
                    pieCollected: 195000, piePending: 50000,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Export PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: OutlinedButton.icon(
                onPressed: () {
                  final csv = StringBuffer();
                  csv.writeln('Tenant,Unit,Property,Amount,Status,Date');
                  for (final row in _payments) {
                    csv.writeln('${row['tenant']},${row['unit']},${row['property']},${row['amount']},${row['status']},${row['date']}');
                  }
                  final blob = web.Blob([csv.toString().toJS].toJS, web.BlobPropertyBag(type: 'text/csv'));
                  final url = web.URL.createObjectURL(blob);
                  web.HTMLAnchorElement()..href = url
                    ..setAttribute('download', 'report_${_period.replaceAll(' ', '_')}.csv')
                    ..click();
                  web.URL.revokeObjectURL(url);
                },
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: const Text('Export CSV'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: FilledButton.icon(
                onPressed: () => _showSnack('Reminders queued for overdue tenants.'),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send Reminders'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.onTertiaryFixed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Revenue Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface)),
              Spacer(),
              _LegendDot(color: AppColors.kodiBlue, label: 'Collected'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.kodiOrange, label: 'Expected'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50000,
                  getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.outlineVariant, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 48,
                      getTitlesWidget: (value, meta) => Text('KSh ${_fmt(value.toInt())}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                        return Text(labels[index], style: const TextStyle(fontSize: 11, color: AppColors.muted));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 4, minY: 0, maxY: 350000,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 120000), FlSpot(1, 160000), FlSpot(2, 145000), FlSpot(3, 195000), FlSpot(4, 180000)],
                    isCurved: true, barWidth: 3, color: AppColors.kodiBlue,
                    belowBarData: BarAreaData(show: true, color: AppColors.kodiBlue.withValues(alpha: 0.08)),
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: const [FlSpot(0, 160000), FlSpot(1, 200000), FlSpot(2, 180000), FlSpot(3, 245000), FlSpot(4, 220000)],
                    isCurved: true, barWidth: 3, color: AppColors.kodiOrange, dashArray: [6, 4],
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface)),
          SizedBox(height: 16),
          _OverviewRow(label: 'Collected', value: 'KSh 195,000', color: AppColors.kodiGreen, pct: '80%'),
          SizedBox(height: 14),
          _OverviewRow(label: 'Pending', value: 'KSh 50,000', color: AppColors.warning, pct: '20%'),
          SizedBox(height: 14),
          _OverviewRow(label: 'Overdue', value: 'KSh 25,000', color: AppColors.danger, pct: '10%'),
          SizedBox(height: 14),
          _OverviewRow(label: 'Occupied Units', value: '8 / 9', color: AppColors.kodiBlue, pct: '89%'),
        ],
      ),
    );
  }

  Widget _buildPaymentsTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Recent Payments', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                SizedBox(width: 120, child: Text('Tenant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
                SizedBox(width: 80, child: Text('Unit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
                Expanded(child: Text('Property', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
                SizedBox(width: 80, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
                SizedBox(width: 60, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
                SizedBox(width: 80, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._payments.map((p) => Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
            child: Row(
              children: [
                SizedBox(width: 120, child: Text(p['tenant']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface))),
                SizedBox(width: 80, child: Text(p['unit']!, style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
                Expanded(child: Text(p['property']!, style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
                SizedBox(width: 80, child: Text(p['amount']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface))),
                SizedBox(width: 60, child: _StatusBadge(label: p['status']!, paid: p['status'] == 'Paid')),
                SizedBox(width: 80, child: Text(p['date']!, style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  final List<Map<String, String>> _payments = [
    {'tenant': 'Mary Wanjiku', 'unit': 'A2', 'property': 'Sunview Apartments', 'amount': 'KSh 25,000', 'status': 'Paid', 'date': '15 May 2026'},
    {'tenant': 'John Kamau', 'unit': 'B1', 'property': 'Greenfield Heights', 'amount': 'KSh 20,000', 'status': 'Paid', 'date': '14 May 2026'},
    {'tenant': 'Peter Ochieng', 'unit': 'C3', 'property': 'Lakeview Villas', 'amount': 'KSh 25,000', 'status': 'Pending', 'date': '-'},
    {'tenant': 'Grace Mwangi', 'unit': 'A1', 'property': 'Sunview Apartments', 'amount': 'KSh 30,000', 'status': 'Paid', 'date': '12 May 2026'},
    {'tenant': 'David Otieno', 'unit': 'B2', 'property': 'Greenfield Heights', 'amount': 'KSh 15,000', 'status': 'Overdue', 'date': '-'},
  ];

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── Helper widgets ─────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface, fontFamily: 'Lexend')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String pct;
  const _OverviewRow({required this.label, required this.value, required this.color, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(pct, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool paid;
  const _StatusBadge({required this.label, required this.paid});

  @override
  Widget build(BuildContext context) {
    final color = paid ? AppColors.kodiGreen : (label == 'Overdue' ? AppColors.danger : AppColors.warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

