import 'package:flutter/material.dart';
import '../models/maintenance_item.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import '../widgets/shared_screen_components.dart';

class MaintenanceDetailScreen extends StatelessWidget {
  final MaintenanceItem item;
  const MaintenanceDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = maintenanceStatusColor(item.status);
    final statusLabel = maintenanceStatusLabel(item.status);
    return FeatureScaffold(
      title: 'Issue Details',
      accentColor: statusColor,
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
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.build_circle_outlined,
                          color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: AppStyles.heading2),
                          const SizedBox(height: 4),
                          Text(
                            item.unitNumber.isEmpty
                                ? item.propertyName
                                : '${item.propertyName} • Unit ${item.unitNumber}',
                            style: AppStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    StatusPill(label: statusLabel, color: statusColor),
                    const SizedBox(width: 8),
                    MaintenanceTag(
                      label: capitalizeWord(item.priority),
                      color: maintenancePriorityColor(item.priority),
                    ),
                    const SizedBox(width: 8),
                    MaintenanceTag(
                      label: capitalizeWord(item.category),
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
                  item.description.isEmpty
                      ? 'No description provided.'
                      : item.description,
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
                const Text('Timeline', style: titleStyle),
                const SizedBox(height: 12),
                MaintenanceTimelineRow(
                  icon: Icons.report_problem_outlined,
                  color: AppColors.kodiBlue,
                  label: 'Reported',
                  time: item.createdAt,
                ),
                if (item.updatedAt != item.createdAt)
                  MaintenanceTimelineRow(
                    icon: item.status.toLowerCase() == 'completed'
                        ? Icons.check_circle_outline
                        : Icons.timelapse_outlined,
                    color: statusColor,
                    label: 'Last updated ($statusLabel)',
                    time: item.updatedAt,
                  ),
                if (item.status.toLowerCase() == 'completed') ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Your caretaker marked this issue as completed.',
                    style: AppStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
