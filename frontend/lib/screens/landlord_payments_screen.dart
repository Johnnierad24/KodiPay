import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/payment_record.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'payment_detail_screen.dart';
import 'payment_report_screen.dart';

class LandlordPaymentsScreen extends StatefulWidget {
  const LandlordPaymentsScreen({super.key});

  @override
  State<LandlordPaymentsScreen> createState() => _LandlordPaymentsScreenState();
}

class _LandlordPaymentsScreenState extends State<LandlordPaymentsScreen> {
  final ApiService _api = ApiService();
  String _filter = 'All';
  Future<List<PaymentRecord>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<List<PaymentRecord>> _fetch() async {
    final tenancyResp = await _api.get('/tenancies');
    if (tenancyResp.statusCode != 200) {
      throw Exception('Could not load tenancies (${tenancyResp.statusCode})');
    }
    final tenancies = (jsonDecode(tenancyResp.body) as List<dynamic>)
        .map((item) =>
            TenancyRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    final records = <PaymentRecord>[];
    for (final tenancy in tenancies) {
      List<Map<String, dynamic>> payments = const [];
      try {
        final paymentsResp =
            await _api.get('/payments/tenancy/${tenancy.id}');
        if (paymentsResp.statusCode == 200) {
          payments = (jsonDecode(paymentsResp.body) as List<dynamic>)
              .cast<Map<String, dynamic>>();
        }
      } catch (_) {
        // Skip tenancies whose payment fetch fails; show pending fallback.
      }

      if (payments.isEmpty) {
        if (tenancy.status == 'active') {
          records.add(PaymentRecord.pendingFor(tenancy));
        }
        continue;
      }

      final now = DateTime.now();
      final hasPaymentThisMonth = payments.any((p) {
        final date = parseDate(p['payment_date']) ??
            parseDate(p['created_at']);
        return date != null &&
            date.year == now.year &&
            date.month == now.month;
      });

      for (final payment in payments) {
        records.add(PaymentRecord.fromTenancyAndPayment(tenancy, payment));
      }

      // Only synthesize a "Pending" row when there is no payment at all
      // this month — otherwise the existing pending payment row already
      // represents this month's rent.
      if (!hasPaymentThisMonth && tenancy.status == 'active') {
        records.add(PaymentRecord.pendingFor(tenancy));
      }
    }

    records.sort((a, b) {
      if (a.isPending && !b.isPending) return -1;
      if (!a.isPending && b.isPending) return 1;
      return 0;
    });
    return records;
  }

  Future<void> _sendPaymentReminder(PaymentRecord payment) async {
    if (payment.tenancyId == null) {
      showSnack(context, 'Missing tenancy info — cannot send reminder.');
      return;
    }
    try {
      final response = await _api.post('/notifications/rent-reminder', {
        'tenancy_id': payment.tenancyId,
        'message':
            'Dear ${payment.tenantName}, your rent of ${money(payment.amount)} for ${payment.property} (Unit ${payment.unit}) is overdue by ${payment.daysLate} days. Please make payment to avoid penalties.',
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        showSnack(context, 'Reminder sent to ${payment.tenantName}.');
      } else {
        showSnack(context,
            'Reminder failed (${response.statusCode}) for ${payment.tenantName}.');
      }
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'Reminder failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Payments',
      accentColor: AppColors.kodiGreen,
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<PaymentRecord>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(30),
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.error_outline_rounded,
                      size: 56, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              );
            }
            final allPayments = snapshot.data ?? const <PaymentRecord>[];
            final visiblePayments = _filter == 'All'
                ? allPayments
                : allPayments
                    .where((payment) => payment.status == _filter)
                    .toList();
            final totalCollected = allPayments
                .where((payment) => payment.isPaid)
                .fold<int>(0, (sum, payment) => sum + payment.amount);
            final totalPending = allPayments
                .where((payment) => payment.isPending)
                .fold<int>(0, (sum, payment) => sum + payment.amount);

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    FilterChipWidget(
                        label: 'All',
                        selected: _filter == 'All',
                        onTap: () => setState(() => _filter = 'All')),
                    const SizedBox(width: 8),
                    FilterChipWidget(
                        label: 'Paid',
                        selected: _filter == 'Paid',
                        onTap: () => setState(() => _filter = 'Paid')),
                    const SizedBox(width: 8),
                    FilterChipWidget(
                        label: 'Pending',
                        selected: _filter == 'Pending',
                        onTap: () => setState(() => _filter = 'Pending')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: MetricCard(
                            label: 'Total Received',
                            value: money(totalCollected),
                            color: AppColors.kodiGreen)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: MetricCard(
                            label: 'Pending',
                            value: money(totalPending),
                            color: AppColors.kodiOrange)),
                  ],
                ),
                const SizedBox(height: 16),
                if (visiblePayments.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No payments found',
                    subtitle: 'Try a different payment filter.',
                  )
                else
                  ...visiblePayments.map(
                    (payment) => PaymentItem(
                      payment: payment,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PaymentDetailScreen(payment: payment),
                        ),
                      ),
                      onReminder: payment.isPending && payment.tenancyId != null
                          ? () => _sendPaymentReminder(payment)
                          : null,
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: allPayments.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PaymentReportScreen(payments: allPayments),
                            ),
                          ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Report'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

