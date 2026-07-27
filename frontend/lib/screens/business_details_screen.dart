import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});
  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Business Details',
      accentColor: AppColors.kodiNavy,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _section('Legal Information'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: Ui.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field('Business Name', 'Amani Kwetu Properties Ltd'),
                const SizedBox(height: 12),
                _field('Registration Number', 'BN/2024/67890'),
                const SizedBox(height: 12),
                _buildKraField(),
                const SizedBox(height: 12),
                _field('Contact Person', 'James Mwangi'),
                const SizedBox(height: 12),
                _field('Phone Number', '0700 000 111'),
                const SizedBox(height: 12),
                _field('Email Address', 'james@amanikwetu.co.ke'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _section('Business Address'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: Ui.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field('Address', '123 Ngong Road, Nairobi'),
                const SizedBox(height: 12),
                _field('City', 'Nairobi'),
                const SizedBox(height: 12),
                _field('Postal Code', '00100'),
                const SizedBox(height: 14),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 36, color: AppColors.muted),
                        SizedBox(height: 6),
                        Text('Map Preview', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Ngong Road, Nairobi, Kenya', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _section('Verification Status'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Verified Business', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      const Text('Your business information has been verified', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                        child: const Text('VERIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success, letterSpacing: 0.8)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => showSnack(context, 'Business details updated.'),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _section(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark));
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildKraField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('KRA PIN', style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Text('P051234567Z', style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 10, color: AppColors.success),
                    SizedBox(width: 3),
                    Text('Verified', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
