import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/maintenance_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class CaretakerAlertHistoryScreen extends StatefulWidget {
  const CaretakerAlertHistoryScreen({super.key});

  @override
  State<CaretakerAlertHistoryScreen> createState() => _CaretakerAlertHistoryScreenState();
}

class _CaretakerAlertHistoryScreenState extends State<CaretakerAlertHistoryScreen> {
  final ApiService _api = ApiService();
  Future<List<MaintenanceItem>>? _future;

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

  Future<List<MaintenanceItem>> _fetch() async {
    final response = await _api.get('/maintenance/mine');
    if (response.statusCode != 200) {
      throw Exception('Could not load history (${response.statusCode})');
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .map((e) => MaintenanceItem.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Alert History', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontFamily: 'Lexend')),
      ),
      body: SafeArea(
        child: FutureBuilder<List<MaintenanceItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                    const SizedBox(height: 10),
                    const Text('Could not load alert history', style: AppStyles.bodyMedium),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final items = snapshot.data ?? const <MaintenanceItem>[];
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 48, color: AppColors.muted),
                    SizedBox(height: 12),
                    Text('No alerts recorded yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  ],
                ),
              );
            }
            final pending = items.where((i) => i.status.toLowerCase() == 'pending').toList();
            final inProgress = items.where((i) => i.status.toLowerCase() == 'in_progress').toList();
            final completed = items.where((i) => i.status.toLowerCase() == 'completed').toList();
            final cancelled = items.where((i) => i.status.toLowerCase() == 'cancelled').toList();

            return RefreshIndicator(
              onRefresh: () async { _reload(); await _future; },
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  if (pending.isNotEmpty) ...[
                    _groupHeader('Pending', pending.length, AppColors.kodiOrange),
                    ...pending.map((i) => _historyCard(i)),
                  ],
                  if (inProgress.isNotEmpty) ...[
                    _groupHeader('In Progress', inProgress.length, AppColors.kodiBlue),
                    ...inProgress.map((i) => _historyCard(i)),
                  ],
                  if (completed.isNotEmpty) ...[
                    _groupHeader('Completed', completed.length, AppColors.kodiGreen),
                    ...completed.map((i) => _historyCard(i)),
                  ],
                  if (cancelled.isNotEmpty) ...[
                    _groupHeader('Cancelled', cancelled.length, AppColors.muted),
                    ...cancelled.map((i) => _historyCard(i)),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _groupHeader(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color, fontFamily: 'Lexend')),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
            child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(MaintenanceItem item) {
    final statusColor = maintenanceStatusColor(item.status);
    final priorityColor = maintenancePriorityColor(item.priority);
    final time = relativeTime(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(_alertIcon(item.category), color: priorityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title.isEmpty ? capitalize(item.category) : item.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        maintenanceStatusLabel(item.status),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.description.isEmpty ? capitalize(item.category) : item.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _meta(Icons.schedule_rounded, time),
                    if (item.propertyName.isNotEmpty) _meta(Icons.location_on_outlined, item.propertyName),
                    if (item.unitNumber.isNotEmpty) _meta(Icons.meeting_room_outlined, 'Unit ${item.unitNumber}'),
                    _meta(Icons.flag_outlined, capitalize(item.priority)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
      ],
    );
  }

  IconData _alertIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.water_damage_rounded;
      case 'electrical':
        return Icons.bolt_rounded;
      case 'security':
        return Icons.lock_open_rounded;
      case 'hvac':
        return Icons.ac_unit_rounded;
      case 'structural':
        return Icons.foundation_rounded;
      default:
        return Icons.build_rounded;
    }
  }
}
