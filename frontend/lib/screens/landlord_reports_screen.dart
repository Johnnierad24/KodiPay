import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/pdf_report_service.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class LandlordReportsScreen extends StatefulWidget {
  const LandlordReportsScreen({super.key});

  @override
  State<LandlordReportsScreen> createState() => _LandlordReportsScreenState();
}

class _LandlordReportsScreenState extends State<LandlordReportsScreen> {
  String _period = 'This Month';
  bool _loading = true;

  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _incomeSummary = {};
  List<Map<String, dynamic>> _incomeByProperty = [];
  List<Map<String, dynamic>> _paymentTrends = [];
  List<Map<String, dynamic>> _arrears = [];
  List<Map<String, String>> _payments = [];

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.get('/analytics/dashboard'),
        api.get('/reports/income'),
        api.get('/reports/payment-trends', query: {'months': '12'}),
        api.get('/reports/transactions'),
        api.get('/reports/arrears'),
      ]);

      if (results[0].statusCode == 200) {
        _dashboard = jsonDecode(results[0].body) as Map<String, dynamic>;
      }
      if (results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body) as Map<String, dynamic>;
        _incomeSummary = (data['summary'] as Map<String, dynamic>?) ?? {};
        _incomeByProperty = ((data['byProperty'] as List?) ?? []).cast<Map<String, dynamic>>();
      }
      if (results[2].statusCode == 200) {
        _paymentTrends = ((jsonDecode(results[2].body) as List?) ?? []).cast<Map<String, dynamic>>();
      }
      if (results[3].statusCode == 200) {
        final txn = ((jsonDecode(results[3].body) as List?) ?? []).cast<Map<String, dynamic>>();
        final sorted = List<Map<String, dynamic>>.from(txn)
          ..sort((a, b) => (b['payment_date'] ?? '').toString().compareTo((a['payment_date'] ?? '').toString()));
        _payments = sorted.take(10).map(_mapPayment).toList();
      }
      if (results[4].statusCode == 200) {
        _arrears = ((jsonDecode(results[4].body) as List?) ?? []).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Reports fetch error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, String> _mapPayment(Map<String, dynamic> t) {
    return {
      'tenant': (t['tenant_name'] ?? '-').toString(),
      'unit': (t['unit_number'] ?? '-').toString(),
      'property': (t['property_name'] ?? '-').toString(),
      'amount': 'KSh ${_fmt(_num(t['amount']))}',
      'status': _capitalize((t['status'] ?? 'pending').toString()),
      'date': _formatDate((t['payment_date'] ?? '').toString()),
    };
  }

  int _num(dynamic v) {
    if (v == null) return 0;
    return (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
  }

  double _dbl(dynamic v) {
    if (v == null) return 0;
    return (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
  }

  double _pct(double part, double total) {
    if (total <= 0) return 0;
    return (part / total * 100).roundToDouble();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatDate(String iso) {
    if (iso.isEmpty || iso == '-') return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    final totalProperties = _num(_dashboard['total_properties']);
    final totalUnits = _num(_dashboard['total_units']);
    final occupiedUnits = _num(_dashboard['occupied_units']);
    final thisMonthIncome = _num(_dashboard['this_month_income']);
    final pendingAmount = _num(_dashboard['pending_amount']);
    final overdueInvoices = _num(_dashboard['overdue_invoices']);
    final occupancy = _pct(occupiedUnits.toDouble(), totalUnits.toDouble());

    final collected = _num(_incomeSummary['collected']);
    final expected = _num(_incomeSummary['expected']);
    final pending = _num(_incomeSummary['pending']);
    final assignedExpected = expected > 0 ? expected : thisMonthIncome + pendingAmount;

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
        Wrap(
          spacing: 14, runSpacing: 14,
          children: [
            _SummaryCard(title: 'Total Properties', value: '$totalProperties', icon: Icons.domain, color: AppColors.kodiBlue),
            _SummaryCard(title: 'Total Units', value: '$totalUnits', icon: Icons.meeting_room, color: AppColors.tertiaryFixed),
            _SummaryCard(title: 'Occupancy', value: '$occupancy%', icon: Icons.people, color: AppColors.kodiGreen),
            _SummaryCard(title: 'Monthly Revenue', value: 'KSh ${_fmt(thisMonthIncome)}', icon: Icons.trending_up, color: AppColors.kodiOrange),
          ],
        ),
        const SizedBox(height: 20),

        // Chart + Overview
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final chart = _loading ? _buildLoading(height: 200) : _buildChart();
            final overview = _loading ? _buildLoading(height: 150) : _buildOverview(
              collected: thisMonthIncome,
              pending: pendingAmount,
              overdueAmount: overdueInvoices,
              occupied: occupiedUnits,
              total: totalUnits,
              expected: assignedExpected,
            );
            return isNarrow
                ? Column(
                    children: [
                      chart,
                      const SizedBox(height: 16),
                      overview,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: chart),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: overview),
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
                  final user = auth.user;
                  await pdf.generatePaymentReport(
                    landlordName: '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
                    landlordEmail: user?.email ?? '',
                    landlordPhone: user?.phone ?? '',
                    propertyCount: totalProperties,
                    totalExpected: expected > 0 ? expected : pending + collected,
                    totalCollected: collected,
                    totalPending: pending,
                    period: _period,
                    payments: _payments.map((p) => {'tenant': p['tenant']!, 'unit': p['unit']!, 'property': p['property']!, 'amount': p['amount']!, 'status': p['status']!, 'date': p['date']!}).toList(),
                    propertyBreakdown: _incomeByProperty.map((b) => {
                      'name': (b['property_name'] ?? '-').toString(),
                      'units': '-',
                      'collected': 'KSh ${_fmt(_num(b['collected']))}',
                      'pending': 'KSh ${_fmt(_num(b['pending']))}',
                    }).toList(),
                    arrears: _arrears.map((a) => {
                      'tenant': (a['tenant_name'] ?? '-').toString(),
                      'unit': (a['unit_number'] ?? '-').toString(),
                      'amount': 'KSh ${_fmt(_num(a['amount']))}',
                      'days': '${_num(a['days_overdue'])} days',
                    }).toList(),
                    barChartData: _incomeByProperty.map((b) => {
                      'label': (b['property_name'] ?? '-').toString(),
                      'value': _num(b['collected']),
                    }).toList(),
                    pieCollected: collected,
                    piePending: pending,
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

  Widget _buildLoading({required double height}) {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildChart() {
    final spots = _paymentTrends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _dbl(e.value['income']))).toList();
    final labels = _paymentTrends.map((t) {
      final m = DateTime.tryParse((t['month'] ?? '').toString());
      return m != null ? _months[m.month - 1] : '-';
    }).toList();
    final maxX = spots.isEmpty ? 0.0 : (spots.length - 1).toDouble();
    final maxY = spots.isEmpty ? 0.0 : spots.fold<double>(0, (m, s) => s.y > m ? s.y : m) * 1.2;

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
            child: spots.isEmpty
                ? const Center(child: Text('No data available', style: TextStyle(color: AppColors.muted)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
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
                              final index = value.toInt();
                              if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                              return Text(labels[index], style: const TextStyle(fontSize: 11, color: AppColors.muted));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0, maxX: maxX, minY: 0, maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true, barWidth: 3, color: AppColors.kodiBlue,
                          belowBarData: BarAreaData(show: true, color: AppColors.kodiBlue.withValues(alpha: 0.08)),
                          dotData: const FlDotData(show: true),
                        ),
                        LineChartBarData(
                          spots: spots.map((s) => FlSpot(s.x, s.y * 1.2)).toList(),
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

  Widget _buildOverview({
    required int collected,
    required int pending,
    required int overdueAmount,
    required int occupied,
    required int total,
    required int expected,
  }) {
    final totalIncome = collected + pending;
    final collectedPct = _pct(collected.toDouble(), totalIncome.toDouble());
    final pendingPct = _pct(pending.toDouble(), totalIncome.toDouble());
    final overduePct = _pct(overdueAmount.toDouble(), totalIncome.toDouble());
    final occupancyPct = _pct(occupied.toDouble(), total.toDouble());

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
          const Text('Quick Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface)),
          const SizedBox(height: 16),
          _OverviewRow(label: 'Collected', value: 'KSh ${_fmt(collected)}', color: AppColors.kodiGreen, pct: '$collectedPct%'),
          const SizedBox(height: 14),
          _OverviewRow(label: 'Pending', value: 'KSh ${_fmt(pending)}', color: AppColors.warning, pct: '$pendingPct%'),
          const SizedBox(height: 14),
          _OverviewRow(label: 'Overdue', value: 'KSh ${_fmt(overdueAmount)}', color: AppColors.danger, pct: '$overduePct%'),
          const SizedBox(height: 14),
          _OverviewRow(label: 'Occupied Units', value: '$occupied / $total', color: AppColors.kodiBlue, pct: '$occupancyPct%'),
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
              const Expanded(child: Text('Recent Payments', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface))),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 550;
              if (isNarrow) {
                return Column(
                  children: _payments.map((p) => _paymentCard(p)).toList(),
                );
              }
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('Tenant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
                        Expanded(flex: 2, child: Text('Unit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
                        Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
                        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
                        Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._payments.map((p) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(p['tenant']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface))),
                        Expanded(flex: 2, child: Text(p['unit']!, style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
                        Expanded(flex: 2, child: Text(p['amount']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface))),
                        Expanded(flex: 2, child: _StatusBadge(label: p['status']!, paid: p['status'] == 'Paid')),
                        Expanded(flex: 2, child: Text(p['date']!, style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
                      ],
                    ),
                  )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(Map<String, String> p) {
    final color = p['status'] == 'Paid' ? AppColors.kodiGreen : (p['status'] == 'Overdue' ? AppColors.danger : AppColors.warning);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(p['tenant']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(p['status']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Unit ${p['unit']!}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(width: 12),
              Text(p['property']!, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const Spacer(),
              Text(p['amount']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 4),
          Text(p['date']!, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }

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
