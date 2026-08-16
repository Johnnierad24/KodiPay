import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'raise_maintenance_scheduling_screen.dart';

class RaiseMaintenanceEvidenceScreen extends StatefulWidget {
  const RaiseMaintenanceEvidenceScreen({super.key});

  @override
  State<RaiseMaintenanceEvidenceScreen> createState() => _RaiseMaintenanceEvidenceScreenState();
}

class _RaiseMaintenanceEvidenceScreenState extends State<RaiseMaintenanceEvidenceScreen> {
  final List<PlatformFile> _images = [];
  String _urgency = 'medium';
  bool _showEmergencyTooltip = false;

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;
    setState(() => _images.addAll(result.files));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise Maintenance', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              children: [Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepIndicator(),
                  const SizedBox(height: 40),
                  _BentoContent(
                    images: _images,
                    urgency: _urgency,
                    showEmergencyTooltip: _showEmergencyTooltip,
                    onImageAdd: _pickImages,
                    onImageRemove: (i) => setState(() => _images.removeAt(i)),
                    onUrgencyChanged: (v) => setState(() {
                      _urgency = v;
                      _showEmergencyTooltip = false;
                    }),
                    onTooltipToggle: () => setState(() => _showEmergencyTooltip = !_showEmergencyTooltip),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
              ],
            ),
          ),
          _NavigationFooter(
            canProceed: _images.isNotEmpty,
            onContinue: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RaiseMaintenanceSchedulingScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _StepItem(
          step: '1',
          label: 'Issue Info',
          isCompleted: true,
          isActive: false,
        ),
        _StepLine(isActive: true),
        _StepItem(
          step: '2',
          label: 'Photos & Urgency',
          isCompleted: false,
          isActive: true,
        ),
        _StepLine(isActive: false),
        _StepItem(
          step: '3',
          label: 'Scheduling',
          isCompleted: false,
          isActive: false,
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String step;
  final String label;
  final bool isCompleted;
  final bool isActive;

  const _StepItem({
    required this.step,
    required this.label,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: isActive ? 48 : 40,
          height: isActive ? 48 : 40,
          decoration: BoxDecoration(
            color: isCompleted || isActive ? AppColors.primary : AppColors.surfaceHigh,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: AppColors.tertiaryFixed, width: 4)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    step,
                    style: TextStyle(
                      color: isCompleted || isActive ? Colors.white : AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
            color: isActive || isCompleted ? AppColors.primary : AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;
  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _BentoContent extends StatelessWidget {
  final List<PlatformFile> images;
  final String urgency;
  final bool showEmergencyTooltip;
  final VoidCallback onImageAdd;
  final ValueChanged<int> onImageRemove;
  final ValueChanged<String> onUrgencyChanged;
  final VoidCallback onTooltipToggle;

  const _BentoContent({
    required this.images,
    required this.urgency,
    required this.showEmergencyTooltip,
    required this.onImageAdd,
    required this.onImageRemove,
    required this.onUrgencyChanged,
    required this.onTooltipToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _PhotoUploadSection(
                images: images,
                onAdd: onImageAdd,
                onRemove: onImageRemove,
              ),
              const SizedBox(height: 24),
              _UrgencySection(
                urgency: urgency,
                showEmergencyTooltip: showEmergencyTooltip,
                onChanged: onUrgencyChanged,
                onTooltipToggle: onTooltipToggle,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _PhotoUploadSection(
                images: images,
                onAdd: onImageAdd,
                onRemove: onImageRemove,
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 5,
              child: _UrgencySection(
                urgency: urgency,
                showEmergencyTooltip: showEmergencyTooltip,
                onChanged: onUrgencyChanged,
                onTooltipToggle: onTooltipToggle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PhotoUploadSection extends StatelessWidget {
  final List<PlatformFile> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PhotoUploadSection({
    required this.images,
    required this.onAdd,
    required this.onRemove,
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
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text('Upload Evidence', style: AppStyles.headlineMd, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Visual documentation helps our team diagnose the problem faster and bring the right tools. High-quality photos of the affected area are preferred.',
            style: AppStyles.bodyMd.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Click to upload or drag and drop',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG, JPG or JPEG (max. 50MB)',
                    style: AppStyles.bodySm.copyWith(color: AppColors.secondary),
                  ),
                ],
              ),
            ),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width < 400 ? 3 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
              children: [
                ...images.asMap().entries.map((entry) {
                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (entry.value.bytes != null)
                          Image.memory(entry.value.bytes!, fit: BoxFit.cover)
                        else
                          Center(
                            child: Icon(
                              Icons.image_rounded,
                              color: AppColors.primary.withValues(alpha: 0.3),
                              size: 32,
                            ),
                          ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => onRemove(entry.key),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant, width: 2),
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.secondary, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UrgencySection extends StatelessWidget {
  final String urgency;
  final bool showEmergencyTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onTooltipToggle;

  const _UrgencySection({
    required this.urgency,
    required this.showEmergencyTooltip,
    required this.onChanged,
    required this.onTooltipToggle,
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
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.priority_high_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text('Urgency Level', style: AppStyles.headlineMd, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _UrgencyCard(
            value: 'low',
            label: 'Low - Routine',
            description: "A minor issue that doesn't impact daily living (e.g., loose cupboard handle).",
            color: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            icon: Icons.info_outline_rounded,
            isSelected: urgency == 'low',
            onTap: () => onChanged('low'),
          ),
          const SizedBox(height: 16),
          _UrgencyCard(
            value: 'medium',
            label: 'Medium - Urgent',
            description: 'Needs attention within 48 hours (e.g., slow drain, broken AC).',
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            icon: Icons.warning_amber_rounded,
            isSelected: urgency == 'medium',
            showCheck: true,
            onTap: () => onChanged('medium'),
          ),
          const SizedBox(height: 16),
          _EmergencyCard(
            isSelected: urgency == 'high',
            showTooltip: showEmergencyTooltip,
            onTap: () => onChanged('high'),
            onTooltipToggle: onTooltipToggle,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Tip: ',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 14),
                        ),
                        TextSpan(
                          text: 'For after-hours emergencies, our dispatch team will call you within 15 minutes of submission.',
                          style: TextStyle(color: AppColors.onSurface, fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
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

class _UrgencyCard extends StatelessWidget {
  final String value;
  final String label;
  final String description;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final bool isSelected;
  final bool showCheck;
  final VoidCallback onTap;

  const _UrgencyCard({
    required this.value,
    required this.label,
    required this.description,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.isSelected,
    this.showCheck = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLow : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 16),
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
            if (isSelected && showCheck)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final bool isSelected;
  final bool showTooltip;
  final VoidCallback onTap;
  final VoidCallback onTooltipToggle;

  const _EmergencyCard({
    required this.isSelected,
    required this.showTooltip,
    required this.onTap,
    required this.onTooltipToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            onEnter: (_) => onTooltipToggle(),
            onExit: (_) => onTooltipToggle(),
            child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.error, width: 4)),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.error : AppColors.outlineVariant,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emergency_rounded, color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'High - Emergency',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.help_outline_rounded, color: AppColors.secondary, size: 16),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Immediate threat to health, safety, or property damage.',
                          style: AppStyles.bodySm.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
        if (showTooltip)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inverseSurface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What counts as an emergency?',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.inverseOnSurface, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...[
                  'Total loss of power or water',
                  'Major water leak or burst pipe',
                  'Gas leak (Call emergency services first!)',
                  'Security issues (broken front door/locks)',
                  'Fire or structural damage',
                ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.inverseOnSurface, fontSize: 14)),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(color: AppColors.inverseOnSurface.withValues(alpha: 0.9), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
      ],
    );
  }
}

class _NavigationFooter extends StatelessWidget {
  final bool canProceed;
  final VoidCallback onContinue;

  const _NavigationFooter({required this.canProceed, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.outlineVariant)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: isMobile
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: canProceed ? onContinue : null,
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: const Text('Next Step: Scheduling', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back'),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back'),
                    ),
                  ),
                  Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'PROGRESS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '66% Complete',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: canProceed ? onContinue : null,
                          icon: const Icon(Icons.calendar_today_rounded, size: 18),
                          label: const Text('Next Step: Scheduling', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
