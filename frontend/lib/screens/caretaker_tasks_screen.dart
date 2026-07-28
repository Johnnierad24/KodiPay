import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/maintenance_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'caretaker_task_detail_screen.dart';

class CaretakerTasksScreen extends StatefulWidget {
  const CaretakerTasksScreen({super.key});

  @override
  State<CaretakerTasksScreen> createState() => _CaretakerTasksScreenState();
}

class _CaretakerTasksScreenState extends State<CaretakerTasksScreen> {
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
      throw Exception('Could not load tasks (${response.statusCode})');
    }
    final all = (jsonDecode(response.body) as List<dynamic>)
        .map((item) => MaintenanceItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return all;
  }

  Future<void> _open(MaintenanceItem item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CaretakerTaskDetailScreen(item: item)),
    );
    if (changed == true) _reload();
  }

  Future<void> _startTask(MaintenanceItem item) async {
    try {
      final response = await _api.put('/maintenance/${item.id}/status', {'status': 'in_progress'});
      if (response.statusCode == 200 && mounted) {
        showSnack(context, 'Task started');
        _reload();
      }
    } catch (_) {}
  }

  Future<void> _completeTask(MaintenanceItem item) async {
    try {
      final response = await _api.put('/maintenance/${item.id}/status', {'status': 'completed'});
      if (response.statusCode == 200 && mounted) {
        showSnack(context, 'Task completed!');
        _reload();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 1000;

    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            sliver: SliverToBoxAdapter(
              child: _buildToolbar(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<List<MaintenanceItem>>(
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
                            Text(snapshot.error.toString(), textAlign: TextAlign.center, style: AppStyles.bodyMedium),
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
                  final items = snapshot.data ?? const <MaintenanceItem>[];
                  final todo = items.where((i) => i.status.toLowerCase() == 'pending').toList();
                  final inProgress = items.where((i) => i.status.toLowerCase() == 'in_progress').toList();
                  final done = items.where((i) => i.status.toLowerCase() == 'completed').toList();
                  final allOpen = items.where((i) => !i.isResolved).toList();
                  final critical = items.where((i) => i.priority == 'emergency' && !i.isResolved).length;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 520,
                            child: _buildKanbanBoard(todo, inProgress, done),
                          ),
                        ),
                        const SizedBox(width: 18),
                        SizedBox(width: 240, child: _buildStatsPanel(allOpen.length, critical, items)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      SizedBox(
                        height: 480,
                        child: _buildKanbanBoard(todo, inProgress, done),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsPanel(allOpen.length, critical, items),
                    ],
                  );
                },
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        const Expanded(
          child: Text('Task Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('All Tasks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.muted),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.kodiBlue,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('New Task', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKanbanBoard(List<MaintenanceItem> todo, List<MaintenanceItem> inProgress, List<MaintenanceItem> done) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _kanbanColumn('To Do', todo, AppColors.kodiOrange, const Color(0xFFFFF7ED))),
        const SizedBox(width: 12),
        Expanded(child: _kanbanColumn('In Progress', inProgress, AppColors.kodiBlue, const Color(0xFFEFF6FF))),
        const SizedBox(width: 12),
        Expanded(child: _kanbanColumn('Completed', done, AppColors.kodiGreen, const Color(0xFFE7F8EF))),
      ],
    );
  }

  Widget _kanbanColumn(String title, List<MaintenanceItem> items, Color accent, Color bgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: accent)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${items.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, size: 28, color: AppColors.muted),
                        SizedBox(height: 4),
                        Text('No tasks', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => _kanbanCard(items[index], accent),
                ),
        ),
      ],
    );
  }

  Widget _kanbanCard(MaintenanceItem item, Color accent) {
    final priorityColor = maintenancePriorityColor(item.priority);
    final unitLabel = item.unitNumber.isNotEmpty ? item.unitNumber : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(item),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unitLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title.isEmpty ? capitalize(item.category) : item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description.isEmpty
                      ? capitalize(item.category)
                      : item.description,
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        capitalize(item.priority),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: priorityColor),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.kodiNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        capitalize(item.category),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.kodiNavy),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: item.status.toLowerCase() == 'pending'
                          ? SizedBox(
                              height: 28,
                              child: OutlinedButton(
                                onPressed: () => _startTask(item),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: const BorderSide(color: AppColors.kodiOrange),
                                  foregroundColor: AppColors.kodiOrange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('Start', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                            )
                          : item.status.toLowerCase() == 'in_progress'
                              ? SizedBox(
                                  height: 28,
                                  child: ElevatedButton(
                                    onPressed: () => _completeTask(item),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor: AppColors.kodiGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: const Text('Mark as Done', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _open(item),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsPanel(int activeTickets, int openCritical, List<MaintenanceItem> allItems) {
    final completedCount = allItems.where((i) => i.isResolved).length;
    final total = allItems.length;
    final productivity = total > 0 ? ((completedCount / total) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Stats', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 16),
          _statRow('Daily Productivity', '$productivity%', AppColors.kodiGreen, Icons.speed_rounded),
          const SizedBox(height: 14),
          _statRow('Avg Response', '1.2d', AppColors.kodiBlue, Icons.timer_outlined),
          const SizedBox(height: 14),
          _statRow('Active Tickets', '$activeTickets', AppColors.kodiOrange, Icons.assignment_outlined),
          const SizedBox(height: 14),
          _statRow('Open Critical', '$openCritical', AppColors.danger, Icons.warning_amber_rounded),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color, fontFamily: 'Lexend')),
      ],
    );
  }
}
