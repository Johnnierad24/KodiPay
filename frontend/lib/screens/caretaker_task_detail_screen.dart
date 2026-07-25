import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/maintenance_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import '../widgets/shared_screen_components.dart';

class CaretakerTaskDetailScreen extends StatefulWidget {
  final MaintenanceItem item;
  final bool isEmergency;
  const CaretakerTaskDetailScreen({
    super.key,
    required this.item,
    this.isEmergency = false,
  });

  @override
  State<CaretakerTaskDetailScreen> createState() =>
      _CaretakerTaskDetailScreenState();
}

class _CaretakerTaskDetailScreenState extends State<CaretakerTaskDetailScreen> {
  final ApiService _api = ApiService();
  late MaintenanceItem _item;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _setStatus(String status, String label) async {
    setState(() => _submitting = true);
    try {
      final response = await _api
          .put('/maintenance/${_item.id}/status', {'status': status});
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _item = MaintenanceItem(
            id: _item.id,
            title: _item.title,
            description: _item.description,
            status: (data['status'] ?? status).toString(),
            priority: _item.priority,
            category: _item.category,
            propertyName: _item.propertyName,
            unitNumber: _item.unitNumber,
            tenantName: _item.tenantName,
            tenantPhone: _item.tenantPhone,
            tenantEmail: _item.tenantEmail,
            createdAt: _item.createdAt,
            updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? '') ??
                DateTime.now(),
          );
          _submitting = false;
        });
        showSnack(context, '$label.');
      } else {
        setState(() => _submitting = false);
        showSnack(context,
            'Failed to update status (${response.statusCode}).');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showSnack(context, 'Failed to update status: $e');
    }
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    showSnack(context, '$label copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = maintenanceStatusColor(_item.status);
    final statusLabel = maintenanceStatusLabel(_item.status);
    final accent =
        widget.isEmergency ? AppColors.danger : AppColors.kodiOrange;
    final phone = _item.tenantPhone?.trim();
    final email = _item.tenantEmail?.trim();
    final tenantName = _item.tenantName.isEmpty ? 'Tenant' : _item.tenantName;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _item.status != widget.item.status);
      },
      child: FeatureScaffold(
        title: widget.isEmergency ? 'Emergency' : 'Task',
        accentColor: accent,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TappableCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          widget.isEmergency
                              ? Icons.warning_rounded
                              : Icons.handyman_rounded,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_item.title, style: AppStyles.heading2),
                            const SizedBox(height: 4),
                            Text(
                              _item.unitNumber.isEmpty
                                  ? _item.propertyName
                                  : '${_item.propertyName} • Unit ${_item.unitNumber}',
                              style: AppStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusPill(label: statusLabel, color: statusColor),
                      MaintenanceTag(
                        label: capitalizeWord(_item.priority),
                        color: maintenancePriorityColor(_item.priority),
                      ),
                      MaintenanceTag(
                        label: capitalizeWord(_item.category),
                        color: AppColors.kodiNavy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TappableCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: titleStyle),
                  const SizedBox(height: 8),
                  Text(
                    _item.description.isEmpty
                        ? 'No description provided.'
                        : _item.description,
                    style: const TextStyle(
                        color: AppColors.textDark, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TappableCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reported by', style: titleStyle),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        child: Text(
                          tenantName.isNotEmpty
                              ? tenantName.characters.first.toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(tenantName,
                            style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _ContactRow(
                      icon: Icons.call_outlined,
                      label: phone,
                      onTap: () => _copy('Phone number', phone),
                    ),
                  ],
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _ContactRow(
                      icon: Icons.mail_outline_rounded,
                      label: email,
                      onTap: () => _copy('Email', email),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            TappableCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Timeline', style: titleStyle),
                  const SizedBox(height: 12),
                  MaintenanceTimelineRow(
                    icon: Icons.report_problem_outlined,
                    color: AppColors.kodiBlue,
                    label: 'Reported',
                    time: _item.createdAt,
                  ),
                  if (_item.updatedAt != _item.createdAt)
                    MaintenanceTimelineRow(
                      icon: _item.isResolved
                          ? Icons.check_circle_outline
                          : Icons.timelapse_outlined,
                      color: statusColor,
                      label: 'Last updated ($statusLabel)',
                      time: _item.updatedAt,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_item.isResolved)
              const TappableCard(
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.kodiGreen),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This has been marked completed. The tenant has been notified.',
                        style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              if (_item.status.toLowerCase() == 'pending')
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => _setStatus('in_progress', 'Marked in progress'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start working on this'),
                  ),
                ),
              if (_item.status.toLowerCase() == 'pending')
                const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submitting
                      ? null
                      : () => _setStatus(
                            'completed',
                            widget.isEmergency
                                ? 'Emergency resolved'
                                : 'Task completed',
                          ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : Icon(widget.isEmergency
                          ? Icons.health_and_safety_outlined
                          : Icons.check_circle_outline_rounded),
                  label: Text(
                    widget.isEmergency
                        ? 'Mark Emergency Resolved'
                        : 'Mark Task Complete',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppColors.kodiBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.copy_rounded, color: AppColors.muted, size: 16),
          ],
        ),
      ),
    );
  }
}
