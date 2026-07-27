import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/maintenance_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'caretaker_tasks_screen.dart';
import 'caretaker_properties_screen.dart';
import 'caretaker_profile_screen.dart';
import 'caretaker_alerts_screen.dart';

class CaretakerDashboard extends StatefulWidget {
  const CaretakerDashboard({super.key});

  @override
  State<CaretakerDashboard> createState() => _CaretakerDashboardState();
}

class _CaretakerDashboardState extends State<CaretakerDashboard> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = screenW > 768;

    final navLabels = ['Home', 'Tasks', 'Properties', 'Alerts', 'Profile'];
    final navIcons = [
      Icons.home_outlined, Icons.assignment_outlined, Icons.domain_outlined,
      Icons.notifications_outlined, Icons.person_outlined,
    ];
    final navIconsFilled = [
      Icons.home_rounded, Icons.assignment_rounded, Icons.domain_rounded,
      Icons.notifications_rounded, Icons.person_rounded,
    ];
    final navColors = List<Color>.filled(5, const Color(0xFF8192A7));
    navColors[3] = const Color(0xFF8192A7); // alerts default
    if (_navIndex == 3) navColors[3] = AppColors.kodiGreen;

    final screens = <Widget>[
      _CaretakerHomeTab(),
      const CaretakerTasksScreen(),
      const CaretakerPropertiesScreen(),
      const CaretakerAlertsScreen(),
      const CaretakerProfileScreen(),
    ];

    final sidebar = _buildSidebar(
      navLabels, navIcons, navIconsFilled, navColors,
    );

    final topBar = _buildTopBar();

    final body = IndexedStack(index: _navIndex, children: screens);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            sidebar,
            Expanded(
              child: Column(
                children: [
                  topBar,
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile
    return Scaffold(
      body: Column(
        children: [
          topBar,
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(navLabels, navIcons, navIconsFilled),
    );
  }

  Widget _buildSidebar(
    List<String> labels,
    List<IconData> icons,
    List<IconData> iconsFilled,
    List<Color> activeColors,
  ) {
    return Container(
      width: 280,
      height: double.infinity,
      color: AppColors.kodiNavy,
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KodiPay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Caretaker Portal', style: TextStyle(fontSize: 13, color: Color(0xFF8192A7))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(5, (i) {
            final isActive = _navIndex == i;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _navIndex = i),
                  child: Container(
                    decoration: BoxDecoration(
                      border: isActive
                          ? const Border(left: BorderSide(color: AppColors.kodiGreen, width: 4))
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          isActive ? iconsFilled[i] : icons[i],
                          size: 22,
                          color: isActive ? Colors.white : const Color(0xFF8192A7),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? Colors.white : const Color(0xFF8192A7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _navIndex == 3
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(color: AppColors.surfaceHigh, shape: BoxShape.circle),
                          child: const Icon(Icons.support_agent_rounded, color: AppColors.kodiNavy, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Support Hub', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                              Text('24/7 Availability', style: TextStyle(fontSize: 11, color: Color(0xFF8192A7))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.surfaceHigh,
                          child: Text('JK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kodiNavy)),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Alex Mwangi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                              Text('Senior Caretaker', style: TextStyle(fontSize: 11, color: Color(0xFF8192A7))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.surfaceHigh)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search properties...',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.notifications_outlined, size: 22, color: AppColors.textDark.withValues(alpha: 0.6)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.kodiGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('JK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.kodiGreen))),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
    List<String> labels,
    List<IconData> icons,
    List<IconData> iconsFilled,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.surfaceHigh)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(5, (i) {
              final isActive = _navIndex == i;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _navIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? iconsFilled[i] : icons[i],
                          size: 22,
                          color: isActive
                              ? (i == 3 ? AppColors.kodiGreen : AppColors.kodiNavy)
                              : AppColors.muted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? (i == 3 ? AppColors.kodiGreen : AppColors.kodiNavy)
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────

class _CaretakerHomeTab extends StatefulWidget {
  @override
  State<_CaretakerHomeTab> createState() => _CaretakerHomeTabState();
}

class _CaretakerHomeTabState extends State<_CaretakerHomeTab> {
  final ApiService _api = ApiService();
  List<MaintenanceItem> _pendingTasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get('/maintenance/mine');
      if (response.statusCode == 200) {
        final all = (jsonDecode(response.body) as List<dynamic>)
            .map((item) => MaintenanceItem.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _pendingTasks = all.where((i) => !i.isResolved).take(4).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Could not load tasks'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  Future<void> _markDone(MaintenanceItem item) async {
    try {
      final response = await _api.put('/maintenance/${item.id}/status', {'status': 'completed'});
      if (response.statusCode == 200 && mounted) {
        showSnack(context, 'Task marked as done');
        _loadTasks();
      }
    } catch (_) {}
  }

  void _confirmMarkDone(MaintenanceItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Done?'),
        content: Text('Mark "${item.title.isEmpty ? capitalize(item.category) : item.title}" as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _markDone(item); },
            child: const Text('Mark Done', style: TextStyle(color: AppColors.kodiGreen)),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _pendingTasks.length;
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 1100;

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(totalPending),
            const SizedBox(height: 24),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildLeftColumn()),
                  const SizedBox(width: 24),
                  SizedBox(width: 280, child: _buildRightSidebar()),
                ],
              )
            else
              _buildMobileColumn(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(int totalPending) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF041627), Color(0xFF0A2744)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.kodiNavy.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.kodiGreen.withValues(alpha: 0.2),
            child: const Text('JK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.kodiGreen)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_greeting()}, James', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  totalPending > 0
                      ? 'You have $totalPending pending tasks today.'
                      : 'All caught up! No pending tasks.',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricsGrid(),
        const SizedBox(height: 24),
        _buildPendingTasksSection(),
        const SizedBox(height: 24),
        _buildVisualAccentCard(),
        const SizedBox(height: 24),
        _buildEmergencyCallButton(),
      ],
    );
  }

  Widget _buildMobileColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricsGrid(),
        const SizedBox(height: 24),
        _buildPendingTasksSection(),
        const SizedBox(height: 24),
        _buildPropertyHealth(),
        const SizedBox(height: 24),
        _buildVisualAccentCard(),
        const SizedBox(height: 24),
        _buildEmergencyCallButton(),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        final cards = [
          _metricBento('Uptime', '94%', Icons.wifi_tethering_rounded, AppColors.success, 'Building uptime score'),
          _metricBento('Avg Fix Time', '1.2d', Icons.timer_outlined, AppColors.kodiBlue, 'Average resolution'),
          _metricBento('Occupancy', '48/50', Icons.people_outline, AppColors.kodiGreen, 'Units occupied'),
          _metricBento('Occupancy Rate', '96%', Icons.trending_up_rounded, AppColors.kodiOrange, 'Overall rate'),
        ];
        if (isNarrow) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
            ],
          );
        }
        return Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList());
      },
    );
  }

  Widget _metricBento(String label, String value, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 14),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color, fontFamily: 'Lexend')),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildPendingTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pending Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 32, color: AppColors.muted),
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: _loadTasks, icon: const Icon(Icons.refresh_rounded, size: 14), label: const Text('Retry')),
                ],
              ),
            ),
          )
        else if (_pendingTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: _cardDecoration(),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.kodiGreen),
                  SizedBox(height: 8),
                  Text('All tasks completed!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  SizedBox(height: 4),
                  Text('No pending maintenance issues.', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),
          )
        else
          ...List.generate(_pendingTasks.length, (i) {
            final item = _pendingTasks[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < _pendingTasks.length - 1 ? 10 : 0),
              child: _pendingTaskCard(item),
            );
          }),
      ],
    );
  }

  Widget _pendingTaskCard(MaintenanceItem item) {
    final priorityColor = maintenancePriorityColor(item.priority);
    final categoryIcon = _categoryIcon(item.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(categoryIcon, color: priorityColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty ? capitalize(item.category) : item.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.unitNumber.isNotEmpty ? "Unit ${item.unitNumber}" : item.propertyName} • ${capitalize(item.priority)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(height: 3),
                Text(relativeTime(item.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
            child: Text(capitalize(item.priority), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: priorityColor)),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _confirmMarkDone(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Mark as Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kodiGreen)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualAccentCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFE7F8EF), Color(0xFFD1FAE5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kodiGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.kodiGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quarterly Safety Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(
                  'All 50 units passed the Q2 2026 safety inspection. No critical issues found.',
                  style: TextStyle(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCallButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showEmergencyDialog(),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFF991B1B)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(
            children: [
              Icon(Icons.emergency_share_rounded, color: Colors.white, size: 26),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency Call Dispatch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 3),
                    Text('Contact emergency services immediately', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 40),
        title: const Text('Emergency Dispatch'),
        content: const Text('This will connect you to the emergency services line. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); showSnack(context, 'Connecting to emergency services...'); },
            child: const Text('Call Now', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyHealth() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Property Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 16),
          _healthItem('Maintenance Compliance', 0.98, AppColors.kodiGreen),
          const SizedBox(height: 14),
          _healthItem('Tenant Retention', 0.92, AppColors.kodiBlue),
          const SizedBox(height: 14),
          _healthItem('Recent Updates', null, AppColors.kodiOrange, count: 6),
        ],
      ),
    );
  }

  Widget _healthItem(String label, double? progress, Color color, {int? count}) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
        if (progress != null)
          Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color, fontFamily: 'Lexend'))
        else
          Text('${count ?? 0}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color, fontFamily: 'Lexend')),
      ],
    );
  }

  Widget _buildRightSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertyHealth(),
        const SizedBox(height: 20),
        _buildRecentUpdates(),
      ],
    );
  }

  Widget _buildRecentUpdates() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Updates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 14),
          _updateItem(Icons.check_circle_rounded, AppColors.kodiGreen, 'Unit B3 plumbing fixed', '2 hours ago'),
          const SizedBox(height: 12),
          _updateItem(Icons.build_rounded, AppColors.kodiOrange, 'Unit A2 electrical inspected', '5 hours ago'),
          const SizedBox(height: 12),
          _updateItem(Icons.check_circle_rounded, AppColors.kodiGreen, 'Common area repainted', 'Yesterday'),
        ],
      ),
    );
  }

  Widget _updateItem(IconData icon, Color color, String title, String time) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
  );

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing': return Icons.water_drop_rounded;
      case 'electrical': return Icons.bolt_rounded;
      case 'hvac': return Icons.ac_unit_rounded;
      case 'structural': return Icons.foundation_rounded;
      case 'painting': return Icons.format_paint_rounded;
      case 'pest_control': return Icons.pest_control_rounded;
      case 'security': return Icons.shield_rounded;
      default: return Icons.build_rounded;
    }
  }
}
