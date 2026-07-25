import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  // Rent Payments
  bool _rentEmail = true;
  bool _rentPush = true;
  // Maintenance
  bool _maintEmail = true;
  bool _maintPush = false;
  // System Alerts
  bool _sysEmail = true;
  bool _sysPush = true;
  // Marketing
  bool _mktEmail = false;
  bool _mktPush = false;

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Notification Settings',
      accentColor: AppColors.kodiNavy,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildCategoryCard(
            'Rent Payments',
            'Payment confirmations, reminders, and arrears alerts',
            Icons.receipt_long_rounded,
            AppColors.kodiGreen,
            _rentEmail, _rentPush,
            (v) => setState(() => _rentEmail = v),
            (v) => setState(() => _rentPush = v),
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            'Maintenance Requests',
            'New requests, status updates, and work orders',
            Icons.build_outlined,
            AppColors.kodiOrange,
            _maintEmail, _maintPush,
            (v) => setState(() => _maintEmail = v),
            (v) => setState(() => _maintPush = v),
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            'System Alerts',
            'Payment callbacks, exports, and account notices',
            Icons.notifications_active_rounded,
            AppColors.kodiBlue,
            _sysEmail, _sysPush,
            (v) => setState(() => _sysEmail = v),
            (v) => setState(() => _sysPush = v),
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            'Marketing & Updates',
            'Product updates, tips, and promotional offers',
            Icons.campaign_outlined,
            AppColors.kodiNavy,
            _mktEmail, _mktPush,
            (v) => setState(() => _mktEmail = v),
            (v) => setState(() => _mktPush = v),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => showSnack(context, 'Notification preferences saved.'),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kodiNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool email,
    bool push,
    ValueChanged<bool> onEmailChanged,
    ValueChanged<bool> onPushChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _toggleRow(Icons.email_outlined, 'Email', email, onEmailChanged),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _toggleRow(Icons.phone_android_outlined, 'Push', push, onPushChanged),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: value ? AppColors.kodiNavy.withValues(alpha: 0.06) : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: value ? AppColors.kodiNavy.withValues(alpha: 0.15) : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: value ? AppColors.kodiNavy : AppColors.muted),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: value ? AppColors.kodiNavy : AppColors.muted)),
          const Spacer(),
          SizedBox(
            height: 24,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.kodiGreen.withValues(alpha: 0.4), activeThumbColor: AppColors.kodiGreen,
            ),
          ),
        ],
      ),
    );
  }
}
