import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class LandlordSettingsScreen extends StatefulWidget {
  const LandlordSettingsScreen({super.key});

  @override
  State<LandlordSettingsScreen> createState() => _LandlordSettingsScreenState();
}

class _LandlordSettingsScreenState extends State<LandlordSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.firstName ?? '';
    final lastName = user?.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = user?.email ?? '—';

    return Scaffold(
      body: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            color: AppColors.surfaceLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.kodiGreen.withValues(alpha: 0.12),
                      child: Text(
                        _initials(firstName, lastName),
                        style: const TextStyle(color: AppColors.kodiGreen, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName.isEmpty ? 'Landlord' : fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, fontFamily: 'Lexend', color: AppColors.onSurface)),
                          const SizedBox(height: 2),
                          Text(email, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.kodiGreen,
                  unselectedLabelColor: AppColors.secondary,
                  indicatorColor: AppColors.kodiGreen,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Personal Info'),
                    Tab(text: 'Business Details'),
                    Tab(text: 'Security'),
                    Tab(text: 'Notifications'),
                  ],
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PersonalInfoTab(fullName: fullName, email: email, firstName: firstName, lastName: lastName, phone: user?.phone ?? '', profilePhotoUrl: user?.profilePhotoUrl),
                const _BusinessDetailsTab(),
                const _SecurityTab(),
                const _NotificationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String firstName, String lastName) {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return '?';
    return ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase();
  }
}

// ── Personal Info Tab ─────────────────────────────────
class _PersonalInfoTab extends StatefulWidget {
  final String fullName;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String? profilePhotoUrl;
  const _PersonalInfoTab({required this.fullName, required this.email, required this.firstName, required this.lastName, this.phone = '', this.profilePhotoUrl});

  @override
  State<_PersonalInfoTab> createState() => _PersonalInfoTabState();
}

class _PersonalInfoTabState extends State<_PersonalInfoTab> {
  late final TextEditingController _firstNameCtl;
  late final TextEditingController _lastNameCtl;
  late final TextEditingController _emailCtl;
  late final TextEditingController _phoneCtl;
  String? _selectedPhotoPath;
  bool _uploading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _firstNameCtl = TextEditingController(text: widget.firstName);
    _lastNameCtl = TextEditingController(text: widget.lastName);
    _emailCtl = TextEditingController(text: widget.email);
    _phoneCtl = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  ImageProvider<Object>? _avatarProvider() {
    if (_selectedPhotoPath != null) return FileImage(File(_selectedPhotoPath!));
    if (widget.profilePhotoUrl != null && widget.profilePhotoUrl!.isNotEmpty) {
      return NetworkImage(widget.profilePhotoUrl!);
    }
    return null;
  }

  Future<void> _pickAndUploadPhoto() async {
    final auth = context.read<AuthProvider>();
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final bytes = await File(path).readAsBytes();
    setState(() { _selectedPhotoPath = path; _uploading = true; });
    String? errorText;
    try {
      final response = await ApiService().uploadMultipart('/users/profile-photo', fileBytes: bytes, fileName: result.files.single.name, fieldName: 'photo', mimeType: result.files.single.extension == null ? null : 'image/${result.files.single.extension}');
      if (response.statusCode >= 400) {
        errorText = 'Upload failed (${response.statusCode})';
      } else {
        _showSnack('Photo updated successfully');
        await auth.refreshProfile();
      }
    } catch (e) {
      errorText = 'Upload error: $e';
    }
    if (!mounted) return;
    if (errorText != null) _showSnack(errorText);
    setState(() => _uploading = false);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final saved = await auth.updateProfile(
      firstName: _firstNameCtl.text,
      lastName: _lastNameCtl.text,
      email: _emailCtl.text,
      phone: _phoneCtl.text,
    );
    if (!mounted) return;
    _showSnack(saved ? 'Profile updated successfully' : 'Could not save your profile. Please try again.');
    if (saved) {
      await auth.refreshProfile();
      if (mounted) {
        final user = auth.user;
        setState(() {
          _firstNameCtl.text = user?.firstName ?? _firstNameCtl.text;
          _lastNameCtl.text = user?.lastName ?? _lastNameCtl.text;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _sectionHeader('Personal Information'),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.kodiGreen.withValues(alpha: 0.12),
                    backgroundImage: _avatarProvider(),
                    child: (_selectedPhotoPath == null && (widget.profilePhotoUrl == null || widget.profilePhotoUrl!.isEmpty))
                        ? Text(
                            _initials(widget.firstName, widget.lastName),
                            style: const TextStyle(color: AppColors.kodiGreen, fontWeight: FontWeight.w800, fontSize: 24),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.kodiGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Photo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  const Text('JPG, GIF, or PNG. Max 2MB.', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _uploading ? null : _pickAndUploadPhoto,
                    icon: _uploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_rounded, size: 16),
                    label: Text(_uploading ? 'Uploading...' : 'Upload New Photo', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('First Name', _firstNameCtl, Icons.person_outline_rounded, validator: (v) => validateHumanName(v, 'First name')),
          const SizedBox(height: 16),
          _buildField('Last Name', _lastNameCtl, Icons.person_outline_rounded, validator: (v) => validateHumanName(v, 'Last name')),
          const SizedBox(height: 16),
          _buildField('Email Address', _emailCtl, Icons.email_outlined, validator: validateEmail),
          const SizedBox(height: 16),
          _buildField('Phone Number', _phoneCtl, Icons.phone_outlined, validator: validatePhone),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiGreen),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign out?'),
                    content: const Text('You will need to sign in again to use KodiPay.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.dangerSoft),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showSnack('Account deletion coming soon'),
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
              label: const Text('Delete Account', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.dangerSoft),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String firstName, String lastName) {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return '?';
    return ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase();
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface, fontFamily: 'Lexend'));
  }

  Widget _buildField(String label, TextEditingController ctl, IconData icon, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctl,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}

// ── Business Details Tab ──────────────────────────────
class _BusinessDetailsTab extends StatefulWidget {
  const _BusinessDetailsTab();

  @override
  State<_BusinessDetailsTab> createState() => _BusinessDetailsTabState();
}

class _BusinessDetailsTabState extends State<_BusinessDetailsTab> {
  late TextEditingController _businessNameCtl;
  late TextEditingController _registrationCtl;
  late TextEditingController _kraPinCtl;
  late TextEditingController _contactPersonCtl;
  late TextEditingController _phoneCtl;
  late TextEditingController _emailCtl;
  late TextEditingController _addressCtl;
  late TextEditingController _cityCtl;
  late TextEditingController _countyCtl;
  late TextEditingController _postalCodeCtl;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _businessNameCtl = TextEditingController();
    _registrationCtl = TextEditingController();
    _kraPinCtl = TextEditingController();
    _contactPersonCtl = TextEditingController();
    _phoneCtl = TextEditingController();
    _emailCtl = TextEditingController();
    _addressCtl = TextEditingController();
    _cityCtl = TextEditingController();
    _countyCtl = TextEditingController();
    _postalCodeCtl = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameCtl.dispose();
    _registrationCtl.dispose();
    _kraPinCtl.dispose();
    _contactPersonCtl.dispose();
    _phoneCtl.dispose();
    _emailCtl.dispose();
    _addressCtl.dispose();
    _cityCtl.dispose();
    _countyCtl.dispose();
    _postalCodeCtl.dispose();
    super.dispose();
  }

  void _initFromUser(User? user) {
    if (_initialized || user == null) return;
    _initialized = true;
    _businessNameCtl.text = user.businessName ?? '';
    _registrationCtl.text = user.businessRegistration ?? '';
    _kraPinCtl.text = user.businessKraPin ?? '';
    _contactPersonCtl.text = user.businessContactPerson ?? '';
    _phoneCtl.text = user.businessPhone ?? '';
    _emailCtl.text = user.businessEmail ?? '';
    _addressCtl.text = user.businessAddress ?? '';
    _cityCtl.text = user.businessCity ?? '';
    _countyCtl.text = user.businessCounty ?? '';
    _postalCodeCtl.text = user.businessPostalCode ?? '';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final success = await context.read<AuthProvider>().updateProfile(
      businessName: _businessNameCtl.text.trim(),
      businessRegistration: _registrationCtl.text.trim(),
      businessKraPin: _kraPinCtl.text.trim(),
      businessContactPerson: _contactPersonCtl.text.trim(),
      businessPhone: _phoneCtl.text.trim(),
      businessEmail: _emailCtl.text.trim(),
      businessAddress: _addressCtl.text.trim(),
      businessCity: _cityCtl.text.trim(),
      businessCounty: _countyCtl.text.trim(),
      businessPostalCode: _postalCodeCtl.text.trim(),
    );
    if (mounted) {
      setState(() => _saving = false);
      _showSnack(success ? 'Business details updated successfully' : 'Update failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    _initFromUser(user);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionHeader('Legal Information'),
        const SizedBox(height: 16),
        _buildField('Business Name', Icons.business_rounded, _businessNameCtl),
        const SizedBox(height: 16),
        _buildField('Registration Number', Icons.assignment_outlined, _registrationCtl),
        const SizedBox(height: 16),
        _buildField('KRA PIN', Icons.receipt_long_outlined, _kraPinCtl),
        const SizedBox(height: 16),
        _buildField('Contact Person', Icons.person_outline_rounded, _contactPersonCtl),
        const SizedBox(height: 16),
        _buildField('Phone Number', Icons.phone_outlined, _phoneCtl),
        const SizedBox(height: 16),
        _buildField('Email Address', Icons.email_outlined, _emailCtl),
        const SizedBox(height: 24),
        _sectionHeader('Business Address'),
        const SizedBox(height: 16),
        _buildField('Building/Street', Icons.location_on_outlined, _addressCtl),
        const SizedBox(height: 16),
        _buildField('City', Icons.map_outlined, _cityCtl),
        const SizedBox(height: 16),
        _buildField('County', Icons.map_outlined, _countyCtl),
        const SizedBox(height: 16),
        _buildField('Postal Code', Icons.mail_outline_rounded, _postalCodeCtl),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiGreen),
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface, fontFamily: 'Lexend'));
  }

  Widget _buildField(String label, IconData icon, TextEditingController ctl) {
    return TextField(
      controller: ctl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}

// ── Security Tab ──────────────────────────────────────
class _SecurityTab extends StatefulWidget {
  const _SecurityTab();

  @override
  State<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<_SecurityTab> {
  final ApiService _api = ApiService();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _twoFactorEnabled = false;
  bool _submitting = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    setState(() => _submitting = true);
    try {
      final response = await _api.post('/auth/change-password', {
        'current_password': current,
        'new_password': next,
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
        _showSnack('Password updated successfully');
        setState(() => _submitting = false);
        return;
      }
      Map<String, dynamic>? data;
      try { data = jsonDecode(response.body) as Map<String, dynamic>; } catch (_) {}
      setState(() => _submitting = false);
      _showSnack(data?['error']?.toString() ?? 'Failed to change password (${response.statusCode}).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack('Failed to change password: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _sectionHeader('Change Password'),
          const SizedBox(height: 16),
          _buildPasswordField(_currentCtrl, 'Current Password', _obscureCurrent, (v) => setState(() => _obscureCurrent = v), validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            return null;
          }),
          const SizedBox(height: 16),
          _buildPasswordField(_newCtrl, 'New Password', _obscureNew, (v) => setState(() => _obscureNew = v), validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length < 6) return 'Min 6 characters';
            return null;
          }),
          const SizedBox(height: 16),
          _buildPasswordField(_confirmCtrl, 'Confirm New Password', _obscureConfirm, (v) => setState(() => _obscureConfirm = v), validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v != _newCtrl.text) return 'Passwords do not match';
            return null;
          }),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _changePassword,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiGreen),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 28),
          _sectionHeader('Two-Factor Authentication'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.infoSoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.security_rounded, color: AppColors.info, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.onSurface)),
                      const SizedBox(height: 2),
                      Text(
                        _twoFactorEnabled ? 'Your account is secure with 2FA' : 'Add an extra layer of security',
                        style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _twoFactorEnabled,
                  onChanged: (v) => setState(() => _twoFactorEnabled = v),
                  activeThumbColor: AppColors.kodiGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _sectionHeader('Active Sessions'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                _sessionRow('This device', 'Active now', Icons.laptop_windows_rounded, true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showSnack('All other sessions logged out'),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log Out All Sessions', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.dangerSoft),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface, fontFamily: 'Lexend'));
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, ValueChanged<bool> onToggle, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
          onPressed: () => onToggle(!obscure),
        ),
      ),
    );
  }

  Widget _sessionRow(String device, String status, IconData icon, bool isActive) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onSurface)),
              Text(status, style: TextStyle(fontSize: 11, color: isActive ? AppColors.kodiGreen : AppColors.secondary)),
            ],
          ),
        ),
        if (isActive)
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: AppColors.kodiGreen, shape: BoxShape.circle),
          ),
      ],
    );
  }
}

// ── Notifications Tab ─────────────────────────────────
class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  bool _rentPayments = true;
  bool _maintenanceRequests = true;
  bool _leaseRenewals = true;
  bool _propertyInquiries = true;
  bool _systemUpdates = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionHeader('Notification Preferences'),
        const SizedBox(height: 4),
        const Text('Choose what notifications you receive', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
        const SizedBox(height: 20),
        _sectionSubHeader('Alert Types'),
        const SizedBox(height: 12),
        _toggleTile('Rent Payments', 'Payment received and overdue alerts', Icons.payments_outlined, _rentPayments, (v) => setState(() => _rentPayments = v)),
        _toggleTile('Maintenance Requests', 'New requests and status updates', Icons.build_outlined, _maintenanceRequests, (v) => setState(() => _maintenanceRequests = v)),
        _toggleTile('Lease Renewals', 'Upcoming lease expiration reminders', Icons.description_outlined, _leaseRenewals, (v) => setState(() => _leaseRenewals = v)),
        _toggleTile('Property Inquiries', 'New tenant inquiries and viewings', Icons.home_work_outlined, _propertyInquiries, (v) => setState(() => _propertyInquiries = v)),
        _toggleTile('System Updates', 'Platform updates and maintenance', Icons.system_update_outlined, _systemUpdates, (v) => setState(() => _systemUpdates = v)),
        const SizedBox(height: 24),
        _sectionSubHeader('Notification Channels'),
        const SizedBox(height: 12),
        _toggleTile('Email', 'Receive notifications via email', Icons.email_outlined, _emailNotifications, (v) => setState(() => _emailNotifications = v)),
        _toggleTile('Push', 'Receive push notifications', Icons.notifications_outlined, _pushNotifications, (v) => setState(() => _pushNotifications = v)),
        _toggleTile('SMS', 'Receive SMS notifications', Icons.sms_outlined, _smsNotifications, (v) => setState(() => _smsNotifications = v)),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => _showSnack('Notification preferences saved'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiGreen),
            child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface, fontFamily: 'Lexend'));
  }

  Widget _sectionSubHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.secondary, letterSpacing: 0.5));
  }

  Widget _toggleTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onSurface)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.kodiGreen,
          ),
        ],
      ),
    );
  }
}
