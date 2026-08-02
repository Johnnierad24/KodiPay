import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'pay_rent_screen.dart';
import 'payment_card_screen.dart';
import 'payment_bank_screen.dart';
import 'payment_cash_screen.dart';

class TenantPaymentsScreen extends StatefulWidget {
  const TenantPaymentsScreen({super.key});

  @override
  State<TenantPaymentsScreen> createState() => _TenantPaymentsScreenState();
}

class _TenantPaymentsScreenState extends State<TenantPaymentsScreen> {
  final ApiService _api = ApiService();
  Future<_PaymentsBundle>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _fetch();
    setState(() {});
  }

  Future<_PaymentsBundle> _fetch() async {
    final tenancyResp = await _api.get('/tenancies');
    if (tenancyResp.statusCode != 200) throw Exception('Could not load tenancy (${tenancyResp.statusCode})');
    final tenancies = (jsonDecode(tenancyResp.body) as List).cast<Map<String, dynamic>>();
    if (tenancies.isEmpty) return const _PaymentsBundle(payments: [], tenancy: null);

    final active = tenancies.firstWhere((t) => (t['status']?.toString() ?? 'active') == 'active', orElse: () => tenancies.first);
    final tenancyId = active['id'];
    final paymentsResp = await _api.get('/payments/tenancy/$tenancyId');
    if (paymentsResp.statusCode != 200) throw Exception('Could not load payments (${paymentsResp.statusCode})');
    final payments = (jsonDecode(paymentsResp.body) as List)
        .map((item) => _TenantPayment.fromJson(item as Map<String, dynamic>)).toList();

    return _PaymentsBundle(payments: payments, tenancy: _TenancySummary.fromJson(active));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments', style: TextStyle(fontFamily: 'Lexend', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<_PaymentsBundle>(
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
            final bundle = snapshot.data ?? const _PaymentsBundle(payments: [], tenancy: null);
            return _PaymentsContent(bundle: bundle, onRefresh: _reload);
          },
        ),
      ),
    );
  }
}

class _PaymentsContent extends StatefulWidget {
  final _PaymentsBundle bundle;
  final VoidCallback onRefresh;
  const _PaymentsContent({required this.bundle, required this.onRefresh});

  @override
  State<_PaymentsContent> createState() => _PaymentsContentState();
}

class _PaymentsContentState extends State<_PaymentsContent> {
  String _selectedMethod = 'M-Pesa';

  RentDue _toRentDue() => RentDue(
    tenancyId: widget.bundle.tenancy?.id ?? 0,
    propertyName: widget.bundle.tenancy?.propertyName ?? '',
    unitNumber: widget.bundle.tenancy?.unitNumber ?? '',
    rentAmount: widget.bundle.tenancy?.rentAmount ?? 45000,
    dueDate: DateTime.now(),
  );

  void _payNow() {
    final due = _toRentDue();
    switch (_selectedMethod) {
      case 'M-Pesa':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PayRentScreen()));
        break;
      case 'Bank Transfer':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentBankScreen(due: due)));
        break;
      case 'Cash':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentCashScreen(due: due)));
        break;
      case 'Credit/Debit Card':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentCardScreen(due: due)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenancy = widget.bundle.tenancy;
    final payments = widget.bundle.payments;
    final rentAmount = tenancy?.rentAmount ?? 45000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              return isNarrow
                  ? Column(
                      children: [
                        _BalanceCard(amount: rentAmount, selectedMethod: _selectedMethod, onPayNow: _payNow),
                        const SizedBox(height: 16),
                        _LastPaymentCard(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _BalanceCard(amount: rentAmount, selectedMethod: _selectedMethod, onPayNow: _payNow)),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: _LastPaymentCard()),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1000;
              return isNarrow
                  ? Column(
                      children: [
                        _UpcomingBillsSection(rentAmount: rentAmount),
                        const SizedBox(height: 16),
                        _PaymentMethodsSection(
                          selectedMethod: _selectedMethod,
                          onMethodSelected: (m) => setState(() => _selectedMethod = m),
                          onPayNow: _payNow,
                        ),
                        const SizedBox(height: 16),
                        _TransactionHistoryTable(payments: payments),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _UpcomingBillsSection(rentAmount: rentAmount),
                              const SizedBox(height: 16),
                              _PaymentMethodsSection(
                                selectedMethod: _selectedMethod,
                                onMethodSelected: (m) => setState(() => _selectedMethod = m),
                                onPayNow: _payNow,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(flex: 8, child: _TransactionHistoryTable(payments: payments)),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineVariant))),
            child: const Column(
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 16),
                        SizedBox(width: 6),
                        Text('SSL Secured', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.policy, size: 16),
                        SizedBox(width: 6),
                        Text('PCI-DSS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text('© 2023 KodiPay Silicon Savannah. All transactions are final.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Balance Card ─────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final num amount;
  final String selectedMethod;
  final VoidCallback onPayNow;
  const _BalanceCard({required this.amount, required this.selectedMethod, required this.onPayNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CURRENT BALANCE DUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.white.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Text('KSh ${formatKsh(amount)}.00', style: const TextStyle(fontFamily: 'Lexend', fontSize: 40, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Due by October 1st, 2023 • No late fees yet', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPayNow,
              icon: const Icon(Icons.payments, size: 20),
              label: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiaryFixed,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.verified_user, size: 16, color: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text('SECURE & ENCRYPTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.white.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Last Payment Card ────────────────────────────────────
class _LastPaymentCard extends StatelessWidget {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Last Payment', style: TextStyle(fontFamily: 'Lexend', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.kodiGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('SUCCESSFUL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.kodiGreen)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Rent - September 2023', style: TextStyle(fontSize: 14, color: AppColors.secondary)),
          const SizedBox(height: 4),
          const Text('KSh 45,000', style: TextStyle(fontFamily: 'Lexend', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineVariant))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaction ID', style: TextStyle(fontSize: 14, color: AppColors.secondary)),
                Text('#KP-9283-X1', style: TextStyle(fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming Bills ───────────────────────────────────────
class _UpcomingBillsSection extends StatelessWidget {
  final num rentAmount;
  const _UpcomingBillsSection({required this.rentAmount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.schedule, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Upcoming Bills', style: TextStyle(fontFamily: 'Lexend', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        _BillCard(icon: Icons.apartment, title: 'Monthly Rent', subtitle: 'Due Oct 1', amount: 'KSh ${formatKsh(rentAmount)}'),
        const SizedBox(height: 12),
        const _BillCard(icon: Icons.cleaning_services, title: 'Service Charge', subtitle: 'Due Oct 1', amount: 'KSh 3,500'),
        const SizedBox(height: 12),
        const _BillCard(icon: Icons.water_drop, title: 'Water Bill', subtitle: 'Reading: 243 m³', amount: 'KSh 1,500'),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  const _BillCard({required this.icon, required this.title, required this.subtitle, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 16)),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.secondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.onSurface)),
              const Text('PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.tertiaryFixed)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Payment Methods ──────────────────────────────────────
class _PaymentMethodsSection extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodSelected;
  final VoidCallback onPayNow;
  const _PaymentMethodsSection({required this.selectedMethod, required this.onMethodSelected, required this.onPayNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECT PAYMENT METHOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.secondary)),
          const SizedBox(height: 12),
          ...[
            (Icons.phone_android, 'M-Pesa'),
            (Icons.account_balance, 'Bank Transfer'),
            (Icons.credit_card, 'Credit/Debit Card'),
            (Icons.money, 'Cash'),
          ].map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PaymentMethodTile(
              icon: entry.$1,
              label: entry.$2,
              selected: selectedMethod == entry.$2,
              onTap: () => onMethodSelected(entry.$2),
            ),
          )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPayNow,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text('Pay with $selectedMethod', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _PaymentMethodTile({required this.icon, required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 16)),
            const Spacer(),
            if (selected)
              Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              )
            else
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.outlineVariant)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction History Table ────────────────────────────
class _TransactionHistoryTable extends StatelessWidget {
  final List<_TenantPayment> payments;
  const _TransactionHistoryTable({required this.payments});

  @override
  Widget build(BuildContext context) {
    final displayPayments = [
      const _DemoPayment('Sep 01, 2023', 'Rent Payment - September', 'Via M-Pesa (0712...890)', '45,000.00', 'PAID'),
      const _DemoPayment('Aug 03, 2023', 'Water Bill - July', 'Via Bank Transfer', '1,820.00', 'PAID'),
      const _DemoPayment('Aug 01, 2023', 'Rent Payment - August', 'Via M-Pesa', '45,000.00', 'PAID'),
      const _DemoPayment('Jul 15, 2023', 'Maintenance Surcharge', 'Window Repair - Unit 4B', '3,500.00', 'PAID'),
      const _DemoPayment('Jul 01, 2023', 'Rent Payment - July', 'Failed Attempt - Card ****4242', '45,000.00', 'FAILED'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transaction History', style: TextStyle(fontFamily: 'Lexend', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Statement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              if (isNarrow) {
                return Column(
                  children: [
                    ...displayPayments.map((p) {
                      final isFailed = p.status == 'FAILED';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5))),
                          color: isFailed ? AppColors.danger.withValues(alpha: 0.03) : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(p.date, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isFailed ? AppColors.danger.withValues(alpha: 0.08) : AppColors.kodiGreen.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(p.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isFailed ? AppColors.danger : AppColors.kodiGreen)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(p.amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    color: AppColors.surfaceLow,
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant))),
                        Expanded(flex: 3, child: Text('DESCRIPTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant))),
                        Expanded(flex: 2, child: Text('AMOUNT (KSH)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant))),
                        Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant))),
                        SizedBox(width: 48),
                      ],
                    ),
                  ),
                  ...displayPayments.map((p) {
                    final isFailed = p.status == 'FAILED';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5))),
                        color: isFailed ? AppColors.danger.withValues(alpha: 0.03) : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(p.date, style: const TextStyle(fontSize: 14, fontFamily: 'Inter'))),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                Text(p.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                              ],
                            ),
                          ),
                          Expanded(flex: 2, child: Text(p.amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isFailed ? AppColors.danger.withValues(alpha: 0.08) : AppColors.kodiGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(p.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isFailed ? AppColors.danger : AppColors.kodiGreen)),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: isFailed
                                ? const Text('Insufficient Funds', style: TextStyle(fontSize: 12, color: AppColors.secondary))
                                : IconButton(icon: const Icon(Icons.receipt_long, size: 20), color: AppColors.outline, onPressed: () {}),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                const Text('Showing 5 of 24 transactions', style: TextStyle(fontSize: 13, color: AppColors.secondary)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                      child: const Text('Previous', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoPayment {
  final String date, description, subtitle, amount, status;
  const _DemoPayment(this.date, this.description, this.subtitle, this.amount, this.status);
}

// ── Data Models ──────────────────────────────────────────
class _PaymentsBundle {
  final List<_TenantPayment> payments;
  final _TenancySummary? tenancy;
  const _PaymentsBundle({required this.payments, required this.tenancy});
}

class _TenancySummary {
  final int id;
  final String propertyName;
  final String unitNumber;
  final num rentAmount;
  const _TenancySummary({required this.id, required this.propertyName, required this.unitNumber, required this.rentAmount});

  factory _TenancySummary.fromJson(Map<String, dynamic> json) => _TenancySummary(
    id: toInt(json['id']),
    propertyName: (json['property_name'] ?? '').toString(),
    unitNumber: (json['unit_number'] ?? '').toString(),
    rentAmount: toNum(json['rent_amount']),
  );
}

class _TenantPayment {
  final int id;
  final num amount;
  final String method;
  final String? transactionRef;
  final String status;
  final DateTime? paymentDate;
  const _TenantPayment({required this.id, required this.amount, required this.method, required this.transactionRef, required this.status, required this.paymentDate});

  factory _TenantPayment.fromJson(Map<String, dynamic> json) => _TenantPayment(
    id: toInt(json['id']),
    amount: toNum(json['amount']),
    method: (json['payment_method'] ?? '').toString(),
    transactionRef: json['transaction_ref']?.toString(),
    status: (json['status'] ?? '').toString(),
    paymentDate: DateTime.tryParse(json['payment_date']?.toString() ?? ''),
  );
}
