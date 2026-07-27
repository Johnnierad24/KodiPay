import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class LandlordNotificationsScreen extends StatefulWidget {
  const LandlordNotificationsScreen({super.key});

  @override
  State<LandlordNotificationsScreen> createState() =>
      _LandlordNotificationsScreenState();
}

class _LandlordNotificationsScreenState
    extends State<LandlordNotificationsScreen> {
  final ApiService _api = ApiService();
  Future<List<NotificationItem>>? _future;
  bool _markingAll = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<List<NotificationItem>> _fetch() async {
    final response = await _api.get('/notifications');
    if (response.statusCode != 200) {
      throw Exception('Could not load notifications (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .where((item) => !item.isRead)
        .toList();
  }

  Future<void> _markOne(int id) async {
    try {
      await _api.put('/notifications/$id/read');
      _changed = true;
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark as read')),
      );
    }
  }

  Future<void> _markAll() async {
    setState(() => _markingAll = true);
    try {
      await _api.put('/notifications/read-all');
      _changed = true;
      if (!mounted) return;
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark all as read')),
      );
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _changed);
      },
      child: FeatureScaffold(
        title: 'Notifications',
        accentColor: AppColors.kodiBlue,
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<NotificationItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(40),
                  children: [
                    const SizedBox(height: 60),
                    const Icon(Icons.error_outline_rounded,
                        size: 56, color: AppColors.danger),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                );
              }
              final items = snapshot.data ?? const <NotificationItem>[];
              if (items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(40),
                  children: const [
                    SizedBox(height: 80),
                    Icon(Icons.notifications_none_rounded,
                        size: 72, color: AppColors.muted),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        'You\'re all caught up',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 6),
                    Center(
                      child: Text(
                        'New activity will show up here.',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  for (final item in items) NotificationApiCard(
                    item: item,
                    onMarkRead: () => _markOne(item.id),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _markingAll ? null : _markAll,
                    icon: _markingAll
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.done_all_rounded),
                    label: Text(_markingAll
                        ? 'Marking...'
                        : 'Mark All as Read (${items.length})'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class NotificationApiCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onMarkRead;

  const NotificationApiCard({super.key, required this.item, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final palette = paletteForType(item.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
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
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.message, style: AppStyles.bodyMedium),
                ],
                const SizedBox(height: 6),
                Text(
                  relativeTime(item.createdAt),
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mark as read',
            onPressed: onMarkRead,
            icon: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.kodiGreen),
          ),
        ],
      ),
    );
  }
}

class NotificationPalette {
  final Color color;
  final IconData icon;
  const NotificationPalette(this.color, this.icon);
}

NotificationPalette paletteForType(String type) {
  switch (type.toLowerCase()) {
    case 'reminder':
    case 'rent_reminder':
      return const NotificationPalette(AppColors.kodiBlue, Icons.sms_outlined);
    case 'maintenance':
      return const NotificationPalette(
          AppColors.kodiOrange, Icons.build_outlined);
    case 'payment':
    case 'mpesa':
      return const NotificationPalette(
          AppColors.kodiGreen, Icons.verified_outlined);
    case 'alert':
    case 'warning':
      return const NotificationPalette(
          AppColors.danger, Icons.warning_amber_rounded);
    default:
      return const NotificationPalette(
          AppColors.kodiNavy, Icons.notifications_active_outlined);
  }
}

String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}

