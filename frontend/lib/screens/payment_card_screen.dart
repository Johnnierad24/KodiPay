import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'pay_rent_screen.dart';
import 'payment_success_screen.dart';

class PaymentCardScreen extends StatefulWidget {
  final RentDue due;
  const PaymentCardScreen({super.key, required this.due});

  @override
  State<PaymentCardScreen> createState() => _PaymentCardScreenState();
}

class _PaymentCardScreenState extends State<PaymentCardScreen> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _saveCard = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _formatCardNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final buffered = StringBuffer();
    for (var i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffered.write(' ');
      buffered.write(digits[i]);
    }
    _numberController.value = TextEditingValue(
      text: buffered.toString(),
      selection: TextSelection.collapsed(offset: buffered.length),
    );
  }

  void _formatExpiry(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 2) {
      final formatted = '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(0, 4))}';
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _submit() {
    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            amount: widget.due.rentAmount,
            method: 'Credit/Debit Card',
            transactionRef: 'CARD-${DateTime.now().millisecondsSinceEpoch}',
            propertyName: widget.due.propertyName,
            unitNumber: widget.due.unitNumber,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final due = widget.due;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Complete Payment', style: TextStyle(fontFamily: 'Lexend', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
        centerTitle: false,
        actions: [
          const Icon(Icons.notifications_outlined, color: AppColors.secondary),
          const SizedBox(width: 16),
          const Icon(Icons.help_outline, color: AppColors.secondary),
          const SizedBox(width: 12),
          CircleAvatar(radius: 16, backgroundColor: AppColors.surfaceHigh, child: const Icon(Icons.person, size: 20, color: AppColors.primary)),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildStepper(),
            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;
                return isNarrow
                    ? Column(
                        children: [
                          _buildCardForm(due),
                          const SizedBox(height: 16),
                          _buildSummarySidebar(due),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 8, child: _buildCardForm(due)),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: _buildSummarySidebar(due)),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepperDot(label: 'Select Method', isCompleted: true),
        _StepperLine(completed: true),
        _StepperDot(label: 'Card Details', isActive: true),
        _StepperLine(completed: false),
        _StepperDot(label: 'Verification', isPending: true),
      ],
    );
  }

  Widget _buildCardForm(RentDue due) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Credit or Debit Card', style: AppStyles.headlineMd),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('VISA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1A1F71))),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('MC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFEB001B))),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('CARDHOLDER NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. KOFI ANNAN',
                  hintStyle: TextStyle(color: AppColors.secondary.withValues(alpha: 0.4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              const Text('CARD NUMBER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                onChanged: _formatCardNumber,
                style: const TextStyle(fontFamily: 'Inter', letterSpacing: 3),
                decoration: InputDecoration(
                  hintText: '0000 0000 0000 0000',
                  hintStyle: TextStyle(color: AppColors.secondary.withValues(alpha: 0.4)),
                  suffixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.secondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EXPIRY DATE (MM/YY)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          onChanged: _formatExpiry,
                          style: const TextStyle(fontFamily: 'Inter'),
                          decoration: InputDecoration(
                            hintText: 'MM/YY',
                            hintStyle: TextStyle(color: AppColors.secondary.withValues(alpha: 0.4)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CVV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          obscureText: true,
                          style: const TextStyle(fontFamily: 'Inter'),
                          decoration: InputDecoration(
                            hintText: '•••',
                            hintStyle: TextStyle(color: AppColors.secondary.withValues(alpha: 0.4)),
                            counterText: '',
                            suffixIcon: const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _saveCard = !_saveCard),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _saveCard ? AppColors.tertiaryFixedDim : AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _saveCard ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Save card for future payments', style: TextStyle(color: AppColors.onSurface, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'Processing...' : 'Pay KSh ${formatKsh(due.rentAmount)}.00',
                    style: const TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_rounded, color: AppColors.tertiaryFixedDim, size: 18),
            const SizedBox(width: 6),
            Text('PCI-DSS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondary, letterSpacing: 0.05)),
            const SizedBox(width: 24),
            Icon(Icons.lock_rounded, color: AppColors.tertiaryFixedDim, size: 18),
            const SizedBox(width: 6),
            Text('256-BIT ENCRYPTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondary, letterSpacing: 0.05)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySidebar(RentDue due) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Summary', style: AppStyles.headlineMd),
              const SizedBox(height: 20),
              _SummaryRow(label: 'Monthly Rent', value: 'KSh ${formatKsh(due.rentAmount)}.00'),
              const SizedBox(height: 12),
              const _SummaryRow(label: 'Service Charge', value: 'KSh 3,000.00'),
              const SizedBox(height: 12),
              const _SummaryRow(label: 'Utility Balance', value: 'KSh 0.00'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineVariant))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total to Pay', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
                    Text('KSh ${formatKsh(due.rentAmount)}.00', style: const TextStyle(fontFamily: 'Lexend', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PAYMENT METHOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.credit_card_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Credit/Debit Card', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 16)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('CHANGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onTertiaryFixed, letterSpacing: 0.05)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.security_rounded, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              const Text('Secure Checkout', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                'Your payment information is processed securely. We do not store your full card details on our servers.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperDot extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isActive;
  final bool isPending;

  const _StepperDot({
    required this.label,
    this.isCompleted = false,
    this.isActive = false,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.tertiaryFixedDim
                : isActive
                    ? Colors.white
                    : Colors.white,
            border: Border.all(
              color: isCompleted
                  ? AppColors.tertiaryFixedDim
                  : isActive
                      ? AppColors.primary
                      : AppColors.outlineVariant,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    isActive ? '2' : '3',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.primary : AppColors.secondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
            color: isPending ? AppColors.secondary : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StepperLine extends StatelessWidget {
  final bool completed;
  const _StepperLine({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: completed ? AppColors.tertiaryFixedDim : AppColors.outlineVariant,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.secondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Inter')),
      ],
    );
  }
}
