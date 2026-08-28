import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/caretaker_entry.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/shared_screen_components.dart';

class CaretakerDetailScreen extends StatefulWidget {
  final CaretakerEntry entry;
  final VoidCallback onRemove;
  const CaretakerDetailScreen({
    super.key,
    required this.entry,
    required this.onRemove,
  });

  @override
  State<CaretakerDetailScreen> createState() => _CaretakerDetailScreenState();
}

class _CaretakerDetailScreenState extends State<CaretakerDetailScreen> {
  late CaretakerEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    showSnack(context, '$label copied');
  }

  Future<void> _edit() async {
    final updated = await showModalBottomSheet<CaretakerEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditCaretakerSheet(entry: _entry),
    );
    if (updated != null && mounted) {
      setState(() => _entry = updated);
      showSnack(context, 'Caretaker updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _entry.fullName.isEmpty ? _entry.email : _entry.fullName;
    final initials = _entry.fullName.isEmpty
        ? _entry.email.characters.first.toUpperCase()
        : _entry.fullName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase();
    final phone = _entry.phone?.trim();
    return FeatureScaffold(
      title: 'Caretaker',
      accentColor: AppColors.kodiOrange,
      actions: [
        IconButton(
          onPressed: _edit,
          icon: const Icon(Icons.edit_outlined, color: AppColors.kodiOrange),
          tooltip: 'Edit caretaker',
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TappableCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      AppColors.kodiOrange.withValues(alpha: 0.12),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.kodiOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: AppStyles.heading2),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.kodiOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Caretaker',
                    style: TextStyle(
                      color: AppColors.kodiOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DetailSection(
            title: 'Contact',
            rows: [
              DetailRowData('Full name', name),
              DetailRowData('Email', _entry.email),
              DetailRowData(
                  'Phone',
                  (phone?.isNotEmpty ?? false) ? phone! : 'Not added'),
            ],
          ),
          const SizedBox(height: 14),
          DetailSection(
            title: 'Assigned property',
            rows: [
              DetailRowData(
                  'Property',
                  _entry.propertyName.isEmpty ? '—' : _entry.propertyName),
              DetailRowData(
                  'Address',
                  _entry.propertyAddress.isEmpty
                      ? '—'
                      : _entry.propertyAddress),
            ],
          ),
          const SizedBox(height: 14),
          SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Edit caretaker details',
            subtitle: 'Update name, phone, etc.',
            onTap: _edit,
          ),
          SettingsTile(
            icon: Icons.copy_all_outlined,
            title: 'Copy email',
            subtitle: _entry.email,
            onTap: () => _copy(context, 'Email', _entry.email),
          ),
          if (phone != null && phone.isNotEmpty)
            SettingsTile(
              icon: Icons.call_outlined,
              title: 'Copy phone',
              subtitle: phone,
              onTap: () => _copy(context, 'Phone', phone),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onRemove();
              },
              icon: const Icon(Icons.person_remove_outlined),
              label: Text(
                  'Remove from ${_entry.propertyName.isEmpty ? "this property" : _entry.propertyName}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Removing only removes this caretaker from this property. Other property assignments stay intact.',
            style: AppStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _EditCaretakerSheet extends StatefulWidget {
  final CaretakerEntry entry;
  const _EditCaretakerSheet({required this.entry});

  @override
  State<_EditCaretakerSheet> createState() => _EditCaretakerSheetState();
}

class _EditCaretakerSheetState extends State<_EditCaretakerSheet> {
  late final TextEditingController _firstNameCtl;
  late final TextEditingController _lastNameCtl;
  late final TextEditingController _phoneCtl;
  bool _saving = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _firstNameCtl = TextEditingController(text: widget.entry.firstName);
    _lastNameCtl = TextEditingController(text: widget.entry.lastName);
    _phoneCtl = TextEditingController(text: widget.entry.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final api = ApiService();
      final res = await api.put('/caretakers/${widget.entry.caretakerId}', {
        'first_name': _firstNameCtl.text.trim(),
        'last_name': _lastNameCtl.text.trim(),
        'phone': _phoneCtl.text.trim(),
      });
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        Navigator.pop(context, CaretakerEntry(
          assignmentId: widget.entry.assignmentId,
          caretakerId: widget.entry.caretakerId,
          email: data['email'] ?? widget.entry.email,
          firstName: data['first_name'] ?? _firstNameCtl.text.trim(),
          lastName: data['last_name'] ?? _lastNameCtl.text.trim(),
          phone: data['phone'] ?? _phoneCtl.text.trim(),
          propertyId: widget.entry.propertyId,
          propertyName: widget.entry.propertyName,
          propertyAddress: widget.entry.propertyAddress,
        ));
      } else {
        final body = jsonDecode(res.body);
        setState(() { _error = body['error'] ?? 'Update failed'; _saving = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Connection error'; _saving = false; });
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
                  const Text('Edit Caretaker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 4),
              Text(widget.entry.email, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
              const SizedBox(height: 20),
              _field('First Name', _firstNameCtl, validator: (v) => validateHumanName(v, 'First name')),
              const SizedBox(height: 14),
              _field('Last Name', _lastNameCtl, validator: (v) => validateHumanName(v, 'Last name')),
              const SizedBox(height: 14),
              _field('Phone', _phoneCtl, keyboardType: TextInputType.phone, validator: validatePhone),
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
                    backgroundColor: AppColors.kodiOrange,
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
              borderSide: BorderSide(color: AppColors.kodiOrange, width: 1.5),
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
