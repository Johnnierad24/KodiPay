import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import 'feature_screens.dart';

class TenantDashboard extends StatelessWidget {
  const TenantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.firstName ?? 'Mary';
    final lastName = user?.lastName ?? 'Wanjiku';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                name: '$firstName $lastName',
                subtitle: 'Welcome back!',
                accentColor: AppColors.kodiBlue,
                onLogout: () => context.read<AuthProvider>().logout(),
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
              GradientPanel(
                startColor: const Color(0xFF1D6FD8),
                endColor: const Color(0xFF0047A1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rent Due',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'KSh 25,000',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text('Due on 25th May 2024',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 13)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.kodiBlue,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/pay-rent'),
                        child: const Text('Pay Now (M-Pesa)'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionTitle(title: 'Quick Actions'),
              GridView.count(
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
                                builder: (_) =>
                                    const TenantMaintenanceScreen()),
                          )),
                  QuickActionTile(
                      label: 'Receipts',
                      icon: Icons.description_outlined,
                      color: AppColors.kodiNavy,
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TenantPaymentsScreen()),
                          )),
                  QuickActionTile(
                      label: 'Notices',
                      icon: Icons.campaign_outlined,
                      color: AppColors.kodiNavy,
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TenantNoticesScreen()),
                          )),
                ],
              ),
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
              const ListPanel(
                children: [
                  _HistoryRow(
                      month: 'Apr 2024',
                      amount: 'KSh 25,000',
                      date: 'Apr 25, 2024'),
                  _DividerLine(),
                  _HistoryRow(
                      month: 'Mar 2024',
                      amount: 'KSh 25,000',
                      date: 'Mar 25, 2024'),
                ],
              ),
            ],
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
