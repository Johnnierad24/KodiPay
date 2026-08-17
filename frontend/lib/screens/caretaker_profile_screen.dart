import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class CaretakerProfileScreen extends StatefulWidget {
  const CaretakerProfileScreen({super.key});
  @override
  State<CaretakerProfileScreen> createState() => _CaretakerProfileScreenState();
}

class _CaretakerProfileScreenState extends State<CaretakerProfileScreen> {
  bool _pushNotifs = true;
  bool _smsNotifs = true;
  bool _emailReports = false;

  final ApiService _api = ApiService();
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _properties = [];
  bool _loading = true;

  String get _fullName {
    final first = (_user?['first_name'] ?? '').toString();
    final last = (_user?['last_name'] ?? '').toString();
    return '$first $last'.trim();
  }

  String get _initials {
    final first = (_user?['first_name'] ?? '').toString();
    final last = (_user?['last_name'] ?? '').toString();
    if (first.isNotEmpty && last.isNotEmpty) return '${first[0]}${last[0]}'.toUpperCase();
    if (first.isNotEmpty) return first[0].toUpperCase();
    return '...';
  }

  String get _propertyName => _properties.isNotEmpty ? (_properties.first['property_name'] ?? 'Unassigned') : 'Unassigned';
  int get _totalUnits => _properties.fold<int>(0, (s, p) => s + (p['total_units'] as int? ?? 0));
  int get _occupiedUnits => _properties.fold<int>(0, (s, p) => s + (p['occupied_units'] as int? ?? 0));
  int get _openMaintenance => _properties.fold<int>(0, (s, p) => s + (p['open_maintenance'] as int? ?? 0));

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.get('/auth/me'),
        _api.get('/caretaker/my-properties'),
      ]);
      final userRes = results[0];
      final propRes = results[1];
      if (userRes.statusCode == 200) {
        _user = Map<String, dynamic>.from(jsonDecode(userRes.body));
      }
      if (propRes.statusCode == 200) {
        _properties = (jsonDecode(propRes.body) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _openEditSheet() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditProfileSheet(user: _user),
    ).then((saved) {
      if (saved == true) _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 900;

    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            sliver: SliverToBoxAdapter(
              child: isWide ? _buildWideProfileHero() : _buildMobileProfileHero(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildLeftColumn()),
                        const SizedBox(width: 18),
                        SizedBox(width: 300, child: _buildRightColumn()),
                      ],
                    )
                  : _buildMobileColumn(),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildWideProfileHero() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildIdentityCard()),
        const SizedBox(width: 18),
        SizedBox(width: 300, child: _buildAssignmentCard()),
      ],
    );
  }

  Widget _buildMobileProfileHero() {
    return Column(
      children: [
        _buildIdentityCard(),
        const SizedBox(height: 16),
        _buildAssignmentCard(),
      ],
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                color: AppColors.kodiGreen.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.kodiGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12)],
                    ),
                    child: Center(child: Text(_initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.kodiGreen))),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(color: AppColors.kodiNavy, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(_loading ? 'Loading...' : (_fullName.isNotEmpty ? _fullName : 'Caretaker'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.kodiGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('Verified Caretaker', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.kodiGreen, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoPill(Icons.email_outlined, _user?['email'] ?? '—'),
                    const SizedBox(height: 6),
                    _infoPill(Icons.phone_outlined, _user?['phone'] ?? '—'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _badgeChip(Icons.badge_outlined, 'ID: KP-${_user?['id'] ?? '—'}'),
                        _badgeChip(Icons.work_outline_rounded, 'Caretaker'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textLight), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _badgeChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.kodiNavy),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.kodiNavy)),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.kodiNavy, Color(0xFF0A2744)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.kodiNavy.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Assignment'.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(_loading ? 'Loading...' : _propertyName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Lexend')),
          const SizedBox(height: 4),
          Text(_loading ? '' : '$_occupiedUnits of $_totalUnits units occupied | $_openMaintenance maintenance pending', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 18),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.map_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                Text('Estate Map View', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.kodiGreen,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('View Estate Map', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPersonalInfo(),
        const SizedBox(height: 18),
        _buildEmergencyContact(),
      ],
    );
  }

  Widget _buildMobileColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPersonalInfo(),
        const SizedBox(height: 18),
        _buildEmergencyContact(),
        const SizedBox(height: 18),
        _buildAccountSecurity(),
        const SizedBox(height: 18),
        _buildNotifications(),
        const SizedBox(height: 18),
        _buildSignOutButton(),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAccountSecurity(),
        const SizedBox(height: 18),
        _buildNotifications(),
        const SizedBox(height: 18),
        _buildSignOutButton(),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Personal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
                TextButton.icon(
                  onPressed: _openEditSheet,
                  icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.kodiGreen),
                  label: const Text('Edit Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kodiGreen)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _detailField('Full Name', _fullName.isNotEmpty ? _fullName : '—')),
                          const SizedBox(width: 20),
                          Expanded(child: _detailField('Email', _user?['email'] ?? '—')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _detailField('Phone', _user?['phone'] ?? '—')),
                          const SizedBox(width: 20),
                          Expanded(child: _detailField('Role', (_user?['role'] ?? 'caretaker').toString().toUpperCase())),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildEmergencyContact() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.emergency_outlined, size: 18, color: AppColors.danger),
                SizedBox(width: 8),
                Text('Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.danger, fontFamily: 'Lexend')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _detailField('Contact Name', 'Peter Njenga')),
                    const SizedBox(width: 20),
                    Expanded(child: _detailField('Relationship', 'Spouse')),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _detailField('Primary Phone', '+254 712 000 333')),
                    const SizedBox(width: 20),
                    Expanded(child: _detailField('Alternative Phone', '+254 700 444 555')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurity() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Text('Account Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _securityTile(
                  Icons.lock_outline_rounded,
                  'Password',
                  'Last changed 3 months ago',
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (_) => const ChangePasswordSheet(accentColor: AppColors.kodiGreen),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
                ),
                const SizedBox(height: 8),
                _securityTile(
                  Icons.verified_user_outlined,
                  'Two-Factor Auth',
                  null,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                    child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.kodiGreen)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityTile(IconData icon, String title, String? subtitle, {VoidCallback? onTap, required Widget trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textLight),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifications() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _notifToggle('Push Notifications', 'Alerts on task updates', _pushNotifs, (v) => setState(() => _pushNotifs = v)),
                const SizedBox(height: 12),
                _notifToggle('SMS Alerts', 'Emergency & payment alerts', _smsNotifs, (v) => setState(() => _smsNotifs = v)),
                const SizedBox(height: 12),
                _notifToggle('Email Reports', 'Weekly property status', _emailReports, (v) => setState(() => _emailReports = v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.kodiGreen.withValues(alpha: 0.4),
          activeThumbColor: AppColors.kodiGreen,
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign Out?'),
                content: const Text('You will need to sign in again to use KodiPay.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            );
            if (!mounted) return;
            if (confirm == true) {
              await context.read<AuthProvider>().logout();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.danger, width: 2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                SizedBox(width: 8),
                Text('Sign Out Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic>? user;
  const _EditProfileSheet({this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _firstNameCtl;
  late final TextEditingController _lastNameCtl;
  late final TextEditingController _emailCtl;
  late final TextEditingController _phoneCtl;
  bool _saving = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _firstNameCtl = TextEditingController(text: widget.user?['first_name'] ?? '');
    _lastNameCtl = TextEditingController(text: widget.user?['last_name'] ?? '');
    _emailCtl = TextEditingController(text: widget.user?['email'] ?? '');
    _phoneCtl = TextEditingController(text: widget.user?['phone'] ?? '');
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final api = ApiService();
      final res = await api.put('/auth/profile', {
        'first_name': _firstNameCtl.text.trim(),
        'last_name': _lastNameCtl.text.trim(),
        'email': _emailCtl.text.trim(),
        'phone': _phoneCtl.text.trim(),
      });
      if (res.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.'), backgroundColor: AppColors.kodiGreen),
        );
      } else {
        final body = jsonDecode(res.body);
        setState(() { _error = body['error'] ?? 'Update failed'; _saving = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPad),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _field('First Name', _firstNameCtl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 14),
              _field('Last Name', _lastNameCtl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 14),
              _field('Email', _emailCtl, keyboardType: TextInputType.emailAddress, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                return null;
              }),
              const SizedBox(height: 14),
              _field('Phone', _phoneCtl, keyboardType: TextInputType.phone),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kodiGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctl, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctl,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLow,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: AppColors.kodiGreen, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}
