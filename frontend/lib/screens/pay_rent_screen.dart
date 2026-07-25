import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class PayRentScreen extends StatefulWidget {
  const PayRentScreen({super.key});

  @override
  State<PayRentScreen> createState() => _PayRentScreenState();
}

class _PayRentScreenState extends State<PayRentScreen> {
  final ApiService _api = ApiService();
  final _phoneCtrl = TextEditingController(text: '0712 345 678');
  Future<RentDue?>? _future;
  int _step = 1;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _error;
  String? _checkoutRequestId;

  void _reload() {
    _future = _fetchActiveTenancy();
    setState(() {});
  }

  Future<RentDue?> _fetchActiveTenancy() async {
    final response = await _api.get('/tenancies');
    if (response.statusCode != 200) throw Exception('Could not load tenancy (${response.statusCode})');
    final list = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    final active = list.firstWhere((t) => (t['status']?.toString() ?? 'active') == 'active', orElse: () => list.first);
    return RentDue.fromJson(active);
  }

  Future<void> _sendPrompt(RentDue due) async {
    setState(() { _sending = true; _error = null; });
    try {
      var phone = _phoneCtrl.text.replaceAll(RegExp(r'[\s\-]'), '');
      if (phone.length < 9) {
        setState(() { _sending = false; _error = 'Please enter a valid M-Pesa phone number.'; });
        return;
      }
      // Daraja requires international format: 254XXXXXXXXX
      if (phone.startsWith('0')) {
        phone = '254${phone.substring(1)}';
      }
      final body = {
        'tenancy_id': due.tenancyId,
        'amount': due.rentAmount,
        'payment_method': 'mpesa',
        'phone_number': phone,
      };
      final response = await _api.post('/payments', body);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final checkoutReqId = data['checkout_request_id']?.toString() ?? data['transaction_ref']?.toString();
        setState(() { _sending = false; _sent = true; _step = 3; _checkoutRequestId = checkoutReqId; });
      } else {
        final data = jsonDecode(response.body);
        final msg = data is Map ? (data['error'] ?? data['message'] ?? 'Payment failed') : 'Payment failed (${response.statusCode})';
        setState(() { _sending = false; _error = msg.toString(); });
      }
    } catch (e) {
      setState(() { _sending = false; _error = 'Network error: ${e.toString()}'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment', style: TextStyle(fontFamily: 'Lexend', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
        centerTitle: false,
        actions: [
          const Icon(Icons.notifications_outlined, color: AppColors.secondary),
          const SizedBox(width: 16),
          const Icon(Icons.help_outline, color: AppColors.secondary),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceHigh,
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<RentDue?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(30),
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Center(child: Text(snapshot.error.toString(), textAlign: TextAlign.center, style: AppStyles.bodyMedium)),
                  const SizedBox(height: 14),
                  Center(child: OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'))),
                ],
              );
            }
            final due = snapshot.data;
            if (due == null) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: Text('No active tenancy found on your account.', style: AppStyles.bodyMedium, textAlign: TextAlign.center)),
              );
            }
            return _PaymentContent(
              due: due,
              step: _step,
              sending: _sending,
              sent: _sent,
              error: _error,
              phoneCtrl: _phoneCtrl,
              onSendPrompt: (d) => _sendPrompt(d),
            );
          },
        ),
      ),
    );
  }
}

class _PaymentContent extends StatelessWidget {
  final RentDue due;
  final int step;
  final bool sending;
  final bool sent;
  final String? error;
  final TextEditingController phoneCtrl;
  final ValueChanged<RentDue> onSendPrompt;

  const _PaymentContent({required this.due, required this.step, required this.sending, required this.sent, this.error, required this.phoneCtrl, required this.onSendPrompt});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Stepper
          _buildStepper(),
          const SizedBox(height: 40),

          // Main content
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              return isNarrow
                  ? Column(
                      children: [
                        _buildMpesaCard(context),
                        const SizedBox(height: 16),
                        _buildSummaryCard(due),
                        const SizedBox(height: 16),
                        _buildSecurityCard(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _buildMpesaCard(context)),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: Column(
                          children: [
                            _buildSummaryCard(due),
                            const SizedBox(height: 16),
                            _buildSecurityCard(),
                          ],
                        )),
                      ],
                    );
            },
          ),

          const SizedBox(height: 48),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineVariant))),
            child: Column(
              children: [
                Text('© 2023 Silicon Savannah Fintech. Regulated by the Central Bank of Kenya.', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Privacy Policy', style: TextStyle(fontSize: 11, color: AppColors.secondary, decoration: TextDecoration.underline)),
                    const SizedBox(width: 16),
                    Text('Terms of Service', style: TextStyle(fontSize: 11, color: AppColors.secondary, decoration: TextDecoration.underline)),
                    const SizedBox(width: 16),
                    Text('Secure Hosting by AWS Africa', style: TextStyle(fontSize: 11, color: AppColors.secondary, decoration: TextDecoration.underline)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepperItem(number: '1', label: 'SELECT METHOD', completed: true),
          _StepperLine(completed: true),
          _StepperItem(number: '2', label: 'PAYMENT DETAILS', active: step == 2),
          _StepperLine(completed: false),
          _StepperItem(number: '3', label: 'CONFIRMATION', active: step == 3),
        ],
      ),
    );
  }

  Widget _buildMpesaCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          // M-Pesa header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.phone_android, color: Color(0xFF4CAF50), size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('M-Pesa Payment', style: TextStyle(color: Colors.white, fontFamily: 'Lexend', fontSize: 20, fontWeight: FontWeight.w500)),
                      SizedBox(height: 2),
                      Text('Secure STK Push Technology', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('VERIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.tertiaryFixedDim, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          // Phone input + button
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your registered M-Pesa phone number below. We will send a secure STK Push prompt directly to your handset to authorize the transaction.',
                  style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant, height: 1.6),
                ),
                const SizedBox(height: 24),
                const Text('M-PESA PHONE NUMBER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.primary)),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 18, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Icon(Icons.smartphone, color: AppColors.secondary),
                    ),
                    hintText: '07xx xxx xxx',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                if (!sent) ...[
                  if (error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(child: Text(error!, style: const TextStyle(fontSize: 14, color: AppColors.danger))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: sending ? null : () => onSendPrompt(due),
                      icon: sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, size: 20),
                      label: Text(sending ? 'Processing...' : 'Send Payment Prompt', style: const TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w600, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ensure your phone is unlocked and you have sufficient funds to complete the KSh ${formatKsh(due.rentAmount)} transaction.',
                            style: TextStyle(fontSize: 14, color: AppColors.secondary, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Having trouble? Click here for manual Paybill instructions.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.kodiGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.kodiGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, size: 48, color: AppColors.kodiGreen),
                        const SizedBox(height: 12),
                        const Text('Prompt Sent', style: TextStyle(fontFamily: 'Lexend', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        const SizedBox(height: 8),
                        Text('Check your phone to enter M-Pesa PIN.', style: TextStyle(fontSize: 14, color: AppColors.secondary)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(RentDue due) {
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
          const Text('Payment Summary', style: TextStyle(fontFamily: 'Lexend', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 20),
          _SummaryRow(label: 'Rent (October 2023)', value: 'KSh ${formatKsh(due.rentAmount)}.00'),
          const SizedBox(height: 12),
          const _SummaryRow(label: 'Service Charge', value: 'KSh 3,000.00'),
          const SizedBox(height: 12),
          const _SummaryRow(label: 'Utility Balance', value: 'KSh 0.00'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineVariant))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total to Pay', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
                Text('KSh ${formatKsh(due.rentAmount)}', style: const TextStyle(fontFamily: 'Lexend', fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: AppColors.tertiaryFixedDim, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('LIVE SECURITY MONITORING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your payment is encrypted and processed directly by Safaricom. KodiPay never stores your M-Pesa PIN.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Stepper Components ───────────────────────────────────
class _StepperItem extends StatelessWidget {
  final String number;
  final String label;
  final bool completed;
  final bool active;
  const _StepperItem({required this.number, required this.label, this.completed = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    final isDone = completed;
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppColors.tertiaryFixedDim
                : active
                    ? AppColors.primary
                    : AppColors.surfaceHigh,
            border: active ? Border.all(color: Colors.white, width: 4) : null,
            boxShadow: active ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)] : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                : Text(number, style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.secondary,
                  )),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w800 : FontWeight.w700,
          color: active ? AppColors.primary : AppColors.secondary,
          letterSpacing: 0.5,
        )),
      ],
    );
  }
}

class _StepperLine extends StatelessWidget {
  final bool completed;
  const _StepperLine({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: completed ? AppColors.tertiaryFixedDim : AppColors.outlineVariant,
      ),
    );
  }
}

// ── Summary Row ──────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.secondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary)),
      ],
    );
  }
}

// ── Model ────────────────────────────────────────────────
class RentDue {
  final int tenancyId;
  final String propertyName;
  final String unitNumber;
  final num rentAmount;
  final DateTime dueDate;

  const RentDue({required this.tenancyId, required this.propertyName, required this.unitNumber, required this.rentAmount, required this.dueDate});

  factory RentDue.fromJson(Map<String, dynamic> json) {
    final start = DateTime.tryParse(json['start_date']?.toString() ?? '');
    final now = DateTime.now();
    final day = (start?.day ?? 25).clamp(1, 28);
    return RentDue(
      tenancyId: toInt(json['id']),
      propertyName: (json['property_name'] ?? '').toString(),
      unitNumber: (json['unit_number'] ?? '').toString(),
      rentAmount: toNum(json['rent_amount']),
      dueDate: DateTime(now.year, now.month, day),
    );
  }
}
