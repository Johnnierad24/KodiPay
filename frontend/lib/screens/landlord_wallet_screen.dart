import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class LandlordWalletScreen extends StatefulWidget {
  const LandlordWalletScreen({super.key});

  @override
  State<LandlordWalletScreen> createState() => _LandlordWalletScreenState();
}

class _LandlordWalletScreenState extends State<LandlordWalletScreen> {
  final _api = ApiService();
  bool _loading = true;
  double _balance = 0;
  List<Map<String, dynamic>> _payouts = [];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _fmtKsh(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'KSh $buf';
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '-';
    try {
      final dt = DateTime.parse(d);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return d;
    }
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.get('/payouts/balance'),
        _api.get('/payouts'),
        _api.get('/reports/transactions'),
      ]);
      if (!mounted) return;
      final balRes = results[0];
      final payRes = results[1];
      final txRes = results[2];

      Map<String, dynamic> balData = {};
      List<dynamic> payList = [];
      List<dynamic> txList = [];

      if (balRes.statusCode == 200) balData = jsonDecode(balRes.body);
      if (payRes.statusCode == 200) payList = jsonDecode(payRes.body);
      if (txRes.statusCode == 200) txList = jsonDecode(txRes.body);

      setState(() {
        _balance = (balData['balance'] ?? 0).toDouble();
        _payouts = payList.cast<Map<String, dynamic>>();
        _transactions = txList.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildBentoGrid(),
                  const SizedBox(height: 24),
                  _buildTransactionHistory(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Wallet & Payouts', style: AppStyles.headlineLg),
        const SizedBox(height: 4),
        Text('Manage your property earnings and distribution settings.',
            style: AppStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.kodiGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.kodiGreen.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_rounded, size: 16, color: AppColors.kodiGreen),
              SizedBox(width: 6),
              Text('Funds are protected by SecureFast Escrow',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kodiGreen)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildBalanceCard()),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildUpcomingPayouts()),
            ],
          );
        }
        return Column(
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 16),
            _buildUpcomingPayouts(),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard() {
    final whole = _balance.floor();
    final cents = ((_balance - whole) * 100).round().toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AVAILABLE BALANCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.primaryFixedDim)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: _fmtKsh(whole), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.onPrimary)),
                TextSpan(text: '.$cents', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.primaryFixedDim)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _showWithdrawDialog,
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: const Text('Withdraw to Bank/M-Pesa', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiaryFixed,
                  foregroundColor: AppColors.onTertiaryFixed,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showPayoutMethodsDialog,
                icon: const Icon(Icons.account_balance_rounded, size: 18),
                label: const Text('Manage Payout Methods', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onPrimary,
                  side: BorderSide(color: AppColors.onPrimary.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPayouts() {
    final scheduled = _payouts
        .where((p) => (p['status'] == 'scheduled' || p['status'] == 'pending'))
        .toList()
      ..sort((a, b) {
        final da = a['scheduled_date'] ?? '';
        final db = b['scheduled_date'] ?? '';
        return da.toString().compareTo(db.toString());
      });
    final show = scheduled.take(2).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upcoming Payouts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
              Icon(Icons.schedule_rounded, size: 20, color: AppColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),
          if (show.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No upcoming payouts', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
            )
          else ...[
            for (var i = 0; i < show.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _payoutItem(
                show[i]['description'] ?? show[i]['method'] ?? 'Payout',
                _fmtDate(show[i]['scheduled_date']),
                _fmtKsh((show[i]['amount'] ?? 0).toDouble()),
                (show[i]['status'] ?? 'pending').toString().toUpperCase(),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _showPayoutCalendarDialog,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View Payout Calendar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payoutItem(String title, String date, String amount, String status) {
    final isScheduled = status == 'SCHEDULED';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.onSurface)),
              Text(date, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isScheduled ? AppColors.surfaceHigh : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryContainer)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _TransactionRowData _mapTransaction(Map<String, dynamic> t) {
    final amount = (t['amount'] ?? 0).toDouble();
    final paymentMethod = (t['payment_method'] ?? '').toString().toLowerCase();
    final isPositive = amount >= 0;
    final icon = paymentMethod.contains('mpesa') || paymentMethod.contains('m-pesa')
        ? Icons.phone_android_rounded
        : paymentMethod.contains('bank')
            ? Icons.account_balance_rounded
            : Icons.receipt_long_rounded;
    final color = isPositive ? AppColors.kodiGreen : AppColors.error;
    final tenantName = t['tenant_name'] ?? '';
    final unit = t['unit_number'] ?? '';
    final prop = t['property_name'] ?? '';
    final details = [if (unit.isNotEmpty) unit, if (prop.isNotEmpty) prop].join(' - ');
    final amountStr = '${isPositive ? '+' : '-'} ${_fmtKsh(amount.abs())}';
    final status = (t['status'] ?? 'SUCCESS').toString().toUpperCase();
    final dateStr = _fmtDate(t['payment_date']);
    return _TransactionRowData(
      tenantName.isNotEmpty ? tenantName : (t['transaction_ref'] ?? 'Transaction'),
      details.isNotEmpty ? details : '-',
      dateStr,
      amountStr,
      status,
      icon,
      color,
    );
  }

  Widget _buildTransactionHistory() {
    final txs = _transactions.take(10).toList();
    final transactions = txs.map(_mapTransaction).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showFilterSheet,
                      icon: const Icon(Icons.filter_alt_rounded, size: 16),
                      label: const Text('Filter', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _exportCsv,
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    ),
                  ],
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
                    ...transactions.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)))),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: t.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: Icon(t.icon, size: 18, color: t.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface))),
                                    Text(t.amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.amount.startsWith('+') ? AppColors.kodiGreen : AppColors.error)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(child: Text(t.details, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: t.status == 'SUCCESS' ? AppColors.kodiGreen.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(t.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.status == 'SUCCESS' ? AppColors.kodiGreen : AppColors.warning)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                );
              }
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    color: AppColors.surfaceLow,
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _th('Type')),
                        Expanded(flex: 3, child: _th('Details')),
                        Expanded(flex: 2, child: _th('Date')),
                        Expanded(flex: 2, child: _th('Amount', align: TextAlign.right)),
                        Expanded(flex: 2, child: _th('Status')),
                      ],
                    ),
                  ),
                  ...transactions.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)))),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: t.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                child: Icon(t.icon, size: 14, color: t.color),
                              ),
                              const SizedBox(width: 8),
                              Text(t.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                            ],
                          ),
                        ),
                        Expanded(flex: 3, child: Text(t.details, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))),
                        Expanded(flex: 2, child: Text(t.date, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))),
                        Expanded(
                          flex: 2,
                          child: Text(t.amount, textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: t.amount.startsWith('+') ? AppColors.kodiGreen : AppColors.error)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: t.status == 'SUCCESS' ? AppColors.kodiGreen.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: t.status == 'SUCCESS' ? AppColors.kodiGreen.withValues(alpha: 0.2) : AppColors.warning.withValues(alpha: 0.2)),
                            ),
                            child: Text(t.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                color: t.status == 'SUCCESS' ? AppColors.kodiGreen : AppColors.warning)),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text('Showing 1-${transactions.length} of ${_transactions.length} transactions', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const IconButton(
                      icon: Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.muted),
                      onPressed: null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
                      onPressed: _transactions.length > 10 ? () => _showSnack('Page 2 of ${(_transactions.length / 10).ceil()}') : null,
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

  Widget _th(String label, {TextAlign align = TextAlign.left}) {
    return Text(label.toUpperCase(), textAlign: align,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant));
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
        child: Text('© 2026 KodiPay Kenya. All transactions are securely processed through our central escrow gateway.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showWithdrawDialog() {
    final amountCtrl = TextEditingController();
    String method = 'M-Pesa';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (KSh)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder()),
              items: const [DropdownMenuItem(value: 'M-Pesa', child: Text('M-Pesa')), DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer'))],
              onChanged: (v) { if (v != null) method = v; },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () { Navigator.pop(ctx); _showSnack('Withdrawal of KSh ${amountCtrl.text} initiated via $method'); }, child: const Text('Withdraw')),
        ],
      ),
    );
  }

  void _showPayoutMethodsDialog() {
    final user = context.read<AuthProvider>().user;
    final phone = user?.phone ?? '-';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payout Methods'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(leading: const Icon(Icons.phone_android), title: const Text('M-Pesa'), subtitle: Text(phone), contentPadding: EdgeInsets.zero),
            const Divider(),
            const ListTile(leading: Icon(Icons.account_balance), title: Text('Bank Transfer'), subtitle: Text('No bank account linked'), contentPadding: EdgeInsets.zero),
            const Divider(),
            const ListTile(leading: Icon(Icons.add_circle_outline), title: Text('Add New Method'), contentPadding: EdgeInsets.zero),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showPayoutCalendarDialog() {
    final scheduled = _payouts
        .where((p) => p['scheduled_date'] != null)
        .toList()
      ..sort((a, b) => a['scheduled_date'].toString().compareTo(b['scheduled_date'].toString()));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payout Calendar'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scheduled.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No scheduled payouts', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                )
              else
                for (final p in scheduled) ...[
                  Text('${_fmtDate(p['scheduled_date'])} - ${p['description'] ?? p['method'] ?? 'Payout'} (${_fmtKsh((p['amount'] ?? 0).toDouble())})', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Transactions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const Wrap(spacing: 8, children: [
              Chip(label: Text('All'), avatar: Icon(Icons.check, size: 16)),
              Chip(label: Text('Rent')),
              Chip(label: Text('Withdrawal')),
              Chip(label: Text('Service Fee')),
            ]),
            const SizedBox(height: 16),
            const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Row(children: [
              Expanded(child: TextField(decoration: InputDecoration(labelText: 'From', border: OutlineInputBorder(), isDense: true))),
              SizedBox(width: 12),
              Expanded(child: TextField(decoration: InputDecoration(labelText: 'To', border: OutlineInputBorder(), isDense: true))),
            ]),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Apply Filters')),
          ],
        ),
      ),
    );
  }

  void _exportCsv() {
    final csv = StringBuffer();
    csv.writeln('Type,Details,Date,Amount,Status');
    for (final t in _transactions) {
      final tx = _mapTransaction(t);
      csv.writeln('${tx.title},${tx.details},${tx.date},${tx.amount},${tx.status}');
    }
    _showSnack('CSV exported: ${csv.toString().length} bytes');
  }
}

class _TransactionRowData {
  final String title;
  final String details;
  final String date;
  final String amount;
  final String status;
  final IconData icon;
  final Color color;

  const _TransactionRowData(this.title, this.details, this.date, this.amount, this.status, this.icon, this.color);
}
