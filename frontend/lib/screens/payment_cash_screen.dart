import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'pay_rent_screen.dart';
import 'payment_success_screen.dart';

class PaymentCashScreen extends StatefulWidget {
  final RentDue due;
  const PaymentCashScreen({super.key, required this.due});

  @override
  State<PaymentCashScreen> createState() => _PaymentCashScreenState();
}

class _PaymentCashScreenState extends State<PaymentCashScreen> {
  final ApiService _api = ApiService();
  bool _isSubmitting = false;
  bool _confirmed = false;

  Future<void> _confirmCashPayment() async {
    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'tenancy_id': widget.due.tenancyId,
        'amount': widget.due.rentAmount,
        'payment_method': 'cash',
      };
      final response = await _api.post('/payments', body);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode == 201) {
        _showSuccessModal();
      } else {
        _showSnack('Payment recording failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack('Error: $e');
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.kodiGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 44, color: AppColors.kodiGreen),
              ),
              const SizedBox(height: 18),
              const Text('Cash Payment Recorded', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textDark)),
              const SizedBox(height: 10),
              Text(
                'Your cash payment of KSh ${formatKsh(widget.due.rentAmount)} has been submitted. The caretaker will confirm receipt shortly.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(color: AppColors.textLight, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentSuccessScreen(
                          amount: widget.due.rentAmount,
                          method: 'Cash',
                          transactionRef: _extractRefLocal(),
                          propertyName: widget.due.propertyName,
                          unitNumber: widget.due.unitNumber,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kodiGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractRefLocal() => 'CASH-${DateTime.now().millisecondsSinceEpoch}';

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final amount = 'KSh ${formatKsh(widget.due.rentAmount)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pay with Cash', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 18)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Instructions card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cash Payment Instructions', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Follow these steps to complete your cash payment', style: AppStyles.caption),
                  const SizedBox(height: 20),
                  const _StepItem(number: '1', title: 'Visit the Caretaker Office', desc: 'Go to the caretaker office at your property during office hours.'),
                  _StepItem(number: '2', title: 'Make Cash Payment', desc: 'Pay $amount in cash. Request a signed receipt from the caretaker.'),
                  const _StepItem(number: '3', title: 'Confirmation', desc: 'The caretaker will confirm your payment in the system within 24 hours.'),
                  const _StepItem(number: '4', title: 'Payment Updated', desc: 'Your balance will be updated automatically once confirmed.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Caretaker info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Caretaker Information', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 15)),
                  const SizedBox(height: 16),
                  const _InfoRow(icon: Icons.person_outline_rounded, label: 'Name', value: 'John Kamau'),
                  const SizedBox(height: 12),
                  const _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: '+254 712 345 678'),
                  const SizedBox(height: 12),
                  const _InfoRow(icon: Icons.schedule_outlined, label: 'Office Hours', value: 'Mon–Fri, 8 AM – 5 PM'),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: 'Ground Floor, ${widget.due.propertyName}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'After payment, your balance will update within 24 hours once the caretaker confirms receipt.',
                      style: TextStyle(fontSize: 13, color: AppColors.textLight.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Confirmation checkbox
            GestureDetector(
              onTap: () => setState(() => _confirmed = !_confirmed),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _confirmed ? AppColors.kodiGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _confirmed ? AppColors.kodiGreen : AppColors.outlineVariant, width: 2),
                      ),
                      child: _confirmed
                          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I have made the cash payment',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _confirmed ? AppColors.textDark : AppColors.textLight,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || !_confirmed) ? null : _confirmCashPayment,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(_isSubmitting ? 'Recording...' : 'Confirm Cash Payment', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kodiGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.outlineVariant,
                  disabledForegroundColor: AppColors.muted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String desc;
  const _StepItem({required this.number, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: AppColors.kodiGreen, shape: BoxShape.circle),
            child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 14)),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: 13, color: AppColors.textLight.withValues(alpha: 0.9), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.kodiBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
