import 'package:flutter/material.dart';
import '../widgets/kodi_pay_logo.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.kodiNavy.withValues(alpha: 0.06),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    KodiPayLogo(iconSize: 96, fontSize: 42),
                    SizedBox(height: 14),
                    Text(
                      'Pay Rent. Stay Worry-Free.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.kodiNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Managing rent made easy',
                textAlign: TextAlign.center,
                style: AppStyles.heading1,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your role to get started with the rental workflows designed for you.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium,
              ),
              const SizedBox(height: 30),
              _buildRoleOption(
                context,
                title: 'I am a Landlord',
                description: 'Manage properties, tenants, and collections.',
                icon: Icons.business_rounded,
                color: AppColors.kodiGreen,
                role: 'landlord',
              ),
              const SizedBox(height: 14),
              _buildRoleOption(
                context,
                title: 'I am a Tenant',
                description: 'Pay rent, view receipts, and report issues.',
                icon: Icons.home_rounded,
                color: AppColors.kodiBlue,
                role: 'tenant',
              ),
              const SizedBox(height: 14),
              _buildRoleOption(
                context,
                title: 'I am a Caretaker',
                description: 'Track assigned issues and emergency alerts.',
                icon: Icons.handyman_rounded,
                color: AppColors.kodiOrange,
                role: 'caretaker',
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String role,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/register', arguments: role),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
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
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(description, style: AppStyles.caption),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
