import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class RightsScreen extends StatelessWidget {
  final String role;
  const RightsScreen({super.key, required this.role});

  bool get _isLandlord => role.toLowerCase() == 'landlord';
  Color get _accent =>
      _isLandlord ? AppColors.kodiGreen : AppColors.kodiBlue;

  static const List<_RightsTopic> _topics = [
    _RightsTopic(
      icon: Icons.payments_outlined,
      title: 'Rent & rent increases',
      landlord: [
        'You set rent by agreement. If a tenant disputes it, the Tribunal can set a fair rent based on comparable lettings.',
        'You can raise rent only after at least 12 months since the previous increase (residential), and only after giving 90 days\' written notice.',
        'Permitted reasons include capital improvements, a new or extra service you provide, or inflation tracked to the Consumer Price Index.',
        'A rent increase that has not been notified in writing is void.',
      ],
      tenant: [
        'Rent is fixed by the agreement you signed. If you think it\'s unfair, you can ask the Tribunal to assess it.',
        'A rent increase needs 90 days\' written notice and cannot happen more than once every 12 months (residential).',
        'If your landlord stops providing a service that was part of the rent (e.g. water, security), you can ask for a proportional rent reduction.',
        'Any increase without proper written notice is not enforceable.',
      ],
      source: 'Rent Restriction Act ss.9–13 · Landlord & Tenant Bill 2021 ss.17–22',
    ),
    _RightsTopic(
      icon: Icons.exit_to_app_rounded,
      title: 'Eviction & notice to quit',
      landlord: [
        'You can only end a tenancy on specific grounds (e.g. unpaid rent, breach, you reasonably need the unit, repairs/demolition, or a fixed term ending).',
        'Notice must be in writing, state the reason, and give at least 2 months for residential premises (3 months for business).',
        'For "I need the unit for myself or family", you must act in good faith and give a minimum of 60 days.',
        'You may never lock out, harass, or evict a tenant without a Tribunal order — that is a criminal offence.',
      ],
      tenant: [
        'You can only be evicted on legal grounds (mostly unpaid rent, breach, or the landlord legitimately needing the premises).',
        'Eviction always requires a written termination notice of at least 2 months (residential) and, if you don\'t leave, a Tribunal order.',
        'A landlord who locks you out, removes your belongings, cuts services, or harasses you to leave commits an offence.',
        'You can give your landlord at least 1 month\'s written notice to end your own tenancy.',
      ],
      source: 'Rent Restriction Act ss.14–15 · Landlord & Tenant Bill 2021 ss.19, 24–29, 47',
    ),
    _RightsTopic(
      icon: Icons.handyman_outlined,
      title: 'Repairs & habitability',
      landlord: [
        'You are responsible for keeping the premises structurally sound, weather-proof, and fit for human habitation.',
        'You must repair roofs, main walls, drainage, main electrical wiring, and the common parts of the building.',
        'If you don\'t do a repair you are liable for, the Tribunal can order it done at your cost — including authorising the tenant to do it and deduct from rent.',
      ],
      tenant: [
        'Your landlord must keep the building structurally sound and fit to live in — including roof, walls, main wiring, plumbing, and common areas.',
        'You are responsible for normal internal upkeep — fair wear and tear is not your fault.',
        'If your landlord ignores a repair they owe you, you can apply to the Tribunal; the Tribunal can authorise you to do it and deduct the cost from your rent.',
      ],
      source: 'Rent Restriction Act s.26 · Landlord & Tenant Bill 2021 s.45 & Schedule',
    ),
    _RightsTopic(
      icon: Icons.money_off_outlined,
      title: 'Deposits, key money & receipts',
      landlord: [
        'You may not demand a "premium", "key money", or any extra payment as a condition of letting — only rent and lawful deposits.',
        'Charging key money is an offence punishable by up to 12 months\' imprisonment.',
        'If you intend to deduct from a security deposit (for damages or unpaid rent), you must give the tenant receipts for the expenses.',
        'You must keep a rent record and provide the tenant with a copy.',
      ],
      tenant: [
        'It is illegal for a landlord to ask for "key money", a premium, or any payment in addition to rent and a normal deposit.',
        'If you paid one already, you can recover it from your landlord through the Tribunal within 2 years.',
        'When your landlord deducts from your deposit, they must show you receipts for what they\'re charging you for.',
        'You\'re entitled to a rent record/rent book showing each payment.',
      ],
      source: 'Rent Restriction Act ss.17, 19, 21 · Landlord & Tenant Bill 2021 ss.40, 45',
    ),
    _RightsTopic(
      icon: Icons.swap_horiz_rounded,
      title: 'Subletting & assignment',
      landlord: [
        'A tenant cannot sublet or assign the tenancy without your written consent — but you cannot unreasonably refuse.',
        'If you refuse unreasonably and the tenant goes to the Tribunal, the Tribunal can grant the assignment over your refusal.',
        'If you discover an unauthorised sublet, it is a ground to terminate the tenancy.',
      ],
      tenant: [
        'You need the landlord\'s written consent before subletting or assigning your tenancy — but the landlord cannot refuse unreasonably.',
        'If consent is unreasonably refused, you can apply to the Tribunal to allow the sublet or assignment.',
        'Subletting without consent is a ground for the landlord to terminate your tenancy.',
      ],
      source: 'Rent Restriction Act ss.27–28 · Landlord & Tenant Bill 2021 ss.30–32',
    ),
    _RightsTopic(
      icon: Icons.power_settings_new_rounded,
      title: 'Services & lockouts',
      landlord: [
        'You cannot cut off water, light, sanitation, or any other service to force a tenant to leave or pay — even if they are in arrears.',
        'Doing so is an offence with a fine of up to KSh 10,000 or up to 6 months\' imprisonment.',
        'Distress (seizing property) for unpaid rent requires legal process — you cannot do it on your own.',
      ],
      tenant: [
        'Your landlord cannot disconnect your water, electricity, drainage, or any service to pressure you to leave or pay rent.',
        'If they do, that\'s an offence. You can report it and the Tribunal can order the service restored.',
        'A landlord cannot seize your property for unpaid rent without going through legal process.',
      ],
      source: 'Rent Restriction Act ss.16, 23, 29 · Landlord & Tenant Bill 2021 ss.42, 48, 57',
    ),
    _RightsTopic(
      icon: Icons.balance_outlined,
      title: 'Disputes & where to go',
      landlord: [
        'Rent, eviction, repair, deposit, and service disputes are handled by the Landlord and Tenant Tribunal (which replaces the older Rent Tribunal).',
        'You must obey Tribunal orders. Ignoring one is an offence.',
        'You can appeal a Tribunal decision to the Environment and Land Court only on points of law.',
      ],
      tenant: [
        'You can take any rent, eviction, repair, deposit, or service complaint to the Landlord and Tenant Tribunal.',
        'Filing fees are small. The Tribunal aims to decide within 3 months.',
        'If you disagree with the Tribunal\'s decision on a point of law, you can appeal to the Environment and Land Court.',
      ],
      source: 'Rent Restriction Act ss.4–8 · Landlord & Tenant Bill 2021 ss.4–7',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Your Rights',
      accentColor: _accent,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel_outlined, color: _accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isLandlord
                            ? 'What landlords need to know'
                            : 'What tenants need to know',
                        style: titleStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Plain-English summary of the Rent Restriction Act (Cap. 296) and the Landlord and Tenant Bill 2021. This is for orientation only — it is not legal advice.',
                  style: AppStyles.caption,
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://www.kenyalaw.org'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          color: AppColors.kodiBlue, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Read the official text on kenyalaw.org',
                        style: TextStyle(
                          color: AppColors.kodiBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final topic in _topics) ...[
            _RightsTopicCard(
              topic: topic,
              accent: _accent,
              isLandlord: _isLandlord,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 6),
          Text(
            'This summary may not reflect the latest amendments. When in doubt, refer to the published Act on kenyalaw.org or consult a lawyer.',
            style: AppStyles.caption.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _RightsTopic {
  final IconData icon;
  final String title;
  final List<String> landlord;
  final List<String> tenant;
  final String source;
  const _RightsTopic({
    required this.icon,
    required this.title,
    required this.landlord,
    required this.tenant,
    required this.source,
  });
}

class _RightsTopicCard extends StatelessWidget {
  final _RightsTopic topic;
  final Color accent;
  final bool isLandlord;
  const _RightsTopicCard({
    required this.topic,
    required this.accent,
    required this.isLandlord,
  });

  @override
  Widget build(BuildContext context) {
    final bullets = isLandlord ? topic.landlord : topic.tenant;
    return TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(topic.icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(topic.title, style: titleStyle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            topic.source,
            style: AppStyles.caption.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

