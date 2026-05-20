import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';

class PayRentScreen extends StatefulWidget {
  const PayRentScreen({super.key});

  @override
  State<PayRentScreen> createState() => _PayRentScreenState();
}

class _PayRentScreenState extends State<PayRentScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _phoneController = TextEditingController();
  String _paymentMethod = 'M-Pesa';
  bool _isSubmitting = false;
  Future<_RentDue?>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _fetchActiveTenancy();
    });
  }

  Future<_RentDue?> _fetchActiveTenancy() async {
    final response = await _api.get('/tenancies');
    if (response.statusCode != 200) {
      throw Exception('Could not load tenancy (${response.statusCode})');
    }
    final list = (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    final active = list.firstWhere(
      (t) => (t['status']?.toString() ?? 'active') == 'active',
      orElse: () => list.first,
    );
    return _RentDue.fromJson(active);
  }

  String _moneyKsh(num value) {
    final whole = value.toInt();
    return 'KSh ${whole.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        )}';
  }

  String _formatDueDate(DateTime due) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final day = due.day;
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : (day % 10 == 1)
            ? 'st'
            : (day % 10 == 2)
                ? 'nd'
                : (day % 10 == 3)
                    ? 'rd'
                    : 'th';
    return '$day$suffix ${months[due.month - 1]} ${due.year}';
  }

  Future<void> _submitPayment(_RentDue due) async {
    final user = context.read<AuthProvider>().user;
    String phone = _phoneController.text.trim();
    if (_paymentMethod == 'M-Pesa') {
      if (phone.isEmpty) phone = user?.phone?.trim() ?? '';
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter your M-Pesa phone number.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final method = _paymentMethod == 'M-Pesa'
          ? 'mpesa'
          : _paymentMethod == 'Bank Transfer'
              ? 'bank_transfer'
              : 'cash';
      final body = <String, dynamic>{
        'tenancy_id': due.tenancyId,
        'amount': due.rentAmount,
        'payment_method': method,
      };
      if (method == 'mpesa') body['phone_number'] = phone;

      final response = await _api.post('/payments', body);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode != 201) {
        Map<String, dynamic>? data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data?['error']?.toString() ??
                  'Payment failed (${response.statusCode}).',
            ),
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded,
              color: AppColors.kodiGreen, size: 44),
          title: Text(method == 'mpesa'
              ? 'STK Push Sent'
              : 'Payment Recorded'),
          content: Text(
            method == 'mpesa'
                ? 'Check your phone and enter your M-Pesa PIN to complete the ${_moneyKsh(due.rentAmount)} payment.'
                : 'Your $_paymentMethod payment of ${_moneyKsh(due.rentAmount)} has been recorded.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pay Rent',
          style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<_RentDue?>(
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
                  const Icon(Icons.error_outline_rounded,
                      size: 56, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              );
            }
            final due = snapshot.data;
            if (due == null) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    'No active tenancy found on your account.',
                    style: AppStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return _buildContent(due);
          },
        ),
      ),
    );
  }

  Widget _buildContent(_RentDue due) {
    final user = context.watch<AuthProvider>().user;
    final phoneHint = user?.phone?.trim() ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PaymentCard(
            title: 'Payment Summary',
            children: [
              _SummaryRow(label: 'Property', value: due.propertyName),
              _SummaryRow(label: 'Unit', value: due.unitNumber),
              _SummaryRow(
                  label: 'Rent Amount', value: _moneyKsh(due.rentAmount)),
              _SummaryRow(
                  label: 'Due Date', value: _formatDueDate(due.dueDate)),
            ],
          ),
          const SizedBox(height: 16),
          _PaymentCard(
            title: 'Payment Method',
            children: [
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded,
                      color: AppColors.kodiGreen),
                ),
                items: const [
                  DropdownMenuItem(value: 'M-Pesa', child: Text('M-Pesa')),
                  DropdownMenuItem(
                      value: 'Bank Transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _paymentMethod = value);
                },
              ),
              if (_paymentMethod == 'M-Pesa') ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'M-Pesa phone number',
                    hintText:
                        phoneHint.isEmpty ? '2547XXXXXXXX' : phoneHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kodiGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSubmitting ? null : () => _submitPayment(due),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.white, strokeWidth: 2),
                    )
                  : Text('Pay ${_moneyKsh(due.rentAmount)}',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              _paymentMethod == 'M-Pesa'
                  ? 'You will receive an M-Pesa prompt'
                  : 'Your payment will be marked pending confirmation',
              style: AppStyles.caption,
            ),
          ),
          const SizedBox(height: 26),
          const Divider(color: AppColors.border),
          const SizedBox(height: 18),
          const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded,
                    color: AppColors.kodiGreen, size: 16),
                SizedBox(width: 8),
                Text('Secure payment powered by M-Pesa',
                    style: AppStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _ReceiptPreview(),
        ],
      ),
    );
  }
}

class _RentDue {
  final int tenancyId;
  final String propertyName;
  final String unitNumber;
  final num rentAmount;
  final DateTime dueDate;

  const _RentDue({
    required this.tenancyId,
    required this.propertyName,
    required this.unitNumber,
    required this.rentAmount,
    required this.dueDate,
  });

  factory _RentDue.fromJson(Map<String, dynamic> json) {
    final start = DateTime.tryParse(json['start_date']?.toString() ?? '');
    final now = DateTime.now();
    final day = (start?.day ?? 25).clamp(1, 28);
    return _RentDue(
      tenancyId: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      propertyName: (json['property_name'] ?? '').toString(),
      unitNumber: (json['unit_number'] ?? '').toString(),
      rentAmount: (json['rent_amount'] is num)
          ? json['rent_amount'] as num
          : num.tryParse(json['rent_amount']?.toString() ?? '') ?? 0,
      dueDate: DateTime(now.year, now.month, day),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PaymentCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppStyles.caption)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textDark, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview();

  @override
  Widget build(BuildContext context) {
    return const ListPanel(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.kodiGreen, size: 34),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipt ready after payment',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    SizedBox(height: 2),
                    Text(
                        'Downloadable confirmation is generated once M-Pesa confirms.',
                        style: AppStyles.caption),
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
