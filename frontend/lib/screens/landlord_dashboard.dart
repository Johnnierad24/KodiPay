import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/maintenance_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'maintenance_detail_screen.dart';
import 'property_list_screen.dart';
import 'add_property_screen.dart';
import 'landlord_notifications_screen.dart';
import 'landlord_reports_screen.dart';
import 'landlord_settings_screen.dart';
import 'landlord_wallet_screen.dart';
import 'caretakers_screen.dart';
import 'tenant_rights_screen.dart';
import 'landlord_tenant_act_screen.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
  final ApiService _api = ApiService();
  int _unreadCount = 0;
  _DashboardOverview? _overview;
  int _navIndex = 0;
  bool _sidebarOpen = true;
  bool _mobileSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _loadOverview();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await _api.get('/notifications');
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as List<dynamic>;
      final unread = data.where((item) => (item as Map)['is_read'] != true).length;
      if (!mounted) return;
      setState(() => _unreadCount = unread);
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    }
  }

  Future<void> _loadOverview() async {
    try {
      final response = await _api.get('/analytics/dashboard');
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _overview = _DashboardOverview.fromJson(data));
    } catch (e) {
      debugPrint('Failed to load dashboard overview: $e');
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _navIndex = index;
      _mobileSidebarOpen = false;
    });
  }

  void _onMenuTap() {
    setState(() {
      if (MediaQuery.of(context).size.width > 1024) {
        _sidebarOpen = !_sidebarOpen;
      } else {
        _mobileSidebarOpen = !_mobileSidebarOpen;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isWide = MediaQuery.of(context).size.width > 1024;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar (desktop, collapsible)
                if (isWide)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    width: _sidebarOpen ? 280 : 0,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    child: _Sidebar(navIndex: _navIndex, onTap: _onNavTap, onLogout: () => _confirmLogout(context)),
                  ),

                // Main content
                Expanded(
                  child: Column(
                    children: [
                      // Top bar
                      _TopBar(
                        unreadCount: _unreadCount,
                        userName: '${user?.firstName ?? 'Landlord'}${user?.lastName != null ? ' ${user!.lastName}' : ''}',
                        sidebarOpen: isWide ? _sidebarOpen : _mobileSidebarOpen,
                        onMenuTap: _onMenuTap,
                        onNotifications: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const LandlordNotificationsScreen()));
                          if (context.mounted) _loadOverview();
                        },
                        onProfileTap: () => _onNavTap(5),
                        onLogout: () => _confirmLogout(context),
                      ),

                      // Body
                      Expanded(
                        child: IndexedStack(
                          index: _navIndex,
                          children: [
                            _HomeTab(
                              user: user,
                              overview: _overview,
                              unreadCount: _unreadCount,
                              onRefresh: _loadOverview,
                              onNavigateToReports: () => _onNavTap(2),
                              onNavigateToProperties: () => _onNavTap(1),
                            ),
                            const PropertyListScreen(),
                            const LandlordReportsScreen(),
                            const LandlordWalletScreen(),
                            const CaretakersScreen(),
                            const LandlordSettingsScreen(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Mobile sidebar overlay
            if (!isWide && _mobileSidebarOpen) ...[
              GestureDetector(
                onTap: () => setState(() => _mobileSidebarOpen = false),
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: SizedBox(width: 280, child: _Sidebar(navIndex: _navIndex, onTap: _onNavTap, onLogout: () => _confirmLogout(context))),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use KodiPay.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}

// ── Sidebar ──────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int navIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  const _Sidebar({required this.navIndex, required this.onTap, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Home', Icons.home_outlined, Icons.home),
      ('Properties', Icons.domain_outlined, Icons.domain),
      ('Reports', Icons.assessment_outlined, Icons.assessment),
      ('Wallet', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
      ('Caretakers', Icons.supervisor_account_outlined, Icons.supervisor_account),
      ('Profile', Icons.person_outline, Icons.person),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/kodipay_logo.png',
                        width: 48, height: 32, fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('KodiPay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.onPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('PROPERTY MANAGEMENT', style: TextStyle(fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: AppColors.onPrimary.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Nav items
          ...List.generate(items.length, (i) {
            final active = navIndex == i;
            final item = items[i];
            return Container(
              decoration: active ? const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.tertiaryFixed, width: 4)),
              ) : null,
              child: Material(
                color: active ? AppColors.onPrimary.withValues(alpha: 0.1) : Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      children: [
                        Icon(active ? item.$3 : item.$2, size: 22, color: active ? AppColors.onPrimary : AppColors.onPrimary.withValues(alpha: 0.7)),
                        const SizedBox(width: 12),
                        Text(item.$1, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                          color: active ? AppColors.onPrimary : AppColors.onPrimary.withValues(alpha: 0.7),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          // Legal Corner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LEGAL CORNER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.tertiaryFixed)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TenantRightsScreen())),
                  child: Row(
                    children: [
                      Icon(Icons.gavel, size: 16, color: AppColors.onPrimary.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Text('Tenant Rights', style: TextStyle(color: AppColors.onPrimary.withValues(alpha: 0.5), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LandlordTenantActScreen())),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book, size: 16, color: AppColors.onPrimary.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Text('Landlord-Tenant Act', style: TextStyle(color: AppColors.onPrimary.withValues(alpha: 0.5), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.danger),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Top Bar ──────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int unreadCount;
  final String userName;
  final bool sidebarOpen;
  final VoidCallback onMenuTap;
  final VoidCallback onNotifications;
  final VoidCallback onProfileTap;
  final VoidCallback onLogout;

  const _TopBar({
    required this.unreadCount,
    required this.userName,
    required this.sidebarOpen,
    required this.onMenuTap,
    required this.onNotifications,
    required this.onProfileTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          // Menu + Search
          Row(
            children: [
              IconButton(
                icon: Icon(sidebarOpen ? Icons.menu_open : Icons.menu),
                onPressed: onMenuTap,
              ),
              if (!isNarrow) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search portfolio...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.secondary),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.surfaceLow,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.secondary),
                onPressed: onNotifications,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$unreadCount', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 4),
            const Icon(Icons.help_outline, size: 20, color: AppColors.secondary),
            Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 12), color: AppColors.outlineVariant),
          ],
          // User
          GestureDetector(
            onTap: onProfileTap,
            child: Row(
              children: [
                if (!isNarrow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                      const Text('Gold Tier Landlord', style: TextStyle(fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                    ],
                  ),
                if (!isNarrow) const SizedBox(width: 10),
                Container(
                  width: 36, height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryFixed,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Text(
                    _initials(userName),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.secondary),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || name.trim().isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

// ── Home Tab ─────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final dynamic user;
  final _DashboardOverview? overview;
  final int unreadCount;
  final Future<void> Function() onRefresh;
  final VoidCallback? onNavigateToReports;
  final VoidCallback? onNavigateToProperties;

  const _HomeTab({required this.user, this.overview, required this.unreadCount, required this.onRefresh, this.onNavigateToReports, this.onNavigateToProperties});

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final collectionRate = o?.collectionRate ?? 0;
    final totalCollected = o?.totalCollected ?? 0;
    final outstanding = o?.outstanding ?? 0;
    final pendingIssues = o?.pendingIssues ?? 0;
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthName = months[DateTime.now().month - 1];

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPad = constraints.maxWidth < 600 ? 16.0 : 24.0;
        return AppRefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 24),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome
          const SizedBox(height: 8),
          Text('Welcome back, ${user?.firstName ?? 'Landlord'}!', style: AppStyles.headlineLg.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text('Here is your portfolio performance for $monthName.', style: AppStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 24),
          // Quick Actions
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  if (onNavigateToProperties != null) {
                    onNavigateToProperties!();
                  } else {
                    final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
                    if (added == true && context.mounted) onRefresh();
                  }
                },
                icon: const Icon(Icons.add_circle_outlined, size: 18),
                label: const Text('Add Property'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  if (onNavigateToReports != null) {
                    onNavigateToReports!();
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LandlordReportsScreen()));
                  }
                },
                icon: const Icon(Icons.summarize_outlined, size: 18),
                label: const Text('Generate New Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stats Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    label: 'Collection Rate',
                    icon: Icons.analytics_outlined,
                    iconColor: AppColors.tertiaryFixedDim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$collectionRate', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
                            const Text('%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: collectionRate / 100,
                              child: Container(decoration: BoxDecoration(color: AppColors.tertiaryFixedDim, borderRadius: BorderRadius.circular(999))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatCard(
                    label: 'Total Collected',
                    icon: Icons.account_balance_outlined,
                    iconColor: AppColors.tertiaryFixedDim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$monthName ${DateTime.now().year}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.secondary)),
                        const SizedBox(height: 4),
                        Text('KSh ${_fmt(totalCollected)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
                      ],
                    ),
                  ),
                  _StatCard(
                    label: 'Outstanding',
                    icon: Icons.priority_high_outlined,
                    iconColor: AppColors.error,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KSh ${_fmt(outstanding)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: AppColors.onSurfaceVariant),
                            SizedBox(width: 4),
                            Text('Updated in real time', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatCard(
                    label: 'Maintenance',
                    icon: Icons.build_outlined,
                    iconColor: AppColors.tertiaryFixedDim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$pendingIssues New', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
                        const SizedBox(height: 4),
                        const Text('Pending Requests', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const _PendingMaintenancePanel(),
          const SizedBox(height: 24),
          // Dashboard body grid
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth > 900;
              if (stack) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _RecentTransactions()),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _PortfolioYield()),
                  ],
                );
              }
              return Column(
                children: [
                  _RecentTransactions(),
                  const SizedBox(height: 24),
                  _PortfolioYield(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLow,
              border: Border(top: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: Column(
              children: [
                const Text('© 2026 KodiPay Kenya. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24, runSpacing: 8, alignment: WrapAlignment.center,
                  children: [
                    TextButton(onPressed: () => Navigator.pushNamed(context, '/terms'), child: const Text('Terms of Service', style: TextStyle(fontSize: 12, color: AppColors.secondary, decoration: TextDecoration.underline))),
                    TextButton(onPressed: () => Navigator.pushNamed(context, '/privacy'), child: const Text('Privacy Policy', style: TextStyle(fontSize: 12, color: AppColors.secondary, decoration: TextDecoration.underline))),
                    TextButton(onPressed: () => Navigator.pushNamed(context, '/contact'), child: const Text('Contact Support', style: TextStyle(fontSize: 12, color: AppColors.secondary, decoration: TextDecoration.underline))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
      },
    );
  }

  String _fmt(num? v) {
    if (v == null) return '--';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

// ── Stat Card ─────────────────────────────────────────
class _PendingMaintenancePanel extends StatefulWidget {
  const _PendingMaintenancePanel();

  @override
  State<_PendingMaintenancePanel> createState() => _PendingMaintenancePanelState();
}

class _PendingMaintenancePanelState extends State<_PendingMaintenancePanel> {
  final ApiService _api = ApiService();
  late Future<List<MaintenanceItem>> _future;
  final Set<int> _reminding = {};

  @override
  void initState() {
    super.initState();
    _future = _fetchPendingTasks();
  }

  Future<List<MaintenanceItem>> _fetchPendingTasks() async {
    final response = await _api.get('/maintenance/mine');
    if (response.statusCode != 200) {
      throw Exception('Could not load pending maintenance tasks');
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => MaintenanceItem.fromJson(item as Map<String, dynamic>))
        .where((item) => !item.isResolved)
        .toList();
  }

  Future<void> _remindCaretaker(MaintenanceItem item) async {
    setState(() => _reminding.add(item.id));
    try {
      final response = await _api.post('/maintenance/${item.id}/remind-caretaker', const {});
      if (!mounted) return;
      if (response.statusCode == 200) {
        showSnack(context, 'Caretaker notified');
      } else {
        String message = 'Could not notify caretaker';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['error'] != null) message = body['error'].toString();
        } catch (_) {}
        showSnack(context, message);
      }
    } catch (_) {
      if (mounted) showSnack(context, 'Connection error while notifying caretaker');
    } finally {
      if (mounted) setState(() => _reminding.remove(item.id));
    }
  }

  void _reload() {
    setState(() => _future = _fetchPendingTasks());
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 14 : 20, 16, isMobile ? 14 : 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Pending Maintenance Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),
          ),
          FutureBuilder<List<MaintenanceItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
                        const SizedBox(height: 8),
                        Text(snapshot.error.toString(), textAlign: TextAlign.center, style: AppStyles.bodySmall),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Retry')),
                      ],
                    ),
                  ),
                );
              }
              final tasks = snapshot.data ?? const <MaintenanceItem>[];
              if (tasks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: AppColors.kodiGreen, size: 34),
                        SizedBox(height: 8),
                        Text('No pending tenant-raised maintenance tasks.', style: TextStyle(fontSize: 13, color: AppColors.secondary)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < tasks.length; i++)
                    _LandlordMaintenanceTaskRow(
                      item: tasks[i],
                      isLast: i == tasks.length - 1,
                      reminding: _reminding.contains(tasks[i].id),
                      onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaintenanceDetailScreen(item: tasks[i]))),
                      onRemind: () => _remindCaretaker(tasks[i]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LandlordMaintenanceTaskRow extends StatelessWidget {
  final MaintenanceItem item;
  final bool isLast;
  final bool reminding;
  final VoidCallback onOpen;
  final VoidCallback onRemind;

  const _LandlordMaintenanceTaskRow({
    required this.item,
    required this.isLast,
    required this.reminding,
    required this.onOpen,
    required this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = maintenancePriorityColor(item.priority);
    final statusColor = maintenanceStatusColor(item.status);
    return InkWell(
      onTap: onOpen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 680;
          final titleBlock = Row(
            children: [
              Container(
                width: isNarrow ? 36 : 40,
                height: isNarrow ? 36 : 40,
                decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.build_circle_outlined, color: priorityColor, size: isNarrow ? 20 : 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title.isEmpty ? capitalizeWord(item.category) : item.title, style: TextStyle(fontSize: isNarrow ? 13 : 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${item.propertyName}${item.unitNumber.isEmpty ? '' : ' - Unit ${item.unitNumber}'}${item.tenantName.isEmpty ? '' : ' - ${item.tenantName}'}',
                      style: AppStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniPill(label: maintenanceStatusLabel(item.status), color: statusColor),
              _MiniPill(label: capitalizeWord(item.priority), color: priorityColor),
              Text(relativeTime(item.createdAt), style: AppStyles.caption),
              SizedBox(
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: reminding ? null : onRemind,
                  icon: reminding
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.notifications_active_outlined, size: 15),
                  label: Text(reminding ? 'Notifying' : 'Notify Caretaker', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          );

          return Container(
            padding: EdgeInsets.fromLTRB(isNarrow ? 14 : 20, isNarrow ? 12 : 14, isNarrow ? 14 : 20, isNarrow ? 12 : 14),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6))),
            ),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleBlock,
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MiniPill(label: maintenanceStatusLabel(item.status), color: statusColor),
                          _MiniPill(label: capitalizeWord(item.priority), color: priorityColor),
                          Text(relativeTime(item.createdAt), style: AppStyles.caption),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: reminding ? null : onRemind,
                          icon: reminding
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.notifications_active_outlined, size: 15),
                          label: Text(reminding ? 'Notifying...' : 'Notify Caretaker', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: titleBlock),
                      const SizedBox(width: 16),
                      actions,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _StatCard({required this.label, required this.icon, required this.iconColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.secondary)),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Recent Transactions ──────────────────────────────
class _RecentTransactions extends StatefulWidget {
  @override
  State<_RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<_RecentTransactions> {
  final ApiService _api = ApiService();
  late Future<List<_TxnRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadTransactions();
  }

  Future<List<_TxnRow>> _loadTransactions() async {
    try {
      final res = await _api.get('/reports/transactions');
      if (res.statusCode != 200) return _fallback();
      final list = jsonDecode(res.body) as List<dynamic>;
      final rows = list.take(5).map<_TxnRow>((item) {
        final m = item as Map<String, dynamic>;
        final paid = (m['status'] ?? '').toString().toLowerCase() == 'completed';
        final amount = (m['amount'] is num) ? (m['amount'] as num).toInt() : int.tryParse('${m['amount']}') ?? 0;
        final dateStr = _fmtDate(m['payment_date']);
        final unit = '${m['property_name'] ?? ''} #${m['unit_number'] ?? ''}';
        return _TxnRow(date: dateStr, unit: unit, amount: 'KSh ${_fmtKsh(amount)}', status: paid ? 'Paid' : 'Unpaid', color: paid ? AppColors.tertiaryFixedDim : AppColors.errorContainer, textColor: paid ? AppColors.onTertiaryFixedVariant : AppColors.onErrorContainer);
      }).toList();
      return rows.isEmpty ? _fallback() : rows;
    } catch (_) {
      return _fallback();
    }
  }

  static List<_TxnRow> _fallback() => const [];

  static String _fmtDate(dynamic d) {
    if (d == null) return '-';
    try {
      final dt = DateTime.parse(d.toString());
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
    } catch (_) {
      return d.toString();
    }
  }

  static String _fmtKsh(int v) => v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Lexend', color: AppColors.primary)),
                TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          // Transaction list - responsive
          FutureBuilder<List<_TxnRow>>(
            future: _future,
            builder: (context, snapshot) {
              final transactions = snapshot.data ?? const <_TxnRow>[];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 500;
                  if (transactions.isEmpty) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: Text('No recent transactions.', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant))),
                    );
                  }
                  if (isNarrow) {
                    return Column(
                      children: transactions.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)))),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(t.unit, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: t.status == 'Paid' ? AppColors.tertiaryFixed.withValues(alpha: 0.2) : AppColors.errorContainer,
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: t.status == 'Paid' ? AppColors.tertiaryFixedDim : AppColors.error.withValues(alpha: 0.2)),
                                        ),
                                        child: Text(t.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.textColor)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(t.date, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                                      const Spacer(),
                                      Text(t.amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    );
                  }
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        color: AppColors.surfaceLow,
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: _th('Date')),
                            Expanded(flex: 3, child: _th('Unit')),
                            Expanded(flex: 2, child: _th('Amount')),
                            Expanded(flex: 2, child: _th('Status')),
                            Expanded(child: _th('Action')),
                          ],
                        ),
                      ),
                      ...transactions.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)))),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(t.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurface))),
                            Expanded(flex: 3, child: Text(t.unit, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
                            Expanded(flex: 2, child: Text(t.amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                            Expanded(flex: 2, child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: t.status == 'Paid' ? AppColors.tertiaryFixed.withValues(alpha: 0.2) : AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: t.status == 'Paid' ? AppColors.tertiaryFixedDim : AppColors.error.withValues(alpha: 0.2)),
                              ),
                              child: Text(t.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.textColor)),
                            )),
                            const Expanded(child: Icon(Icons.more_horiz, size: 18, color: AppColors.secondary)),
                          ],
                        ),
                      )),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _th(String label) {
    return Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.secondary));
  }
}

class _TxnRow {
  final String date;
  final String unit;
  final String amount;
  final String status;
  final Color color;
  final Color textColor;
  const _TxnRow({required this.date, required this.unit, required this.amount, required this.status, required this.color, required this.textColor});
}

// ── Portfolio Yield ──────────────────────────────────
class _PortfolioYield extends StatefulWidget {
  @override
  State<_PortfolioYield> createState() => _PortfolioYieldState();
}

class _PortfolioYieldState extends State<_PortfolioYield> {
  final ApiService _api = ApiService();
  late Future<_YieldData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadYield();
  }

  Future<_YieldData> _loadYield() async {
    List<double> bars = [0.6, 0.75, 0.65, 0.9, 0.8, 0.85];
    List<String> labels = ['MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT'];
    String occupancy = '98.2%';
    String avgDelay = '-';
    try {
      final trendsRes = await _api.get('/reports/payment-trends?months=12');
      if (trendsRes.statusCode == 200) {
        final trendList = jsonDecode(trendsRes.body) as List<dynamic>;
        if (trendList.isNotEmpty) {
          final recent6 = trendList.length > 6 ? trendList.sublist(trendList.length - 6) : trendList;
          final incomes = recent6.map<num>((e) => (e['income'] as num?) ?? 0).toList();
          final maxIncome = incomes.fold<num>(0, (a, b) => a > b ? a : b);
          bars = incomes.map<double>((e) => maxIncome > 0 ? (e / maxIncome).toDouble().clamp(0.05, 1.0) : 0.0).toList();
          labels = recent6.map<String>((e) {
            final monthStr = (e['month'] ?? '').toString();
            try {
              final dt = DateTime.parse(monthStr);
              const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
              return months[dt.month - 1];
            } catch (_) {
              return monthStr.substring(0, monthStr.length > 3 ? 3 : monthStr.length).toUpperCase();
            }
          }).toList();
        }
      }
    } catch (_) {}

    try {
      final occRes = await _api.get('/analytics/occupancy');
      if (occRes.statusCode == 200) {
        final occData = jsonDecode(occRes.body) as Map<String, dynamic>;
        final rate = occData['occupancy_rate'];
        if (rate != null) occupancy = '$rate%';
      }
    } catch (_) {}

    try {
      final dashRes = await _api.get('/analytics/dashboard');
      if (dashRes.statusCode == 200) {
        final dashData = jsonDecode(dashRes.body) as Map<String, dynamic>;
        final overdue = dashData['overdue_count'];
        if (overdue != null) avgDelay = '$overdue overdue';
      }
    } catch (_) {}

    return _YieldData(bars: bars, labels: labels, occupancy: occupancy, avgDelay: avgDelay);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: FutureBuilder<_YieldData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const _YieldData(bars: [0.6,0.75,0.65,0.9,0.8,0.85], labels: ['MAY','JUN','JUL','AUG','SEP','OCT'], occupancy: '98.2%', avgDelay: '-');
          final bars = data.bars;
          final labels = data.labels;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Portfolio Yield', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Lexend', color: AppColors.primary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.outlineVariant)),
                    child: const Text('Last 6 Months', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Chart bars
              SizedBox(
                height: 220,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(bars.length, (i) {
                    final isLast = i == bars.length - 1;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 210 * bars[i],
                              decoration: BoxDecoration(
                                color: isLast ? AppColors.tertiaryFixedDim : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              // X-axis labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(labels.length, (i) {
                  final isLast = i == labels.length - 1;
                  return Text(labels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isLast ? AppColors.primary : AppColors.secondary));
                }),
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: AppColors.outlineVariant),
              const SizedBox(height: 20),
              _yieldRow('Occupancy Rate', data.occupancy),
              const SizedBox(height: 12),
              _yieldRow('Avg. Rent Delay', data.avgDelay),
            ],
          );
        },
      ),
    );
  }

  Widget _yieldRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ],
    );
  }
}

class _YieldData {
  final List<double> bars;
  final List<String> labels;
  final String occupancy;
  final String avgDelay;
  const _YieldData({required this.bars, required this.labels, required this.occupancy, required this.avgDelay});
}

class _DashboardOverview {
  final double totalCollected;
  final double outstanding;
  final int collectionRate;
  final int pendingIssues;

  _DashboardOverview({required this.totalCollected, required this.outstanding, required this.collectionRate, required this.pendingIssues});

  factory _DashboardOverview.fromJson(Map<String, dynamic> json) {
    return _DashboardOverview(
      totalCollected: (json['total_collected'] ?? 0).toDouble(),
      outstanding: (json['outstanding'] ?? 0).toDouble(),
      collectionRate: (json['collection_rate'] ?? 0).toInt(),
      pendingIssues: (json['pending_issues'] ?? 0).toInt(),
    );
  }
}
