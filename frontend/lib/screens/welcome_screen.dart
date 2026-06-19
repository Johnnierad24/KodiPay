import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/animations.dart';
import '../widgets/kodi_pay_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String _heroImage = 'assets/images/onboarding_hero.png';

  static const List<Shadow> _textShadow = [
    Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed, sharp photo background.
          Image.asset(
            _heroImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: AppColors.kodiNavy),
          ),
          // Dark scrim so the white foreground stays legible.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x8C001022),
                  Color(0x59001022),
                  Color(0xBF001022),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          // Foreground content.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const FadeSlideIn(child: _LogoBadge()),
                  const SizedBox(height: 30),
                  FadeSlideIn(
                    delay: FadeSlideIn.stagger(1),
                    child: const Text(
                      'Karibu KodiPay',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        shadows: _textShadow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: FadeSlideIn.stagger(2),
                    child: const Text(
                      'Pay rent. Stay worry-free.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        shadows: _textShadow,
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/onboarding'),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The logo on a white circular badge with a faint outer ring.
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1.5,
        ),
      ),
      child: Container(
        width: 150,
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.kodiNavy.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: KodiPayLogo(
            iconSize: 42,
            fontSize: 19,
            vertical: true,
          ),
        ),
      ),
    );
  }
}
