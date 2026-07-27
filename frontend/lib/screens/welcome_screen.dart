import 'package:flutter/material.dart';
import '../utils/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _TopNavBar(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(),
            _RoleSelectionSection(),
            _TrustSection(),
            _FooterSection(),
          ],
        ),
      ),
    );
  }
}

// ── Top Nav Bar ─────────────────────────────────────────
class _TopNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        border: const Border(bottom: BorderSide(color: AppColors.outlineVariant)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            return Row(
              children: [
                const SizedBox(width: 24),
                // Logo
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: Text('K', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                    ),
                    const SizedBox(width: 8),
                    const Text('KodiPay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
                  ],
                ),
                const Spacer(),
                if (!isNarrow) ...[
                  // Nav links (desktop)
                  Row(
                    children: ['Features', 'Roles', 'Help'].map((label) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 8),
                ],
                // Login button
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                // Register button
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Register', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Hero Section ────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 600),
      decoration: const BoxDecoration(color: AppColors.surfaceLowest),
      child: Stack(
        children: [
          // Background blur blobs
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                color: AppColors.tertiaryFixedDim.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80, right: -80,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                color: AppColors.primaryFixedDim.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return isWide ? _heroWide(context) : _heroNarrow(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroWide(BuildContext ctx) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _heroTextContent(ctx)),
        const SizedBox(width: 32),
        Expanded(child: _heroImageCard()),
      ],
    );
  }

  Widget _heroNarrow(BuildContext ctx) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.only(top: 40), child: _heroTextContent(ctx)),
        const SizedBox(height: 32),
        SizedBox(height: 380, child: _heroImageCard()),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _heroTextContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.onTertiaryFixedVariant.withValues(alpha: 0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 16, color: AppColors.tertiaryFixed),
                SizedBox(width: 4),
                Text('LICENSED & REGULATED', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.tertiaryFixed)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Heading
          RichText(
            text: TextSpan(
              style: AppStyles.displayKsh.copyWith(fontSize: 48),
              children: const [
                TextSpan(text: 'Seamless Rent Management for '),
                TextSpan(text: 'Modern Living.', style: TextStyle(color: AppColors.onTertiaryFixedVariant)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Automate your property finances with Kenya\'s most trusted payment gateway. Pay rent, manage tenants, and track maintenance in one unified dashboard.',
            style: AppStyles.bodyLg,
          ),
          const SizedBox(height: 28),
          // CTA buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/pay-rent'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Pay Rent Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.outlineVariant, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Explore Features'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Trust stats
          Container(
            padding: const EdgeInsets.only(top: 20),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('24/7', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
                    Text('SECURE SUPPORT', style: AppStyles.labelCaps.copyWith(fontSize: 10, letterSpacing: 0.8)),
                  ],
                ),
                Container(width: 1, height: 36, color: AppColors.outlineVariant),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('99.9%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
                    Text('UPTIME RELIABILITY', style: AppStyles.labelCaps.copyWith(fontSize: 10, letterSpacing: 0.8)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroImageCard() {
    return Container(
      height: 520,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: const DecorationImage(
          image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuD_moHkLZJiVbncnIrQNIzYL8jeH3Km26h22J8X-vGx-fz26OOMMoT1z79b9PzrXqc3Yy0Pinkvs8Z46uSnxFg40ZQpQPB7OxM9aBDWS-bAwURxyfjpGwRhVedmx-7yfwGOGuYAKJ_AR9HimfbrF8qqJSY8WG1j1LffeWscvDa9iXw6GebvxVGjYIcvjpwpu1rchcO4gbQbx-AHwFjhWyDIvIx8P4UhfrsjB1xvSEgizyOvZuD3GNHX'),
          fit: BoxFit.cover,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          // Overlay
          Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), color: AppColors.primary.withValues(alpha: 0.05)))),
          // Floating card
          Positioned(
            bottom: 24, left: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.tertiaryFixedDim, shape: BoxShape.circle), child: const Icon(Icons.check_circle, size: 20, color: AppColors.onTertiaryFixed)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('RENT PAID', style: AppStyles.labelCaps.copyWith(fontSize: 9, color: AppColors.secondary)),
                      const Text('KES 45,000.00', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role Selection ─────────────────────────────────────
class _RoleSelectionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          const Text('Tailored for Every Stakeholder', style: AppStyles.headlineLg),
          const SizedBox(height: 12),
          Text('Choose your path in the KodiPay ecosystem. We provide specialized tools for each role in property management.', textAlign: TextAlign.center, style: AppStyles.bodyMd.copyWith(color: AppColors.secondary)),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _roleCard(
                      icon: Icons.person_outline,
                      title: 'Tenant',
                      description: 'Pay rent securely via M-Pesa or Card, track your payment history, and raise maintenance requests with a single tap.',
                      isHighlighted: false,
                      onGetStarted: () {},
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _roleCard(
                      icon: Icons.business_outlined,
                      title: 'Landlord',
                      description: 'Automate rent collection, generate tax-ready financial reports, and manage multi-unit properties from a central dashboard.',
                      isHighlighted: true,
                      onGetStarted: () => Navigator.pushNamed(context, '/register', arguments: 'landlord'),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _roleCard(
                      icon: Icons.assignment_outlined,
                      title: 'Caretaker',
                      description: 'Oversee day-to-day operations, verify tenant payments, and manage utility billing with ease and transparency.',
                      isHighlighted: false,
                      onGetStarted: () {},
                    )),
                  ],
                );
              }
              return Column(
                children: [
                  _roleCard(icon: Icons.person_outline, title: 'Tenant', description: 'Pay rent securely via M-Pesa or Card, track your payment history, and raise maintenance requests with a single tap.', isHighlighted: false, onGetStarted: () {}),
                  const SizedBox(height: 16),
                  _roleCard(icon: Icons.business_outlined, title: 'Landlord', description: 'Automate rent collection, generate tax-ready financial reports, and manage multi-unit properties from a central dashboard.', isHighlighted: true, onGetStarted: () => Navigator.pushNamed(context, '/register', arguments: 'landlord')),
                  const SizedBox(height: 16),
                  _roleCard(icon: Icons.assignment_outlined, title: 'Caretaker', description: 'Oversee day-to-day operations, verify tenant payments, and manage utility billing with ease and transparency.', isHighlighted: false, onGetStarted: () {}),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isHighlighted,
    required VoidCallback onGetStarted,
  }) {
    final bgColor = isHighlighted ? AppColors.primary : AppColors.surfaceLowest;
    final textColor = isHighlighted ? AppColors.onPrimary : AppColors.primary;
    final descColor = isHighlighted ? AppColors.onPrimaryContainer : AppColors.secondary;
    final btnColor = isHighlighted ? AppColors.tertiaryFixed : AppColors.secondaryContainer;
    final btnTextColor = isHighlighted ? AppColors.onTertiaryFixed : AppColors.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isHighlighted ? AppColors.primaryContainer : AppColors.outlineVariant),
        boxShadow: isHighlighted ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: isHighlighted ? AppColors.primaryContainer : AppColors.surfaceContainer, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, size: 24, color: isHighlighted ? AppColors.tertiaryFixed : AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: textColor)),
          const SizedBox(height: 12),
          Text(description, style: AppStyles.bodyMd.copyWith(color: descColor)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: btnTextColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('GET STARTED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trust Section ──────────────────────────────────────
class _TrustSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        border: Border(top: BorderSide(color: AppColors.primaryContainer)),
      ),
      child: Column(
        children: [
          // Avatars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _avatar('https://lh3.googleusercontent.com/aida-public/AB6AXuCa28b2mZrUX5BTu-SbdmeCSKUPGD1xI-UYIMA-_xPSps4e5dV-6T2cxCT2UTRJcmoAraZpK5c_c_jgnmVOS86AzOocfdFF4-IiXGlC6Mi7zTo3lpFZIVlMtFGY5wKxxb10UJsKrgmwYXIaccvgv7_R7iEBN2bXgL_w-n0ETmKjvy2v0P7UhIeo3F4u7tcxwucYbn_rdj70NpJLNDtlDTxhRlm8gF5x_EY__brXryejDYaty5Hn0qKp'),
              const SizedBox(width: 8),
              _avatar('https://lh3.googleusercontent.com/aida-public/AB6AXuBSZwYN7ZlIEc04yHnsSWtvzZ-ieCbDDNUnUiZoDfhaGRon6Ch8xY5y3eVnQUixzsG6zecF9yQTvajsJVDYNgTjzOi2Ya-HpEzg5Fy9IxHcnRFfca3wdjYsJKeYvWBm47vNCZ3Gt8_ghDd1aXhAYdaxTI1ofK8Ch3ef_f64Bw6BqeenBGNRZfb8OuPVZtgtgF5wXu4hqJxRv70CEAc4NlN_t9fD2dibQb2uIEVebENvA9wm2DJRZr6T'),
              const SizedBox(width: 8),
              _avatar('https://lh3.googleusercontent.com/aida-public/AB6AXuAZYUOpkZQI1a9gPxRnP1HOhkXzHTAIlJQvd4svuFb4NoS7cyE-9svOnvLYaFvxsSmk1xYXdrwp6wAWk09XAMjy3wY8t_4XvKAwy3iztB9rQJ-hBl3o9Vadlgit793G92f7S1ffCQoohr9Ihc_wqM9dH7KT_21EzpAh9rvUReUHPH8CTevjaCAXKda7dDiSan0-6lkboVKHuaq4ef8OiXtVlFx6E4FLMOtkEOrQidJlhoKtegDGwP9z'),
              const SizedBox(width: 12),
              const Text('SecureFast 24/7 Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Lexend', color: AppColors.tertiaryFixed)),
            ],
          ),
          const SizedBox(height: 32),
          Text('Trusted by 5,000+ Property Owners Across East Africa', textAlign: TextAlign.center, style: AppStyles.headlineLg.copyWith(color: Colors.white, fontSize: 28)),
          const SizedBox(height: 48),
          // Trust badges grid
          LayoutBuilder(
            builder: (context, constraints) {
              final badges = [
                _trustBadge(Icons.security_outlined, 'PCI DSS Level 1'),
                _trustBadge(Icons.payments_outlined, 'Instant Settlement'),
                _trustBadge(Icons.cloud_done_outlined, 'Bank-Grade Encryption'),
                _trustBadge(Icons.gavel_outlined, 'Licensed by CBK'),
              ];
              if (constraints.maxWidth > 600) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: badges.map((b) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: b))).toList(),
                );
              }
              return Wrap(
                spacing: 16, runSpacing: 16,
                children: badges.map((b) => SizedBox(width: 160, child: b)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _avatar(String url) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryContainer, width: 3),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.tertiaryFixedDim),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.onPrimaryContainer)),
        ],
      ),
    );
  }
}

// ── Footer ──────────────────────────────────────────────
class _FooterSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLow,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)), child: const Center(child: Text('K', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)))),
                          const SizedBox(width: 6),
                          const Text('KodiPay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('The most advanced property management and rent payment platform in the Silicon Savannah.', style: AppStyles.bodySm.copyWith(color: AppColors.secondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 24, runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                TextButton(onPressed: () {}, child: const Text('Terms of Service', style: AppStyles.bodySm)),
                TextButton(onPressed: () {}, child: const Text('Privacy Policy', style: AppStyles.bodySm)),
                TextButton(onPressed: () {}, child: const Text('Contact Support', style: AppStyles.bodySm)),
              ],
            ),
            const SizedBox(height: 16),
            Text('© 2024 KodiPay Kenya. All rights reserved.', style: AppStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face_outlined, size: 20, color: AppColors.onSurfaceVariant),
                SizedBox(width: 16),
                Icon(Icons.business_outlined, size: 20, color: AppColors.onSurfaceVariant),
                SizedBox(width: 16),
                Icon(Icons.rss_feed_outlined, size: 20, color: AppColors.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
