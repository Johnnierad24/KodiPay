import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class NoticeDetailScreen extends StatelessWidget {
  final NotificationItem item;
  const NoticeDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = paletteForType(item.type);
    return FeatureScaffold(
      title: _labelForType(item.type),
      accentColor: palette.color,
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(palette.icon, color: palette.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: AppStyles.heading2),
                          const SizedBox(height: 4),
                          Text(
                            relativeTime(item.createdAt),
                            style: AppStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _labelForType(item.type),
                    style: TextStyle(
                      color: palette.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Message', style: titleStyle),
                const SizedBox(height: 10),
                Text(
                  item.message.isEmpty
                      ? 'No additional details provided.'
                      : item.message,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Received ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} at '
                  '${item.createdAt.hour.toString().padLeft(2, '0')}:'
                  '${item.createdAt.minute.toString().padLeft(2, '0')}',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _labelForType(String type) {
  switch (type.toLowerCase()) {
    case 'reminder':
    case 'rent_reminder':
    case 'sms_reminder':
      return 'Rent Reminder';
    case 'maintenance':
      return 'Maintenance Update';
    case 'announcement':
      return 'Announcement';
    case 'payment':
    case 'mpesa':
      return 'Payment';
    case 'alert':
    case 'warning':
      return 'Alert';
    default:
      return 'Notice';
  }
}

