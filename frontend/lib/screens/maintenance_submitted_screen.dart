import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MaintenanceSubmittedScreen extends StatelessWidget {
  const MaintenanceSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    _SuccessAnimation(),
                    const SizedBox(height: 48),
                    _ConfirmationDetails(),
                    const SizedBox(height: 48),
                    _BentoStatusSummary(),
                    const SizedBox(height: 48),
                    _NextStepsSection(),
                    const SizedBox(height: 64),
                    _FooterLinks(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: AppColors.tertiaryFixed.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.tertiaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.onTertiaryFixed,
                size: 64,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmationDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Maintenance Request Submitted',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.25),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Ticket ID: #TK-9928',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your request has been successfully logged. Our property management team is working to resolve this as quickly as possible.',
          style: AppStyles.bodyLg.copyWith(color: AppColors.secondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BentoStatusSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StatusCard(
            icon: Icons.schedule_rounded,
            title: 'Estimated Response',
            value: '4 Hours',
            description: 'A caretaker will review your submission details.',
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: _StatusCard(
            icon: Icons.build_rounded,
            title: 'Service Type',
            value: 'Plumbing',
            description: 'Emergency repair for unit 4B master bath leakage.',
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: _StatusCard(
            icon: Icons.verified_user_rounded,
            title: 'Assigned Agent',
            value: 'KodiCare HQ',
            description: 'Automated routing to the Silicon Savannah team.',
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String description;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.onSurface, height: 1.33),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: AppStyles.bodySm.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _NextStepsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const Text(
            'WHAT HAPPENS NEXT?',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NextStep(
                  step: '1',
                  title: 'Review',
                  description: 'Our supervisor validates the urgency of your plumbing request.',
                  isActive: true,
                ),
              ),
              SizedBox(width: 32),
              Expanded(
                child: _NextStep(
                  step: '2',
                  title: 'Dispatch',
                  description: 'A local technician is notified and assigned your ticket.',
                  isActive: false,
                ),
              ),
              SizedBox(width: 32),
              Expanded(
                child: _NextStep(
                  step: '3',
                  title: 'Resolution',
                  description: 'Technician visits your unit to perform the necessary repairs.',
                  isActive: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.track_changes_rounded, size: 20),
                  label: const Text('TRACK PROGRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05)),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.support_agent_rounded, size: 20),
                  label: const Text('GO TO SUPPORT CENTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final bool isActive;

  const _NextStep({
    required this.step,
    required this.title,
    required this.description,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.outlineVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step,
                  style: TextStyle(
                    color: isActive ? AppColors.onPrimary : AppColors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(description, style: AppStyles.bodySm.copyWith(color: AppColors.secondary)),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              const Icon(Icons.gavel_rounded, color: AppColors.secondary, size: 14),
              const SizedBox(width: 8),
              Text(
                'TENANT RIGHTS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              const Icon(Icons.description_rounded, color: AppColors.secondary, size: 14),
              const SizedBox(width: 8),
              Text(
                'LANDLORD-TENANT ACT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
