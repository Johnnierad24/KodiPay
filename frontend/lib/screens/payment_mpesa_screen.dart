import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'pay_rent_screen.dart';
import 'payment_success_screen.dart';

class PaymentMpesaScreen extends StatefulWidget {
  final RentDue due;
  const PaymentMpesaScreen({super.key, required this.due});

  @override
  State<PaymentMpesaScreen> createState() => _PaymentMpesaScreenState();
}

class _PaymentMpesaScreenState extends State<PaymentMpesaScreen> {
  final _phoneController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isSubmitting = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user?.phone != null && user!.phone!.trim().isNotEmpty) {
      _phoneController.text = user.phone!.trim();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Enter your M-Pesa registered phone number.');
      return;
    }
    if (phone.length < 10) {
      _showSnack('Enter a valid phone number (e.g. 2547XXXXXXXX).');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'tenancy_id': widget.due.tenancyId,
        'amount': widget.due.rentAmount,
        'payment_method': 'mpesa',
        'phone_number': phone,
      };
      final response = await _api.post('/payments', body);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              amount: widget.due.rentAmount,
              method: 'M-Pesa',
              transactionRef: _extractRef(response.body),
              propertyName: widget.due.propertyName,
              unitNumber: widget.due.unitNumber,
            ),
          ),
        );
      } else {
        _showSnack('Payment failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack('Payment failed: $e');
    }
  }

  String _extractRef(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['transaction_ref']?.toString() ?? 'MPESA-${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      return 'MPESA-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final amount = 'KSh ${formatKsh(widget.due.rentAmount)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Pesa Payment', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MpesaBranding(),
            const SizedBox(height: 20),
            _StepIndicator(currentStep: _currentStep, steps: const ['Amount', 'Phone', 'Confirm', 'Pay']),
            const SizedBox(height: 24),
            if (_currentStep <= 1) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Amount', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('KSh ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textLight)),
                        Flexible(child: Text(formatKsh(widget.due.rentAmount), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDark))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${widget.due.propertyName} • Unit ${widget.due.unitNumber}', style: AppStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_currentStep <= 1) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('M-Pesa Phone Number', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixText: '+254 ',
                        hintText: '712 345 678',
                        prefixIcon: Icon(Icons.phone_android_rounded, color: Color(0xFF4CAF50)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Enter the phone number registered for M-Pesa', style: AppStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _currentStep = 2);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text('Continue - Pay $amount', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                ),
              ),
            ],
            if (_currentStep == 2) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
                    const SizedBox(height: 16),
                    _ConfirmRow(label: 'Amount', value: amount),
                    const SizedBox(height: 8),
                    _ConfirmRow(label: 'Property', value: widget.due.propertyName),
                    const SizedBox(height: 8),
                    _ConfirmRow(label: 'Unit', value: widget.due.unitNumber),
                    const SizedBox(height: 8),
                    _ConfirmRow(label: 'Phone', value: '+254 ${_phoneController.text.trim()}'),
                    const SizedBox(height: 8),
                    const _ConfirmRow(label: 'Method', value: 'M-Pesa'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitPayment,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.payments_outlined),
                  label: Text(_isSubmitting ? 'Processing...' : 'Pay $amount via M-Pesa', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  child: const Text('Change phone number', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('You will receive an STK push prompt on your phone to enter your M-Pesa PIN.',
                        style: TextStyle(fontSize: 12, color: AppColors.textLight.withValues(alpha: 0.8))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MpesaBranding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.phone_android_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('M-Pesa', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), fontSize: 16)),
                Text('Fast, secure mobile money payment', style: TextStyle(fontSize: 11, color: Color(0xFF33691E))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= currentStep;
        return Expanded(
          child: Row(
            children: [
              if (i > 0) Expanded(child: Container(height: 2, color: isActive ? const Color(0xFF4CAF50) : AppColors.border)),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF4CAF50) : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${i + 1}', style: TextStyle(color: isActive ? Colors.white : AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              if (i < steps.length - 1) Expanded(child: Container(height: 2, color: isActive ? const Color(0xFF4CAF50) : AppColors.border)),
            ],
          ),
        );
      }),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: AppStyles.caption)),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 13))),
      ],
    );
  }
}
