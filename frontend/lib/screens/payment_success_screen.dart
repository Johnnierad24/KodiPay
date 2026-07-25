import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final num amount;
  final String method;
  final String transactionRef;
  final String propertyName;
  final String unitNumber;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.method,
    required this.transactionRef,
    required this.propertyName,
    required this.unitNumber,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnim;
  late Animation<double> _confettiAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _confettiAnim = CurvedAnimation(parent: _confettiController, curve: Curves.easeOut);
    _scaleController.forward();
    _confettiController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountStr = 'KSh ${formatKsh(widget.amount)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Confetti background + animated checkmark
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _confettiAnim,
                      builder: (context, _) => CustomPaint(
                        size: const Size(120, 120),
                        painter: _ConfettiPainter(progress: _confettiAnim.value),
                      ),
                    ),
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.kodiGreen.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, size: 56, color: AppColors.kodiGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              Text(
                'Your ${widget.method} payment of $amountStr has been processed successfully.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(color: AppColors.textLight, height: 1.5),
              ),
              const SizedBox(height: 32),
              // Transaction Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transaction Summary', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
                    const SizedBox(height: 18),
                    _SummaryRow(label: 'Amount Paid', value: amountStr, highlight: true),
                    const Divider(height: 22, color: AppColors.border),
                    _SummaryRow(label: 'Payment Method', value: widget.method),
                    const Divider(height: 22, color: AppColors.border),
                    _SummaryRow(label: 'Reference', value: widget.transactionRef),
                    const Divider(height: 22, color: AppColors.border),
                    _SummaryRow(label: 'Property', value: widget.propertyName),
                    const Divider(height: 22, color: AppColors.border),
                    _SummaryRow(label: 'Unit', value: widget.unitNumber),
                    const Divider(height: 22, color: AppColors.border),
                    _SummaryRow(label: 'Date', value: _formattedDate()),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => showSnack(context, 'Receipt download coming soon'),
                  icon: const Icon(Icons.download_rounded, size: 22),
                  label: const Text('Download Receipt', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kodiGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
                  icon: const Icon(Icons.home_outlined, size: 22),
                  label: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${now.day} ${months[now.month - 1]} ${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SummaryRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppStyles.caption),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.kodiGreen : AppColors.textDark,
              fontSize: highlight ? 17 : 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final center = Offset(size.width / 2, size.height / 2);
    final colors = [AppColors.kodiGreen, AppColors.kodiOrange, AppColors.kodiBlue, AppColors.danger, AppColors.kodiNavy];

    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi;
      final maxDist = 50.0 + rng.nextDouble() * 10;
      final dist = maxDist * Curves.easeOut.transform(progress);
      final x = center.dx + cos(angle) * dist;
      final y = center.dy + sin(angle) * dist;
      final radius = 2.0 + rng.nextDouble() * 2;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: (1 - progress).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
