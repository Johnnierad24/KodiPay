import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'maintenance_submitted_screen.dart';

class RaiseMaintenanceSchedulingScreen extends StatefulWidget {
  final String category;
  final String description;
  final String urgency;
  final List<PlatformFile> images;

  const RaiseMaintenanceSchedulingScreen({
    super.key,
    required this.category,
    required this.description,
    required this.urgency,
    required this.images,
  });

  @override
  State<RaiseMaintenanceSchedulingScreen> createState() => _RaiseMaintenanceSchedulingScreenState();
}

class _RaiseMaintenanceSchedulingScreenState extends State<RaiseMaintenanceSchedulingScreen> {
  final ApiService _api = ApiService();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  bool _allowUnattended = true;
  bool _submitting = false;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  Future<void> _submit() async {
    final description = widget.description.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the issue before submitting.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final tenanciesResponse = await _api.get('/tenancies');
      if (tenanciesResponse.statusCode != 200) {
        throw Exception('Could not load your tenancy');
      }
      final tenancies = jsonDecode(tenanciesResponse.body) as List<dynamic>;
      Map<String, dynamic>? activeTenancy;
      for (final item in tenancies) {
        final map = (item as Map).cast<String, dynamic>();
        if (map['status'] == 'active') {
          activeTenancy = map;
          break;
        }
      }
      if (activeTenancy == null) {
        throw Exception('No active tenancy found on your account');
      }
      final unitId = activeTenancy['unit_id'];
      if (unitId == null) {
        throw Exception('No unit linked to your tenancy');
      }

      final response = await _api.post('/maintenance', {
        'unit_id': unitId,
        'title': _buildTitle(),
        'description': description,
        'category': _normalizeCategory(widget.category),
        'priority': widget.urgency,
      });
      if (!mounted) return;
      if (response.statusCode == 201) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MaintenanceSubmittedScreen()),
          (route) => route.isFirst,
        );
      } else {
        String message = 'Failed to submit request (${response.statusCode}).';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['error'] != null) {
            message = body['error'].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit request: $e')));
      setState(() => _submitting = false);
    }
  }

  String _buildTitle() {
    final label = _categoryLabel(widget.category);
    final desc = widget.description.trim().replaceAll('\n', ' ');
    if (desc.isEmpty) return '$label issue';
    final snippet = desc.length <= 48 ? desc : '${desc.substring(0, 48).trimRight()}...';
    return '$label - $snippet';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Maintenance', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          _WizardProgress(),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _CalendarSection(
                      selectedDate: _selectedDate,
                      focusedMonth: _focusedMonth,
                      onDateSelected: (d) => setState(() => _selectedDate = d),
                      onMonthChanged: (m) => setState(() => _focusedMonth = m),
                      selectedTime: _selectedTime,
                      onTimeSelected: (t) => setState(() => _selectedTime = t),
                    ),
                    const SizedBox(height: 24),
                    _RightColumn(
                      allowUnattended: _allowUnattended,
                      selectedDate: _selectedDate,
                      selectedTime: _selectedTime,
                      category: widget.category,
                      description: widget.description,
                      urgency: widget.urgency,
                      submitting: _submitting,
                      onSubmit: _submit,
                      onToggleUnattended: (v) => setState(() => _allowUnattended = v),
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _CalendarSection(
                      selectedDate: _selectedDate,
                      focusedMonth: _focusedMonth,
                      onDateSelected: (d) => setState(() => _selectedDate = d),
                      onMonthChanged: (m) => setState(() => _focusedMonth = m),
                      selectedTime: _selectedTime,
                      onTimeSelected: (t) => setState(() => _selectedTime = t),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 5,
                    child: _RightColumn(
                      allowUnattended: _allowUnattended,
                      selectedDate: _selectedDate,
                      selectedTime: _selectedTime,
                      category: widget.category,
                      description: widget.description,
                      urgency: widget.urgency,
                      submitting: _submitting,
                      onSubmit: _submit,
                      onToggleUnattended: (v) => setState(() => _allowUnattended = v),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WizardProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step 3 of 3: Scheduling',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.primary),
            ),
            Text(
              'Finalizing Request',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(3, (i) => Expanded(
            child: Container(
              height: 8,
              margin: i < 2 ? const EdgeInsets.only(right: 8) : null,
              decoration: BoxDecoration(
                color: AppColors.tertiaryFixed,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
        ),
      ],
    );
  }
}

class _CalendarSection extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;
  final String? selectedTime;
  final ValueChanged<String> onTimeSelected;

  const _CalendarSection({
    required this.selectedDate,
    required this.focusedMonth,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Select Preferred Date', style: AppStyles.headlineMd, overflow: TextOverflow.ellipsis),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: focusedMonth.isAfter(DateTime(DateTime.now().year, DateTime.now().month))
                        ? () => onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month - 1))
                        : null,
                  ),
                  const SizedBox(width: 4),
                  _NavArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + 1)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(_monthName(focusedMonth.month), style: AppStyles.bodyMd),
          const SizedBox(height: 16),
          _CalendarGrid(
            focusedMonth: focusedMonth,
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHOOSE TIME SLOTS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 140,
                      child: _TimeSlotChip(
                        icon: Icons.light_mode_rounded,
                        label: 'Morning',
                        sublabel: '8:00 - 12:00',
                        isSelected: selectedTime == 'morning',
                        onTap: () => onTimeSelected('morning'),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: _TimeSlotChip(
                        icon: Icons.wb_sunny_rounded,
                        label: 'Afternoon',
                        sublabel: '12:00 - 16:00',
                        isSelected: selectedTime == 'afternoon',
                        onTap: () => onTimeSelected('afternoon'),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: _TimeSlotChip(
                        icon: Icons.dark_mode_rounded,
                        label: 'Evening',
                        sublabel: '16:00 - 19:00',
                        isSelected: selectedTime == 'evening',
                        onTap: () => onTimeSelected('evening'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[m - 1];
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: onTap != null ? AppColors.primary : AppColors.outline, size: 20),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = today.add(const Duration(days: 30));
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(focusedMonth.year, focusedMonth.month, 1).weekday - 1;

    return Column(
      children: [
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => Expanded(
            child: Center(
              child: Text(
                d,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondary),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.outlineVariant),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.2,
          children: List.generate(firstWeekday + daysInMonth, (i) {
            if (i < firstWeekday) return const SizedBox.shrink();
            final day = i - firstWeekday + 1;
            final date = DateTime(focusedMonth.year, focusedMonth.month, day);
            final isDisabled = date.isBefore(today) || date.isAfter(lastDay);
            final isSelected = date == selectedDate;

            return GestureDetector(
              onTap: isDisabled ? null : () => onDateSelected(date),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isDisabled
                              ? AppColors.outline.withValues(alpha: 0.4)
                              : AppColors.primary,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isSelected,
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
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.tertiaryFixed : AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white.withValues(alpha: 0.7) : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  final bool allowUnattended;
  final DateTime selectedDate;
  final String? selectedTime;
  final String category;
  final String description;
  final String urgency;
  final bool submitting;
  final VoidCallback onSubmit;
  final ValueChanged<bool> onToggleUnattended;

  const _RightColumn({
    required this.allowUnattended,
    required this.selectedDate,
    required this.selectedTime,
    required this.category,
    required this.description,
    required this.urgency,
    required this.submitting,
    required this.onSubmit,
    required this.onToggleUnattended,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _UnattendedToggle(
          allowUnattended: allowUnattended,
          onChanged: onToggleUnattended,
        ),
        const SizedBox(height: 24),
        _RequestSummaryCard(
          selectedDate: selectedDate,
          selectedTime: selectedTime,
          category: category,
          description: description,
          urgency: urgency,
        ),
        const SizedBox(height: 24),
        _ActionButtons(
          canSubmit: selectedTime != null,
          submitting: submitting,
          onSubmit: onSubmit,
        ),
        const SizedBox(height: 24),
        _HelpBento(),
      ],
    );
  }
}

class _UnattendedToggle extends StatelessWidget {
  final bool allowUnattended;
  final ValueChanged<bool> onChanged;

  const _UnattendedToggle({required this.allowUnattended, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unattended Entry',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Allow the caretaker to enter the premises if you are not home during the selected slot.',
                  style: AppStyles.bodySm.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => onChanged(!allowUnattended),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: allowUnattended ? AppColors.tertiaryFixedDim : AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: allowUnattended ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestSummaryCard extends StatelessWidget {
  final DateTime selectedDate;
  final String? selectedTime;
  final String category;
  final String description;
  final String urgency;

  const _RequestSummaryCard({
    required this.selectedDate,
    required this.selectedTime,
    required this.category,
    required this.description,
    required this.urgency,
  });

  @override
  Widget build(BuildContext context) {
    final descSnippet = description.trim().replaceAll('\n', ' ');
    final issueLine = '$categoryName - ${descSnippet.isEmpty ? 'no details provided' : (descSnippet.length <= 40 ? descSnippet : '${descSnippet.substring(0, 40).trimRight()}...')}';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: const Text(
              'REQUEST SUMMARY',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.onPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ISSUE TYPE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            issueLine,
                            style: AppStyles.bodyMd.copyWith(color: AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: urgencyBadgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        urgencyLabel.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: urgencyBadgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'PRIORITY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '$urgencyLabel Priority',
                  style: AppStyles.bodyMd.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PREFERRED SLOT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedTime == null ? _formatDate(selectedDate) : '${_formatDate(selectedDate)} - ${_timeLabel(selectedTime!)}',
                  style: AppStyles.bodyMd.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.outlineVariant)),
                  ),
                  child: GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, color: AppColors.secondary, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Edit Details',
                          style: AppStyles.bodyMd.copyWith(color: AppColors.secondary),
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

  String get categoryName => _categoryLabel(category);
  String get urgencyLabel => _urgencyLabel(urgency);
  Color get urgencyBadgeColor => _urgencyBadgeColor(urgency);
  Color get urgencyBadgeBg => _urgencyBadgeBg(urgency);
}

class _ActionButtons extends StatelessWidget {
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onSubmit;

  const _ActionButtons({
    required this.canSubmit,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: canSubmit && !submitting ? onSubmit : null,
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 20),
            label: Text(
              submitting ? 'Submitting...' : 'Submit Request',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel & Discard'),
          ),
        ),
      ],
    );
  }
}

class _HelpBento extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.support_agent_rounded, color: AppColors.tertiaryFixed, size: 24),
          const SizedBox(height: 8),
          const Text(
            'Need Help?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.white, height: 1.33),
          ),
          const SizedBox(height: 4),
          Text(
            'Our caretaker team usually responds within 2 hours for urgent issues.',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), height: 1.43),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Live Chat with Caretaker',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
                color: AppColors.tertiaryFixed,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.tertiaryFixed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _normalizeCategory(String value) {
  switch (value.toLowerCase()) {
    case 'plumbing':
    case 'electrical':
    case 'structural':
      return value.toLowerCase();
    case 'appliances':
    case 'general':
    default:
      return 'other';
  }
}

String _categoryLabel(String value) {
  switch (value.toLowerCase()) {
    case 'plumbing':
      return 'Plumbing';
    case 'electrical':
      return 'Electrical';
    case 'structural':
      return 'Structural';
    case 'appliances':
      return 'Appliances';
    case 'general':
      return 'General';
    default:
      return 'Maintenance';
  }
}

String _urgencyLabel(String value) {
  switch (value.toLowerCase()) {
    case 'low':
      return 'Low';
    case 'high':
    case 'urgent':
      return 'High';
    case 'emergency':
      return 'Emergency';
    default:
      return 'Medium';
  }
}

Color _urgencyBadgeColor(String value) {
  switch (value.toLowerCase()) {
    case 'emergency':
      return AppColors.danger;
    case 'high':
    case 'urgent':
      return AppColors.warning;
    case 'low':
      return AppColors.info;
    default:
      return AppColors.primary;
  }
}

Color _urgencyBadgeBg(String value) {
  switch (value.toLowerCase()) {
    case 'emergency':
      return AppColors.dangerSoft;
    case 'high':
    case 'urgent':
      return AppColors.warningSoft;
    case 'low':
      return AppColors.infoSoft;
    default:
      return AppColors.primaryFixed;
  }
}

String _formatDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _timeLabel(String value) {
  switch (value) {
    case 'morning':
      return 'Morning (8:00 - 12:00)';
    case 'afternoon':
      return 'Afternoon (12:00 - 16:00)';
    case 'evening':
      return 'Evening (16:00 - 19:00)';
    default:
      return value;
  }
}
