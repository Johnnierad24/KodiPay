import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';

class PayRentScreen extends StatefulWidget {
  const PayRentScreen({super.key});

  @override
  State<PayRentScreen> createState() => _PayRentScreenState();
}

class _PayRentScreenState extends State<PayRentScreen> {
  String _paymentMethod = 'M-Pesa';
  bool _isSubmitting = false;

  Future<void> _submitPayment() async {
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded,
            color: AppColors.kodiGreen, size: 44),
        title: const Text('Payment Started'),
        content: Text(
          _paymentMethod == 'M-Pesa'
              ? 'Check your phone and enter your M-Pesa PIN to complete the KSh 25,000 payment.'
              : 'Your $_paymentMethod payment has been recorded as pending confirmation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt preview opened.')),
              );
            },
            child: const Text('View Receipt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pay Rent',
          style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PaymentCard(
                title: 'Payment Summary',
                children: [
                  _SummaryRow(label: 'Property', value: 'Sunview Apartments'),
                  _SummaryRow(label: 'Unit', value: 'A2'),
                  _SummaryRow(label: 'Rent Amount', value: 'KSh 25,000'),
                  _SummaryRow(label: 'Due Date', value: '25th May 2024'),
                ],
              ),
              const SizedBox(height: 16),
              _PaymentCard(
                title: 'Payment Method',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_balance_wallet_rounded,
                          color: AppColors.kodiGreen),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M-Pesa', child: Text('M-Pesa')),
                      DropdownMenuItem(
                          value: 'Bank Transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _paymentMethod = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kodiGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSubmitting ? null : _submitPayment,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : const Text('Pay KSh 25,000'),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  _paymentMethod == 'M-Pesa'
                      ? 'You will receive an M-Pesa prompt'
                      : 'Your payment will be marked pending confirmation',
                  style: AppStyles.caption,
                ),
              ),
              const SizedBox(height: 26),
              const Divider(color: AppColors.border),
              const SizedBox(height: 18),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded,
                        color: AppColors.kodiGreen, size: 16),
                    SizedBox(width: 8),
                    Text('Secure payment powered by M-Pesa',
                        style: AppStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const _ReceiptPreview(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PaymentCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppStyles.caption)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textDark, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview();

  @override
  Widget build(BuildContext context) {
    return const ListPanel(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.kodiGreen, size: 34),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipt ready after payment',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    SizedBox(height: 2),
                    Text(
                        'Downloadable confirmation is generated once M-Pesa confirms.',
                        style: AppStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
