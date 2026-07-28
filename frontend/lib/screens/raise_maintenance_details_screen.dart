import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'raise_maintenance_evidence_screen.dart';

class RaiseMaintenanceDetailsScreen extends StatefulWidget {
  const RaiseMaintenanceDetailsScreen({super.key});

  @override
  State<RaiseMaintenanceDetailsScreen> createState() => _RaiseMaintenanceDetailsScreenState();
}

class _RaiseMaintenanceDetailsScreenState extends State<RaiseMaintenanceDetailsScreen> {
  String _selectedCategory = 'plumbing';
  final _descriptionController = TextEditingController();
  String _urgency = 'medium';

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KodiPay', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          _Breadcrumbs(),
          const SizedBox(height: 16),
          const Text('Raise Maintenance', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.25)),
          const SizedBox(height: 8),
          Text('Let us know what\'s wrong, and we\'ll send a technician right away.', style: AppStyles.bodyMd.copyWith(color: AppColors.secondary)),
          const SizedBox(height: 40),
          _Stepper(),
          const SizedBox(height: 40),
          _WizardCard(
            selectedCategory: _selectedCategory,
            descriptionController: _descriptionController,
            urgency: _urgency,
            onCategoryChanged: (v) => setState(() => _selectedCategory = v),
            onUrgencyChanged: (v) => setState(() => _urgency = v),
            onContinue: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RaiseMaintenanceEvidenceScreen()),
            ),
          ),
          const SizedBox(height: 24),
          _TipsBento(),
        ],
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Support',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary),
        ),
        SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, color: AppColors.secondary, size: 16),
        SizedBox(width: 8),
        Text(
          'New Maintenance Request',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const _StepCircle(step: '1', label: 'Details', isActive: true),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.outlineVariant,
              ),
            ),
            const _StepCircle(step: '2', label: 'Photos', isActive: false),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.outlineVariant,
              ),
            ),
            const _StepCircle(step: '3', label: 'Schedule', isActive: false),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Step 1 of 3: Issue Details',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final String step;
  final String label;
  final bool isActive;

  const _StepCircle({required this.step, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: isActive ? null : Border.all(color: AppColors.outlineVariant, width: 2),
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: isActive ? AppColors.onPrimary : AppColors.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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
            color: isActive ? AppColors.primary : AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _WizardCard extends StatelessWidget {
  final String selectedCategory;
  final TextEditingController descriptionController;
  final String urgency;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onUrgencyChanged;
  final VoidCallback onContinue;

  const _WizardCard({
    required this.selectedCategory,
    required this.descriptionController,
    required this.urgency,
    required this.onCategoryChanged,
    required this.onUrgencyChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ISSUE CATEGORY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CategoryRadio(
                icon: Icons.plumbing_rounded,
                label: 'Plumbing',
                value: 'plumbing',
                isSelected: selectedCategory == 'plumbing',
                onTap: () => onCategoryChanged('plumbing'),
              ),
              _CategoryRadio(
                icon: Icons.electrical_services_rounded,
                label: 'Electrical',
                value: 'electrical',
                isSelected: selectedCategory == 'electrical',
                onTap: () => onCategoryChanged('electrical'),
              ),
              _CategoryRadio(
                icon: Icons.kitchen_rounded,
                label: 'Appliances',
                value: 'appliances',
                isSelected: selectedCategory == 'appliances',
                onTap: () => onCategoryChanged('appliances'),
              ),
              _CategoryRadio(
                icon: Icons.construction_rounded,
                label: 'General',
                value: 'general',
                isSelected: selectedCategory == 'general',
                onTap: () => onCategoryChanged('general'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'DESCRIBE THE PROBLEM',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Please provide as much detail as possible. For example: \'The kitchen faucet is leaking from the base and causing water to pool on the counter...\'',
              hintStyle: TextStyle(color: AppColors.secondary.withValues(alpha: 0.5), fontSize: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.secondary.withValues(alpha: 0.6), size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Accurate descriptions help us send the right expert.',
                      style: TextStyle(color: AppColors.secondary.withValues(alpha: 0.6), fontSize: 14, fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                '${descriptionController.text.length} / 1000',
                style: AppStyles.bodySm.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'URGENCY LEVEL',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: urgency,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low - General repair (Within 3 days)')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium - Noticeable issue (Within 24 hours)')),
                  DropdownMenuItem(value: 'high', child: Text('High - Urgent / Disruption (Within 4-8 hours)')),
                  DropdownMenuItem(value: 'emergency', child: Text('Emergency - Safety Risk (Immediate Action)')),
                ],
                onChanged: (v) {
                  if (v != null) onUrgencyChanged(v);
                },
                icon: const Icon(Icons.expand_more_rounded, color: AppColors.secondary),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Continue to Photos', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded, color: AppColors.secondary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Cancel Request',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRadio extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryRadio({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryFixed.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.secondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
                color: isSelected ? AppColors.primary : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsBento extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: const [
        _TipCard(
          icon: Icons.schedule_rounded,
          title: 'Fast Turnaround',
          description: 'Average response time is under 12 hours.',
        ),
        _TipCard(
          icon: Icons.verified_user_rounded,
          title: 'Certified Pros',
          description: 'All technicians are background checked.',
        ),
        _TipCard(
          icon: Icons.notifications_active_rounded,
          title: 'Live Tracking',
          description: 'Track the technician\'s arrival on the map.',
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppStyles.bodySm.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
