import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});
  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Security Settings',
      accentColor: AppColors.kodiNavy,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _section('Change Password'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: Ui.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPasswordField('Current Password'),
                const SizedBox(height: 12),
                _buildPasswordField('New Password'),
                const SizedBox(height: 12),
                _buildPasswordField('Confirm New Password'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => showSnack(context, 'Password updated.'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kodiNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _section('Two-Factor Authentication'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: Ui.card(),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.kodiBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.security_rounded, color: AppColors.kodiBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Authenticator App', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text(_twoFactorEnabled ? 'Extra security is active' : 'Add an extra layer of security', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _twoFactorEnabled,
                      onChanged: (v) => setState(() => _twoFactorEnabled = v),
                      activeTrackColor: AppColors.kodiGreen.withValues(alpha: 0.4), activeThumbColor: AppColors.kodiGreen,
                    ),
                  ],
                ),
                if (_twoFactorEnabled) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text('Two-factor authentication is enabled', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          _section('Active Sessions'),
          const SizedBox(height: 10),
          _sessionItem('Chrome on Windows', 'Nairobi, KE • Current session', Icons.laptop_windows_rounded, true),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _sessionItem('Safari on iPhone', 'Nairobi, KE • 2 hours ago', Icons.phone_iphone_rounded, false),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _sessionItem('Firefox on macOS', 'Mombasa, KE • 3 days ago', Icons.laptop_mac_rounded, false),
          const SizedBox(height: 22),
          _section('Login History'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: Ui.card(),
            child: Column(
              children: [
                _loginHistoryRow('Chrome on Windows', 'Nairobi, KE', 'Jul 20, 2026 09:15 AM', AppColors.success),
                const Divider(height: 1),
                _loginHistoryRow('Safari on iPhone', 'Nairobi, KE', 'Jul 19, 2026 14:30 PM', AppColors.success),
                const Divider(height: 1),
                _loginHistoryRow('Firefox on macOS', 'Mombasa, KE', 'Jul 17, 2026 08:45 AM', AppColors.warning),
                const Divider(height: 1),
                _loginHistoryRow('Chrome on Android', 'Nairobi, KE', 'Jul 15, 2026 22:10 PM', AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark));
  }

  Widget _buildPasswordField(String label) {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        filled: true,
        fillColor: AppColors.surfaceLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _sessionItem(String device, String subtitle, IconData icon, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.infoSoft : AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.kodiBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.kodiBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(device, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                        child: const Text('CURRENT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.kodiGreen, letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
          if (!isCurrent)
            TextButton(
              onPressed: () => showSnack(context, 'Session terminated.'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: const Text('Revoke', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _loginHistoryRow(String device, String location, String time, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textDark)),
                const SizedBox(height: 1),
                Text(location, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
      ),
    );
  }
}
