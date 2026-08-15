import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class TenantProfileScreen extends StatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergNameController = TextEditingController();
  final _emergPhoneController = TextEditingController();
  String _emergRelation = 'Spouse';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    _emailController.text = user?.email ?? '';
    _phoneController.text = (user?.phone?.trim().isNotEmpty ?? false) ? user!.phone!.trim() : '';
    _emergNameController.text = 'Jane Mercer';
    _emergPhoneController.text = '+254 789 012 345';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergNameController.dispose();
    _emergPhoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('Settings Saved – Your profile has been updated.')),
          ],
        ),
        backgroundColor: AppColors.tertiaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final fullName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final initials = fullName.isEmpty ? '?' : fullName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 18)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PersonalInfoCard(initials: initials, nameController: _nameController, emailController: _emailController, phoneController: _phoneController),
          const SizedBox(height: 16),
          const _LeaseDetailsCard(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return isNarrow
                  ? Column(
                      children: [
                        _EmergencyContactCard(nameController: _emergNameController, phoneController: _emergPhoneController, relation: _emergRelation, onRelationChanged: (v) => setState(() => _emergRelation = v)),
                        const SizedBox(height: 16),
                        const _DocumentCenterCard(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _EmergencyContactCard(nameController: _emergNameController, phoneController: _emergPhoneController, relation: _emergRelation, onRelationChanged: (v) => setState(() => _emergRelation = v))),
                        const SizedBox(width: 16),
                        const Expanded(child: _DocumentCenterCard()),
                      ],
                    );
            },
          ),
          const SizedBox(height: 16),
          // Account Security
          const _AccountSecurityCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  final String initials;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  const _PersonalInfoCard({required this.initials, required this.nameController, required this.emailController, required this.phoneController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          final avatar = Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.surfaceHigh,
                    child: Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.photo_camera_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(initials.isEmpty ? 'Tenant' : nameController.text.isNotEmpty ? nameController.text : 'Tenant',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 16)),
              const SizedBox(height: 2),
              const Text('Verified Tenant', style: TextStyle(fontSize: 13, color: AppColors.secondary)),
            ],
          );
          final form = Column(
            children: [
              _ProfileField(label: 'Full Name', controller: nameController),
              const SizedBox(height: 16),
              _ProfileField(label: 'Email Address', controller: emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _ProfileField(label: 'Phone Number', controller: phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              const _ReadonlyField(label: 'National ID / Passport', value: '********4521'),
            ],
          );
          if (isNarrow) {
            return Column(children: [avatar, const SizedBox(height: 20), form]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 28),
              Expanded(child: form),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _ProfileField({required this.label, required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.outlineVariant)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.outlineVariant)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadonlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.kodiGreen),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontSize: 14, fontFamily: 'Inter', color: AppColors.secondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaseDetailsCard extends StatelessWidget {
  const _LeaseDetailsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lease Details', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.kodiGreen,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Property
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.apartment_rounded, color: AppColors.kodiGreen, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PROPERTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: Colors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    const Text('The Heights', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Unit 4B, Silicon Valley East', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('START DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: Colors.white.withValues(alpha: 0.5))),
                      const SizedBox(height: 4),
                      Text('Jan 01, 2024', style: TextStyle(fontSize: 14, fontFamily: 'Inter', color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('END DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: Colors.white.withValues(alpha: 0.5))),
                      const SizedBox(height: 4),
                      Text('Dec 31, 2024', style: TextStyle(fontSize: 14, fontFamily: 'Inter', color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MONTHLY RENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: Colors.white.withValues(alpha: 0.5))),
                const Text('KSh 120,000', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.kodiGreen, fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final String relation;
  final ValueChanged<String> onRelationChanged;
  const _EmergencyContactCard({required this.nameController, required this.phoneController, required this.relation, required this.onRelationChanged});

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),
          _ProfileField(label: 'Full Name', controller: nameController),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Relationship', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: relation,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                  DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                  DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) { if (v != null) onRelationChanged(v); },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileField(label: 'Phone Number', controller: phoneController, keyboardType: TextInputType.phone),
        ],
      ),
    );
  }
}

class _DocumentCenterCard extends StatelessWidget {
  const _DocumentCenterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Document Center', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),
          const _DocTile(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: AppColors.danger,
            iconBg: AppColors.dangerSoft,
            title: 'View Lease Agreement',
            subtitle: 'PDF • 2.4 MB • Updated Jan 2024',
          ),
          const SizedBox(height: 10),
          const _DocTile(
            icon: Icons.description_rounded,
            iconColor: AppColors.kodiBlue,
            iconBg: AppColors.infoSoft,
            title: 'House Rules & Regulations',
            subtitle: 'PDF • 1.1 MB',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded: ${result.files.first.name}')));
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Upload Additional Document', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.outlineVariant, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  const _DocTile({required this.icon, required this.iconColor, required this.iconBg, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
              ],
            ),
          ),
          const Icon(Icons.download_rounded, color: AppColors.secondary, size: 20),
        ],
      ),
    );
  }
}

class _AccountSecurityCard extends StatelessWidget {
  const _AccountSecurityCard();

  void _openChangePassword(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const ChangePasswordSheet(accentColor: AppColors.kodiGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account Security', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('Manage your password and security preferences.', style: TextStyle(fontSize: 13, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openChangePassword(context),
                      icon: const Icon(Icons.key_rounded, size: 18),
                      label: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.outline),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showSnack(context, '2FA coming soon'),
                      icon: const Icon(Icons.phonelink_lock_rounded, size: 18),
                      label: const Text('Two-Factor Auth', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.outline),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Security', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18)),
                    SizedBox(height: 4),
                    Text('Manage your password and security preferences.', style: TextStyle(fontSize: 13, color: AppColors.secondary)),
                  ],
                ),
              ),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openChangePassword(context),
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.outline),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showSnack(context, '2FA coming soon'),
                    icon: const Icon(Icons.phonelink_lock_rounded, size: 18),
                    label: const Text('Two-Factor Auth', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.outline),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
