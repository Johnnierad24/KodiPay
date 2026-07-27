import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class LandlordTenantActScreen extends StatefulWidget {
  const LandlordTenantActScreen({super.key});

  @override
  State<LandlordTenantActScreen> createState() => _LandlordTenantActScreenState();
}

class _LandlordTenantActScreenState extends State<LandlordTenantActScreen> {
  final _chatController = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isBot: true,
      text: 'Hello! I can help you understand the Landlord and Tenant Bill, 2021. This Bill repeals Cap 301, Cap 296, and Cap 293. Ask me anything about rent, notices, deposits, or tribunal powers.',
    ),
    const _ChatMessage(
      isBot: false,
      text: 'How many days notice do I need for a rent increase?',
    ),
    const _ChatMessage(
      isBot: true,
      text: 'Under the Bill, your landlord must provide at least a 90-day written notice before increasing the rent. The Bill also requires all disputes to be determined within 3 months by the tribunal.',
    ),
  ];

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(isBot: false, text: text));
    });
    _chatController.clear();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final lower = text.toLowerCase();
      String reply;
      if (lower.contains('distress') || lower.contains('levy')) {
        reply = 'Under the Bill, a landlord must obtain orders from the tribunal before levying distress for rent. This reverses the current process where tenants had to seek court protection.';
      } else if (lower.contains('deposit') || lower.contains('refund')) {
        reply = 'The Bill states that a tenant\'s right to recover a security deposit is attached to restoring the premises to its condition at the start of the tenancy and settling all utility bills.';
      } else if (lower.contains('death') || lower.contains('die')) {
        reply = 'If a tenant dies and there are no other tenants on the premises, the tenancy is deemed terminated 60 days after the death. The same applies if a tenant company is dissolved.';
      } else if (lower.contains('government') || lower.contains('local authority')) {
        reply = 'The Bill removes the previous exclusion of government and local authority tenancies. A lease involving the government could now give rise to a controlled tenancy.';
      } else if (lower.contains('penalty') || lower.contains('fine')) {
        reply = 'The Bill significantly increases penalties: failure to comply with a tribunal order carries a fine of KSh 100,000 and/or 12 months imprisonment. Depriving a tenant of service: KSh 10,000 fine and/or 6 months.';
      } else if (lower.contains('tribunal') || lower.contains('dispute')) {
        reply = 'Tribunals now have powers to enforce decrees, issue injunctive orders, and punish for contempt — the same as any court. All disputes must be resolved within 3 months.';
      } else {
        reply = 'The Landlord and Tenant Bill, 2021 consolidates Kenyan property law. It offers equal protection to both landlords and tenants, increases penalties for violations, and streamlines tribunal processes. What specific aspect would you like to know about?';
      }
      setState(() {
        _messages.add(_ChatMessage(isBot: true, text: reply));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Corner', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HeroSection(),
          const SizedBox(height: 24),
          _BentoGrid(),
          const SizedBox(height: 24),
          _LowerSection(
            chatController: _chatController,
            messages: _messages,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.tertiaryFixed.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          const Positioned(
            right: 20,
            bottom: 20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.gavel_rounded, size: 120, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'KENYAN LAW (BILL 2021)',
                  style: TextStyle(
                    color: AppColors.onTertiaryFixed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Landlord and Tenant Bill, 2021',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 560,
                child: Text(
                  'The Bill introduces a consolidated legal framework to govern landlord-tenant relationships in Kenya. It repeals the Landlord and Tenant Act (Cap 301), the Rent Restriction Act (Cap 296), and the Distress for Rent Act (Cap 293), offering equal protection to both landlords and tenants.',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.onPrimaryContainer,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RepealChip(label: 'Repeals Cap 301 (LTA)'),
                  _RepealChip(label: 'Repeals Cap 296 (RRA)'),
                  _RepealChip(label: 'Repeals Cap 293 (DRA)'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepealChip extends StatelessWidget {
  final String label;
  const _RepealChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _BentoGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _GlassCard(
            icon: Icons.balance_rounded,
            title: 'Equality & Increased Penalties',
            description:
                'The Bill offers protection to both landlords and tenants — a shift from the old pro-tenant LTA and RRA. Penalties are significantly increased: failure to comply with a tribunal order carries a fine of KSh 100,000 and/or 12 months imprisonment.',
            linkLabel: 'PENALTIES',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _GlassCard(
            icon: Icons.gavel_rounded,
            title: 'Tribunal Powers & Timelines',
            description:
                'Tribunals can now enforce decrees, issue injunctive orders, and punish for contempt — the same as any court of law. All disputes must be resolved within 3 months to eliminate backlogs.',
            linkLabel: 'TRIBUNAL PROCESS',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _GlassCard(
            icon: Icons.security_rounded,
            title: 'Distress for Rent Reform',
            description:
                'Landlords must now obtain tribunal orders before levying distress for rent, reversing the old process. Government and local authority tenancies are no longer excluded from controlled tenancy protections.',
            linkLabel: 'DISTRESS LAWS',
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String linkLabel;
  final VoidCallback onTap;

  const _GlassCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.linkLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 24),
          Text(title, style: AppStyles.headlineMd),
          const SizedBox(height: 8),
          Text(description, style: AppStyles.bodyMd.copyWith(color: AppColors.secondary)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Text(linkLabel, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowerSection extends StatelessWidget {
  final TextEditingController chatController;
  final List<_ChatMessage> messages;
  final VoidCallback onSend;

  const _LowerSection({
    required this.chatController,
    required this.messages,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _ChatbotWidget(
            controller: chatController,
            messages: messages,
            onSend: onSend,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _ResourcesAndDisclaimer(),
        ),
      ],
    );
  }
}

class _ChatMessage {
  final bool isBot;
  final String text;
  const _ChatMessage({required this.isBot, required this.text});
}

class _ChatbotWidget extends StatelessWidget {
  final TextEditingController controller;
  final List<_ChatMessage> messages;
  final VoidCallback onSend;

  const _ChatbotWidget({
    required this.controller,
    required this.messages,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.tertiaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KodiPay Legal Assistant',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        'Automated Legal Guidance',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 250),
            padding: const EdgeInsets.all(24),
            color: const Color(0xFFF8FAFC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: messages.map((msg) {
                if (msg.isBot) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.gavel_rounded, color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.outlineVariant),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
                              ],
                            ),
                            child: Text(msg.text, style: const TextStyle(fontSize: 14, height: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
                              ],
                            ),
                            child: Text(
                              msg.text,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Ask a legal question...',
                      hintStyle: const TextStyle(color: AppColors.outline, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSend,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcesAndDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Official Resources', style: AppStyles.headlineMd),
              const SizedBox(height: 16),
              _ResourceItem(
                icon: Icons.open_in_new_rounded,
                title: 'Kenya Law (Cap 301)',
                subtitle: 'Download the original Act from Kenya Law Reports.',
                onTap: () => launchUrl(Uri.parse('http://kenyalaw.org/kl/index.php?id=398'), mode: LaunchMode.externalApplication),
              ),
              const SizedBox(height: 16),
              _ResourceItem(
                icon: Icons.description_rounded,
                title: 'Landlord & Tenant Bill, 2021',
                subtitle: 'Read the proposed Bill consolidating Kenyan property law.',
                onTap: () => launchUrl(Uri.parse('http://kenyalaw.org/kl/index.php?id=41049'), mode: LaunchMode.externalApplication),
              ),
              const SizedBox(height: 16),
              _ResourceItem(
                icon: Icons.account_balance_rounded,
                title: 'Rent Restriction Tribunal',
                subtitle: 'Locate your nearest tribunal and filing fees.',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _ResourceItem(
                icon: Icons.mail_rounded,
                title: 'Contact Legal Aid',
                subtitle: 'Free legal advice for qualifying tenants.',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.errorContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.onErrorContainer, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'DISCLAIMER',
                    style: TextStyle(
                      color: AppColors.onErrorContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'The information provided on this platform is for general informational purposes only and does not constitute legal advice. For specific cases, please consult a certified advocate of the High Court of Kenya.',
                style: TextStyle(color: AppColors.secondary, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResourceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
