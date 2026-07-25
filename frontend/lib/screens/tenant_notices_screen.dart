import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'notice_detail_screen.dart';

class TenantNoticesScreen extends StatefulWidget {
  const TenantNoticesScreen({super.key});

  @override
  State<TenantNoticesScreen> createState() => _TenantNoticesScreenState();
}

class _TenantNoticesScreenState extends State<TenantNoticesScreen> {
  final ApiService _api = ApiService();
  Future<List<NotificationItem>>? _future;

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
      throw Exception('Could not load notices (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _openNotice(NotificationItem item) async {
    if (!item.isRead) {
      try {
        await _api.put('/notifications/${item.id}/read');
      } catch (_) {
        // Non-fatal — proceed to open the detail screen.
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoticeDetailScreen(item: item)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Notices',
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
                padding: const EdgeInsets.all(30),
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.error_outline_rounded,
                      size: 56, color: AppColors.danger),
                  const SizedBox(height: 12),
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
                      'No notices yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Reminders, announcements, and maintenance updates will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final item in items)
                  _TenantNoticeCard(
                    item: item,
                    onTap: () => _openNotice(item),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TenantNoticeCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _TenantNoticeCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = paletteForType(item.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TappableCard(
        onTap: onTap,
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
                  Row(
                    children: [
                      Expanded(child: Text(item.title, style: titleStyle)),
                      if (!item.isRead)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.kodiBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (item.message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.caption,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(relativeTime(item.createdAt), style: AppStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

