import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class SupportScreen extends StatefulWidget {
  final Color accentColor;
  const SupportScreen({super.key, this.accentColor = AppColors.kodiBlue});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const String _supportEmail = 'support@kodipay.co.ke';
  static const String _supportPhone = '+254 700 123 456';
  static const String _supportWhatsAppDigits = '254700123456';

  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'Payments';

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launch(Uri uri, {String fallbackCopy = ''}) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {
      // fallthrough to clipboard
    }
    if (!mounted) return;
    if (fallbackCopy.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: fallbackCopy));
      if (!mounted) return;
      showSnack(context, 'Could not open app — copied "$fallbackCopy" instead.');
    } else {
      showSnack(context, 'Could not open the requested app.');
    }
  }

  Future<void> _openEmail({String? subject, String? body}) async {
    final query = <String, String>{};
    if (subject != null && subject.isNotEmpty) query['subject'] = subject;
    if (body != null && body.isNotEmpty) query['body'] = body;
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: query.isEmpty
          ? null
          : query.entries
              .map((e) =>
                  '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
              .join('&'),
    );
    await _launch(uri, fallbackCopy: _supportEmail);
  }

  Future<void> _openDialer() async {
    final uri = Uri(scheme: 'tel', path: _supportPhone.replaceAll(' ', ''));
    await _launch(uri, fallbackCopy: _supportPhone);
  }

  Future<void> _openWhatsApp({String? text}) async {
    const base = 'https://wa.me/$_supportWhatsAppDigits';
    final uri = (text == null || text.isEmpty)
        ? Uri.parse(base)
        : Uri.parse('$base?text=${Uri.encodeQueryComponent(text)}');
    await _launch(uri, fallbackCopy: '+$_supportWhatsAppDigits');
  }

  Future<void> _sendMessage() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      showSnack(context, 'Please add a subject and a message.');
      return;
    }
    await _openEmail(
      subject: '[$_category] $subject',
      body: 'Category: $_category\n\n$message',
    );
  }

  Future<void> _sendOnWhatsApp() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      showSnack(context, 'Please add a subject and a message.');
      return;
    }
    await _openWhatsApp(
      text: 'KodiPay support — $_category\n$subject\n\n$message',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Support',
      accentColor: widget.accentColor,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          widget.accentColor.withValues(alpha: 0.12),
                      child: Icon(Icons.support_agent_rounded,
                          color: widget.accentColor),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text("We're here to help", style: titleStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reach out about payments, reports, account access, or anything else. We typically respond within a few hours on business days.',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text('Contact KodiPay', style: smallBoldStyle),
          ),
          SettingsTile(
            icon: Icons.email_outlined,
            title: 'Email support',
            subtitle: _supportEmail,
            onTap: () => _openEmail(),
          ),
          SettingsTile(
            icon: Icons.call_outlined,
            title: 'Call us',
            subtitle: _supportPhone,
            onTap: _openDialer,
          ),
          SettingsTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'WhatsApp',
            subtitle: '+$_supportWhatsAppDigits',
            onTap: () => _openWhatsApp(),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text('Send us a message', style: smallBoldStyle),
          ),
          TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What do you need help with?',
                    style: AppStyles.caption),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'Payments',
                        child: Text('Payments (M-Pesa, invoices)')),
                    DropdownMenuItem(
                        value: 'Reports',
                        child: Text('Reports (PDF, CSV, charts)')),
                    DropdownMenuItem(
                        value: 'Account', child: Text('Account & security')),
                    DropdownMenuItem(
                        value: 'Other', child: Text('Something else')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Describe the issue',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accentColor,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _sendOnWhatsApp,
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('WhatsApp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF25D366),
                            side: const BorderSide(color: Color(0xFF25D366)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Opens your email app or WhatsApp with the message prefilled. If neither opens, the address is copied to your clipboard.',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text('Quick answers', style: smallBoldStyle),
          ),
          const TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpRow(
                  icon: Icons.payments_outlined,
                  title: 'Payment not showing up?',
                  body:
                      'Confirm the tenant used the correct M-Pesa till and reference. Most receipts post within 2–3 minutes.',
                ),
                SizedBox(height: 12),
                _HelpRow(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Report missing data?',
                  body:
                      'Make sure the date range covers the invoices, then re-download the PDF or CSV from Reports.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _HelpRow({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.kodiBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              const SizedBox(height: 3),
              Text(body, style: AppStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}
