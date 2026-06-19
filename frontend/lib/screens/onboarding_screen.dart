import 'dart:ui';

import 'package:flutter/material.dart';
import '../utils/app_icons.dart';
import '../widgets/animations.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

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
          // Full-bleed photo background (shared with the welcome screen).
          Image.asset(
            _heroImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: AppColors.kodiNavy),
          ),
          // Dark scrim for legibility.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xA6001022),
                  Color(0x73001022),
                  Color(0xCC001022),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Foreground content.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(AppIcons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      tooltip: 'Back',
                    ),
                  ),
                  const Spacer(flex: 2),
                  const FadeSlideIn(
                    child: Text(
                      "Choose how you'll\nuse KodiPay",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        shadows: _textShadow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: FadeSlideIn.stagger(1),
                    child: const Text(
                      'Pick your role to get started with the workflows designed for you.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.35,
                        shadows: _textShadow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    delay: FadeSlideIn.stagger(2),
                    child: _RoleCard(
                      title: 'I am a Landlord',
                      description: 'Manage properties, tenants, and collections.',
                      icon: AppIcons.business_rounded,
                      color: AppColors.kodiGreen,
                      onTap: () => _goToRegister(context, 'landlord'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: FadeSlideIn.stagger(3),
                    child: _RoleCard(
                      title: 'I am a Tenant',
                      description: 'Pay rent, view receipts, and report issues.',
                      icon: AppIcons.home_rounded,
                      color: AppColors.kodiBlue,
                      onTap: () => _goToRegister(context, 'tenant'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: FadeSlideIn.stagger(4),
                    child: _RoleCard(
                      title: 'I am a Caretaker',
                      description: 'Track assigned issues and emergency alerts.',
                      icon: AppIcons.handyman_rounded,
                      color: AppColors.kodiOrange,
                      onTap: () => _goToRegister(context, 'caretaker'),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: Colors.white70,
                            shadows: _textShadow,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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

  void _goToRegister(BuildContext context, String role) {
    Navigator.pushNamed(context, '/role-auth', arguments: role);
  }
}

/// A frosted-glass role option that floats over the photo background.
class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.white.withValues(alpha: 0.14),
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(AppIcons.chevron_right_rounded,
                        color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
