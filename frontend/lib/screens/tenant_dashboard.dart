import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import 'feature_screens.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  final ApiService _api = ApiService();
  Future<_TenantHomeData>? _future;

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

  Future<_TenantHomeData> _fetch() async {
    // 1. Tenancy
    final tenancyResp = await _api.get('/tenancies');
    _ActiveTenancy? tenancy;
    List<_TenantHistoryItem> history = const [];
    if (tenancyResp.statusCode == 200) {
      final tenancies = (jsonDecode(tenancyResp.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      if (tenancies.isNotEmpty) {
        final active = tenancies.firstWhere(
          (t) => (t['status']?.toString() ?? 'active') == 'active',
          orElse: () => tenancies.first,
        );
        tenancy = _ActiveTenancy.fromJson(active);

        // 2. Payments for that tenancy
        try {
          final paymentsResp =
              await _api.get('/payments/tenancy/${tenancy.id}');
          if (paymentsResp.statusCode == 200) {
            history = (jsonDecode(paymentsResp.body) as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map(_TenantHistoryItem.fromJson)
                .toList();
          }
        } catch (_) {/* skip */}
      }
    }

    // 3. Notices (used as fallback content if no rent due)
    List<_TenantNoticePeek> notices = const [];
    try {
      final notifResp = await _api.get('/notifications');
      if (notifResp.statusCode == 200) {
        notices = (jsonDecode(notifResp.body) as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(_TenantNoticePeek.fromJson)
            .toList();
      }
    } catch (_) {/* skip */}

    return _TenantHomeData(
      tenancy: tenancy,
      history: history,
      notices: notices,
    );
  }

  bool _paidForCurrentMonth(List<_TenantHistoryItem> history) {
    final now = DateTime.now();
    return history.any((p) =>
        p.isPaid &&
        p.date != null &&
        p.date!.year == now.year &&
        p.date!.month == now.month);
  }

  String _money(num value) {
    final whole = value.toInt();
    return whole.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        );
  }

  String _dueDateLabel(DateTime due) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = due.day;
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : (day % 10 == 1)
            ? 'st'
            : (day % 10 == 2)
                ? 'nd'
                : (day % 10 == 3)
                    ? 'rd'
                    : 'th';
    return 'Due $day$suffix ${months[due.month - 1]} ${due.year}';
  }

  String _historyMonth(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _historyDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.firstName ?? 'Tenant';
    final lastName = user?.lastName ?? '';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<_TenantHomeData>(
            future: _future,
            builder: (context, snapshot) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardHeader(
                      name: '$firstName $lastName'.trim(),
                      subtitle: 'Welcome back!',
                      accentColor: AppColors.kodiBlue,
                      onLogout: () =>
                          context.read<AuthProvider>().logout(),
                      onMenuTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(
                            role: 'Tenant',
                            accentColor: AppColors.kodiBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildTopPanel(snapshot),
                    const SizedBox(height: 22),
                    const SectionTitle(title: 'Quick Actions'),
                    _buildQuickActions(context),
                    const SizedBox(height: 22),
                    SectionTitle(
                      title: 'Recent Payments',
                      actionLabel: 'View all',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TenantPaymentsScreen()),
                      ),
                    ),
                    _buildHistory(snapshot),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        selectedColor: AppColors.kodiBlue,
        onTap: (index) {
          final List<Widget?> screens = [
            null,
            const TenantPaymentsScreen(),
            const TenantMaintenanceScreen(),
            const TenantNoticesScreen(),
            const ProfileScreen(
              role: 'Tenant',
              accentColor: AppColors.kodiBlue,
            ),
          ];
          final screen = screens[index];
          if (screen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Payments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.handyman_outlined), label: 'Maintenance'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_rounded), label: 'Notices'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildTopPanel(AsyncSnapshot<_TenantHomeData> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D6FD8), Color(0xFF0047A1)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.white),
      );
    }

    final data = snapshot.data;
    if (data == null || data.tenancy == null) {
      return GradientPanel(
        startColor: const Color(0xFF1D6FD8),
        endColor: const Color(0xFF0047A1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No active tenancy',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are not currently linked to a unit. Contact your landlord if this is wrong.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final tenancy = data.tenancy!;
    final paidThisMonth = _paidForCurrentMonth(data.history);

    if (paidThisMonth) {
      return _buildAllCaughtUpPanel(tenancy, data.notices, data.history);
    }
    return _buildRentDuePanel(tenancy);
  }

  Widget _buildRentDuePanel(_ActiveTenancy tenancy) {
    final now = DateTime.now();
    final dueDay = (tenancy.startDay ?? 25).clamp(1, 28);
    final dueDate = DateTime(now.year, now.month, dueDay);
    return GradientPanel(
      startColor: const Color(0xFF1D6FD8),
      endColor: const Color(0xFF0047A1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rent Due',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'KSh ${_money(tenancy.rentAmount)}',
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${tenancy.propertyName} • Unit ${tenancy.unitNumber} • ${_dueDateLabel(dueDate)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.kodiBlue,
              ),
              onPressed: () => Navigator.pushNamed(context, '/pay-rent'),
              child: const Text('Pay Now (M-Pesa)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCaughtUpPanel(
    _ActiveTenancy tenancy,
    List<_TenantNoticePeek> notices,
    List<_TenantHistoryItem> history,
  ) {
    final paid = history.firstWhere(
      (p) => p.isPaid,
      orElse: () => _TenantHistoryItem.empty(),
    );
    final paidLabel = paid.date != null
        ? 'You paid KSh ${_money(paid.amount)} on ${_historyDate(paid.date!)}.'
        : 'You are paid up for this month.';
    final latest = notices.isNotEmpty ? notices.first : null;

    return GradientPanel(
      startColor: const Color(0xFF10A55A),
      endColor: const Color(0xFF047857),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white.withValues(alpha: 0.95)),
              const SizedBox(width: 8),
              const Text(
                "You're all caught up",
                style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            paidLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
            ),
          ),
          if (latest != null) ...[
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TenantNoticesScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_outlined,
                        color: AppColors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latest.title,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (latest.message.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              latest.message,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.86),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.white),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: [
        QuickActionTile(
          label: 'Pay Rent',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.kodiBlue,
          onTap: () => Navigator.pushNamed(context, '/pay-rent'),
        ),
        QuickActionTile(
          label: 'Maintenance',
          icon: Icons.build_outlined,
          color: AppColors.kodiOrange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const TenantMaintenanceScreen()),
          ),
        ),
        QuickActionTile(
          label: 'Receipts',
          icon: Icons.description_outlined,
          color: AppColors.kodiNavy,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TenantPaymentsScreen()),
          ),
        ),
        QuickActionTile(
          label: 'Notices',
          icon: Icons.campaign_outlined,
          color: AppColors.kodiNavy,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TenantNoticesScreen()),
          ),
        ),
        QuickActionTile(
          label: 'Your Rights',
          icon: Icons.gavel_outlined,
          color: AppColors.kodiGreen,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const RightsScreen(role: 'tenant')),
          ),
        ),
      ],
    );
  }

  Widget _buildHistory(AsyncSnapshot<_TenantHomeData> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final history = (snapshot.data?.history ?? const <_TenantHistoryItem>[])
        .where((p) => p.isPaid)
        .take(2)
        .toList();
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.receipt_long_outlined, color: AppColors.muted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No payments yet. Your paid receipts will appear here.',
                style: AppStyles.caption,
              ),
            ),
          ],
        ),
      );
    }
    return ListPanel(
      children: [
        for (var i = 0; i < history.length; i++) ...[
          if (i > 0) const _DividerLine(),
          _HistoryRow(
            month: history[i].date != null
                ? _historyMonth(history[i].date!)
                : '—',
            amount: 'KSh ${_money(history[i].amount)}',
            date: history[i].date != null
                ? _historyDate(history[i].date!)
                : '—',
          ),
        ],
      ],
    );
  }
}

class _ActiveTenancy {
  final int id;
  final String propertyName;
  final String unitNumber;
  final num rentAmount;
  final int? startDay;

  const _ActiveTenancy({
    required this.id,
    required this.propertyName,
    required this.unitNumber,
    required this.rentAmount,
    required this.startDay,
  });

  factory _ActiveTenancy.fromJson(Map<String, dynamic> json) {
    int? day;
    final raw = json['start_date']?.toString();
    if (raw != null && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      day = parsed?.day;
    }
    return _ActiveTenancy(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      propertyName: (json['property_name'] ?? '').toString(),
      unitNumber: (json['unit_number'] ?? '').toString(),
      rentAmount: (json['rent_amount'] is num)
          ? json['rent_amount'] as num
          : num.tryParse(json['rent_amount']?.toString() ?? '') ?? 0,
      startDay: day,
    );
  }
}

class _TenantHistoryItem {
  final num amount;
  final String status;
  final DateTime? date;

  const _TenantHistoryItem({
    required this.amount,
    required this.status,
    required this.date,
  });

  bool get isPaid => status.toLowerCase() == 'completed';

  factory _TenantHistoryItem.empty() =>
      const _TenantHistoryItem(amount: 0, status: '', date: null);

  factory _TenantHistoryItem.fromJson(Map<String, dynamic> json) {
    return _TenantHistoryItem(
      amount: (json['amount'] is num)
          ? json['amount'] as num
          : num.tryParse(json['amount']?.toString() ?? '') ?? 0,
      status: (json['status'] ?? 'pending').toString(),
      date: DateTime.tryParse(json['payment_date']?.toString() ?? ''),
    );
  }
}

class _TenantNoticePeek {
  final String title;
  final String message;
  const _TenantNoticePeek({required this.title, required this.message});

  factory _TenantNoticePeek.fromJson(Map<String, dynamic> json) {
    return _TenantNoticePeek(
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class _TenantHomeData {
  final _ActiveTenancy? tenancy;
  final List<_TenantHistoryItem> history;
  final List<_TenantNoticePeek> notices;

  const _TenantHomeData({
    required this.tenancy,
    required this.history,
    required this.notices,
  });
}

class _HistoryRow extends StatelessWidget {
  final String month;
  final String amount;
  final String date;

  const _HistoryRow({
    required this.month,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(month,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(amount,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    const StatusPill(label: 'Paid', color: AppColors.kodiGreen),
                  ],
                ),
              ],
            ),
          ),
          Text(date, style: AppStyles.caption),
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
        height: 1, indent: 15, endIndent: 15, color: AppColors.border);
  }
}
