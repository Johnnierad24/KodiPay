import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../models/payment_record.dart';
import '../models/property_data.dart';
import '../models/maintenance_item.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'kodi_pay_logo.dart';
import 'dashboard_components.dart';

// ── Navigation Scaffold ─────────────────────────────────
class FeatureScaffold extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;
  final Widget? floatingActionButton;

  const FeatureScaffold({
    super.key,
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: child),
    );
  }
}

// ── Card / Tile Widgets ─────────────────────────────────
class TappableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const TappableCard({super.key, required this.child, this.onTap});

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

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const SettingsTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TappableCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.kodiBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle),
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

class DetailSection extends StatelessWidget {
  final String title;
  final List<DetailRowData> rows;
  const DetailSection({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 12),
          ...rows.map((row) => DetailRow(row: row)),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final DetailRowData row;
  const DetailRow({super.key, required this.row});

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
            child: Text(row.value, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class DetailRowData {
  final String label;
  final String value;
  const DetailRowData(this.label, this.value);
}

class DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const DetailChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textLight),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return TappableCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: AppColors.muted, size: 34),
            const SizedBox(height: 10),
            Text(title, style: titleStyle),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: AppStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ── Maintenance Widgets ─────────────────────────────────
class MaintenanceTag extends StatelessWidget {
  final String label;
  final Color color;
  const MaintenanceTag({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class MaintenanceTimelineRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final DateTime time;
  const MaintenanceTimelineRow({super.key, required this.icon, required this.color, required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${time.day}/${time.month}/${time.year} • ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}', style: AppStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Report Widgets (used in PaymentReportScreen + LandlordReportsScreen) ──
class ReportDocumentCard extends StatelessWidget {
  final Widget child;
  const ReportDocumentCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.kodiNavy.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: child,
    );
  }
}

class ReportBlock extends StatelessWidget {
  final String title;
  final Widget child;
  const ReportBlock({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class ReportInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const ReportInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppStyles.caption)),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: smallBoldStyle)),
        ],
      ),
    );
  }
}

class ReportSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const ReportSummaryCard({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppStyles.caption),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class ReportTableHeader extends StatelessWidget {
  final List<String> columns;
  const ReportTableHeader({super.key, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: columns.map((column) => Expanded(
          child: Text(column, style: const TextStyle(color: AppColors.textDark, fontSize: 11, fontWeight: FontWeight.w900)),
        )).toList(),
      ),
    );
  }
}

class ReportTableRow extends StatelessWidget {
  final List<String> cells;
  final Color statusColor;
  const ReportTableRow({super.key, required this.cells, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: cells.asMap().entries.map((entry) => Expanded(
          child: Text(
            entry.value, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: entry.key == cells.length - 2 ? statusColor : AppColors.textDark,
              fontSize: 11,
              fontWeight: entry.key == 0 ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class PaymentItem extends StatelessWidget {
  final PaymentRecord payment;
  final VoidCallback onTap;
  final VoidCallback? onReminder;
  const PaymentItem({super.key, required this.payment, required this.onTap, this.onReminder});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TappableCard(
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
                      Text(payment.tenantName, style: titleStyle),
                      Text('${payment.unit} - ${payment.property}', style: AppStyles.caption),
                      const SizedBox(height: 3),
                      Text(payment.isPaid ? 'Paid ${payment.paidAt}' : 'Due ${payment.dueDate} - ${payment.daysLate} days late', style: AppStyles.caption),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(money(payment.amount), style: smallBoldStyle),
                    const SizedBox(height: 5),
                    StatusPill(label: payment.status, color: paymentStatusColor(payment.status)),
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

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const MetricCard({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.caption),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const FilterChipWidget({super.key, required this.label, required this.selected, required this.onTap});

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

class PreferenceSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const PreferenceSwitch({super.key, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TappableCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppStyles.caption),
                ],
              ),
            ),
            Switch(value: value, activeThumbColor: AppColors.kodiGreen, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const LegendRow({super.key, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: titleStyle)),
        Text(value, style: smallBoldStyle),
      ],
    );
  }
}

// ── Payment Report Header Widgets ────────────────────────
class PaymentReportHeader extends StatelessWidget {
  final String generatedDate;
  final String period;
  const PaymentReportHeader({super.key, required this.generatedDate, required this.period});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18, runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const KodiPayLogo(iconSize: 38, fontSize: 18),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KodiPay', style: TextStyle(color: AppColors.kodiNavy, fontSize: 18, fontWeight: FontWeight.w900)),
            SizedBox(height: 3),
            Text('Pay Rent. Stay Worry-Free.', style: AppStyles.caption),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Payment Report', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Generated: $generatedDate', style: AppStyles.caption),
            Text('Period: $period', style: AppStyles.caption),
          ],
        ),
      ],
    );
  }
}

class LandlordReportInfo extends StatelessWidget {
  const LandlordReportInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportBlock(
      title: 'Landlord Information',
      child: Column(
        children: [
          ReportInfoRow(label: 'Landlord Name', value: 'James Mwangi'),
          ReportInfoRow(label: 'Email / Phone', value: 'james@kodipay.co.ke / 0700 000 111'),
          ReportInfoRow(label: 'Property Count', value: '3 properties'),
        ],
      ),
    );
  }
}

class PaymentReportSummary extends StatelessWidget {
  final int totalExpected;
  final int totalCollected;
  final int totalPending;
  final int collectionRate;
  const PaymentReportSummary({super.key, required this.totalExpected, required this.totalCollected, required this.totalPending, required this.collectionRate});

  @override
  Widget build(BuildContext context) {
    return ReportBlock(
      title: 'Summary',
      child: GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.15, mainAxisSpacing: 10, crossAxisSpacing: 10,
        children: [
          ReportSummaryCard(label: 'Total Expected', value: money(totalExpected), color: AppColors.kodiBlue),
          ReportSummaryCard(label: 'Collected', value: money(totalCollected), color: AppColors.kodiGreen),
          ReportSummaryCard(label: 'Pending', value: money(totalPending), color: AppColors.danger),
          ReportSummaryCard(label: 'Collection Rate', value: '$collectionRate%', color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class PropertyPaymentBreakdown {
  final String propertyName;
  final int units;
  final int collected;
  final int pending;
  const PropertyPaymentBreakdown({required this.propertyName, required this.units, required this.collected, required this.pending});
}

class PropertyBreakdownTable extends StatelessWidget {
  final List<PropertyPaymentBreakdown> rows;
  const PropertyBreakdownTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return ReportBlock(
      title: 'Property Breakdown',
      child: Column(
        children: [
          const ReportTableHeader(columns: ['Property', 'Units', 'Collected', 'Pending']),
          ...rows.map((row) => ReportTableRow(
            cells: [row.propertyName, row.units.toString(), money(row.collected), money(row.pending)],
            statusColor: row.pending > 0 ? AppColors.danger : AppColors.kodiGreen,
          )),
        ],
      ),
    );
  }
}

class DetailedPaymentTable extends StatelessWidget {
  final List<PaymentRecord> payments;
  const DetailedPaymentTable({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    return ReportBlock(
      title: 'Detailed Payment Table',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 760,
          child: Column(
            children: [
              const ReportTableHeader(columns: ['Tenant', 'Unit', 'Property', 'Amount', 'Status', 'Date']),
              ...payments.map((payment) => ReportTableRow(
                cells: [payment.tenantName, payment.unit, payment.property, money(payment.amount), payment.status, payment.paidAt ?? '-'],
                statusColor: paymentStatusColor(payment.status),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class ArrearsTable extends StatelessWidget {
  final List<PaymentRecord> payments;
  const ArrearsTable({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    return ReportBlock(
      title: 'Arrears Section',
      child: Column(
        children: [
          const ReportTableHeader(columns: ['Tenant', 'Unit', 'Amount Owed', 'Days Late']),
          if (payments.isEmpty)
            const Padding(padding: EdgeInsets.all(14), child: Text('No arrears for this period.', style: AppStyles.caption))
          else
            ...payments.map((payment) => ReportTableRow(
              cells: [payment.tenantName, payment.unit, money(payment.amount), '${payment.daysLate} days'],
              statusColor: AppColors.danger,
            )),
        ],
      ),
    );
  }
}

class ReportCharts extends StatelessWidget {
  final List<PropertyPaymentBreakdown> propertyRows;
  final int totalCollected;
  final int totalPending;
  const ReportCharts({super.key, required this.propertyRows, required this.totalCollected, required this.totalPending});

  @override
  Widget build(BuildContext context) {
    return ReportBlock(
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
                barGroups: propertyRows.asMap().entries.map((entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [BarChartRodData(toY: entry.value.collected / 1000, color: AppColors.kodiGreen, width: 22, borderRadius: BorderRadius.circular(5))],
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PaidPendingMiniChart(totalCollected: totalCollected, totalPending: totalPending),
        ],
      ),
    );
  }
}

class _PaidPendingMiniChart extends StatelessWidget {
  final int totalCollected;
  final int totalPending;
  const _PaidPendingMiniChart({required this.totalCollected, required this.totalPending});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 118, height: 118,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 30, sectionsSpace: 2,
              sections: [
                PieChartSectionData(value: totalCollected.toDouble(), color: AppColors.kodiGreen, title: 'Paid', radius: 28, titleStyle: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                PieChartSectionData(value: totalPending.toDouble(), color: AppColors.danger, title: 'Pending', radius: 28, titleStyle: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              LegendRow(color: AppColors.kodiGreen, label: 'Paid', value: money(totalCollected)),
              const SizedBox(height: 10),
              LegendRow(color: AppColors.danger, label: 'Pending', value: money(totalPending)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Report Section Widgets (used in LandlordReportsScreen) ──
class ReportFilters extends StatelessWidget {
  final String period;
  final String property;
  final String status;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onPropertyChanged;
  final ValueChanged<String> onStatusChanged;
  const ReportFilters({super.key, required this.period, required this.property, required this.status, required this.onPeriodChanged, required this.onPropertyChanged, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: titleStyle),
          const SizedBox(height: 12),
          ReportDropdown(label: 'Date Range', value: period, values: const ['Today', 'This Month', 'This Quarter', 'This Year'], onChanged: onPeriodChanged),
          const SizedBox(height: 10),
          ReportDropdown(label: 'Property', value: property, values: const ['All Properties', 'Sunview Apartments', 'Greenfield Heights', 'Lakeview Villas'], onChanged: onPropertyChanged),
          const SizedBox(height: 10),
          ReportDropdown(label: 'Status', value: status, values: const ['All', 'Paid', 'Pending', 'Overdue'], onChanged: onStatusChanged),
        ],
      ),
    );
  }
}

class ReportDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  const ReportDropdown({super.key, required this.label, required this.value, required this.values, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: (value) { if (value != null) onChanged(value); },
    );
  }
}

class ReportTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const ReportTypeSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const types = ['Income', 'Arrears', 'Property', 'Maintenance', 'Trends', 'Transactions'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(type),
            selected: selected == type,
            selectedColor: AppColors.kodiBlue.withValues(alpha: 0.14),
            labelStyle: TextStyle(color: selected == type ? AppColors.kodiBlue : AppColors.textDark, fontWeight: FontWeight.w700),
            onSelected: (_) => onChanged(type),
          ),
        )).toList(),
      ),
    );
  }
}

class ReportSummaryGrid extends StatelessWidget {
  final String reportType;
  const ReportSummaryGrid({super.key, required this.reportType});

  @override
  Widget build(BuildContext context) {
    final cards = switch (reportType) {
      'Arrears' => const [
        ReportMetric(label: 'Overdue Amount', value: 'KSh 75,000', color: AppColors.danger),
        ReportMetric(label: 'Tenants Overdue', value: '5', color: AppColors.kodiOrange),
        ReportMetric(label: 'Avg Days Late', value: '9', color: AppColors.kodiBlue),
      ],
      'Maintenance' => const [
        ReportMetric(label: 'Open Issues', value: '12', color: AppColors.kodiOrange),
        ReportMetric(label: 'Completed', value: '18', color: AppColors.kodiGreen),
        ReportMetric(label: 'Cost', value: 'KSh 38k', color: AppColors.kodiBlue),
      ],
      'Property' => const [
        ReportMetric(label: 'Best Property', value: 'Greenfield', color: AppColors.kodiGreen),
        ReportMetric(label: 'Occupancy', value: '94%', color: AppColors.kodiBlue),
        ReportMetric(label: 'Vacant Units', value: '6', color: AppColors.kodiOrange),
      ],
      _ => const [
        ReportMetric(label: 'Collected', value: 'KSh 245k', color: AppColors.kodiGreen),
        ReportMetric(label: 'Expected', value: 'KSh 320k', color: AppColors.kodiBlue),
        ReportMetric(label: 'Pending', value: 'KSh 75k', color: AppColors.kodiOrange),
      ],
    };
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.92, mainAxisSpacing: 10, crossAxisSpacing: 10,
      children: cards,
    );
  }
}

class ReportMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const ReportMetric({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppStyles.caption),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class IncomeTrendCard extends StatelessWidget {
  const IncomeTrendCard({super.key});

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
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28, interval: 1,
                  getTitlesWidget: (value, meta) {
                    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                    return Text(labels[index], style: AppStyles.caption);
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0, maxX: 4, minY: 0, maxY: 320,
            lineBarsData: [
              LineChartBarData(
                spots: const [FlSpot(0, 180), FlSpot(1, 210), FlSpot(2, 195), FlSpot(3, 245), FlSpot(4, 275)],
                isCurved: true, barWidth: 4, color: AppColors.kodiBlue,
                belowBarData: BarAreaData(show: true, color: AppColors.kodiBlue.withValues(alpha: 0.12)),
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaidVsPendingCard extends StatelessWidget {
  const PaidVsPendingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      title: 'Paid vs Pending',
      child: Row(
        children: [
          SizedBox(
            width: 132, height: 132,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3, centerSpaceRadius: 34,
                sections: [
                  PieChartSectionData(value: 77, color: AppColors.kodiGreen, title: '77%', radius: 32, titleStyle: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
                  PieChartSectionData(value: 23, color: AppColors.kodiOrange, title: '23%', radius: 32, titleStyle: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LegendRow(color: AppColors.kodiGreen, label: 'Paid', value: 'KSh 245,000'),
                SizedBox(height: 12),
                LegendRow(color: AppColors.kodiOrange, label: 'Pending', value: 'KSh 75,000'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PropertyIncomeBreakdown extends StatelessWidget {
  const PropertyIncomeBreakdown({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Per Property Breakdown',
      child: Column(
        children: [
          ReportDataRow(label: 'Sunview Apartments', value: 'KSh 250,000', status: '92% paid', color: AppColors.kodiGreen),
          ReportDivider(),
          ReportDataRow(label: 'Greenfield Heights', value: 'KSh 610,000', status: '96% paid', color: AppColors.kodiGreen),
          ReportDivider(),
          ReportDataRow(label: 'Lakeview Villas', value: 'KSh 180,000', status: '78% paid', color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class ArrearsReport extends StatelessWidget {
  final ValueChanged<String> onReminder;
  const ArrearsReport({super.key, required this.onReminder});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      title: 'Tenants With Unpaid Rent',
      child: Column(
        children: [
          _ArrearsRow(tenant: 'Peter Ochieng', unit: 'C3 - Lakeview Villas', amount: 'KSh 25,000', days: '12 days', onReminder: onReminder),
          const ReportDivider(),
          _ArrearsRow(tenant: 'Grace Njeri', unit: 'A1 - Sunview Apts', amount: 'KSh 30,000', days: '8 days', onReminder: onReminder),
          const ReportDivider(),
          _ArrearsRow(tenant: 'Brian Otieno', unit: 'B8 - Greenfield Hts', amount: 'KSh 20,000', days: '5 days', onReminder: onReminder),
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
  const _ArrearsRow({required this.tenant, required this.unit, required this.amount, required this.days, required this.onReminder});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tenant, style: titleStyle)),
              Text(amount, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900)),
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

class PropertyPerformanceReport extends StatelessWidget {
  const PropertyPerformanceReport({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Property Performance',
      child: Column(
        children: [
          ReportDataRow(label: 'Greenfield Heights', value: 'KSh 610,000', status: '25/32 occupied', color: AppColors.kodiGreen),
          ReportDivider(),
          ReportDataRow(label: 'Sunview Apartments', value: 'KSh 250,000', status: '10/12 occupied', color: AppColors.kodiBlue),
          ReportDivider(),
          ReportDataRow(label: 'Lakeview Villas', value: 'KSh 180,000', status: '8/10 occupied', color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class MaintenanceReport extends StatelessWidget {
  const MaintenanceReport({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Maintenance Costs & Issues',
      child: Column(
        children: [
          ReportDataRow(label: 'Plumbing', value: '6 issues', status: 'KSh 18,000', color: AppColors.kodiOrange),
          ReportDivider(),
          ReportDataRow(label: 'Electrical', value: '3 issues', status: 'KSh 12,500', color: AppColors.danger),
          ReportDivider(),
          ReportDataRow(label: 'Locks & Doors', value: '3 issues', status: 'KSh 7,500', color: AppColors.kodiBlue),
        ],
      ),
    );
  }
}

class TransactionReport extends StatelessWidget {
  const TransactionReport({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Transaction History',
      child: Column(
        children: [
          ReportDataRow(label: 'Mary Wanjiku', value: 'KSh 25,000', status: 'M-Pesa - Paid', color: AppColors.kodiGreen),
          ReportDivider(),
          ReportDataRow(label: 'John Kamau', value: 'KSh 20,000', status: 'Bank - Paid', color: AppColors.kodiGreen),
          ReportDivider(),
          ReportDataRow(label: 'Peter Ochieng', value: 'KSh 25,000', status: 'Pending', color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _ReportSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class ReportDataRow extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final Color color;
  const ReportDataRow({super.key, required this.label, required this.value, required this.status, required this.color});

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
                Text(label, style: titleStyle),
                const SizedBox(height: 4),
                Text(status, style: AppStyles.caption),
              ],
            ),
          ),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class ReportDivider extends StatelessWidget {
  const ReportDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.border);
  }
}

class ReportActions extends StatelessWidget {
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;
  final VoidCallback onSendReminders;
  const ReportActions({super.key, required this.onExportPdf, required this.onExportCsv, required this.onSendReminders});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: ElevatedButton.icon(onPressed: onExportPdf, icon: const Icon(Icons.picture_as_pdf_rounded), label: const Text('PDF'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: onExportCsv, icon: const Icon(Icons.table_chart_outlined), label: const Text('CSV'))),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(onPressed: onSendReminders, icon: const Icon(Icons.notifications_active_outlined), label: const Text('Send Arrears Reminders')),
        ),
      ],
    );
  }
}

// ── Notification Widgets ─────────────────────────────────
class NotificationApiCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onMarkRead;
  const NotificationApiCard({super.key, required this.item, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final palette = paletteForType(item.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: palette.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(palette.icon, color: palette.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.message, style: AppStyles.bodyMedium),
                ],
                const SizedBox(height: 6),
                Text(relativeTime(item.createdAt), style: AppStyles.caption),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mark as read',
            onPressed: onMarkRead,
            icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.kodiGreen),
          ),
        ],
      ),
    );
  }
}

class NotificationPalette {
  final Color color;
  final IconData icon;
  const NotificationPalette(this.color, this.icon);
}

NotificationPalette paletteForType(String type) {
  switch (type.toLowerCase()) {
    case 'reminder':
    case 'rent_reminder':
      return const NotificationPalette(AppColors.kodiBlue, Icons.sms_outlined);
    case 'maintenance':
      return const NotificationPalette(AppColors.kodiOrange, Icons.build_outlined);
    case 'payment':
    case 'mpesa':
      return const NotificationPalette(AppColors.kodiGreen, Icons.verified_outlined);
    case 'alert':
    case 'warning':
      return const NotificationPalette(AppColors.danger, Icons.warning_amber_rounded);
    default:
      return const NotificationPalette(AppColors.kodiNavy, Icons.notifications_active_outlined);
  }
}

String labelForType(String type) {
  switch (type.toLowerCase()) {
    case 'reminder':
    case 'rent_reminder':
    case 'sms_reminder':
      return 'Rent Reminder';
    case 'maintenance':
      return 'Maintenance Update';
    case 'announcement':
      return 'Announcement';
    case 'payment':
    case 'mpesa':
      return 'Payment';
    case 'alert':
    case 'warning':
      return 'Alert';
    default:
      return 'Notice';
  }
}

// ── Property Group Header ────────────────────────────────
class PropertyGroupHeader extends StatelessWidget {
  final String name;
  final int count;
  final Color accent;
  const PropertyGroupHeader({super.key, required this.name, required this.count, this.accent = AppColors.kodiOrange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.apartment_rounded, color: accent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
          child: Text(count.toString(), style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

// ── GradientPanel / StatBox / ListPanel (kept for backward compat) ──
class GradientPanel extends StatelessWidget {
  final Color startColor;
  final Color endColor;
  final Widget child;
  const GradientPanel({super.key, required this.startColor, required this.endColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [startColor, endColor]), borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

class StatBox extends StatelessWidget {
  final String value;
  final String label;
  const StatBox({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}

class ListPanel extends StatelessWidget {
  final List<Widget> children;
  const ListPanel({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(children: children),
    );
  }
}

// ── Contact Row ─────────────────────────────────────────
class ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const ContactRow({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppColors.kodiBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600))),
            const Icon(Icons.copy_rounded, color: AppColors.muted, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Helper Functions ─────────────────────────────────────
const titleStyle = TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800);

const smallBoldStyle = TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w800);

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String formatKsh(num value) {
  final whole = value.toInt();
  final formatted = whole.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match.group(1)},',
  );
  return formatted;
}

int toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

num toNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return num.tryParse(value.toString()) ?? 0;
}

String money(int amount) {
  return 'KSh ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

Color paymentStatusColor(String status) {
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

String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}

String capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

String capitalizeWord(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

Color maintenanceStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return AppColors.kodiGreen;
    case 'in_progress':
      return AppColors.kodiBlue;
    case 'cancelled':
      return AppColors.muted;
    default:
      return AppColors.kodiOrange;
  }
}

String maintenanceStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'in_progress':
      return 'In Progress';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Pending';
  }
}

Color maintenancePriorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'emergency':
      return AppColors.danger;
    case 'urgent':
    case 'high':
      return AppColors.kodiOrange;
    case 'low':
      return AppColors.muted;
    default:
      return AppColors.kodiBlue;
  }
}

Map<String, List<MaintenanceItem>> groupByProperty(List<MaintenanceItem> items) {
  final groups = <String, List<MaintenanceItem>>{};
  for (final item in items) {
    final key = item.propertyName.trim().isEmpty ? 'Unassigned' : item.propertyName;
    groups.putIfAbsent(key, () => []).add(item);
  }
  return groups;
}

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  try { return DateTime.parse(value.toString()); } catch (_) { return null; }
}

String decodeError(String body) {
  try {
    final data = jsonDecode(body);
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (data is Map && data['errors'] is List) {
      final list = data['errors'] as List;
      if (list.isNotEmpty && list.first is Map) {
        final first = list.first as Map;
        return (first['msg'] ?? 'Validation failed').toString();
      }
    }
  } catch (_) {}
  return 'Request failed';
}

String csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

List<PropertyPaymentBreakdown> buildPropertyBreakdown(List<PaymentRecord> payments) {
  final map = <String, PropertyPaymentBreakdown>{};
  for (final payment in payments) {
    final propertyName = payment.property;
    final existing = map[propertyName];
    if (existing != null) {
      map[propertyName] = PropertyPaymentBreakdown(
        propertyName: propertyName,
        units: existing.units,
        collected: existing.collected + (payment.isPaid ? payment.amount : 0),
        pending: existing.pending + (payment.isPending ? payment.amount : 0),
      );
    } else {
      map[propertyName] = PropertyPaymentBreakdown(
        propertyName: propertyName,
        units: 1,
        collected: payment.isPaid ? payment.amount : 0,
        pending: payment.isPending ? payment.amount : 0,
      );
    }
  }
  return map.values.toList();
}

// ── Sheets ───────────────────────────────────────────────
Future<bool?> showPropertySheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _AddPropertySheet(),
  );
}

class _AddPropertySheet extends StatefulWidget {
  const _AddPropertySheet();
  @override
  State<_AddPropertySheet> createState() => _AddPropertySheetState();
}

class _AddPropertySheetState extends State<_AddPropertySheet> {
  final ApiService _api = ApiService();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _description = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      setState(() => _error = 'Name and address are required');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      final response = await _api.post('/properties', {
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
      });
      if (response.statusCode >= 400) {
        setState(() { _submitting = false; _error = decodeError(response.body); });
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _submitting = false; _error = 'Failed to save property: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Property', style: AppStyles.heading2),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Property name')),
            const SizedBox(height: 12),
            TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address / Location')),
            const SizedBox(height: 12),
            TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'Description (optional)')),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Text('Save Property'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showTenantSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _AddTenantSheet(),
  );
}

class _VacantUnit {
  final int id;
  final String unitNumber;
  final num rentAmount;
  final String status;
  const _VacantUnit({required this.id, required this.unitNumber, required this.rentAmount, required this.status});
  factory _VacantUnit.fromJson(Map<String, dynamic> json) {
    final rent = json['rent_amount'];
    return _VacantUnit(
      id: json['id'] as int,
      unitNumber: (json['unit_number'] ?? '').toString(),
      rentAmount: rent is num ? rent : num.tryParse(rent?.toString() ?? '') ?? 0,
      status: (json['status'] ?? 'vacant').toString(),
    );
  }
}

class _PasswordBox extends StatelessWidget {
  final String password;
  const _PasswordBox({required this.password});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(password, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark)),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: password));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
            },
          ),
        ],
      ),
    );
  }
}

class _AddTenantSheet extends StatefulWidget {
  const _AddTenantSheet();
  @override
  State<_AddTenantSheet> createState() => _AddTenantSheetState();
}

class _AddTenantSheetState extends State<_AddTenantSheet> {
  final ApiService _api = ApiService();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  Future<List<PropertyData>>? _propertiesFuture;
  PropertyData? _selectedProperty;
  List<_VacantUnit> _vacantUnits = const [];
  bool _loadingUnits = false;
  _VacantUnit? _selectedUnit;
  DateTime _startDate = DateTime.now();
  bool _submitting = false;
  String? _error;

  @override
  void initState() { super.initState(); _propertiesFuture = _loadProperties(); }

  @override
  void dispose() {
    _firstName.dispose(); _lastName.dispose(); _email.dispose(); _phone.dispose();
    super.dispose();
  }

  Future<List<PropertyData>> _loadProperties() async {
    final response = await _api.get('/properties');
    if (response.statusCode != 200) throw Exception('Could not load properties (${response.statusCode})');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => PropertyData.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> _loadUnitsFor(int propertyId) async {
    setState(() { _loadingUnits = true; _vacantUnits = const []; _selectedUnit = null; });
    try {
      final response = await _api.get('/units/property/$propertyId');
      if (response.statusCode != 200) throw Exception('Could not load units');
      final data = jsonDecode(response.body) as List<dynamic>;
      final vacant = data.map((item) => _VacantUnit.fromJson(item as Map<String, dynamic>)).where((u) => u.status == 'vacant').toList();
      if (!mounted) return;
      setState(() { _vacantUnits = vacant; _loadingUnits = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingUnits = false; _error = 'Failed to load units: $e'; });
    }
  }

  Future<void> _submit() async {
    if (_selectedProperty == null) { setState(() => _error = 'Pick a property'); return; }
    if (_selectedUnit == null) { setState(() => _error = 'Pick a vacant unit'); return; }
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) { setState(() => _error = 'Tenant name is required'); return; }
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) { setState(() => _error = 'A valid email is required'); return; }
    setState(() { _submitting = true; _error = null; });
    try {
      final response = await _api.post('/tenancies/with-new-tenant', {
        'unit_id': _selectedUnit!.id,
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        'start_date': _startDate.toIso8601String().split('T').first,
      });
      if (response.statusCode >= 400) {
        setState(() { _submitting = false; _error = decodeError(response.body); });
        return;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final tempPassword = body['temp_password'] as String?;
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final rootContext = navigator.context;
      final tenantName = '${_firstName.text.trim()} ${_lastName.text.trim()}';
      navigator.pop(true);
      if (tempPassword != null) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!rootContext.mounted) return;
        await showDialog<void>(
          context: rootContext,
          builder: (ctx) => AlertDialog(
            title: const Text('Tenant added'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$tenantName can now log in with:'),
                const SizedBox(height: 12),
                _PasswordBox(password: tempPassword),
                const SizedBox(height: 12),
                const Text('Share this with the tenant. They can change it via "Forgot password" on the login screen.', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _submitting = false; _error = 'Failed to add tenant: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Tenant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textDark)),
            const SizedBox(height: 16),
            FutureBuilder<List<PropertyData>>(
              future: _propertiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) return Text(snapshot.error.toString(), style: const TextStyle(color: AppColors.danger));
                final properties = snapshot.data ?? const <PropertyData>[];
                if (properties.isEmpty) return const Text('No properties yet. Add a property first.', style: TextStyle(color: AppColors.textLight));
                return DropdownButtonFormField<PropertyData>(
                  initialValue: _selectedProperty, isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Property'),
                  items: properties.map((p) => DropdownMenuItem(value: p, child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (value) { setState(() => _selectedProperty = value); if (value?.id != null) _loadUnitsFor(value!.id!); },
                );
              },
            ),
            const SizedBox(height: 12),
            if (_loadingUnits)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator())
            else if (_selectedProperty != null && _vacantUnits.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No vacant units in this property. Add a unit first.', style: TextStyle(color: AppColors.textLight)))
            else if (_vacantUnits.isNotEmpty)
              DropdownButtonFormField<_VacantUnit>(
                initialValue: _selectedUnit, isExpanded: true,
                decoration: const InputDecoration(labelText: 'Vacant unit'),
                items: _vacantUnits.map((u) => DropdownMenuItem(value: u, child: Text('Unit ${u.unitNumber} • KSh ${formatKsh(u.rentAmount)}/mo'))).toList(),
                onChanged: (value) => setState(() => _selectedUnit = value),
              ),
            const SizedBox(height: 12),
            TextField(controller: _firstName, decoration: const InputDecoration(labelText: 'First name')),
            const SizedBox(height: 12),
            TextField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last name')),
            const SizedBox(height: 12),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setState(() => _startDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Start date'),
                child: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}', style: const TextStyle(color: AppColors.textDark)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Text('Save Tenant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showIssueSheet(BuildContext context, {required int unitId}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _ReportIssueSheet(unitId: unitId),
  );
}

class _ReportIssueSheet extends StatefulWidget {
  final int unitId;
  const _ReportIssueSheet({required this.unitId});
  @override
  State<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<_ReportIssueSheet> {
  final ApiService _api = ApiService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customPriorityController = TextEditingController();
  String _category = 'plumbing';
  String _urgency = 'urgent';
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose(); _descriptionController.dispose(); _customPriorityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a title and a description.')));
      return;
    }
    String priorityToSend = _urgency;
    String descriptionToSend = description;
    if (_urgency == 'other') {
      final custom = _customPriorityController.text.trim();
      if (custom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Describe the urgency in the "Other" field, or pick Emergency / Urgent.')));
        return;
      }
      priorityToSend = 'medium';
      descriptionToSend = 'Urgency note: $custom\n\n$description';
    }
    setState(() => _submitting = true);
    try {
      final response = await _api.post('/maintenance', {
        'unit_id': widget.unitId,
        'title': title,
        'description': descriptionToSend,
        'category': _category,
        'priority': priorityToSend,
      });
      if (!mounted) return;
      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue reported.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report issue (${response.statusCode}).')));
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report issue: $e')));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report Maintenance Issue', style: AppStyles.heading2),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title (e.g. Leaking sink)', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            const Text('Category', style: AppStyles.caption),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _category, isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'electrical', child: Text('Electrical')),
                DropdownMenuItem(value: 'structural', child: Text('Structural (walls, doors, windows)')),
                DropdownMenuItem(value: 'plumbing', child: Text('Plumbing')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) { if (value != null) setState(() => _category = value); },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            const Text('Urgency', style: AppStyles.caption),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _urgency, isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'emergency', child: Text('Emergency (fire, flood, electrical failure)')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent (lighting replacement, minor leak)')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) { if (value != null) setState(() => _urgency = value); },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            if (_urgency == 'other') ...[
              const SizedBox(height: 12),
              TextField(controller: _customPriorityController, decoration: const InputDecoration(labelText: 'Describe the urgency', border: OutlineInputBorder())),
            ],
            const SizedBox(height: 14),
            TextField(controller: _descriptionController, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'Describe the issue', border: OutlineInputBorder(), alignLabelWithHint: true)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Submitting...' : 'Submit Issue'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiBlue, foregroundColor: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showReminderSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send Reminder', style: AppStyles.heading2),
              const SizedBox(height: 16),
              TextField(decoration: const InputDecoration(labelText: 'Tenant or Unit')),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: 'Message'), minLines: 3, maxLines: 5),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); showSnack(context, 'Reminder queued.'); },
                  child: const Text('Send Reminder'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool?> showAnnouncementSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _AnnouncementSheet(),
  );
}

class _AnnouncementSheet extends StatefulWidget {
  const _AnnouncementSheet();
  @override
  State<_AnnouncementSheet> createState() => _AnnouncementSheetState();
}

class _AnnouncementSheetState extends State<_AnnouncementSheet> {
  final ApiService _api = ApiService();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  List<PropertyData> _properties = const [];
  int? _propertyId;
  bool _loadingProperties = true;
  bool _submitting = false;

  @override
  void initState() { super.initState(); _loadProperties(); }

  @override
  void dispose() { _titleController.dispose(); _messageController.dispose(); super.dispose(); }

  Future<void> _loadProperties() async {
    try {
      final response = await _api.get('/properties');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (!mounted) return;
        setState(() { _properties = data.map((item) => PropertyData.fromJson(item as Map<String, dynamic>)).toList(); _loadingProperties = false; });
      } else { if (!mounted) return; setState(() => _loadingProperties = false); }
    } catch (_) { if (!mounted) return; setState(() => _loadingProperties = false); }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a title and a message.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{'title': title, 'message': message};
      if (_propertyId != null) body['property_id'] = _propertyId;
      final response = await _api.post('/notifications/announcement', body);
      if (!mounted) return;
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final recipients = data['recipients'] ?? 0;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement sent to $recipients tenant(s).')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send announcement (${response.statusCode})')));
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send announcement: $e')));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Post Announcement', style: AppStyles.heading2),
            const SizedBox(height: 6),
            const Text('Every active tenant of the chosen property — or all of your tenants — will see this in their Notices.', style: AppStyles.caption),
            const SizedBox(height: 16),
            const Text('Audience', style: AppStyles.caption),
            const SizedBox(height: 6),
            if (_loadingProperties)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<int?>(
                initialValue: _propertyId, isExpanded: true,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All my tenants')),
                  for (final property in _properties)
                    if (property.id != null)
                      DropdownMenuItem<int?>(value: property.id, child: Text(property.name)),
                ],
                onChanged: (value) => setState(() => _propertyId = value),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            const SizedBox(height: 14),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _messageController, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder(), alignLabelWithHint: true)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.campaign_outlined),
                label: Text(_submitting ? 'Sending...' : 'Send Announcement'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiGreen, foregroundColor: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Caretaker Sheet ──────────────────────────────────
class AddCaretakerSheet extends StatefulWidget {
  const AddCaretakerSheet();
  @override
  State<AddCaretakerSheet> createState() => AddCaretakerSheetState();
}

class AddCaretakerSheetState extends State<AddCaretakerSheet> {
  final ApiService _api = ApiService();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;
  String? _tempPassword;
  List<PropertyData> _properties = const [];
  int? _propertyId;
  String? _selectedPropertyName;
  bool _loadingProperties = true;

  @override
  void initState() { super.initState(); _loadProperties(); }

  @override
  void dispose() {
    _emailController.dispose(); _firstNameController.dispose(); _lastNameController.dispose(); _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      final response = await _api.get('/properties');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _properties = data.map((item) => PropertyData.fromJson(item as Map<String, dynamic>)).where((p) => p.id != null).toList();
          _loadingProperties = false;
          if (_properties.length == 1) { _propertyId = _properties.first.id; _selectedPropertyName = _properties.first.name; }
        });
      } else { setState(() => _loadingProperties = false); }
    } catch (_) { if (!mounted) return; setState(() => _loadingProperties = false); }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    if (_propertyId == null) { showSnack(context, 'Pick a property first.'); return; }
    if (email.isEmpty) { showSnack(context, 'Email is required.'); return; }
    setState(() => _submitting = true);
    try {
      final response = await _api.post('/caretakers', {
        'property_id': _propertyId,
        'email': email,
        if (firstName.isNotEmpty) 'first_name': firstName,
        if (lastName.isNotEmpty) 'last_name': lastName,
        if (phone.isNotEmpty) 'phone': phone,
      });
      if (!mounted) return;
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tempPassword = data['temp_password']?.toString();
        if (tempPassword != null && tempPassword.isNotEmpty) {
          setState(() { _tempPassword = tempPassword; _submitting = false; });
        } else {
          Navigator.pop(context, true);
          showSnack(context, 'Caretaker added.');
        }
      } else {
        Map<String, dynamic>? data;
        try { data = jsonDecode(response.body) as Map<String, dynamic>; } catch (_) {}
        setState(() => _submitting = false);
        showSnack(context, data?['error']?.toString() ?? 'Failed to add caretaker (${response.statusCode}).');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showSnack(context, 'Failed to add caretaker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tempPassword = _tempPassword;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tempPassword != null) ...[
              const Text('Caretaker invited', style: AppStyles.heading2),
              const SizedBox(height: 8),
              Text('Share this temporary password with ${_emailController.text.trim()}. They should change it after first sign-in.', style: AppStyles.caption),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kodiGreen)),
                child: Text(tempPassword, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async { await Clipboard.setData(ClipboardData(text: tempPassword)); if (!context.mounted) return; showSnack(context, 'Password copied'); },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiGreen, foregroundColor: AppColors.white),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text('Add Caretaker', style: AppStyles.heading2),
              const SizedBox(height: 6),
              Text(
                _selectedPropertyName == null
                    ? 'Pick the property this caretaker will handle, then enter their email. If they already have a KodiPay caretaker account we link them; otherwise we create one and give you a temporary password.'
                    : 'Assigning to "$_selectedPropertyName". You can repeat this for other properties.',
                style: AppStyles.caption,
              ),
              const SizedBox(height: 16),
              const Text('Property', style: AppStyles.caption),
              const SizedBox(height: 6),
              if (_loadingProperties)
                const LinearProgressIndicator()
              else if (_properties.isEmpty)
                const Text('You have no properties yet. Add one first, then come back here.', style: AppStyles.caption)
              else
                DropdownButtonFormField<int>(
                  initialValue: _propertyId, isExpanded: true,
                  items: [for (final p in _properties) if (p.id != null) DropdownMenuItem<int>(value: p.id, child: Text(p.name))],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() { _propertyId = value; _selectedPropertyName = _properties.firstWhere((p) => p.id == value).name; });
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              const SizedBox(height: 12),
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First name', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last name', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 6),
              const Text('Name fields are required only if no account exists for this email yet.', style: AppStyles.caption),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(_submitting ? 'Adding...' : 'Add caretaker'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiGreen, foregroundColor: AppColors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Profile Sheets ───────────────────────────────────────
class EditProfileSheet extends StatefulWidget {
  final Color accentColor;
  const EditProfileSheet({super.key, required this.accentColor});
  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _firstNameController.text = user?.firstName ?? '';
    _lastNameController.text = user?.lastName ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose(); _lastNameController.dispose(); _emailController.dispose(); _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      showSnack(context, 'First name, last name, and email are required.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showSnack(context, 'Enter a valid email address.');
      return;
    }
    setState(() => _submitting = true);
    final success = await context.read<AuthProvider>().updateProfile(firstName: firstName, lastName: lastName, email: email, phone: phone);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) { Navigator.pop(context, true); showSnack(context, 'Profile updated.'); }
    else { showSnack(context, 'Failed to update profile.'); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit profile', style: AppStyles.heading2),
            const SizedBox(height: 6),
            const Text('Update your name, email, or phone number.', style: AppStyles.caption),
            const SizedBox(height: 16),
            TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(_submitting ? 'Saving...' : 'Save changes'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiGreen, foregroundColor: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordSheet extends StatefulWidget {
  final Color accentColor;
  const ChangePasswordSheet({super.key, required this.accentColor});
  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final ApiService _api = ApiService();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _submitting = false;

  @override
  void dispose() {
    _currentController.dispose(); _newController.dispose(); _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;
    if (current.isEmpty || next.isEmpty || confirm.isEmpty) { showSnack(context, 'Fill in all three fields.'); return; }
    if (next.length < 6) { showSnack(context, 'New password must be at least 6 characters.'); return; }
    if (next != confirm) { showSnack(context, 'New password and confirmation do not match.'); return; }
    if (next == current) { showSnack(context, 'New password must be different from the current one.'); return; }
    setState(() => _submitting = true);
    try {
      final response = await _api.post('/auth/change-password', {'current_password': current, 'new_password': next});
      if (!mounted) return;
      if (response.statusCode == 200) { Navigator.pop(context, true); showSnack(context, 'Password updated.'); return; }
      Map<String, dynamic>? data;
      try { data = jsonDecode(response.body) as Map<String, dynamic>; } catch (_) {}
      setState(() => _submitting = false);
      showSnack(context, data?['error']?.toString() ?? 'Failed to change password (${response.statusCode}).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showSnack(context, 'Failed to change password: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change password', style: AppStyles.heading2),
            const SizedBox(height: 6),
            const Text('Set a new password using your current one. You will stay signed in.', style: AppStyles.caption),
            const SizedBox(height: 16),
            TextField(controller: _currentController, obscureText: !_showCurrent, decoration: InputDecoration(labelText: 'Current password', border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(_showCurrent ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _showCurrent = !_showCurrent)))),
            const SizedBox(height: 12),
            TextField(controller: _newController, obscureText: !_showNew, decoration: InputDecoration(labelText: 'New password', border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(_showNew ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _showNew = !_showNew)))),
            const SizedBox(height: 12),
            TextField(controller: _confirmController, obscureText: !_showConfirm, decoration: InputDecoration(labelText: 'Confirm new password', border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(_showConfirm ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _showConfirm = !_showConfirm)))),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.lock_reset_rounded),
                label: Text(_submitting ? 'Updating...' : 'Update password'),
                style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor, foregroundColor: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Emergency Card ─────────────────────────────────────
class CaretakerEmergencyCard extends StatelessWidget {
  final MaintenanceItem item;
  final VoidCallback onTap;
  const CaretakerEmergencyCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TappableCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_rounded, color: AppColors.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: titleStyle),
                const SizedBox(height: 3),
                Text(
                  item.unitNumber.isEmpty
                      ? item.propertyName
                      : '${item.propertyName} • Unit ${item.unitNumber}',
                  style: AppStyles.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  relativeTime(item.createdAt),
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
          const StatusPill(label: 'Emergency', color: AppColors.danger),
        ],
      ),
    );
  }
}
