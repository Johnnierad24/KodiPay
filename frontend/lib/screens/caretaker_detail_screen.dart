import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/caretaker_entry.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class CaretakerDetailScreen extends StatelessWidget {
  final CaretakerEntry entry;
  final VoidCallback onRemove;
  const CaretakerDetailScreen({
    super.key,
    required this.entry,
    required this.onRemove,
  });

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    showSnack(context, '$label copied');
  }

  @override
  Widget build(BuildContext context) {
    final name = entry.fullName.isEmpty ? entry.email : entry.fullName;
    final initials = entry.fullName.isEmpty
        ? entry.email.characters.first.toUpperCase()
        : entry.fullName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase();
    final phone = entry.phone?.trim();
    return FeatureScaffold(
      title: 'Caretaker',
      accentColor: AppColors.kodiOrange,
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
              DetailRowData('Email', entry.email),
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
                  entry.propertyName.isEmpty ? '—' : entry.propertyName),
              DetailRowData(
                  'Address',
                  entry.propertyAddress.isEmpty
                      ? '—'
                      : entry.propertyAddress),
            ],
          ),
          const SizedBox(height: 14),
          SettingsTile(
            icon: Icons.copy_all_outlined,
            title: 'Copy email',
            subtitle: entry.email,
            onTap: () => _copy(context, 'Email', entry.email),
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
                onRemove();
              },
              icon: const Icon(Icons.person_remove_outlined),
              label: Text(
                  'Remove from ${entry.propertyName.isEmpty ? "this property" : entry.propertyName}'),
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

