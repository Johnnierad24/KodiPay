import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import 'feature_screens.dart';

class LandlordDashboard extends StatelessWidget {
  const LandlordDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.firstName ?? 'James';
    final lastName = user?.lastName ?? 'Mwangi';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                name: '$firstName $lastName',
                subtitle: 'Good morning!',
                accentColor: AppColors.kodiGreen,
                onLogout: () => context.read<AuthProvider>().logout(),
                onMenuTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoreScreen()),
                ),
              ),
              const SizedBox(height: 18),
              GradientPanel(
                startColor: const Color(0xFF10A55A),
                endColor: const Color(0xFF047857),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Overview',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'This Month',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.25,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      children: const [
                        StatBox(value: '12', label: 'Properties'),
                        StatBox(value: '48', label: 'Units'),
                        StatBox(value: 'KSh 245,000', label: 'Total Income'),
                        StatBox(value: '5', label: 'Pending Payments'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionTitle(
                title: 'Recent Payments',
                actionLabel: 'View all',
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LandlordPaymentsScreen()),
                ),
              ),
              const ListPanel(
                children: [
                  _PaymentRow(
                      name: 'Mary Wanjiku',
                      unit: 'A2 - Sunview Apts',
                      amount: 'KSh 25,000',
                      status: 'Paid'),
                  _DividerLine(),
                  _PaymentRow(
                      name: 'John Kamau',
                      unit: 'B1 - Greenfield Hts',
                      amount: 'KSh 20,000',
                      status: 'Paid'),
                  _DividerLine(),
                  _PaymentRow(
                      name: 'Peter Ochieng',
                      unit: 'C3 - Lakeview Villas',
                      amount: 'KSh 25,000',
                      status: 'Pending'),
                ],
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
                      label: 'Add Property',
                      icon: Icons.add_home_rounded,
                      color: AppColors.kodiGreen,
                      onTap: () => showPropertySheet(context)),
                  QuickActionTile(
                      label: 'Add Tenant',
                      icon: Icons.person_add_alt_1_rounded,
                      color: AppColors.kodiNavy,
                      onTap: () => showTenantSheet(context)),
                  QuickActionTile(
                      label: 'Reminder',
                      icon: Icons.mail_outline_rounded,
                      color: AppColors.kodiBlue,
                      onTap: () => showReminderSheet(context)),
                  QuickActionTile(
                      label: 'Reports',
                      icon: Icons.analytics_outlined,
                      color: AppColors.kodiBlue,
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LandlordReportsScreen()),
                          )),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        selectedColor: AppColors.kodiGreen,
        onTap: (index) {
          final List<Widget?> screens = [
            null,
            const PropertyListScreen(),
            const TenantListScreen(),
            const LandlordPaymentsScreen(),
            const MoreScreen(),
          ];
          final screen = screens[index];
          if (screen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => screen),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.home_work_outlined), label: 'Properties'),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups_2_outlined), label: 'Tenants'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Payments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: 'More'),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String name;
  final String unit;
  final String amount;
  final String status;

  const _PaymentRow({
    required this.name,
    required this.unit,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'Paid';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.kodiGreen.withValues(alpha: 0.12),
            child: Text(name.characters.first,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      fontSize: 12)),
              const SizedBox(height: 5),
              StatusPill(
                  label: status,
                  color: isPaid ? AppColors.kodiGreen : AppColors.kodiOrange),
            ],
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
        height: 1, indent: 58, endIndent: 14, color: AppColors.border);
  }
}
