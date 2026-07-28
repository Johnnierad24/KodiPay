import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/maintenance_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'caretaker_task_detail_screen.dart';

class CaretakerAlertsScreen extends StatefulWidget {
  const CaretakerAlertsScreen({super.key});

  @override
  State<CaretakerAlertsScreen> createState() => _CaretakerAlertsScreenState();
}

class _CaretakerAlertsScreenState extends State<CaretakerAlertsScreen> {
  final ApiService _api = ApiService();
  Future<_AlertBundle>? _future;

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

  Future<_AlertBundle> _fetch() async {
    final emergResp = await _api.get('/maintenance/mine', query: {'priority': 'emergency'});
    final recentResp = await _api.get('/maintenance/mine', query: {'status': 'pending'});
    final doneResp = await _api.get('/maintenance/mine', query: {'status': 'completed'});

    final List<MaintenanceItem> emergency = emergResp.statusCode == 200
        ? (jsonDecode(emergResp.body) as List).map((e) => MaintenanceItem.fromJson(e)).where((m) => !m.isResolved).toList()
        : [];
    final List<MaintenanceItem> recent = recentResp.statusCode == 200
        ? (jsonDecode(recentResp.body) as List).map((e) => MaintenanceItem.fromJson(e)).toList()
        : [];
    final List<MaintenanceItem> completed = doneResp.statusCode == 200
        ? (jsonDecode(doneResp.body) as List).map((e) => MaintenanceItem.fromJson(e)).toList()
        : [];

    return _AlertBundle(emergency: emergency, recent: recent, completed: completed);
  }

  Future<void> _acknowledge(MaintenanceItem item) async {
    try {
      final response = await _api.put('/maintenance/${item.id}/status', {'status': 'in_progress'});
      if (response.statusCode == 200 && mounted) {
        showSnack(context, 'Alert acknowledged');
        _reload();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 1000;

    return Stack(
      children: [
        Container(
          color: AppColors.background,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                sliver: SliverToBoxAdapter(child: _buildPageHeader()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                sliver: SliverToBoxAdapter(child: _buildBentoStats()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: FutureBuilder<_AlertBundle>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                                const SizedBox(height: 10),
                                const Text('Could not load alerts', style: AppStyles.bodyMedium),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _reload,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final bundle = snapshot.data ?? const _AlertBundle(emergency: [], recent: [], completed: []);
                      final urgentCount = bundle.emergency.length;
                      final pendingCount = bundle.recent.where((i) => i.priority != 'emergency').length;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _buildAlertsFeed(bundle)),
                            const SizedBox(width: 18),
                            SizedBox(width: 320, child: _buildSidePanel(bundle, urgentCount, pendingCount)),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildAlertsFeed(bundle),
                          const SizedBox(height: 18),
                          _buildSidePanel(bundle, urgentCount, pendingCount),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton(
            onPressed: () => showSnack(context, 'New incident report'),
            backgroundColor: AppColors.kodiGreen,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Alerts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
              SizedBox(height: 4),
              Text('Real-time monitoring of property infrastructure and security.', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            Material(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list_rounded, size: 16, color: AppColors.textDark),
                      SizedBox(width: 6),
                      Text('Filter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: AppColors.kodiNavy,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Alert History', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final statCards = [
          _statCard('Urgent Alerts', '04', AppColors.danger, Icons.warning_rounded, AppColors.dangerSoft),
          _statCard('Pending Notices', '12', AppColors.kodiNavy, Icons.mail_rounded, AppColors.kodiNavy.withValues(alpha: 0.1)),
          _statCard('Avg. Response Time', '18m', AppColors.kodiGreen, Icons.speed_rounded, AppColors.kodiGreen.withValues(alpha: 0.1)),
        ];

        if (isNarrow) {
          return Column(
            children: [
              statCards[0],
              const SizedBox(height: 12),
              statCards[1],
              const SizedBox(height: 12),
              statCards[2],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: statCards[0]),
            const SizedBox(width: 16),
            Expanded(child: statCards[1]),
            const SizedBox(width: 16),
            Expanded(child: statCards[2]),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon, Color iconBg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color, fontFamily: 'Lexend')),
            ],
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsFeed(_AlertBundle bundle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in bundle.emergency) ...[
          _urgentAlertCard(item),
          const SizedBox(height: 12),
        ],
        for (final item in bundle.recent.where((i) => i.priority != 'emergency')) ...[
          _noticeCard(item),
          const SizedBox(height: 12),
        ],
        if (bundle.emergency.isEmpty && bundle.recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.muted),
                  SizedBox(height: 12),
                  Text('No active alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  SizedBox(height: 4),
                  Text('All systems are operating normally.', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _urgentAlertCard(MaintenanceItem item) {
    final icon = _alertIcon(item.category);
    final time = _timeAgo(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger, width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(width: 6, decoration: const BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: AppColors.danger, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _alertTitle(item),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(999)),
                            child: const Text('URGENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.danger, letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description.isEmpty ? 'Immediate attention required.' : item.description,
                        style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _metaChip(Icons.schedule_rounded, time),
                          const SizedBox(width: 12),
                          _metaChip(Icons.location_on_outlined, item.propertyName),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Material(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => showSnack(context, 'Dispatching team...'),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text('Dispatch Team', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 130,
                      child: Material(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _acknowledge(item),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text('Acknowledge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            ),
                          ),
                        ),
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

  Widget _noticeCard(MaintenanceItem item) {
    final icon = _alertIcon(item.category);
    final time = _timeAgo(item.createdAt);
    final label = _noticeLabel(item);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.kodiNavy, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _alertTitle(item),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(999)),
                        child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.kodiNavy, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description.isEmpty ? capitalize(item.category) : item.description,
                    style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _metaChip(Icons.schedule_rounded, time),
                      const SizedBox(width: 12),
                      if (item.unitNumber.isNotEmpty)
                        _metaChip(Icons.person_outline_rounded, 'Unit ${item.unitNumber}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                SizedBox(
                  width: 130,
                  child: Material(
                    color: AppColors.kodiGreen,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => showSnack(context, 'Action initiated'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text('Take Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 130,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CaretakerTaskDetailScreen(item: item)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: const Center(
                          child: Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                        ),
                      ),
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

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSidePanel(_AlertBundle bundle, int urgentCount, int pendingCount) {
    final totalItems = bundle.emergency.length + bundle.recent.length + bundle.completed.length;
    final criticalPct = totalItems > 0 ? (bundle.emergency.length / totalItems * 100).round() : 25;
    final maintenancePct = totalItems > 0 ? (bundle.recent.length / totalItems * 100).round() : 45;
    final adminPct = 100 - criticalPct - maintenancePct;

    return Column(
      children: [
        _buildDispatchCard(),
        const SizedBox(height: 16),
        _buildPriorityChart(criticalPct, maintenancePct, adminPct),
        const SizedBox(height: 16),
        _buildResolvedFeed(bundle.completed),
      ],
    );
  }

  Widget _buildDispatchCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map_outlined, size: 16, color: AppColors.kodiNavy),
                    SizedBox(width: 8),
                    Text('Active Dispatches', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  ],
                ),
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(color: AppColors.kodiGreen, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.kodiNavy.withValues(alpha: 0.05), AppColors.kodiGreen.withValues(alpha: 0.05)],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.map_outlined, size: 48, color: AppColors.muted.withValues(alpha: 0.3)),
                Positioned(
                  top: 50, left: 80,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.4), blurRadius: 8)],
                    ),
                  ),
                ),
                Positioned(
                  top: 80, left: 160,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.kodiOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                Positioned(
                  top: 60, left: 200,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.kodiGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '3 maintenance crews currently active in Nairobi Central District.',
              style: TextStyle(fontSize: 11, color: AppColors.textLight.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChart(int critical, int maintenance, int admin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alert Priority', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 16),
          _priorityBar('Critical', critical, AppColors.danger),
          const SizedBox(height: 14),
          _priorityBar('Maintenance', maintenance, AppColors.kodiGreen),
          const SizedBox(height: 14),
          _priorityBar('Administrative', admin, AppColors.kodiNavy),
        ],
      ),
    );
  }

  Widget _priorityBar(String label, int pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct / 100.0,
            backgroundColor: AppColors.surfaceLow,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildResolvedFeed(List<MaintenanceItem> completed) {
    final recent = completed.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resolved Recently', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No recently resolved alerts.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
            )
          else
            ...recent.asMap().entries.map((entry) {
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: entry.key < recent.length - 1 ? 14 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(color: AppColors.kodiGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_alertTitle(item), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text(
                            'Marked as resolved',
                            style: TextStyle(fontSize: 11, color: AppColors.textLight.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _timeAgo(item.updatedAt),
                            style: const TextStyle(fontSize: 10, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _alertTitle(MaintenanceItem item) {
    if (item.title.isNotEmpty) return item.title;
    if (item.priority == 'emergency') return 'Emergency: ${capitalize(item.category)}';
    return capitalize(item.category);
  }

  String _noticeLabel(MaintenanceItem item) {
    if (item.category.toLowerCase() == 'plumbing' || item.category.toLowerCase() == 'electrical') return 'Maintenance';
    if (item.priority == 'high' || item.priority == 'emergency') return 'Finance';
    return 'Information';
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

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _AlertBundle {
  final List<MaintenanceItem> emergency;
  final List<MaintenanceItem> recent;
  final List<MaintenanceItem> completed;
  const _AlertBundle({required this.emergency, required this.recent, required this.completed});
}
