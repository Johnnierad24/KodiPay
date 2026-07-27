import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import 'raise_maintenance_details_screen.dart';
import 'tenant_maintenance_screen.dart';

class TenantSupportScreen extends StatelessWidget {
  const TenantSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Support Center', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 18)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Top row: Maintenance + Caretaker (stack on mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [
                    _MaintenanceCard(),
                    const SizedBox(height: 16),
                    _CaretakerCard(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: _MaintenanceCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _CaretakerCard()),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Bottom row: Tickets + FAQ (stack on mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [
                    _OpenTicketsCard(),
                    const SizedBox(height: 16),
                    _FaqCard(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _OpenTicketsCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 7, child: _FaqCard()),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Bottom banner
          _BannerSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Need a repair?', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 20)),
              const SizedBox(height: 8),
              const Text(
                'Report any plumbing, electrical, or structural issues. We usually respond within 4 business hours.',
                style: TextStyle(fontSize: 14, color: AppColors.secondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RaiseMaintenanceDetailsScreen())),
                icon: const Icon(Icons.build_rounded, size: 20),
                label: const Text('Raise Maintenance Issue', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(Icons.engineering_rounded, size: 120, color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }
}

class _CaretakerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.support_agent_rounded, color: AppColors.tertiaryFixed, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.kodiGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.kodiGreen.withValues(alpha: 0.3)),
                ),
                child: const Text('Available', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.tertiaryFixed)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Caretaker', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18)),
          const SizedBox(height: 4),
          Text('Samuel Okumu – Block C', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:+254712345678'), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.call_rounded, size: 18),
              label: const Text('Quick Call', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiaryFixed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenTicketsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Open Tickets', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TenantMaintenanceScreen())),
                child: const Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Ticket 1
          const _TicketItem(
            id: '#TK-8821',
            status: 'In Progress',
            statusColor: AppColors.kodiOrange,
            title: 'Leaking Kitchen Tap',
            date: 'Oct 12, 2023',
            badge: '2 New',
            badgeIcon: Icons.chat_bubble_rounded,
          ),
          const SizedBox(height: 10),
          // Ticket 2
          const _TicketItem(
            id: '#TK-8790',
            status: 'Scheduled',
            statusColor: AppColors.info,
            title: 'HVAC Filter Replacement',
            date: 'Oct 10, 2023',
            badge: 'Oct 15',
            badgeIcon: Icons.event_available_rounded,
          ),
        ],
      ),
    );
  }
}

class _TicketItem extends StatelessWidget {
  final String id, status, title, date, badge;
  final Color statusColor;
  final IconData badgeIcon;
  const _TicketItem({required this.id, required this.status, required this.title, required this.date, required this.badge, required this.statusColor, required this.badgeIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: const TextStyle(fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500, color: AppColors.secondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 14)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
              const SizedBox(width: 12),
              Icon(badgeIcon, size: 13, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(badge, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  int? _expandedIndex;

  final _faqs = const [
    _FaqItem(
      q: 'How do I update my monthly rent payment method?',
      a: 'You can update your payment method by going to the Payments tab in your sidebar. Click on Manage Cards or Bank Accounts to add a new method. Changes take 24 hours to verify for automated billing.',
    ),
    _FaqItem(
      q: 'Who is responsible for utility bill payments?',
      a: 'Standard utility coverage depends on your specific lease agreement. Generally, electricity and water are metered per tenant. You can view your current meter readings and billed amounts in the Payments section under Utilities.',
    ),
    _FaqItem(
      q: 'What qualifies as an emergency repair?',
      a: 'Emergency repairs include total loss of power, burst water pipes, gas leaks, or security breaches (broken locks). For these, please use the Quick Call button to contact the caretaker immediately rather than filing a standard ticket.',
    ),
    _FaqItem(
      q: 'How do I request a lease extension?',
      a: 'Lease extension requests should be made through the Profile section under Lease Documents. We recommend requesting extensions at least 60 days prior to your current lease expiration.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18)),
          const SizedBox(height: 16),
          ...List.generate(_faqs.length, (i) {
            final isExpanded = _expandedIndex == i;
            final isLast = i == _faqs.length - 1;
            return Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_faqs[i].q, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_more_rounded, color: AppColors.secondary, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(_faqs[i].a, style: const TextStyle(fontSize: 13, color: AppColors.secondary, height: 1.5)),
                  ),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                if (!isLast) const Divider(height: 1, color: AppColors.outlineVariant),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String q, a;
  const _FaqItem({required this.q, required this.a});
}

class _BannerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Silicon Savannah Living', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 20)),
                const SizedBox(height: 6),
                Text(
                  'Experience the future of property management with automated payments and instant support.',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiaryFixed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Learn More', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
