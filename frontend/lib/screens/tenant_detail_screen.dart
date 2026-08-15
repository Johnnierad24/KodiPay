import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/payment_record.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'documents_screen.dart';

class TenantDetailScreen extends StatefulWidget {
  final TenancyRecord tenancy;
  const TenantDetailScreen({super.key, required this.tenancy});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  final ApiService _api = ApiService();
  Future<List<_PaymentSummary>>? _paymentsFuture;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _loadPayments();
  }

  Future<List<_PaymentSummary>> _loadPayments() async {
    final response = await _api.get('/payments/tenancy/${widget.tenancy.id}');
    if (response.statusCode != 200) return const [];
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => _PaymentSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _removeTenant() async {
    final t = widget.tenancy;
    final name = t.tenantName.isEmpty ? 'this tenant' : t.tenantName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.danger, size: 44),
        title: const Text('Remove tenant?'),
        content: Text(
          'This will end $name\'s tenancy on Unit ${t.unitNumber} of ${t.propertyName} '
          'and mark the unit vacant. Their payment history is kept. This cannot be undone from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _removing = true);
    try {
      final response = await _api.delete('/tenancies/${t.id}/end');
      if (!mounted) return;
      if (response.statusCode == 200) {
        showSnack(context, '$name removed from Unit ${t.unitNumber}.');
        Navigator.pop(context, true);
      } else {
        Map<String, dynamic>? data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        setState(() => _removing = false);
        showSnack(
          context,
          data?['error']?.toString() ??
              'Failed to remove tenant (${response.statusCode}).',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _removing = false);
      showSnack(context, 'Failed to remove tenant: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tenancy;
    final initials = t.tenantName.isNotEmpty
        ? t.tenantName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase()
        : '?';

    return FeatureScaffold(
      title: t.tenantName.isEmpty ? 'Tenant' : t.tenantName,
      accentColor: AppColors.kodiGreen,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      AppColors.kodiGreen.withValues(alpha: 0.12),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.kodiGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.tenantName.isEmpty ? 'Unnamed' : t.tenantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.propertyName} • Unit ${t.unitNumber}',
                  style: AppStyles.caption,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _DetailChip(
                      icon: Icons.phone_rounded,
                      label: t.tenantPhone?.isNotEmpty == true
                          ? t.tenantPhone!
                          : 'No phone',
                    ),
                    _DetailChip(
                      icon: Icons.email_rounded,
                      label: t.tenantEmail?.isNotEmpty == true
                          ? t.tenantEmail!
                          : 'No email',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                DetailRow(
                  row: DetailRowData(
                    'Status',
                    t.status.isEmpty
                        ? '—'
                        : t.status[0].toUpperCase() + t.status.substring(1),
                  ),
                ),
                const Divider(height: 16, color: AppColors.border),
                DetailRow(
                  row: DetailRowData(
                    'Monthly rent',
                    'KSh ${formatKsh(t.rentAmount)}',
                  ),
                ),
                const Divider(height: 16, color: AppColors.border),
                DetailRow(
                  row: DetailRowData(
                    'Paid so far',
                    'KSh ${formatKsh(t.rentPaid)}',
                  ),
                ),
                const Divider(height: 16, color: AppColors.border),
                DetailRow(
                  row: DetailRowData(
                    'Amount remaining to clear rent',
                    'KSh ${formatKsh(t.rentOutstanding)}',
                  ),
                ),
                const Divider(height: 16, color: AppColors.border),
                DetailRow(
                  row: DetailRowData(
                    'Start date',
                    t.startDate == null
                        ? '—'
                        : '${t.startDate!.day}/${t.startDate!.month}/${t.startDate!.year}',
                  ),
                ),
                if (t.endDate != null) ...[
                  const Divider(height: 16, color: AppColors.border),
                  DetailRow(
                    row: DetailRowData(
                      'End date',
                      '${t.endDate!.day}/${t.endDate!.month}/${t.endDate!.year}',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentsListScreen(
                        propertyId: t.propertyId,
                        propertyName: t.propertyName,
                        tenantId: t.tenantId,
                        tenancyId: t.id,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.folder_copy_outlined),
                  label: const Text('Documents'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showReminderSheet(context),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Reminder'),
                ),
              ),
            ],
          ),
          if (widget.tenancy.status == 'active') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _removing ? null : _removeTenant,
                icon: _removing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.danger),
                      )
                    : const Icon(Icons.person_remove_outlined),
                label: Text(_removing ? 'Removing...' : 'Remove tenant'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Recent Payments',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<_PaymentSummary>>(
            future: _paymentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final payments = snapshot.data ?? const <_PaymentSummary>[];
              if (payments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'No payments recorded for this tenancy yet.',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < payments.length && i < 5; i++) ...[
                      if (i > 0)
                        const Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: AppColors.border),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.kodiGreen
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.payments_outlined,
                                  color: AppColors.kodiGreen, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KSh ${formatKsh(payments[i].amount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    '${payments[i].method} • ${payments[i].paymentDate.day}/${payments[i].paymentDate.month}/${payments[i].paymentDate.year}',
                                    style: AppStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: payments[i].status == 'completed'
                                    ? AppColors.successSoft
                                    : AppColors.warningSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                payments[i].status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  color: payments[i].status == 'completed'
                                      ? AppColors.kodiGreen
                                      : AppColors.kodiOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummary {
  final num amount;
  final String method;
  final String status;
  final DateTime paymentDate;

  const _PaymentSummary({
    required this.amount,
    required this.method,
    required this.status,
    required this.paymentDate,
  });

  factory _PaymentSummary.fromJson(Map<String, dynamic> json) {
    return _PaymentSummary(
      amount: toNum(json['amount']),
      method: (json['payment_method'] ?? '—').toString(),
      status: (json['status'] ?? 'pending').toString(),
      paymentDate:
          parseDate(json['payment_date']) ?? DateTime.now(),
    );
  }
}

