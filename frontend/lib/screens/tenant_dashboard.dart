import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'tenant_payments_screen.dart';
import 'tenant_profile_screen.dart';
import 'tenant_support_screen.dart';
import 'tenant_rights_screen.dart';
import 'landlord_tenant_act_screen.dart';
import 'pay_rent_screen.dart';
import 'login_screen.dart';
import 'raise_maintenance_details_screen.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  final ApiService _api = ApiService();
  int _navIndex = 0;
  bool _sidebarOpen = true;
  bool _mobileSidebarOpen = false;
  _TenantOverview? _overview;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    try {
      final r = await _api.get('/tenant/overview');
      if (r.statusCode != 200) return;
      if (!mounted) return;
      setState(() => _overview = _TenantOverview.fromJson(jsonDecode(r.body)));
    } catch (_) {}
  }

  void _onNavTap(int i) {
    setState(() {
      _navIndex = i;
      _mobileSidebarOpen = false;
    });
  }

  void _onMenuTap() {
    setState(() {
      if (MediaQuery.of(context).size.width > 900) {
        _sidebarOpen = !_sidebarOpen;
      } else {
        _mobileSidebarOpen = !_mobileSidebarOpen;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      _TenantHomeTab(overview: _overview, onRefresh: _loadOverview),
      const TenantPaymentsScreen(),
      const TenantProfileScreen(),
      const TenantSupportScreen(),
    ];

    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    width: _sidebarOpen ? 280 : 0,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    child: _TenantSidebar(navIndex: _navIndex, onTap: _onNavTap),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _TenantTopBar(
                        navIndex: _navIndex,
                        userName: _overview?.tenantName ?? 'Tenant',
                        sidebarOpen: isWide ? _sidebarOpen : _mobileSidebarOpen,
                        onMenuTap: _onMenuTap,
                        onNotifications: () {},
                        onProfileTap: () => _onNavTap(2),
                      ),
                      Expanded(
                        child: IndexedStack(index: _navIndex, children: screens),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isWide && _mobileSidebarOpen) ...[
              GestureDetector(
                onTap: () => setState(() => _mobileSidebarOpen = false),
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: SizedBox(width: 280, child: _TenantSidebar(navIndex: _navIndex, onTap: _onNavTap)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────
class _TenantSidebar extends StatelessWidget {
  final int navIndex;
  final ValueChanged<int> onTap;
  const _TenantSidebar({required this.navIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Home', Icons.home_outlined, Icons.home),
      ('Payments', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
      ('Profile', Icons.person_outline, Icons.person),
      ('Support', Icons.help_outline, Icons.help),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: AppColors.tertiaryFixed, borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: Text('K', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onTertiaryFixed))),
                    ),
                    const SizedBox(width: 10),
                    const Text('KodiPay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.onPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('TENANT PORTAL', style: TextStyle(fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: AppColors.onPrimary.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(items.length, (i) {
            final item = items[i];
            final sel = navIndex == i;
            return Container(
              decoration: sel ? const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.tertiaryFixed, width: 4)),
              ) : null,
              child: Material(
                color: sel ? AppColors.onPrimary.withValues(alpha: 0.1) : Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      children: [
                        Icon(sel ? item.$3 : item.$2, size: 22, color: sel ? AppColors.onPrimary : AppColors.onPrimary.withValues(alpha: 0.7)),
                        const SizedBox(width: 12),
                        Text(item.$1, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                          color: sel ? AppColors.onPrimary : AppColors.onPrimary.withValues(alpha: 0.7),
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
                onPressed: () async {
                  final api = ApiService();
                  await api.clearToken();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
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

// ── Top Bar ──────────────────────────────────────────────
class _TenantTopBar extends StatelessWidget {
  final int navIndex;
  final String userName;
  final bool sidebarOpen;
  final VoidCallback onMenuTap;
  final VoidCallback onNotifications;
  final VoidCallback onProfileTap;
  const _TenantTopBar({required this.navIndex, required this.userName, required this.sidebarOpen, required this.onMenuTap, required this.onNotifications, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Payments', 'Profile', 'Support'];
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(sidebarOpen ? Icons.menu_open : Icons.menu),
            onPressed: onMenuTap,
          ),
          Text(titles[navIndex], style: const TextStyle(fontFamily: 'Lexend', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const Spacer(),
          if (!isNarrow)
            SizedBox(
              width: 260,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.secondary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.surfaceLow,
                ),
              ),
            ),
          if (!isNarrow) const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.secondary),
            onPressed: onNotifications,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceHigh,
              child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'T', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.secondary),
            onPressed: () async {
              final api = ApiService();
              await api.clearToken();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Home Tab ─────────────────────────────────────────────
class _TenantHomeTab extends StatelessWidget {
  final _TenantOverview? overview;
  final VoidCallback onRefresh;
  const _TenantHomeTab({this.overview, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final hasData = o != null;
    final outstanding = hasData ? o.rentOutstanding : 45000;
    final paid = o?.rentPaid ?? 0;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome + alert
            Text('Welcome back, ${o?.tenantName ?? 'Tenant'}!', style: const TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: outstanding > 0 ? AppColors.dangerSoft : AppColors.successSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (outstanding > 0 ? AppColors.danger : AppColors.kodiGreen).withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(outstanding > 0 ? Icons.schedule : Icons.check_circle_outline, size: 20, color: outstanding > 0 ? AppColors.danger : AppColors.kodiGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      outstanding > 0
                          ? 'Rent remaining to clear for ${o?.propertyName ?? 'your property'}, Unit ${o?.unitNumber ?? ''}: KSh ${formatKsh(outstanding)}'
                          : 'Rent for ${o?.propertyName ?? 'your property'}, Unit ${o?.unitNumber ?? ''} is fully paid. You are all clear!',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Hero balance card + maintenance card
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                return isNarrow
                    ? Column(
                        children: [
                          _BalanceHeroCard(amount: outstanding, paid: paid, propertyName: o?.propertyName ?? 'Your Property', unitNumber: o?.unitNumber ?? '', dueDate: o?.dueDay ?? 5),
                          const SizedBox(height: 16),
                          _MaintenanceCard(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _BalanceHeroCard(amount: outstanding, paid: paid, propertyName: o?.propertyName ?? 'Your Property', unitNumber: o?.unitNumber ?? '', dueDate: o?.dueDay ?? 5)),
                          const SizedBox(width: 16),
                          Expanded(flex: 1, child: _MaintenanceCard()),
                        ],
                      );
              },
            ),
            const SizedBox(height: 24),

            // Recent Transactions Table
            _RecentTransactionsTable(),
            const SizedBox(height: 24),

            // Unit details row
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 700 ? 3 : 1;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: cols == 1 ? 2.5 : 1.5,
                  children: [
                    _UnitDetailCard(
                      label: 'Assigned Property',
                      value: o?.propertyName ?? 'The Heights Apartments',
                      subtitle: 'Kileleshwa, Nairobi',
                      icon: Icons.apartment_rounded,
                      color: AppColors.primaryContainer,
                    ),
                    _UnitDetailCard(
                      label: 'Unit Number',
                      value: o?.unitNumber ?? '4B',
                      subtitle: 'Floor 4',
                      icon: Icons.meeting_room,
                      color: AppColors.surfaceLow,
                    ),
                    const _UnitDetailCard(
                      label: 'Lease Ends In',
                      value: '8 Months',
                      subtitle: '',
                      icon: Icons.calendar_month,
                      color: AppColors.surfaceLow,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineVariant))),
              child: const Column(
                children: [
                  Text('© 2024 KodiPay Kenya. All rights reserved.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 16, alignment: WrapAlignment.center,
                    children: [
                      Text('Terms', style: TextStyle(fontSize: 12, color: AppColors.secondary, decoration: TextDecoration.underline)),
                      Text('Privacy', style: TextStyle(fontSize: 12, color: AppColors.secondary, decoration: TextDecoration.underline)),
                      Text('Contact Support', style: TextStyle(fontSize: 12, color: AppColors.secondary, decoration: TextDecoration.underline)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Balance Hero Card ────────────────────────────────────
class _BalanceHeroCard extends StatelessWidget {
  final num amount;
  final num paid;
  final String propertyName;
  final String unitNumber;
  final int dueDate;
  const _BalanceHeroCard({required this.amount, required this.paid, required this.propertyName, required this.unitNumber, required this.dueDate});

  @override
  Widget build(BuildContext context) {
    final cleared = amount <= 0;
    final accent = cleared ? AppColors.kodiGreen : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cleared ? 'RENT CLEARED' : 'AMOUNT REMAINING TO CLEAR RENT', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('KSh ${formatKsh(amount)}', style: TextStyle(fontFamily: 'Lexend', fontSize: 40, fontWeight: FontWeight.w600, color: accent)),
          const SizedBox(height: 8),
          Text(
            paid > 0 ? 'You have paid KSh ${formatKsh(paid)} so far.' : 'No payment recorded yet.',
            style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: cleared
                    ? null
                    : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayRentScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kodiGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(cleared ? 'Rent Cleared' : 'Make Payment', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Download Invoice', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Maintenance Card ─────────────────────────────────────
class _MaintenanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(color: AppColors.surfaceHigh, shape: BoxShape.circle),
            child: const Icon(Icons.engineering, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Maintenance Issue?', style: TextStyle(fontFamily: 'Lexend', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('Broken tap? Electrical flickering? Report it now for quick assistance.', style: TextStyle(fontSize: 14, color: AppColors.secondary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RaiseMaintenanceDetailsScreen())),
              icon: const Icon(Icons.add_circle, size: 18),
              label: const Text('Raise Maintenance Issue', style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Transactions Table ────────────────────────────
class _RecentTransactionsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Transactions', style: TextStyle(fontFamily: 'Lexend', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All History', style: TextStyle(fontSize: 14, color: AppColors.primary)),
                ),
              ],
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppColors.surfaceLow,
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant))),
                Expanded(flex: 3, child: Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant))),
                Expanded(flex: 2, child: Text('REFERENCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant))),
                Expanded(flex: 2, child: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant))),
                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant))),
              ],
            ),
          ),
          const _TxRow(date: 'Oct 02, 2024', desc: 'Monthly Rent - October', ref: 'KP-992384', amount: 'KSh 40,000', status: 'Paid'),
          const _TxRow(date: 'Oct 02, 2024', desc: 'Service Charge', ref: 'KP-992385', amount: 'KSh 5,000', status: 'Paid'),
          const _TxRow(date: 'Sep 01, 2024', desc: 'Monthly Rent - September', ref: 'KP-812039', amount: 'KSh 40,000', status: 'Paid'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final String date, desc, ref, amount, status;
  const _TxRow({required this.date, required this.desc, required this.ref, required this.amount, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 14, fontFamily: 'Inter'))),
          Expanded(flex: 3, child: Text(desc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(ref, style: const TextStyle(fontSize: 14, color: AppColors.secondary))),
          Expanded(flex: 2, child: Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.kodiGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kodiGreen)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Unit Detail Card ─────────────────────────────────────
class _UnitDetailCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _UnitDetailCard({required this.label, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color == AppColors.primaryContainer ? color : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color == AppColors.primaryContainer ? Colors.white.withValues(alpha: 0.1) : AppColors.surfaceLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color == AppColors.primaryContainer ? Colors.white : AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: color == AppColors.primaryContainer ? Colors.white60 : AppColors.secondary)),
                Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color == AppColors.primaryContainer ? Colors.white : AppColors.primary)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: TextStyle(fontSize: 12, color: color == AppColors.primaryContainer ? Colors.white38 : AppColors.secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overview Model ───────────────────────────────────────
class _TenantOverview {
  final String tenantName;
  final String propertyName;
  final String unitNumber;
  final num rentAmount;
  final num rentPaid;
  final num rentOutstanding;
  final int dueDay;
  final String rentStatus;

  _TenantOverview({
    required this.tenantName, required this.propertyName, required this.unitNumber,
    required this.rentAmount, required this.rentPaid, required this.rentOutstanding,
    required this.dueDay, required this.rentStatus,
  });

  factory _TenantOverview.fromJson(Map<String, dynamic> json) => _TenantOverview(
    tenantName: json['tenant_name'] ?? 'Tenant',
    propertyName: json['property_name'] ?? 'Property',
    unitNumber: json['unit_number'] ?? '',
    rentAmount: (json['rent_amount'] ?? 0).toDouble(),
    rentPaid: (json['rent_paid'] ?? 0).toDouble(),
    rentOutstanding: (json['rent_outstanding'] ?? 0).toDouble(),
    dueDay: (json['due_day'] ?? 5).toInt(),
    rentStatus: json['rent_status'] ?? 'pending',
  );
}
