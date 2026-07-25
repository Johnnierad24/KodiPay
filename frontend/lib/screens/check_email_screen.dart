import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: isWide ? _wideLayout() : _narrowLayout(),
            ),
            _Footer(),
          ],
        ),
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(child: _HeroSide()),
        Expanded(child: _EmailConfirmation()),
      ],
    );
  }

  Widget _narrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 180, child: _HeroSide(compact: true)),
          const _EmailConfirmation(),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(7)),
            child: const Center(child: Text('K', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.kodiGreen))),
          ),
          const SizedBox(width: 8),
          Text('KodiPay!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Lexend')),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text('Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _HeroSide extends StatelessWidget {
  final bool compact;
  const _HeroSide({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 180 : double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/welcome_bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF041627),
              Color(0x99041627),
              Color(0x44001633),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Spacer(flex: compact ? 1 : 3),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('K', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.kodiGreen))),
            ),
            const SizedBox(height: 16),
            Text('KodiPay', style: TextStyle(fontSize: compact ? 22 : 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Lexend')),
            const SizedBox(height: 8),
            Text('Secure Property\nManagement', style: TextStyle(fontSize: compact ? 13 : 15, color: Colors.white.withValues(alpha: 0.7), height: 1.5)),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _EmailConfirmation extends StatelessWidget {
  const _EmailConfirmation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_rounded, size: 40, color: AppColors.info),
            ),
            const SizedBox(height: 24),
            const Text('Check your email', style: AppStyles.headlineLg),
            const SizedBox(height: 12),
            Text(
              "We've sent a password reset link to your email. Please check your inbox and follow the instructions.",
              textAlign: TextAlign.center,
              style: AppStyles.bodySm.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiBlue),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/forgot-password', (_) => false);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Resend Email', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kodiBlue,
                  side: const BorderSide(color: AppColors.kodiBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.key_rounded, size: 18, color: AppColors.kodiGreen.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text('256-bit SSL Encrypted', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        border: Border(top: BorderSide(color: AppColors.primaryContainer, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () {}, child: Text('Terms', style: TextStyle(fontSize: 11, color: Colors.white70, decoration: TextDecoration.underline))),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(fontSize: 11, color: Colors.white38)),
              const SizedBox(width: 8),
              TextButton(onPressed: () {}, child: Text('Privacy', style: TextStyle(fontSize: 11, color: Colors.white70, decoration: TextDecoration.underline))),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(fontSize: 11, color: Colors.white38)),
              const SizedBox(width: 8),
              TextButton(onPressed: () {}, child: Text('Contact', style: TextStyle(fontSize: 11, color: Colors.white70, decoration: TextDecoration.underline))),
            ],
          ),
          const SizedBox(height: 6),
          Text('© 2026 KodiPay Kenya. All rights reserved.', style: TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }
}
