import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'property_list_screen.dart';
import 'add_property_screen.dart';
import 'landlord_notifications_screen.dart';
import 'landlord_reports_screen.dart';
import 'landlord_settings_screen.dart';
import 'landlord_wallet_screen.dart';
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
                        userName: '${user?.firstName ?? 'Jabari'} ${user?.lastName ?? 'Kamau'}',
                        sidebarOpen: isWide ? _sidebarOpen : _mobileSidebarOpen,
                        onMenuTap: _onMenuTap,
                        onNotifications: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LandlordNotificationsScreen())),
                        onProfileTap: () => _onNavTap(4),
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
    final isNarrow = MediaQuery.of(context).size.width < 600;
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
  final VoidCallback onRefresh;
  final VoidCallback? onNavigateToReports;
  final VoidCallback? onNavigateToProperties;

  const _HomeTab({required this.user, this.overview, required this.unreadCount, required this.onRefresh, this.onNavigateToReports, this.onNavigateToProperties});

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final collectionRate = o?.collectionRate ?? 92;
    final totalCollected = o?.totalCollected ?? 1100000;
    final outstanding = o?.outstanding ?? 96500;
    final pendingIssues = o?.pendingIssues ?? 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome
          const SizedBox(height: 8),
          Text('Welcome back, ${user?.firstName ?? 'Jabari'}!', style: AppStyles.headlineLg.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text('Here is your portfolio performance for October.', style: AppStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 24),
          // Quick Actions
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (onNavigateToProperties != null) {
                    onNavigateToProperties!();
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
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
                        const Text('Oct 2024', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.secondary)),
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
                            Icon(Icons.trending_up, size: 14, color: AppColors.error),
                            SizedBox(width: 4),
                            Text('+4% from last month', style: TextStyle(fontSize: 12, color: AppColors.error)),
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
class _RecentTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final transactions = [
      ('Oct 12, 2024', 'Riverside Apt #4B', 'KSh 45,000', 'Paid', AppColors.tertiaryFixedDim, AppColors.onTertiaryFixedVariant),
      ('Oct 11, 2024', 'Kilimani Court #12', 'KSh 62,500', 'Unpaid', AppColors.errorContainer, AppColors.onErrorContainer),
      ('Oct 10, 2024', 'Garden Estate #A2', 'KSh 120,000', 'Paid', AppColors.tertiaryFixedDim, AppColors.onTertiaryFixedVariant),
      ('Oct 09, 2024', 'Riverside Apt #2C', 'KSh 45,000', 'Paid', AppColors.tertiaryFixedDim, AppColors.onTertiaryFixedVariant),
      ('Oct 08, 2024', 'Kilimani Court #05', 'KSh 58,000', 'Unpaid', AppColors.errorContainer, AppColors.onErrorContainer),
    ];

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
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
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
                                  Expanded(child: Text(t.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: t.$4 == 'Paid' ? AppColors.tertiaryFixed.withValues(alpha: 0.2) : AppColors.errorContainer,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: t.$4 == 'Paid' ? AppColors.tertiaryFixedDim : AppColors.error.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(t.$4, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.$5)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(t.$1, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                                  const Spacer(),
                                  Text(t.$3, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                        Expanded(flex: 2, child: Text(t.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurface))),
                        Expanded(flex: 3, child: Text(t.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
                        Expanded(flex: 2, child: Text(t.$3, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                        Expanded(flex: 2, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.$4 == 'Paid' ? AppColors.tertiaryFixed.withValues(alpha: 0.2) : AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: t.$4 == 'Paid' ? AppColors.tertiaryFixedDim : AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Text(t.$4, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.$5)),
                        )),
                        const Expanded(child: Icon(Icons.more_horiz, size: 18, color: AppColors.secondary)),
                      ],
                    ),
                  )),
                ],
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

// ── Portfolio Yield ──────────────────────────────────
class _PortfolioYield extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bars = [0.6, 0.75, 0.65, 0.9, 0.8, 0.85];
    final labels = ['MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
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
                final isOct = i == 5;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 210 * bars[i],
                          decoration: BoxDecoration(
                            color: isOct ? AppColors.tertiaryFixedDim : AppColors.primary.withValues(alpha: 0.1),
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
              final isOct = i == 5;
              return Text(labels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isOct ? AppColors.primary : AppColors.secondary));
            }),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 20),
          // Stats
          _yieldRow('Occupancy Rate', '98.2%'),
          const SizedBox(height: 12),
          _yieldRow('Avg. Rent Delay', '2.4 Days'),
        ],
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

class _DashboardOverview {
  final double totalCollected;
  final double outstanding;
  final int collectionRate;
  final int pendingIssues;

  _DashboardOverview({required this.totalCollected, required this.outstanding, required this.collectionRate, required this.pendingIssues});

  factory _DashboardOverview.fromJson(Map<String, dynamic> json) {
    return _DashboardOverview(
      totalCollected: (json['total_collected'] ?? 1100000).toDouble(),
      outstanding: (json['outstanding'] ?? 96500).toDouble(),
      collectionRate: (json['collection_rate'] ?? 92).toInt(),
      pendingIssues: (json['pending_issues'] ?? 3).toInt(),
    );
  }
}

