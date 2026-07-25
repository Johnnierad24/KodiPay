import 'package:flutter/material.dart';
import '../models/payment_record.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import '../widgets/shared_screen_components.dart';

class PaymentDetailScreen extends StatelessWidget {
  final PaymentRecord payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Payment Details',
      accentColor: paymentStatusColor(payment.status),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  payment.isPaid
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: paymentStatusColor(payment.status),
                  size: 54,
                ),
                const SizedBox(height: 12),
                Text(
                  money(payment.amount),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                StatusPill(
                  label: payment.status,
                  color: paymentStatusColor(payment.status),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DetailSection(
            title: 'Tenant',
            rows: [
              DetailRowData('Name', payment.tenantName),
              DetailRowData('Phone', payment.tenantPhone),
              DetailRowData('Email', payment.tenantEmail),
            ],
          ),
          const SizedBox(height: 14),
          DetailSection(
            title: 'Property',
            rows: [
              DetailRowData('Property', payment.property),
              DetailRowData('Unit', payment.unit),
              DetailRowData('Due Date', payment.dueDate),
            ],
          ),
          const SizedBox(height: 14),
          DetailSection(
            title: 'Transaction',
            rows: [
              DetailRowData('Method', payment.method),
              DetailRowData('Reference', payment.transactionRef),
              DetailRowData('Created', payment.createdAt),
              DetailRowData('Updated', payment.updatedAt),
              DetailRowData('Paid At', payment.paidAt ?? 'Not paid yet'),
            ],
          ),
          if (payment.isPending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: payment.tenancyId == null
                    ? null
                    : () async {
                        final api = ApiService();
                        try {
                          final response = await api
                              .post('/notifications/rent-reminder', {
                            'tenancy_id': payment.tenancyId,
                            'message':
                                'Dear ${payment.tenantName}, your rent of ${money(payment.amount)} for ${payment.property} is due.',
                          });
                          if (!context.mounted) return;
                          if (response.statusCode == 200) {
                            showSnack(context,
                                'Reminder sent to ${payment.tenantName}.');
                          } else {
                            showSnack(context,
                                'Reminder failed (${response.statusCode}).');
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          showSnack(context, 'Reminder failed: $e');
                        }
                      },
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(payment.tenancyId == null
                    ? 'Tenancy missing — cannot send reminder'
                    : 'Send Payment Reminder'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
