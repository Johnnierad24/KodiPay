import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class ProfileScreen extends StatelessWidget {
  final String role;
  final Color accentColor;

  const ProfileScreen({
    super.key,
    required this.role,
    required this.accentColor,
  });

  String _initials(String firstName, String lastName) {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return '?';
    return ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase();
  }

  Future<void> _confirmAndSignOut(BuildContext context) async {
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
    if (confirm != true) return;
    if (!context.mounted) return;
    await context.read<AuthProvider>().logout();
  }

  Future<void> _openSheet(BuildContext context, Widget sheet) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.firstName ?? '';
    final lastName = user?.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = user?.email ?? '—';
    final phone = (user?.phone?.trim().isNotEmpty ?? false) ? user!.phone!.trim() : 'Not added';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Profile header
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: accentColor.withValues(alpha: 0.12),
              child: Text(_initials(firstName, lastName),
                style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 22)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName.isEmpty ? role : fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, fontFamily: 'Lexend', color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 13, color: AppColors.secondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.tertiaryFixed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                    child: Text('Gold Tier $role', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.onTertiaryFixed, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Personal Information section
        _sectionHeader('Personal Information'),
        const SizedBox(height: 12),
        _infoCard([
          _infoRow('Full Name', fullName.isEmpty ? '—' : fullName),
          _infoRow('Email Address', email),
          _infoRow('Phone Number', phone),
          _infoRow('Account Type', role),
        ]),
        const SizedBox(height: 20),

        // Quick actions
        _sectionHeader('Account'),
        const SizedBox(height: 12),
        _actionTile(Icons.edit_outlined, 'Edit Profile', 'Update your name, email, or phone', () => _openSheet(context, EditProfileSheet(accentColor: accentColor))),
        const SizedBox(height: 8),
        _actionTile(Icons.lock_reset_rounded, 'Change Password', 'Set a new password', () => _openSheet(context, ChangePasswordSheet(accentColor: accentColor))),
        const SizedBox(height: 8),
        _actionTile(Icons.copy_all_outlined, 'Copy Email', email, () async {
          await Clipboard.setData(ClipboardData(text: email));
          if (!context.mounted) return;
          showSnack(context, 'Email copied to clipboard');
        }),
        const SizedBox(height: 24),

        // Sign out
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmAndSignOut(context),
            icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
            label: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.dangerSoft),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.onSurface));
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.secondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface))),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: accentColor, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
