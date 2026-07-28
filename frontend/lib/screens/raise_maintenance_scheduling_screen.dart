import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'maintenance_submitted_screen.dart';

class RaiseMaintenanceSchedulingScreen extends StatefulWidget {
  const RaiseMaintenanceSchedulingScreen({super.key});

  @override
  State<RaiseMaintenanceSchedulingScreen> createState() => _RaiseMaintenanceSchedulingScreenState();
}

class _RaiseMaintenanceSchedulingScreenState extends State<RaiseMaintenanceSchedulingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  bool _allowUnattended = true;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
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
  final ValueChanged<bool> onToggleUnattended;

  const _RightColumn({
    required this.allowUnattended,
    required this.selectedDate,
    required this.selectedTime,
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
        _RequestSummaryCard(selectedDate: selectedDate, selectedTime: selectedTime),
        const SizedBox(height: 24),
        _ActionButtons(
          canSubmit: selectedTime != null,
          onSubmit: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MaintenanceSubmittedScreen()),
            (route) => route.isFirst,
          ),
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

  const _RequestSummaryCard({required this.selectedDate, required this.selectedTime});

  @override
  Widget build(BuildContext context) {
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
                            'Plumbing - Leaking Faucet',
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
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onErrorContainer),
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
                  'Medium Priority',
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
}

class _ActionButtons extends StatelessWidget {
  final bool canSubmit;
  final VoidCallback onSubmit;

  const _ActionButtons({required this.canSubmit, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: canSubmit ? onSubmit : null,
            icon: const Icon(Icons.send_rounded, size: 20),
            label: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
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
