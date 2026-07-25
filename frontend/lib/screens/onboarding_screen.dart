import 'package:flutter/material.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = [
      _RoleData('Tenant', Icons.person_outline, 'Pay rent securely via M-Pesa or Card,\ntrack your payment history, and raise\nmaintenance requests with a single tap.'),
      _RoleData('Landlord', Icons.business_outlined, 'Automate rent collection, generate tax-\nready financial reports, and manage multi-\nunit properties from a central dashboard.'),
      _RoleData('Caretaker', Icons.engineering_outlined, 'Oversee day-to-day operations, verify\ntenant payments, and manage utility billing\nwith ease and transparency.'),
    ];

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_outlined), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Choose your path', style: AppStyles.heading1),
              const SizedBox(height: 6),
              const Text("We provide specialized tools for each role\nin property management.", style: AppStyles.bodySmall),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final r = roles[i];
                    return _RoleCard(
                      title: r.title,
                      icon: r.icon,
                      description: r.description,
                      onTap: () => Navigator.pushNamed(context, '/register', arguments: r.title.toLowerCase()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                    TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleData {
  final String title;
  final IconData icon;
  final String description;
  _RoleData(this.title, this.icon, this.description);
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({required this.title, required this.icon, required this.description, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.kodiBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.kodiBlue, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.4)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
