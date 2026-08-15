import 'package:flutter/material.dart';
import '../utils/constants.dart';

class InfoScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> sections;

  const InfoScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.sections,
  });

  factory InfoScreen.features() => InfoScreen(
        title: 'Features',
        icon: Icons.stars_outlined,
        sections: [
          _h('Rent Payments'),
          _p('Pay rent securely via M-Pesa STK push or card, with instant digital receipts. '
              'Tenants can pay at any time and landlords receive funds directly.'),
          _h('Property & Tenant Management'),
          _p('Manage multi-unit properties, tenants, leases, and rent schedules from one '
              'central dashboard. Track occupancy and unit status in real time.'),
          _h('Maintenance Requests'),
          _p('Raise maintenance issues in a single tap and track them through to resolution. '
              'Landlords and caretakers get notified the moment a request is logged.'),
          _h('Financial Reports'),
          _p('Generate tax-ready financial reports with income statements, payment histories, '
              'and outstanding balances for every property.'),
          _h('Utility Billing'),
          _p('Create and track utility bills (water, electricity, garbage) alongside rent, '
              'with a clear breakdown of what is due.'),
          _h('Analytics & Insights'),
          _p('Visualise collection rates, income trends, and vacancy across your portfolio '
              'with live charts built into every dashboard.'),
        ],
      );

  factory InfoScreen.roles() => InfoScreen(
        title: 'Roles',
        icon: Icons.groups_outlined,
        sections: [
          _h('Tenant'),
          _p('Pay rent via M-Pesa or card, view payment history and receipts, and raise '
              'maintenance requests — all from your phone.'),
          _h('Landlord'),
          _p('Automate rent collection, manage multi-unit properties, generate tax-ready '
              'financial reports, and oversee maintenance from a central dashboard.'),
          _h('Caretaker'),
          _p('Oversee day-to-day operations, verify tenant payments, manage utility billing, '
              'and keep records accurate with full transparency.'),
        ],
      );

  factory InfoScreen.help() => InfoScreen(
        title: 'Help',
        icon: Icons.help_outline,
        sections: [
          _h('How to Pay Rent'),
          _p('1. Tap \u201CPay Rent Now\u201D on the welcome page.\n'
              '2. Enter your phone number and the rent amount.\n'
              '3. Confirm the M-Pesa STK prompt on your phone.\n'
              '4. You will receive an instant digital receipt once the payment is confirmed.'),
          _h('How to Register'),
          _p('1. Tap \u201CRegister\u201D and choose your role (Tenant, Landlord, or Caretaker).\n'
              '2. Complete your profile details.\n'
              '3. Verify your email and sign in to your dashboard.'),
          _h('Still Stuck?'),
          _p('Reach our 24/7 support team through the \u201CContact Support\u201D link in the '
              'footer, and we will help you resolve any issue.'),
        ],
      );

  factory InfoScreen.terms() => InfoScreen(
        title: 'Terms of Service',
        icon: Icons.description_outlined,
        sections: [
          _h('1. Acceptance of Terms'),
          _p('By accessing or using KodiPay, you agree to be bound by these Terms of Service. '
              'If you do not agree, please do not use the platform.'),
          _h('2. Services'),
          _p('KodiPay provides a property management and rent payment platform. We connect '
              'tenants, landlords, and caretakers, and facilitate payments through licensed '
              'payment gateways such as M-Pesa.'),
          _h('3. Accounts & Security'),
          _p('You are responsible for safeguarding your login credentials and for all activity '
              'that occurs under your account. Notify support immediately of any unauthorised use.'),
          _h('4. Payments'),
          _p('Payments are processed by our licensed payment partners. While we strive for '
              'reliable service, payment confirmation depends on the availability of those '
              'payment systems.'),
          _h('5. Limitation of Liability'),
          _p('To the fullest extent permitted by law, KodiPay shall not be liable for any '
              'indirect, incidental, or consequential damages arising from use of the platform.'),
          _h('6. Changes'),
          _p('We may update these terms from time to time. Continued use of the platform after '
              'changes are posted constitutes acceptance of the updated terms.'),
        ],
      );

  factory InfoScreen.privacy() => InfoScreen(
        title: 'Privacy Policy',
        icon: Icons.privacy_tip_outlined,
        sections: [
          _h('1. Information We Collect'),
          _p('We collect information you provide directly, such as your name, email, phone '
              'number, and property details, as well as transaction and usage data.'),
          _h('2. How We Use Information'),
          _p('Your information is used to operate the platform, process payments, provide '
              'support, send important notices, and improve our services.'),
          _h('3. Data Security'),
          _p('We use bank-grade encryption and industry-standard safeguards to protect your '
              'data. Payment credentials are handled by our licensed payment partners.'),
          _h('4. Sharing'),
          _p('We do not sell your personal information. Data is shared only with service '
              'providers necessary to run the platform, such as payment processors and cloud '
              'hosting, under strict confidentiality.'),
          _h('5. Your Rights'),
          _p('You may request access to, correction of, or deletion of your personal data at '
              'any time by contacting our support team.'),
          _h('6. Contact'),
          _p('For any privacy questions, reach out via the Contact Support link in the footer.'),
        ],
      );

  factory InfoScreen.contact() => InfoScreen(
        title: 'Contact Support',
        icon: Icons.support_agent_outlined,
        sections: [
          _h('We Are Here 24/7'),
          _p('Our support team is available around the clock to help with payments, accounts, '
              'and technical issues.'),
          _h('Email'),
          _p('support@kodipay.co.ke\nWe typically respond within a few hours.'),
          _h('Phone'),
          _p('+254 700 000 000\nCall or WhatsApp for urgent issues.'),
          _h('Business Hours'),
          _p('24 hours a day, 7 days a week — including public holidays.'),
        ],
      );

  static Widget _h(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text, style: AppStyles.headlineMd),
      );

  static Widget _p(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppStyles.bodyMd.copyWith(height: 1.6, color: AppColors.secondary)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLowest,
        foregroundColor: AppColors.primary,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(title, style: AppStyles.headlineMd),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections,
            ),
          ),
        ),
      ),
    );
  }
}
