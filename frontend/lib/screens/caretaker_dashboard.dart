import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import 'feature_screens.dart';

class CaretakerDashboard extends StatefulWidget {
  const CaretakerDashboard({super.key});

  @override
  State<CaretakerDashboard> createState() => _CaretakerDashboardState();
}

class _CaretakerDashboardState extends State<CaretakerDashboard> {
  final ApiService _api = ApiService();
  Future<_CaretakerOverview>? _future;

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

  Future<_CaretakerOverview> _fetch() async {
    final response = await _api.get('/maintenance/mine');
    if (response.statusCode != 200) {
      throw Exception('Could not load maintenance (${response.statusCode})');
    }
    final all = (jsonDecode(response.body) as List<dynamic>)
        .map((item) => _PeekItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final tasks = all.where((m) => !m.isEmergency && !m.isResolved).toList();
    final emergencies =
        all.where((m) => m.isEmergency && !m.isResolved).toList();
    final inProgress =
        tasks.where((m) => m.status.toLowerCase() == 'in_progress').length;
    final pending =
        tasks.where((m) => m.status.toLowerCase() == 'pending').length;
    return _CaretakerOverview(
      tasksTotal: tasks.length,
      tasksInProgress: inProgress,
      tasksPending: pending,
      tasks: tasks.take(3).toList(),
      emergencies: emergencies.take(3).toList(),
    );
  }

  Future<void> _openTasks() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaretakerTasksScreen()),
    );
    _reload();
  }

  Future<void> _openAlerts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaretakerAlertsScreen()),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.firstName ?? 'Caretaker';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<_CaretakerOverview>(
            future: _future,
            builder: (context, snapshot) {
              final overview = snapshot.data;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardHeader(
                      name: firstName,
                      subtitle: 'You have tasks to handle',
                      accentColor: AppColors.kodiOrange,
                      onLogout: () =>
                          context.read<AuthProvider>().logout(),
                      onMenuTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(
                            role: 'Caretaker',
                            accentColor: AppColors.kodiOrange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GradientPanel(
                      startColor: const Color(0xFFFFA51E),
                      endColor: const Color(0xFFF97316),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Tasks',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _TaskStat(
                                  value: overview?.tasksTotal.toString() ?? '—',
                                  label: 'Total',
                                ),
                              ),
                              Expanded(
                                child: _TaskStat(
                                  value:
                                      overview?.tasksInProgress.toString() ?? '—',
                                  label: 'In Progress',
                                ),
                              ),
                              Expanded(
                                child: _TaskStat(
                                  value:
                                      overview?.tasksPending.toString() ?? '—',
                                  label: 'Pending',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SectionTitle(
                      title: 'Assigned Issues',
                      actionLabel: 'View all',
                      onAction: _openTasks,
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasError)
                      _PeekError(
                        message: snapshot.error.toString(),
                        onRetry: _reload,
                      )
                    else if ((overview?.tasks ?? const []).isEmpty)
                      const _PeekEmpty(
                        icon: Icons.task_alt_rounded,
                        text: 'No open tasks right now.',
                      )
                    else
                      ListPanel(
                        children: _interleave(
                          [
                            for (final task in overview!.tasks)
                              _IssueRow(
                                title: task.title,
                                location: task.locationLabel,
                                status: _capitalizeWord(task.priority),
                                color: _priorityColor(task.priority),
                                onTap: _openTasks,
                              ),
                          ],
                          const _DividerLine(),
                        ),
                      ),
                    const SizedBox(height: 22),
                    SectionTitle(
                      title: 'Emergency Alerts',
                      actionLabel: 'View all',
                      onAction: _openAlerts,
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox.shrink()
                    else if (snapshot.hasError)
                      const SizedBox.shrink()
                    else if ((overview?.emergencies ?? const []).isEmpty)
                      const _PeekEmpty(
                        icon: Icons.shield_outlined,
                        text: 'No active emergencies.',
                      )
                    else
                      ListPanel(
                        children: _interleave(
                          [
                            for (final alert in overview!.emergencies)
                              _AlertRow(
                                title: alert.title,
                                location: alert.locationLabel,
                                time: _relativeTime(alert.createdAt),
                                onTap: _openAlerts,
                              ),
                          ],
                          const _DividerLine(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        selectedColor: AppColors.kodiOrange,
        onTap: (index) {
          final List<Widget?> screens = [
            null,
            const CaretakerTasksScreen(),
            const CaretakerAlertsScreen(),
            const ProfileScreen(
              role: 'Caretaker',
              accentColor: AppColors.kodiOrange,
            ),
          ];
          final screen = screens[index];
          if (screen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

List<Widget> _interleave(List<Widget> items, Widget separator) {
  final result = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    if (i > 0) result.add(separator);
    result.add(items[i]);
  }
  return result;
}

Color _priorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'emergency':
      return AppColors.danger;
    case 'urgent':
    case 'high':
      return AppColors.kodiOrange;
    case 'low':
      return AppColors.kodiGreen;
    default:
      return AppColors.kodiBlue;
  }
}

String _capitalizeWord(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}

class _PeekItem {
  final int id;
  final String title;
  final String propertyName;
  final String unitNumber;
  final String status;
  final String priority;
  final DateTime createdAt;

  const _PeekItem({
    required this.id,
    required this.title,
    required this.propertyName,
    required this.unitNumber,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  bool get isEmergency => priority.toLowerCase() == 'emergency';
  bool get isResolved => status.toLowerCase() == 'completed';

  String get locationLabel => unitNumber.isEmpty
      ? propertyName
      : '$propertyName • Unit $unitNumber';

  factory _PeekItem.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return _PeekItem(
      id: toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      propertyName: (json['property_name'] ?? '').toString(),
      unitNumber: (json['unit_number'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

class _CaretakerOverview {
  final int tasksTotal;
  final int tasksInProgress;
  final int tasksPending;
  final List<_PeekItem> tasks;
  final List<_PeekItem> emergencies;

  const _CaretakerOverview({
    required this.tasksTotal,
    required this.tasksInProgress,
    required this.tasksPending,
    required this.tasks,
    required this.emergencies,
  });
}

class _TaskStat extends StatelessWidget {
  final String value;
  final String label;

  const _TaskStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
      ],
    );
  }
}

class _IssueRow extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final Color color;
  final VoidCallback onTap;

  const _IssueRow({
    required this.title,
    required this.location,
    required this.status,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.handyman_rounded,
                  color: AppColors.kodiNavy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 3),
                  Text(location, style: AppStyles.caption),
                ],
              ),
            ),
            StatusPill(label: status, color: color),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final String title;
  final String location;
  final String time;
  final VoidCallback onTap;

  const _AlertRow({
    required this.title,
    required this.location,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.priority_high_rounded,
                  color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('$location • $time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, indent: 14, endIndent: 14, color: AppColors.border);
  }
}

class _PeekEmpty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PeekEmpty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppStyles.caption),
          ),
        ],
      ),
    );
  }
}

class _PeekError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PeekError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: AppStyles.caption),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
