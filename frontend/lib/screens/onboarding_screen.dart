import 'package:flutter/material.dart';
import '../widgets/glass.dart';
import '../widgets/kodi_pay_logo.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 52),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Compact logo badge — kept small so the role choices sit
                      // more towards the centre of the screen.
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.4),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: KodiPayLogo(iconSize: 38, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Managing rent made easy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Select your role to get started with the rental '
                        'workflows designed for you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 14.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const _RoleTile(
                        title: 'I am a Landlord',
                        description:
                            'Manage properties, tenants, and collections.',
                        icon: Icons.business_rounded,
                        color: AppColors.kodiGreen,
                        role: 'landlord',
                      ),
                      const SizedBox(height: 14),
                      const _RoleTile(
                        title: 'I am a Tenant',
                        description: 'Pay rent, view receipts, and report issues.',
                        icon: Icons.home_rounded,
                        color: AppColors.kodiBlue,
                        role: 'tenant',
                      ),
                      const SizedBox(height: 14),
                      const _RoleTile(
                        title: 'I am a Caretaker',
                        description: 'Track assigned issues and emergency alerts.',
                        icon: Icons.handyman_rounded,
                        color: AppColors.kodiOrange,
                        role: 'caretaker',
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/auth'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.white,
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String role;

  const _RoleTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/auth', arguments: role),
      borderRadius: BorderRadius.circular(18),
      child: GlassPanel(
        radius: 18,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.white, size: 25),
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
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
