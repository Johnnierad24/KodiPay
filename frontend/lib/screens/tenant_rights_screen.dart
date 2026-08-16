import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class TenantRightsScreen extends StatelessWidget {
  const TenantRightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Legal Corner', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 18)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeroBanner(),
          const SizedBox(height: 24),
          _BentoGrid(),
          const SizedBox(height: 24),
          _DistressProtectionCard(),
          const SizedBox(height: 24),
          _TenantDeathCard(),
          const SizedBox(height: 24),
          const _FaqSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LANDLORD & TENANT BILL, 2021',
                  style: TextStyle(color: AppColors.onTertiaryFixed, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Know Your Rights as a Tenant in Kenya',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Empowering you with legal knowledge from the Landlord and Tenant Bill, 2021. The Bill repeals Cap 301, Cap 296, and Cap 293, offering equal protection to both landlords and tenants.',
                style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.85), height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse('https://new.kenyalaw.org/akn/ke/bill/na/2021/3/eng@2021-02-12'), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text('Download Bill (PDF)', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kodiGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.gavel_rounded, size: 140, color: Colors.white.withValues(alpha: 0.08)),
          ),
        ],
      ),
    );
  }
}

class _BentoGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return Column(
            children: [
              _HabitableDwellingCard(),
              const SizedBox(height: 16),
              _PrivacyCard(),
              const SizedBox(height: 16),
              _FairRentCard(),
              const SizedBox(height: 16),
              _SecurityDepositCard(),
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: _HabitableDwellingCard()),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _PrivacyCard()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: _FairRentCard()),
                const SizedBox(width: 16),
                Expanded(flex: 8, child: _SecurityDepositCard()),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HabitableDwellingCard extends StatelessWidget {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kodiGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_repair_service_rounded, color: AppColors.kodiGreen, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Right to a Habitable Dwelling', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18, height: 1.3)),
                    SizedBox(height: 6),
                    Text(
                      'Your landlord is legally obligated to ensure the premises are in a good state of repair and fit for human habitation under the Bill.',
                      style: TextStyle(fontSize: 14, color: AppColors.secondary, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KEY OBLIGATIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.textDark)),
                SizedBox(height: 12),
                _ObligationItem(text: 'Structural integrity and safety of the building.'),
                SizedBox(height: 8),
                _ObligationItem(text: 'Functional plumbing, electrical, and drainage systems.'),
                SizedBox(height: 8),
                _ObligationItem(text: 'Provision of clean water and waste disposal.'),
                SizedBox(height: 8),
                _ObligationItem(text: 'Major repairs (roofs, exterior walls, plumbing systems) are the landlord\'s responsibility.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObligationItem extends StatelessWidget {
  final String text;
  const _ObligationItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('● ', style: TextStyle(color: AppColors.kodiGreen, fontSize: 12)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
      ],
    );
  }
}

class _PrivacyCard extends StatelessWidget {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 18),
          const Text('Right to Privacy', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18)),
          const SizedBox(height: 10),
          const Text(
            'The landlord or their agents cannot enter your home without prior notice, except in emergencies.',
            style: TextStyle(fontSize: 13, color: AppColors.secondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STANDARD NOTICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.secondary)),
              Text('24 Hours', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: 1.0,
              minHeight: 8,
              backgroundColor: AppColors.outlineVariant.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Entry must be during reasonable hours (typically 8 AM – 6 PM).',
            style: TextStyle(fontSize: 12, color: AppColors.secondary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _FairRentCard extends StatelessWidget {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 18),
          const Text('Fair Rent Practices', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18)),
          const SizedBox(height: 10),
          const Text(
            'The Bill mandates a 90-day written notice before any rent increase. Increases are subject to market valuation and tribunal limits.',
            style: TextStyle(fontSize: 13, color: AppColors.secondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          const _CheckItem(text: 'Receipts for every payment'),
          const SizedBox(height: 10),
          const _CheckItem(text: 'Security deposit protection'),
          const SizedBox(height: 10),
          const _CheckItem(text: '90-day notice for rent increases'),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.kodiGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
        ],
      ),
    );
  }
}

class _SecurityDepositCard extends StatelessWidget {
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.support_agent_rounded, color: AppColors.kodiGreen, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Security Deposit Protection', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18, height: 1.3)),
                    SizedBox(height: 6),
                    Text(
                      'Under the Bill, your right to recover a security deposit is attached to restoring the premises and settling utility bills.',
                      style: TextStyle(fontSize: 14, color: AppColors.secondary, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TO RECOVER YOUR DEPOSIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: AppColors.textDark)),
                SizedBox(height: 12),
                _ObligationItem(text: 'Restore the premises to its condition at the start of the tenancy.'),
                SizedBox(height: 8),
                _ObligationItem(text: 'Settle all outstanding utility bills.'),
                SizedBox(height: 8),
                _ObligationItem(text: 'Normal wear and tear is excluded from deductions.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => showSnack(context, 'Feature coming soon'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Speak to an Advisor', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showSnack(context, 'Complaint form coming soon'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.outline),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('File a Complaint', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistressProtectionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.tertiaryFixed, size: 28),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Protection Against Unlawful Distress', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 16)),
                SizedBox(height: 6),
                Text(
                  'The Bill requires landlords to obtain tribunal orders before levying distress for rent. This protects you from arbitrary seizure of your belongings. If a landlord levies distress without a tribunal order, it is unlawful.',
                  style: TextStyle(fontSize: 14, color: AppColors.secondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantDeathCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tenancy Upon Death or Dissolution', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 16)),
                SizedBox(height: 6),
                Text(
                  'If a tenant dies and there are no other tenants on the premises, the tenancy is deemed terminated 60 days after the death. The same applies if a tenant company is dissolved. This replaces the old provision where tenancy devolved to representatives.',
                  style: TextStyle(fontSize: 14, color: AppColors.secondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatefulWidget {
  const _FaqSection();

  @override
  State<_FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<_FaqSection> {
  int? _expandedIndex;

  final _faqs = const [
    _FaqItem(
      q: 'Can my landlord evict me immediately for late rent?',
      a: 'No. The Bill requires a legal process. A 30-day notice is typically required, followed by an application to the tribunal if the tenant does not vacate. Self-help evictions (like changing locks) remain illegal. The landlord must now obtain tribunal orders before any action.',
    ),
    _FaqItem(
      q: 'When should I get my security deposit back?',
      a: 'Under the Bill, your right to recover a security deposit is attached to restoring the premises to its condition at the start of the tenancy and settling all utility bills. Normal wear and tear is excluded from deductions.',
    ),
    _FaqItem(
      q: 'Is the landlord responsible for all repairs?',
      a: 'The landlord is responsible for structural and major repairs (roofs, exterior walls, plumbing systems). Tenants are generally responsible for minor internal maintenance and any damage caused by their negligence.',
    ),
    _FaqItem(
      q: 'Can my landlord levy distress for rent without going to court?',
      a: 'No. Under the Bill, a landlord must obtain orders from the tribunal before levying distress for rent. This reverses the old process where tenants had to approach the court for protection. The landlord now bears the burden of obtaining tribunal approval first.',
    ),
    _FaqItem(
      q: 'What happens to my tenancy if I pass away?',
      a: 'If a tenant dies and there are no other tenants on the premises, the tenancy is deemed terminated 60 days after the death. If you are a company tenant, the same applies upon dissolution. Previously, the tenancy would devolve to your representatives.',
    ),
    _FaqItem(
      q: 'How long does a tribunal have to resolve my dispute?',
      a: 'The Bill requires all disputes to be determined within 3 months. This is designed to eliminate the huge backlogs currently faced by tribunals. Tribunals also have new powers to enforce decrees and issue injunctive orders.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18)),
        const SizedBox(height: 16),
        ...List.generate(_faqs.length, (i) {
          final isExpanded = _expandedIndex == i;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_faqs[i].q, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 15)),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_more_rounded, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Text(_faqs[i].a, style: const TextStyle(fontSize: 14, color: AppColors.secondary, height: 1.5)),
                  ),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _FaqItem {
  final String q, a;
  const _FaqItem({required this.q, required this.a});
}
