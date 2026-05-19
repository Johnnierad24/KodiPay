import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:html' as html;
import '../services/pdf_report_service.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import 'dart:convert';
import '../widgets/dashboard_components.dart';
import '../widgets/kodi_pay_logo.dart';

class PropertyListScreen extends StatelessWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final properties = [
      const PropertyData('Sunview Apartments', 'Westlands, Nairobi', '12 Units',
          '10 Occupied', 'KSh 250,000'),
      const PropertyData('Greenfield Heights', 'Kilimani, Nairobi', '32 Units',
          '25 Occupied', 'KSh 610,000'),
      const PropertyData(
          'Lakeview Villas', 'Kisumu', '10 Units', '8 Occupied', 'KSh 180,000'),
    ];

    return _FeatureScaffold(
      title: 'My Properties',
      accentColor: AppColors.kodiGreen,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.kodiGreen,
        onPressed: () => showPropertySheet(context),
        child: const Icon(Icons.add_home_rounded, color: AppColors.white),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: properties.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final property = properties[index];
          return _TappableCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PropertyDetailScreen(property: property)),
            ),
            child: Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.kodiGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.apartment_rounded,
                      color: AppColors.kodiGreen, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.name, style: _titleStyle),
                      const SizedBox(height: 4),
                      Text(property.location, style: AppStyles.caption),
                      const SizedBox(height: 9),
                      Text('${property.units}  -  ${property.occupied}',
                          style: _smallBoldStyle),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PropertyDetailScreen extends StatelessWidget {
  final PropertyData property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: property.name,
      accentColor: AppColors.kodiGreen,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GradientPanel(
            startColor: const Color(0xFF10A55A),
            endColor: const Color(0xFF047857),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.location,
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.86))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: StatBox(
                            value: property.units.split(' ').first,
                            label: 'Total Units')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatBox(
                            value: property.occupied.split(' ').first,
                            label: 'Occupied')),
                    const SizedBox(width: 10),
                    const Expanded(
                        child: StatBox(
                            value: 'KSh 25,000', label: 'Monthly Income')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsTile(
            icon: Icons.meeting_room_outlined,
            title: 'Units',
            subtitle: 'View vacancy and rent status',
            onTap: () => _showSnack(context, 'Units module opened'),
          ),
          _SettingsTile(
            icon: Icons.groups_2_outlined,
            title: 'Tenants',
            subtitle: 'Manage active tenants',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TenantListScreen())),
          ),
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'Transactions',
            subtitle: property.monthlyIncome,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LandlordPaymentsScreen())),
          ),
          _SettingsTile(
            icon: Icons.folder_copy_outlined,
            title: 'Documents',
            subtitle: 'Leases and receipts',
            onTap: () =>
                _showSnack(context, 'Documents are ready for upload wiring'),
          ),
        ],
      ),
    );
  }
}

class TenantListScreen extends StatelessWidget {
  const TenantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Tenants',
      accentColor: AppColors.kodiGreen,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.kodiGreen,
        onPressed: () => showTenantSheet(context),
        child:
            const Icon(Icons.person_add_alt_1_rounded, color: AppColors.white),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search tenants...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          SizedBox(height: 14),
          _TenantRow(
              name: 'Mary Wanjiku',
              unit: 'A2 - Sunview Apartments',
              phone: '0723 456 778',
              active: true),
          _TenantRow(
              name: 'John Kamau',
              unit: 'B1 - Greenfield Heights',
              phone: '0721 987 654',
              active: true),
          _TenantRow(
              name: 'Peter Ochieng',
              unit: 'C3 - Lakeview Villas',
              phone: '0700 111 222',
              active: true),
          _TenantRow(
              name: 'Grace Njeri',
              unit: 'A1 - Sunview Apartments',
              phone: '0711 222 333',
              active: false),
        ],
      ),
    );
  }
}

class LandlordPaymentsScreen extends StatefulWidget {
  const LandlordPaymentsScreen({super.key});

  @override
  State<LandlordPaymentsScreen> createState() => _LandlordPaymentsScreenState();
}

class _LandlordPaymentsScreenState extends State<LandlordPaymentsScreen> {
  String _filter = 'All';

  final List<PaymentRecord> _payments = const [
    PaymentRecord(
      tenantName: 'Mary Wanjiku',
      tenantPhone: '0723 456 778',
      tenantEmail: 'mary.wanjiku@example.com',
      unit: 'A2',
      property: 'Sunview Apartments',
      amount: 25000,
      status: 'Paid',
      method: 'M-Pesa',
      transactionRef: 'RFG45K9Q2',
      dueDate: '25 May 2026',
      paidAt: '02 May 2026, 10:45 AM',
      createdAt: '01 May 2026, 08:00 AM',
      updatedAt: '02 May 2026, 10:45 AM',
      daysLate: 0,
    ),
    PaymentRecord(
      tenantName: 'John Kamau',
      tenantPhone: '0721 987 654',
      tenantEmail: 'john.kamau@example.com',
      unit: 'B1',
      property: 'Greenfield Heights',
      amount: 20000,
      status: 'Paid',
      method: 'Bank Transfer',
      transactionRef: 'BNK-2049-778',
      dueDate: '25 May 2026',
      paidAt: '05 May 2026, 02:15 PM',
      createdAt: '01 May 2026, 08:00 AM',
      updatedAt: '05 May 2026, 02:15 PM',
      daysLate: 0,
    ),
    PaymentRecord(
      tenantName: 'Peter Ochieng',
      tenantPhone: '0700 111 222',
      tenantEmail: 'peter.ochieng@example.com',
      unit: 'C3',
      property: 'Lakeview Villas',
      amount: 25000,
      status: 'Pending',
      method: 'M-Pesa',
      transactionRef: 'Pending',
      dueDate: '25 May 2026',
      paidAt: null,
      createdAt: '01 May 2026, 08:00 AM',
      updatedAt: '12 May 2026, 09:30 AM',
      daysLate: 7,
    ),
    PaymentRecord(
      tenantName: 'Grace Njeri',
      tenantPhone: '0711 222 333',
      tenantEmail: 'grace.njeri@example.com',
      unit: 'A1',
      property: 'Sunview Apartments',
      amount: 30000,
      status: 'Pending',
      method: 'M-Pesa',
      transactionRef: 'Pending',
      dueDate: '25 May 2026',
      paidAt: null,
      createdAt: '01 May 2026, 08:00 AM',
      updatedAt: '15 May 2026, 11:10 AM',
      daysLate: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visiblePayments = _filter == 'All'
        ? _payments
        : _payments.where((payment) => payment.status == _filter).toList();
    final totalCollected = _payments
        .where((payment) => payment.isPaid)
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final totalPending = _payments
        .where((payment) => payment.isPending)
        .fold<int>(0, (sum, payment) => sum + payment.amount);

    return _FeatureScaffold(
      title: 'Payments',
      accentColor: AppColors.kodiGreen,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              _FilterChip(
                  label: 'All',
                  selected: _filter == 'All',
                  onTap: () => setState(() => _filter = 'All')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Paid',
                  selected: _filter == 'Paid',
                  onTap: () => setState(() => _filter = 'Paid')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Pending',
                  selected: _filter == 'Pending',
                  onTap: () => setState(() => _filter = 'Pending')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _MetricCard(
                      label: 'Total Received',
                      value: _money(totalCollected),
                      color: AppColors.kodiGreen)),
              const SizedBox(width: 10),
              Expanded(
                  child: _MetricCard(
                      label: 'Pending',
                      value: _money(totalPending),
                      color: AppColors.kodiOrange)),
            ],
          ),
          const SizedBox(height: 16),
          if (visiblePayments.isEmpty)
            const _EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No payments found',
              subtitle: 'Try a different payment filter.',
            )
          else
            ...visiblePayments.map(
              (payment) => _PaymentItem(
                payment: payment,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentDetailScreen(payment: payment),
                  ),
                ),
                onReminder: payment.isPending
                    ? () => _sendPaymentReminder(payment)
                    : null,
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentReportScreen(payments: _payments),
              ),
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Report'),
          ),
        ],
      ),
    );
  }

  void _sendPaymentReminder(PaymentRecord payment) async {
    try {
      final api = ApiService();
      await api.post('/notifications/rent-reminder', {
        'tenancy_id': 1,
        'message': 'Dear ${payment.tenantName}, your rent of ${_money(payment.amount)} for ${payment.property} (Unit ${payment.unit}) is overdue by ${payment.daysLate} days. Please make payment to avoid penalties.',
      });
      _showSnack(context, 'Reminder sent to ${payment.tenantName}.');
    } catch (_) {
      _showSnack(context, 'Reminder sent to ${payment.tenantName} (offline).');
    }
  }
}

class PaymentDetailScreen extends StatelessWidget {
  final PaymentRecord payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Payment Details',
      accentColor: _paymentStatusColor(payment.status),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  payment.isPaid
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: _paymentStatusColor(payment.status),
                  size: 54,
                ),
                const SizedBox(height: 12),
                Text(
                  _money(payment.amount),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                StatusPill(
                  label: payment.status,
                  color: _paymentStatusColor(payment.status),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Tenant',
            rows: [
              _DetailRowData('Name', payment.tenantName),
              _DetailRowData('Phone', payment.tenantPhone),
              _DetailRowData('Email', payment.tenantEmail),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Property',
            rows: [
              _DetailRowData('Property', payment.property),
              _DetailRowData('Unit', payment.unit),
              _DetailRowData('Due Date', payment.dueDate),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Transaction',
            rows: [
              _DetailRowData('Method', payment.method),
              _DetailRowData('Reference', payment.transactionRef),
              _DetailRowData('Created', payment.createdAt),
              _DetailRowData('Updated', payment.updatedAt),
              _DetailRowData('Paid At', payment.paidAt ?? 'Not paid yet'),
            ],
          ),
          if (payment.isPending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final api = ApiService();
                    await api.post('/notifications/rent-reminder', {
                      'tenancy_id': 1,
                      'message': 'Dear ${payment.tenantName}, your rent of ${_money(payment.amount)} for ${payment.property} is due.',
                    });
                  } catch (_) {}
                  _showSnack(context, 'Reminder sent to ${payment.tenantName}.');
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send Payment Reminder'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PaymentReportScreen extends StatelessWidget {
  final List<PaymentRecord> payments;

  const PaymentReportScreen({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    final totalExpected =
        payments.fold<int>(0, (sum, payment) => sum + payment.amount);
    final totalCollected = payments
        .where((payment) => payment.isPaid)
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final totalPending = totalExpected - totalCollected;
    final collectionRate = totalExpected == 0
        ? 0
        : ((totalCollected / totalExpected) * 100).round();
    final arrears = payments.where((payment) => payment.isPending).toList();
    final propertyBreakdown = _buildPropertyBreakdown(payments);

    return _FeatureScaffold(
      title: 'Payment Report',
      accentColor: AppColors.kodiGreen,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _ReportDocumentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PaymentReportHeader(
                  generatedDate: '19 May 2026',
                  period: 'May 2026',
                ),
                const SizedBox(height: 18),
                const _LandlordReportInfo(),
                const SizedBox(height: 18),
                _PaymentReportSummary(
                  totalExpected: totalExpected,
                  totalCollected: totalCollected,
                  totalPending: totalPending,
                  collectionRate: collectionRate,
                ),
                const SizedBox(height: 18),
                _PropertyBreakdownTable(rows: propertyBreakdown),
                const SizedBox(height: 18),
                _DetailedPaymentTable(payments: payments),
                const SizedBox(height: 18),
                _ArrearsTable(payments: arrears),
                const SizedBox(height: 18),
                _ReportCharts(
                  propertyRows: propertyBreakdown,
                  totalCollected: totalCollected,
                  totalPending: totalPending,
                ),
                const SizedBox(height: 18),
                const Divider(color: AppColors.border),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Generated by KodiPay',
                        style: TextStyle(
                          color: AppColors.kodiNavy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text('support@kodipay.co.ke  |  Page 1'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pdfService = PdfReportService();
                    await pdfService.generatePaymentReport(
                      landlordName: 'Johnnie Njenga',
                      landlordEmail: 'njengajohnnie@gmail.com',
                      landlordPhone: '+254 700 000 000',
                      propertyCount: 3,
                      totalExpected: totalExpected,
                      totalCollected: totalCollected,
                      totalPending: totalPending,
                      period: 'May 2026',
                      payments: payments.map((p) => {
                        'tenant': p.tenantName,
                        'unit': p.unit,
                        'property': p.property,
                        'amount': _money(p.amount),
                        'status': p.status,
                        'date': p.paidAt ?? '-',
                      }).toList(),
                      propertyBreakdown: propertyBreakdown.map((pb) => {
                        'name': pb.propertyName,
                        'units': pb.units.toString(),
                        'collected': _money(pb.collected),
                        'pending': _money(pb.pending),
                      }).toList(),
                      arrears: arrears.map((a) => {
                        'tenant': a.tenantName,
                        'unit': a.unit,
                        'amount': _money(a.amount),
                        'days': '${a.daysLate} days',
                      }).toList(),
                      barChartData: propertyBreakdown.map((pb) => {
                        'label': pb.propertyName,
                        'value': pb.collected,
                      }).toList(),
                      pieCollected: totalCollected,
                      piePending: totalPending,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final csv = StringBuffer();
                    csv.writeln('Tenant,Unit,Property,Amount,Status,Date');
                    for (final p in payments) {
                      csv.writeln('${p.tenantName},${p.unit},${p.property},${p.amount},${p.status},${p.paidAt ?? '-'}');
                    }
                    final blob = html.Blob([csv.toString()], 'text/csv');
                    final url = html.Url.createObjectUrlFromBlob(blob);
                    final anchor = html.AnchorElement(href: url)
                      ..setAttribute('download', 'payment_report_May2026.csv')
                      ..click();
                    html.Url.revokeObjectUrl(url);
                  },
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('CSV'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LandlordReportsScreen extends StatefulWidget {
  const LandlordReportsScreen({super.key});

  @override
  State<LandlordReportsScreen> createState() => _LandlordReportsScreenState();
}

class _LandlordReportsScreenState extends State<LandlordReportsScreen> {
  String _reportType = 'Income';
  String _property = 'All Properties';
  String _period = 'This Month';
  String _status = 'All';

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Reports',
      accentColor: AppColors.kodiBlue,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _ReportFilters(
            period: _period,
            property: _property,
            status: _status,
            onPeriodChanged: (value) => setState(() => _period = value),
            onPropertyChanged: (value) => setState(() => _property = value),
            onStatusChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 16),
          _ReportTypeSelector(
            selected: _reportType,
            onChanged: (value) => setState(() => _reportType = value),
          ),
          const SizedBox(height: 16),
          _ReportSummaryGrid(reportType: _reportType),
          const SizedBox(height: 16),
          if (_reportType == 'Income') ...[
            const _IncomeTrendCard(),
            const SizedBox(height: 16),
            const _PropertyIncomeBreakdown(),
          ] else if (_reportType == 'Arrears') ...[
            _ArrearsReport(onReminder: _sendReminder),
          ] else if (_reportType == 'Property') ...[
            const _PropertyPerformanceReport(),
          ] else if (_reportType == 'Maintenance') ...[
            const _MaintenanceReport(),
          ] else if (_reportType == 'Trends') ...[
            const _IncomeTrendCard(),
            const SizedBox(height: 16),
            const _PaidVsPendingCard(),
          ] else ...[
            const _TransactionReport(),
          ],
          const SizedBox(height: 18),
          _ReportActions(
            onExportPdf: () async {
              final pdf = PdfReportService();
              await pdf.generatePaymentReport(
                landlordName: 'Johnnie Njenga',
                landlordEmail: 'njengajohnnie@gmail.com',
                landlordPhone: '+254 700 000 000',
                propertyCount: 3,
                totalExpected: 245000,
                totalCollected: 195000,
                totalPending: 50000,
                period: '$_period $_property',
                payments: [
                  {'tenant': 'Mary Wanjiku', 'unit': 'A2 - Sunview Apts', 'property': 'Sunview Apartments', 'amount': 'KSh 25,000', 'status': 'Paid', 'date': '15 May 2026'},
                  {'tenant': 'John Kamau', 'unit': 'B1 - Greenfield Hts', 'property': 'Greenfield Heights', 'amount': 'KSh 20,000', 'status': 'Paid', 'date': '14 May 2026'},
                  {'tenant': 'Peter Ochieng', 'unit': 'C3 - Lakeview Villas', 'property': 'Lakeview Villas', 'amount': 'KSh 25,000', 'status': 'Pending', 'date': '-'},
                ],
                propertyBreakdown: [
                  {'name': 'Sunview Apartments', 'units': '3', 'collected': 'KSh 75,000', 'pending': 'KSh 0'},
                  {'name': 'Greenfield Heights', 'units': '3', 'collected': 'KSh 60,000', 'pending': 'KSh 25,000'},
                  {'name': 'Lakeview Villas', 'units': '3', 'collected': 'KSh 60,000', 'pending': 'KSh 25,000'},
                ],
                arrears: [
                  {'tenant': 'Peter Ochieng', 'unit': 'C3', 'amount': 'KSh 25,000', 'days': '5 days'},
                ],
                barChartData: [
                  {'label': 'Sunview Apartments', 'value': 75000},
                  {'label': 'Greenfield Heights', 'value': 60000},
                  {'label': 'Lakeview Villas', 'value': 60000},
                ],
                pieCollected: 195000,
                piePending: 50000,
              );
            },
            onExportCsv: () {
              final csv = StringBuffer();
              csv.writeln('Tenant,Unit,Property,Amount,Status,Date');
              for (final row in [
                ['Mary Wanjiku', 'A2 - Sunview Apts', 'Sunview Apartments', 'KSh 25,000', 'Paid', '15 May 2026'],
                ['John Kamau', 'B1 - Greenfield Hts', 'Greenfield Heights', 'KSh 20,000', 'Paid', '14 May 2026'],
                ['Peter Ochieng', 'C3 - Lakeview Villas', 'Lakeview Villas', 'KSh 25,000', 'Pending', '-'],
              ]) {
                csv.writeln(row.join(','));
              }
              final blob = html.Blob([csv.toString()], 'text/csv');
              final url = html.Url.createObjectUrlFromBlob(blob);
              html.AnchorElement(href: url)
                ..setAttribute('download', 'report_${_period.replaceAll(' ', '_')}.csv')
                ..click();
              html.Url.revokeObjectUrl(url);
            },
            onSendReminders: () =>
                _showSnack(context, 'Reminders queued for overdue tenants.'),
          ),
        ],
      ),
    );
  }

  void _sendReminder(String tenant) {
    _showSnack(context, 'Reminder sent to $tenant.');
  }
}

class _ReportFilters extends StatelessWidget {
  final String period;
  final String property;
  final String status;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onPropertyChanged;
  final ValueChanged<String> onStatusChanged;

  const _ReportFilters({
    required this.period,
    required this.property,
    required this.status,
    required this.onPeriodChanged,
    required this.onPropertyChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: _titleStyle),
          const SizedBox(height: 12),
          _ReportDropdown(
            label: 'Date Range',
            value: period,
            values: const ['Today', 'This Month', 'This Quarter', 'This Year'],
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: 10),
          _ReportDropdown(
            label: 'Property',
            value: property,
            values: const [
              'All Properties',
              'Sunview Apartments',
              'Greenfield Heights',
              'Lakeview Villas',
            ],
            onChanged: onPropertyChanged,
          ),
          const SizedBox(height: 10),
          _ReportDropdown(
            label: 'Status',
            value: status,
            values: const ['All', 'Paid', 'Pending', 'Overdue'],
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _ReportDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _ReportDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ReportTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ReportTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const types = [
      'Income',
      'Arrears',
      'Property',
      'Maintenance',
      'Trends',
      'Transactions'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types
            .map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(type),
                  selected: selected == type,
                  selectedColor: AppColors.kodiBlue.withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    color: selected == type
                        ? AppColors.kodiBlue
                        : AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => onChanged(type),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReportSummaryGrid extends StatelessWidget {
  final String reportType;

  const _ReportSummaryGrid({required this.reportType});

  @override
  Widget build(BuildContext context) {
    final cards = switch (reportType) {
      'Arrears' => const [
          _ReportMetric(
              label: 'Overdue Amount',
              value: 'KSh 75,000',
              color: AppColors.danger),
          _ReportMetric(
              label: 'Tenants Overdue',
              value: '5',
              color: AppColors.kodiOrange),
          _ReportMetric(
              label: 'Avg Days Late', value: '9', color: AppColors.kodiBlue),
        ],
      'Maintenance' => const [
          _ReportMetric(
              label: 'Open Issues', value: '12', color: AppColors.kodiOrange),
          _ReportMetric(
              label: 'Completed', value: '18', color: AppColors.kodiGreen),
          _ReportMetric(
              label: 'Cost', value: 'KSh 38k', color: AppColors.kodiBlue),
        ],
      'Property' => const [
          _ReportMetric(
              label: 'Best Property',
              value: 'Greenfield',
              color: AppColors.kodiGreen),
          _ReportMetric(
              label: 'Occupancy', value: '94%', color: AppColors.kodiBlue),
          _ReportMetric(
              label: 'Vacant Units', value: '6', color: AppColors.kodiOrange),
        ],
      _ => const [
          _ReportMetric(
              label: 'Collected',
              value: 'KSh 245k',
              color: AppColors.kodiGreen),
          _ReportMetric(
              label: 'Expected', value: 'KSh 320k', color: AppColors.kodiBlue),
          _ReportMetric(
              label: 'Pending', value: 'KSh 75k', color: AppColors.kodiOrange),
        ],
    };

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.92,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: cards,
    );
  }
}

class _ReportMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReportMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.caption),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeTrendCard extends StatelessWidget {
  const _IncomeTrendCard();

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      title: 'Monthly Income Trend',
      child: SizedBox(
        height: 210,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(labels[index], style: AppStyles.caption);
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 4,
            minY: 0,
            maxY: 320,
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 180),
                  FlSpot(1, 210),
                  FlSpot(2, 195),
                  FlSpot(3, 245),
                  FlSpot(4, 275),
                ],
                isCurved: true,
                barWidth: 4,
                color: AppColors.kodiBlue,
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.kodiBlue.withValues(alpha: 0.12),
                ),
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaidVsPendingCard extends StatelessWidget {
  const _PaidVsPendingCard();

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      title: 'Paid vs Pending',
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 34,
                sections: [
                  PieChartSectionData(
                    value: 77,
                    color: AppColors.kodiGreen,
                    title: '77%',
                    radius: 32,
                    titleStyle: const TextStyle(
                        color: AppColors.white, fontWeight: FontWeight.w800),
                  ),
                  PieChartSectionData(
                    value: 23,
                    color: AppColors.kodiOrange,
                    title: '23%',
                    radius: 32,
                    titleStyle: const TextStyle(
                        color: AppColors.white, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(
                    color: AppColors.kodiGreen,
                    label: 'Paid',
                    value: 'KSh 245,000'),
                SizedBox(height: 12),
                _LegendRow(
                    color: AppColors.kodiOrange,
                    label: 'Pending',
                    value: 'KSh 75,000'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: _titleStyle)),
        Text(value, style: _smallBoldStyle),
      ],
    );
  }
}

class _PropertyIncomeBreakdown extends StatelessWidget {
  const _PropertyIncomeBreakdown();

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Per Property Breakdown',
      child: Column(
        children: [
          _ReportDataRow(
              label: 'Sunview Apartments',
              value: 'KSh 250,000',
              status: '92% paid',
              color: AppColors.kodiGreen),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Greenfield Heights',
              value: 'KSh 610,000',
              status: '96% paid',
              color: AppColors.kodiGreen),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Lakeview Villas',
              value: 'KSh 180,000',
              status: '78% paid',
              color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class _ArrearsReport extends StatelessWidget {
  final ValueChanged<String> onReminder;

  const _ArrearsReport({required this.onReminder});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      title: 'Tenants With Unpaid Rent',
      child: Column(
        children: [
          _ArrearsRow(
              tenant: 'Peter Ochieng',
              unit: 'C3 - Lakeview Villas',
              amount: 'KSh 25,000',
              days: '12 days',
              onReminder: onReminder),
          const _ReportDivider(),
          _ArrearsRow(
              tenant: 'Grace Njeri',
              unit: 'A1 - Sunview Apts',
              amount: 'KSh 30,000',
              days: '8 days',
              onReminder: onReminder),
          const _ReportDivider(),
          _ArrearsRow(
              tenant: 'Brian Otieno',
              unit: 'B8 - Greenfield Hts',
              amount: 'KSh 20,000',
              days: '5 days',
              onReminder: onReminder),
        ],
      ),
    );
  }
}

class _ArrearsRow extends StatelessWidget {
  final String tenant;
  final String unit;
  final String amount;
  final String days;
  final ValueChanged<String> onReminder;

  const _ArrearsRow({
    required this.tenant,
    required this.unit,
    required this.amount,
    required this.days,
    required this.onReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tenant, style: _titleStyle)),
              Text(amount,
                  style: const TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$unit  -  $days overdue', style: AppStyles.caption),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onReminder(tenant),
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Send Reminder'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyPerformanceReport extends StatelessWidget {
  const _PropertyPerformanceReport();

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Property Performance',
      child: Column(
        children: [
          _ReportDataRow(
              label: 'Greenfield Heights',
              value: 'KSh 610,000',
              status: '25/32 occupied',
              color: AppColors.kodiGreen),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Sunview Apartments',
              value: 'KSh 250,000',
              status: '10/12 occupied',
              color: AppColors.kodiBlue),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Lakeview Villas',
              value: 'KSh 180,000',
              status: '8/10 occupied',
              color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class _MaintenanceReport extends StatelessWidget {
  const _MaintenanceReport();

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Maintenance Costs & Issues',
      child: Column(
        children: [
          _ReportDataRow(
              label: 'Plumbing',
              value: '6 issues',
              status: 'KSh 18,000',
              color: AppColors.kodiOrange),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Electrical',
              value: '3 issues',
              status: 'KSh 12,500',
              color: AppColors.danger),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Locks & Doors',
              value: '3 issues',
              status: 'KSh 7,500',
              color: AppColors.kodiBlue),
        ],
      ),
    );
  }
}

class _TransactionReport extends StatelessWidget {
  const _TransactionReport();

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Transaction History',
      child: Column(
        children: [
          _ReportDataRow(
              label: 'Mary Wanjiku',
              value: 'KSh 25,000',
              status: 'M-Pesa - Paid',
              color: AppColors.kodiGreen),
          _ReportDivider(),
          _ReportDataRow(
              label: 'John Kamau',
              value: 'KSh 20,000',
              status: 'Bank - Paid',
              color: AppColors.kodiGreen),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Peter Ochieng',
              value: 'KSh 25,000',
              status: 'Pending',
              color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ReportDataRow extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final Color color;

  const _ReportDataRow({
    required this.label,
    required this.value,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _titleStyle),
                const SizedBox(height: 4),
                Text(status, style: AppStyles.caption),
              ],
            ),
          ),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ReportDivider extends StatelessWidget {
  const _ReportDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.border);
  }
}

class _ReportActions extends StatelessWidget {
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;
  final VoidCallback onSendReminders;

  const _ReportActions({
    required this.onExportPdf,
    required this.onExportCsv,
    required this.onSendReminders,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onExportPdf,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('PDF'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onExportCsv,
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('CSV'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onSendReminders,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Send Arrears Reminders'),
          ),
        ),
      ],
    );
  }
}

void _showExportSheet(BuildContext context, String type) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export $type Report', style: AppStyles.heading2),
            const SizedBox(height: 10),
            const Text(
              'Includes filters, summaries, arrears, property performance, maintenance, and transactions.',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showSnack(context, '$type export generated.');
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class TenantPaymentsScreen extends StatelessWidget {
  const TenantPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'My Payments',
      accentColor: AppColors.kodiBlue,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GradientPanel(
            startColor: const Color(0xFF1D6FD8),
            endColor: const Color(0xFF0047A1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount Due',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.86))),
                const SizedBox(height: 6),
                const Text('KSh 25,000',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.kodiBlue),
                    onPressed: () => Navigator.pushNamed(context, '/pay-rent'),
                    child: const Text('Pay Now (M-Pesa)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Payment History'),
          const ListPanel(
            children: [
              _TenantPaymentHistory(month: 'Apr 2024', date: 'Apr 25, 2024'),
              Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.border),
              _TenantPaymentHistory(month: 'Mar 2024', date: 'Mar 25, 2024'),
            ],
          ),
        ],
      ),
    );
  }
}

class TenantMaintenanceScreen extends StatelessWidget {
  const TenantMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'My Maintenance',
      accentColor: AppColors.kodiOrange,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.kodiBlue,
        onPressed: () => showIssueSheet(context),
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Report Issue',
            style: TextStyle(color: AppColors.white)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _IssueListItem(
              title: 'Leaking Sink',
              location: 'Kitchen - A2',
              status: 'In Progress',
              color: AppColors.kodiOrange),
          _IssueListItem(
              title: 'Broken Window',
              location: 'Bedroom - A2',
              status: 'Pending',
              color: AppColors.kodiOrange),
          _IssueListItem(
              title: 'Light Not Working',
              location: 'Living Room - A2',
              status: 'Pending',
              color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class TenantNoticesScreen extends StatelessWidget {
  const TenantNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Notices',
      accentColor: AppColors.kodiBlue,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _NoticeCard(
              title: 'Water Interruption',
              body:
                  'Water service will be interrupted on Saturday from 8 AM to noon.'),
          _NoticeCard(
              title: 'Rent Reminder',
              body: 'May rent is due on 25th May 2024.'),
          _NoticeCard(
              title: 'Security Update',
              body: 'Visitor registration is now required at the main gate.'),
        ],
      ),
    );
  }
}

class CaretakerTasksScreen extends StatefulWidget {
  const CaretakerTasksScreen({super.key});

  @override
  State<CaretakerTasksScreen> createState() => _CaretakerTasksScreenState();
}

class _CaretakerTasksScreenState extends State<CaretakerTasksScreen> {
  final Set<String> _completed = {};

  @override
  Widget build(BuildContext context) {
    final tasks = [
      const _TaskData('Broken Tap', 'House 12B', 'High'),
      const _TaskData('Electrical Fault', 'House 8A', 'Medium'),
      const _TaskData('Door Lock Repair', 'House 5C', 'Low'),
    ];

    return _FeatureScaffold(
      title: 'Tasks',
      accentColor: AppColors.kodiOrange,
      child: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = tasks[index];
          final done = _completed.contains(task.title);
          return _TappableCard(
            onTap: () => _showSnack(context, '${task.title} details opened'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.handyman_rounded,
                        color: AppColors.kodiOrange),
                    const SizedBox(width: 10),
                    Expanded(child: Text(task.title, style: _titleStyle)),
                    StatusPill(
                        label: done ? 'Done' : task.priority,
                        color:
                            done ? AppColors.kodiGreen : AppColors.kodiOrange),
                  ],
                ),
                const SizedBox(height: 8),
                Text(task.location, style: AppStyles.caption),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _completed.add(task.title));
                      _showSnack(context, '${task.title} marked complete');
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Mark as Complete'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CaretakerAlertsScreen extends StatelessWidget {
  const CaretakerAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Alerts',
      accentColor: AppColors.kodiOrange,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _AlertCard(
              title: 'Water Leakage', location: 'House 3D', type: 'Emergency'),
          _AlertCard(
              title: 'Power Outage',
              location: 'Greenfield Heights',
              type: 'General'),
          _AlertCard(
              title: 'Fire Alarm Triggered',
              location: 'House 7A',
              type: 'Emergency'),
          _AlertCard(
              title: 'Gas Smell Reported',
              location: 'House 2B',
              type: 'Emergency'),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final String role;
  final Color accentColor;

  const ProfileScreen({
    super.key,
    required this.role,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Profile',
      accentColor: accentColor,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _TappableCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: accentColor.withValues(alpha: 0.12),
                  child: Icon(Icons.person_rounded, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role, style: _titleStyle),
                      const SizedBox(height: 4),
                      const Text('KodiPay account', style: AppStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Security',
            subtitle: 'Password and session settings',
            onTap: () => _showSnack(context, 'Security settings opened'),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Support',
            subtitle: 'Contact KodiPay support',
            onTap: () => _showSnack(context, 'Support request started'),
          ),
        ],
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'More',
      accentColor: AppColors.kodiNavy,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _SettingsTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'App preferences, alerts, and exports',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppPreferencesScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Profile',
            subtitle: 'Landlord account and security',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(
                  role: 'Landlord',
                  accentColor: AppColors.kodiGreen,
                ),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Support',
            subtitle: 'Get help with payments or reports',
            onTap: () => _showSnack(context, 'Support request started.'),
          ),
        ],
      ),
    );
  }
}

class LandlordNotificationsScreen extends StatefulWidget {
  const LandlordNotificationsScreen({super.key});

  @override
  State<LandlordNotificationsScreen> createState() =>
      _LandlordNotificationsScreenState();
}

class _LandlordNotificationsScreenState
    extends State<LandlordNotificationsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final notifications = [
      const _NotificationData(
        type: 'Reminder',
        title: 'Rent reminder sent',
        body: 'Peter Ochieng was reminded about KSh 25,000 overdue rent.',
        status: 'Sent',
        time: 'Today, 9:30 AM',
        color: AppColors.kodiBlue,
        icon: Icons.sms_outlined,
      ),
      const _NotificationData(
        type: 'Maintenance',
        title: 'Broken Tap reported',
        body: 'Mary Wanjiku reported a plumbing issue in House 12B.',
        status: 'In Progress',
        time: 'Today, 8:10 AM',
        color: AppColors.kodiOrange,
        icon: Icons.build_outlined,
      ),
      const _NotificationData(
        type: 'System',
        title: 'M-Pesa callback processed',
        body: 'Payment reconciliation completed for Sunview Apartments.',
        status: 'Resolved',
        time: 'Yesterday, 5:45 PM',
        color: AppColors.kodiGreen,
        icon: Icons.verified_outlined,
      ),
      const _NotificationData(
        type: 'Maintenance',
        title: 'Electrical fault escalated',
        body: 'Caretaker marked House 8A issue as high priority.',
        status: 'Pending',
        time: 'Yesterday, 2:20 PM',
        color: AppColors.danger,
        icon: Icons.warning_amber_rounded,
      ),
    ];
    final visible = _filter == 'All'
        ? notifications
        : notifications.where((item) => item.type == _filter).toList();

    return _FeatureScaffold(
      title: 'Notifications',
      accentColor: AppColors.kodiBlue,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Reminder', 'Maintenance', 'System']
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _filter == filter,
                        selectedColor:
                            AppColors.kodiBlue.withValues(alpha: 0.14),
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          ...visible.map((item) => _NotificationCard(data: item)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showSnack(context, 'All notifications read.'),
            icon: const Icon(Icons.done_all_rounded),
            label: const Text('Mark All as Read'),
          ),
        ],
      ),
    );
  }
}

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  bool _rentReminders = true;
  bool _maintenanceAlerts = true;
  bool _systemAlerts = true;
  bool _monthlyReports = true;
  String _defaultExport = 'PDF';
  String _currency = 'KES';

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'App Preferences',
      accentColor: AppColors.kodiNavy,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _PreferenceSwitch(
            title: 'Rent reminders',
            subtitle: 'Notify when rent is due or overdue',
            value: _rentReminders,
            onChanged: (value) => setState(() => _rentReminders = value),
          ),
          _PreferenceSwitch(
            title: 'Maintenance alerts',
            subtitle: 'Notify when tenants report or update issues',
            value: _maintenanceAlerts,
            onChanged: (value) => setState(() => _maintenanceAlerts = value),
          ),
          _PreferenceSwitch(
            title: 'System alerts',
            subtitle: 'Payment callbacks, exports, and account notices',
            value: _systemAlerts,
            onChanged: (value) => setState(() => _systemAlerts = value),
          ),
          _PreferenceSwitch(
            title: 'Monthly report summary',
            subtitle: 'Send income and arrears summary every month',
            value: _monthlyReports,
            onChanged: (value) => setState(() => _monthlyReports = value),
          ),
          const SizedBox(height: 12),
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Report Defaults', style: _titleStyle),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _defaultExport,
                  decoration: const InputDecoration(labelText: 'Export Format'),
                  items: const [
                    DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                    DropdownMenuItem(value: 'CSV', child: Text('CSV')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _defaultExport = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: const [
                    DropdownMenuItem(value: 'KES', child: Text('KES')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _currency = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showSnack(context, 'Preferences saved.'),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Preferences'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showPropertySheet(BuildContext context) {
  return _showInputSheet(
    context: context,
    title: 'Add Property',
    fields: const ['Property Name', 'Location', 'Monthly Rent'],
    submitLabel: 'Save Property',
    message: 'Property saved locally. Backend wiring comes next.',
  );
}

Future<void> showTenantSheet(BuildContext context) {
  return _showInputSheet(
    context: context,
    title: 'Add Tenant',
    fields: const ['Full Name', 'Phone Number', 'Email', 'Property', 'Unit'],
    submitLabel: 'Save Tenant',
    message: 'Tenant saved locally. Backend wiring comes next.',
  );
}

Future<void> showIssueSheet(BuildContext context) {
  return _showInputSheet(
    context: context,
    title: 'Report Maintenance Issue',
    fields: const ['Issue Title', 'Category', 'Description'],
    submitLabel: 'Submit Issue',
    message: 'Issue submitted locally. Backend wiring comes next.',
  );
}

Future<void> showReminderSheet(BuildContext context) {
  return _showInputSheet(
    context: context,
    title: 'Send Reminder',
    fields: const ['Tenant or Unit', 'Message'],
    submitLabel: 'Send Reminder',
    message: 'Reminder queued.',
  );
}

Future<void> _showInputSheet({
  required BuildContext context,
  required String title,
  required List<String> fields,
  required String submitLabel,
  required String message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
            18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppStyles.heading2),
              const SizedBox(height: 16),
              ...fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      TextField(decoration: InputDecoration(labelText: field)),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSnack(context, message);
                  },
                  child: Text(submitLabel),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FeatureScaffold extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;
  final Widget? floatingActionButton;

  const _FeatureScaffold({
    required this.title,
    required this.accentColor,
    required this.child,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title,
            style: const TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: child),
    );
  }
}

class _TappableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TappableCard({
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _TappableCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.kodiBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailRowData> rows;

  const _DetailSection({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle),
          const SizedBox(height: 12),
          ...rows.map((row) => _DetailRow(row: row)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final _DetailRowData row;

  const _DetailRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(row.label, style: AppStyles.caption)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: AppColors.muted, size: 34),
            const SizedBox(height: 10),
            Text(title, style: _titleStyle),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: AppStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _ReportDocumentCard extends StatelessWidget {
  final Widget child;

  const _ReportDocumentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.kodiNavy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PaymentReportHeader extends StatelessWidget {
  final String generatedDate;
  final String period;

  const _PaymentReportHeader({
    required this.generatedDate,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const KodiPayLogo(iconSize: 38, fontSize: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'KodiPay',
              style: TextStyle(
                color: AppColors.kodiNavy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 3),
            Text('Pay Rent. Stay Worry-Free.', style: AppStyles.caption),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Payment Report',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text('Generated: $generatedDate', style: AppStyles.caption),
            Text('Period: $period', style: AppStyles.caption),
          ],
        ),
      ],
    );
  }
}

class _LandlordReportInfo extends StatelessWidget {
  const _LandlordReportInfo();

  @override
  Widget build(BuildContext context) {
    return const _ReportBlock(
      title: 'Landlord Information',
      child: Column(
        children: [
          _ReportInfoRow(label: 'Landlord Name', value: 'James Mwangi'),
          _ReportInfoRow(label: 'Email / Phone', value: 'james@kodipay.co.ke / 0700 000 111'),
          _ReportInfoRow(label: 'Property Count', value: '3 properties'),
        ],
      ),
    );
  }
}

class _PaymentReportSummary extends StatelessWidget {
  final int totalExpected;
  final int totalCollected;
  final int totalPending;
  final int collectionRate;

  const _PaymentReportSummary({
    required this.totalExpected,
    required this.totalCollected,
    required this.totalPending,
    required this.collectionRate,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportBlock(
      title: 'Summary',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.15,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          _ReportSummaryCard(
            label: 'Total Expected',
            value: _money(totalExpected),
            color: AppColors.kodiBlue,
          ),
          _ReportSummaryCard(
            label: 'Collected',
            value: _money(totalCollected),
            color: AppColors.kodiGreen,
          ),
          _ReportSummaryCard(
            label: 'Pending',
            value: _money(totalPending),
            color: AppColors.danger,
          ),
          _ReportSummaryCard(
            label: 'Collection Rate',
            value: '$collectionRate%',
            color: AppColors.kodiOrange,
          ),
        ],
      ),
    );
  }
}

class _PropertyBreakdownTable extends StatelessWidget {
  final List<_PropertyPaymentBreakdown> rows;

  const _PropertyBreakdownTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _ReportBlock(
      title: 'Property Breakdown',
      child: Column(
        children: [
          const _ReportTableHeader(
            columns: ['Property', 'Units', 'Collected', 'Pending'],
          ),
          ...rows.map(
            (row) => _ReportTableRow(
              cells: [
                row.propertyName,
                row.units.toString(),
                _money(row.collected),
                _money(row.pending),
              ],
              statusColor: row.pending > 0 ? AppColors.danger : AppColors.kodiGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedPaymentTable extends StatelessWidget {
  final List<PaymentRecord> payments;

  const _DetailedPaymentTable({required this.payments});

  @override
  Widget build(BuildContext context) {
    return _ReportBlock(
      title: 'Detailed Payment Table',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 760,
          child: Column(
            children: [
              const _ReportTableHeader(
                columns: ['Tenant', 'Unit', 'Property', 'Amount', 'Status', 'Date'],
              ),
              ...payments.map(
                (payment) => _ReportTableRow(
                  cells: [
                    payment.tenantName,
                    payment.unit,
                    payment.property,
                    _money(payment.amount),
                    payment.status,
                    payment.paidAt ?? '-',
                  ],
                  statusColor: _paymentStatusColor(payment.status),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrearsTable extends StatelessWidget {
  final List<PaymentRecord> payments;

  const _ArrearsTable({required this.payments});

  @override
  Widget build(BuildContext context) {
    return _ReportBlock(
      title: 'Arrears Section',
      child: Column(
        children: [
          const _ReportTableHeader(
            columns: ['Tenant', 'Unit', 'Amount Owed', 'Days Late'],
          ),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('No arrears for this period.', style: AppStyles.caption),
            )
          else
            ...payments.map(
              (payment) => _ReportTableRow(
                cells: [
                  payment.tenantName,
                  payment.unit,
                  _money(payment.amount),
                  '${payment.daysLate} days',
                ],
                statusColor: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportCharts extends StatelessWidget {
  final List<_PropertyPaymentBreakdown> propertyRows;
  final int totalCollected;
  final int totalPending;

  const _ReportCharts({
    required this.propertyRows,
    required this.totalCollected,
    required this.totalPending,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportBlock(
      title: 'Charts',
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: propertyRows
                    .asMap()
                    .entries
                    .map(
                      (entry) => BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.collected / 1000,
                            color: AppColors.kodiGreen,
                            width: 22,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PaidPendingMiniChart(
            totalCollected: totalCollected,
            totalPending: totalPending,
          ),
        ],
      ),
    );
  }
}

class _PaidPendingMiniChart extends StatelessWidget {
  final int totalCollected;
  final int totalPending;

  const _PaidPendingMiniChart({
    required this.totalCollected,
    required this.totalPending,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 118,
          height: 118,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 30,
              sectionsSpace: 2,
              sections: [
                PieChartSectionData(
                  value: totalCollected.toDouble(),
                  color: AppColors.kodiGreen,
                  title: 'Paid',
                  radius: 28,
                  titleStyle: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                PieChartSectionData(
                  value: totalPending.toDouble(),
                  color: AppColors.danger,
                  title: 'Pending',
                  radius: 28,
                  titleStyle: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _LegendRow(
                color: AppColors.kodiGreen,
                label: 'Paid',
                value: _money(totalCollected),
              ),
              const SizedBox(height: 10),
              _LegendRow(
                color: AppColors.danger,
                label: 'Pending',
                value: _money(totalPending),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportBlock({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReportInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppStyles.caption)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _smallBoldStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReportSummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppStyles.caption),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTableHeader extends StatelessWidget {
  final List<String> columns;

  const _ReportTableHeader({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: columns
            .map(
              (column) => Expanded(
                child: Text(
                  column,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReportTableRow extends StatelessWidget {
  final List<String> cells;
  final Color statusColor;

  const _ReportTableRow({
    required this.cells,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: cells
            .asMap()
            .entries
            .map(
              (entry) => Expanded(
                child: Text(
                  entry.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: entry.key == cells.length - 2
                        ? statusColor
                        : AppColors.textDark,
                    fontSize: 11,
                    fontWeight: entry.key == 0 ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TenantRow extends StatelessWidget {
  final String name;
  final String unit;
  final String phone;
  final bool active;

  const _TenantRow({
    required this.name,
    required this.unit,
    required this.phone,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: () => _showSnack(context, '$name selected'),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.kodiGreen.withValues(alpha: 0.12),
              child: Text(name.characters.first,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _titleStyle),
                  const SizedBox(height: 3),
                  Text(unit, style: AppStyles.caption),
                  Text(phone, style: AppStyles.caption),
                ],
              ),
            ),
            StatusPill(
                label: active ? 'Active' : 'Inactive',
                color: active ? AppColors.kodiGreen : AppColors.danger),
          ],
        ),
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final PaymentRecord payment;
  final VoidCallback onTap;
  final VoidCallback? onReminder;

  const _PaymentItem({
    required this.payment,
    required this.onTap,
    this.onReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: onTap,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(payment.tenantName.characters.first)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.tenantName, style: _titleStyle),
                      Text('${payment.unit} - ${payment.property}',
                          style: AppStyles.caption),
                      const SizedBox(height: 3),
                      Text(
                        payment.isPaid
                            ? 'Paid ${payment.paidAt}'
                            : 'Due ${payment.dueDate} - ${payment.daysLate} days late',
                        style: AppStyles.caption,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_money(payment.amount), style: _smallBoldStyle),
                    const SizedBox(height: 5),
                    StatusPill(
                      label: payment.status,
                      color: _paymentStatusColor(payment.status),
                    ),
                  ],
                ),
              ],
            ),
            if (payment.isPending && onReminder != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReminder,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Send Reminder'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.caption),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.kodiGreen.withValues(alpha: 0.16),
      onSelected: (_) => onTap(),
    );
  }
}

class _TenantPaymentHistory extends StatelessWidget {
  final String month;
  final String date;

  const _TenantPaymentHistory({
    required this.month,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(month, style: _titleStyle),
                const SizedBox(height: 5),
                const Row(
                  children: [
                    Text('KSh 25,000',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(width: 10),
                    StatusPill(label: 'Paid', color: AppColors.kodiGreen),
                  ],
                ),
              ],
            ),
          ),
          Text(date, style: AppStyles.caption),
        ],
      ),
    );
  }
}

class _IssueListItem extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final Color color;

  const _IssueListItem({
    required this.title,
    required this.location,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: () => _showSnack(context, '$title details opened'),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.build_circle_outlined,
                  color: AppColors.kodiOrange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 3),
                  Text(location, style: AppStyles.caption),
                ],
              ),
            ),
            StatusPill(label: status, color: color),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String title;
  final String body;

  const _NoticeCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: () => _showSnack(context, title),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.campaign_outlined, color: AppColors.kodiBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 4),
                  Text(body, style: AppStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String location;
  final String type;

  const _AlertCard({
    required this.title,
    required this.location,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final emergency = type == 'Emergency';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: () => _showSnack(context, '$title assigned'),
        child: Row(
          children: [
            Icon(emergency ? Icons.warning_rounded : Icons.info_outline_rounded,
                color: emergency ? AppColors.danger : AppColors.kodiOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 3),
                  Text(location, style: AppStyles.caption),
                ],
              ),
            ),
            StatusPill(
                label: type,
                color: emergency ? AppColors.danger : AppColors.kodiOrange),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationData data;

  const _NotificationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: () => _showSnack(context, data.title),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(data.title, style: _titleStyle)),
                      StatusPill(label: data.status, color: data.color),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(data.body, style: AppStyles.caption),
                  const SizedBox(height: 6),
                  Text(data.time, style: AppStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppStyles.caption),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.kodiGreen,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentRecord {
  final String tenantName;
  final String tenantPhone;
  final String tenantEmail;
  final String unit;
  final String property;
  final int amount;
  final String status;
  final String method;
  final String transactionRef;
  final String dueDate;
  final String? paidAt;
  final String createdAt;
  final String updatedAt;
  final int daysLate;

  const PaymentRecord({
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.unit,
    required this.property,
    required this.amount,
    required this.status,
    required this.method,
    required this.transactionRef,
    required this.dueDate,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
    required this.daysLate,
  });

  bool get isPaid => status == 'Paid';
  bool get isPending => status == 'Pending';
}

class PropertyData {
  final String name;
  final String location;
  final String units;
  final String occupied;
  final String monthlyIncome;

  const PropertyData(
      this.name, this.location, this.units, this.occupied, this.monthlyIncome);
}

class _NotificationData {
  final String type;
  final String title;
  final String body;
  final String status;
  final String time;
  final Color color;
  final IconData icon;

  const _NotificationData({
    required this.type,
    required this.title,
    required this.body,
    required this.status,
    required this.time,
    required this.color,
    required this.icon,
  });
}

class _TaskData {
  final String title;
  final String location;
  final String priority;

  const _TaskData(this.title, this.location, this.priority);
}

class _DetailRowData {
  final String label;
  final String value;

  const _DetailRowData(this.label, this.value);
}

class _PropertyPaymentBreakdown {
  final String propertyName;
  final int units;
  final int collected;
  final int pending;

  const _PropertyPaymentBreakdown({
    required this.propertyName,
    required this.units,
    required this.collected,
    required this.pending,
  });
}

String _money(int amount) {
  return 'KSh ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

Color _paymentStatusColor(String status) {
  switch (status) {
    case 'Paid':
      return AppColors.kodiGreen;
    case 'Pending':
      return AppColors.kodiOrange;
    case 'Overdue':
      return AppColors.danger;
    default:
      return AppColors.muted;
  }
}

List<_PropertyPaymentBreakdown> _buildPropertyBreakdown(List<PaymentRecord> payments) {
  final map = <String, _PropertyPaymentBreakdown>{};
  for (final payment in payments) {
    final propertyName = payment.property;
    final existing = map[propertyName];
    if (existing != null) {
      map[propertyName] = _PropertyPaymentBreakdown(
        propertyName: propertyName,
        units: existing.units,
        collected: existing.collected + (payment.isPaid ? payment.amount : 0),
        pending: existing.pending + (payment.isPending ? payment.amount : 0),
      );
    } else {
      map[propertyName] = _PropertyPaymentBreakdown(
        propertyName: propertyName,
        units: 1,
        collected: payment.isPaid ? payment.amount : 0,
        pending: payment.isPending ? payment.amount : 0,
      );
    }
  }
  return map.values.toList();
}

const _titleStyle = TextStyle(
  color: AppColors.textDark,
  fontWeight: FontWeight.w800,
);

const _smallBoldStyle = TextStyle(
  color: AppColors.textDark,
  fontSize: 12,
  fontWeight: FontWeight.w800,
);

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
