import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import 'feature_screens.dart';

class CaretakerDashboard extends StatelessWidget {
  const CaretakerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.firstName ?? 'Samuel';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                name: firstName,
                subtitle: 'You have tasks to handle',
                accentColor: AppColors.kodiOrange,
                onLogout: () => context.read<AuthProvider>().logout(),
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
              const GradientPanel(
                startColor: Color(0xFFFFA51E),
                endColor: Color(0xFFF97316),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Tasks',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _TaskStat(value: '6', label: 'Total')),
                        Expanded(
                            child: _TaskStat(value: '2', label: 'In Progress')),
                        Expanded(
                            child: _TaskStat(value: '4', label: 'Pending')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionTitle(
                title: 'Assigned Issues',
                actionLabel: 'View all',
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CaretakerTasksScreen()),
                ),
              ),
              const ListPanel(
                children: [
                  _IssueRow(
                      title: 'Broken Tap',
                      location: 'House 12B',
                      status: 'High',
                      color: AppColors.danger),
                  _DividerLine(),
                  _IssueRow(
                      title: 'Electrical Fault',
                      location: 'House 8A',
                      status: 'Medium',
                      color: AppColors.kodiOrange),
                  _DividerLine(),
                  _IssueRow(
                      title: 'Door Lock Repair',
                      location: 'House 5C',
                      status: 'Low',
                      color: AppColors.kodiGreen),
                ],
              ),
              const SizedBox(height: 22),
              SectionTitle(
                title: 'Emergency Alerts',
                actionLabel: 'View all',
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CaretakerAlertsScreen()),
                ),
              ),
              const ListPanel(
                children: [
                  _AlertRow(
                      title: 'Water Leakage',
                      location: 'House 3D',
                      time: 'Today, 10:30 AM'),
                  _DividerLine(),
                  _AlertRow(
                      title: 'Power Outage',
                      location: 'Greenfield Heights',
                      time: 'Today, 9:15 AM'),
                ],
              ),
            ],
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

  const _IssueRow({
    required this.title,
    required this.location,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child:
                const Icon(Icons.plumbing_rounded, color: AppColors.kodiNavy),
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
    );
  }
}

class _AlertRow extends StatelessWidget {
  final String title;
  final String location;
  final String time;

  const _AlertRow({
    required this.title,
    required this.location,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                Text('$location - $time',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.caption),
              ],
            ),
          ),
        ],
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
