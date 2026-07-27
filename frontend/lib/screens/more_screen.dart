import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'app_preferences_screen.dart';
import 'profile_screen.dart';
import 'caretakers_screen.dart';
import 'rights_screen.dart';
import 'support_screen.dart';
import 'landlord_notifications_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(Icons.settings_outlined, 'Settings', 'App preferences, alerts, and exports', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppPreferencesScreen()))),
          _tile(Icons.person_outline_rounded, 'Profile', 'Account and security', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen(role: 'Landlord', accentColor: AppColors.kodiGreen)))),
          _tile(Icons.engineering_outlined, 'Caretakers', 'Add or remove caretakers for your properties', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CaretakersScreen()))),
          _tile(Icons.gavel_outlined, 'Your Rights', 'Landlord & tenant rights, plain English', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RightsScreen(role: 'landlord')))),
          _tile(Icons.help_outline_rounded, 'Support', 'Get help with payments or reports', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen(accentColor: AppColors.kodiGreen)))),
          _tile(Icons.account_balance_wallet_outlined, 'Wallet & Payouts', 'View earnings and request withdrawals', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPayoutsScreen()))),
          _tile(Icons.announcement_outlined, 'Notifications', 'View all notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LandlordNotificationsScreen()))),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: Ui.card(),
        child: ListTile(
          leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.kodiNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.kodiNavy, size: 20)),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: AppStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
          onTap: onTap,
        ),
      ),
    );
  }
}

// ── Wallet & Payouts ──────────────────────────────────
class WalletPayoutsScreen extends StatefulWidget {
  const WalletPayoutsScreen({super.key});
  @override
  State<WalletPayoutsScreen> createState() => _WalletPayoutsScreenState();
}

class _WalletPayoutsScreenState extends State<WalletPayoutsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wallet & Payouts', style: TextStyle(fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Balance card
          _buildBalanceCard(),
          const SizedBox(height: 20),
          // Stats row
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              SizedBox(width: 160, child: _buildStatCard('Total Earnings', 'KSh 827,500', Icons.trending_up, AppColors.kodiGreen)),
              SizedBox(width: 160, child: _buildStatCard('This Month', 'KSh 195,000', Icons.calendar_month, AppColors.kodiBlue)),
              SizedBox(width: 160, child: _buildStatCard('Pending', 'KSh 50,000', Icons.hourglass_empty, AppColors.warning)),
            ],
          ),
          const SizedBox(height: 24),
          // Recent payouts header
          Row(
            children: [
              const Expanded(child: Text('Payout History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface))),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download Statement', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPayoutItem('M-Pesa', 'KSh 45,000', 'Oct 12, 2026', Icons.phone_android_rounded, 'Completed'),
          _buildDivider(),
          _buildPayoutItem('Bank Transfer', 'KSh 62,500', 'Sep 28, 2026', Icons.account_balance_rounded, 'Completed'),
          _buildDivider(),
          _buildPayoutItem('M-Pesa', 'KSh 120,000', 'Sep 15, 2026', Icons.phone_android_rounded, 'Processing'),
          _buildDivider(),
          _buildPayoutItem('Bank Transfer', 'KSh 55,000', 'Aug 30, 2026', Icons.account_balance_rounded, 'Completed'),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF002244)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.tertiaryFixed, borderRadius: BorderRadius.circular(20)),
                child: const Text('ACTIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.onTertiaryFixed, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Available Balance', style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 4),
          const Text('KSh 185,400', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Lexend')),
          const SizedBox(height: 4),
          const Text('+ KSh 195,000 expected this month', style: TextStyle(fontSize: 12, color: AppColors.tertiaryFixed)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiaryFixed,
                      foregroundColor: AppColors.onTertiaryFixed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Add Bank', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.onSurface, fontFamily: 'Lexend')),
        ],
      ),
    );
  }

  Widget _buildPayoutItem(String method, String amount, String date, IconData icon, String status) {
    final isCompleted = status == 'Completed';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(amount, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text('$method • $date', style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.kodiGreen.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: isCompleted ? AppColors.kodiGreen : AppColors.warning,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.outlineVariant);
  }
}

