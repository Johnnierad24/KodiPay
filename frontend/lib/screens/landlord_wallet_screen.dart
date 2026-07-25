import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LandlordWalletScreen extends StatefulWidget {
  const LandlordWalletScreen({super.key});

  @override
  State<LandlordWalletScreen> createState() => _LandlordWalletScreenState();
}

class _LandlordWalletScreenState extends State<LandlordWalletScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
        Row(
          children: [
            Expanded(
              child: Text('Manage your property earnings and distribution settings.',
                  style: AppStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.kodiGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.kodiGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded, size: 16, color: AppColors.kodiGreen),
                  const SizedBox(width: 6),
                  Text('Funds are protected by SecureFast Escrow',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.kodiGreen)),
                ],
              ),
            ),
          ],
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
          Text('AVAILABLE BALANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.primaryFixedDim)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'KSh 840,200', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.onPrimary)),
                TextSpan(text: '.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.primaryFixedDim)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upcoming Payouts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
              Icon(Icons.schedule_rounded, size: 20, color: AppColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),
          _payoutItem('Weekly Settlement', 'Oct 24, 2023', 'KSh 125,000', 'SCHEDULED'),
          const SizedBox(height: 12),
          _payoutItem('Monthly Reserve Release', 'Nov 01, 2023', 'KSh 45,200', 'PENDING'),
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
              Text(date, style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isScheduled ? AppColors.surfaceHigh : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryContainer)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final transactions = <_TransactionRowData>[
      _TransactionRowData('Rent Payment', 'Unit 4B - Savannah Estates', 'Oct 18, 2023', '+ KSh 85,000', 'SUCCESS', Icons.receipt_long_rounded, AppColors.kodiGreen),
      _TransactionRowData('Withdrawal', 'Standard Chartered (A/C ...4521)', 'Oct 15, 2023', '- KSh 300,000', 'SUCCESS', Icons.outbound_rounded, AppColors.primaryContainer),
      _TransactionRowData('Service Fee', 'Maintenance: Plumbing Repair', 'Oct 12, 2023', '- KSh 4,500', 'SUCCESS', Icons.settings_suggest_rounded, AppColors.error),
      _TransactionRowData('Rent Payment', 'Unit 1A - Savannah Estates', 'Oct 10, 2023', '+ KSh 120,000', 'PENDING', Icons.receipt_long_rounded, AppColors.kodiGreen),
    ];

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Lexend', color: AppColors.primary)),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showFilterSheet,
                      icon: const Icon(Icons.filter_alt_rounded, size: 16),
                      label: const Text('Filter', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    ),
                    const SizedBox(width: 8),
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
          // Table header
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
                      Text(t.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                    ],
                  ),
                ),
                Expanded(flex: 3, child: Text(t.details, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))),
                Expanded(flex: 2, child: Text(t.date, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))),
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
                    child: Text(t.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: t.status == 'SUCCESS' ? AppColors.kodiGreen : AppColors.warning)),
                  ),
                ),
              ],
            ),
          )),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing 1-10 of 124 transactions', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.muted),
                      onPressed: null,
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
                      onPressed: () => _showSnack('Page 2 of 13'),
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.onSurfaceVariant));
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text('© 2026 KodiPay Kenya. All transactions are securely processed through our central escrow gateway.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
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
              value: method,
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payout Methods'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(leading: Icon(Icons.phone_android), title: Text('M-Pesa'), subtitle: Text('+254 712 345 678'), contentPadding: EdgeInsets.zero),
            Divider(),
            ListTile(leading: Icon(Icons.account_balance), title: Text('Standard Chartered'), subtitle: Text('A/C ****4521'), contentPadding: EdgeInsets.zero),
            Divider(),
            ListTile(leading: Icon(Icons.add_circle_outline), title: Text('Add New Method'), contentPadding: EdgeInsets.zero),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showPayoutCalendarDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payout Calendar'),
        content: const SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('October 2024', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              SizedBox(height: 12),
              Text('Mon 24 - Weekly Settlement (KSh 125,000)'),
              SizedBox(height: 4),
              Text('Wed 26 - M-Pesa Processing (KSh 85,000)'),
              SizedBox(height: 4),
              Text('Fri 28 - Bank Transfer (KSh 300,000)'),
              SizedBox(height: 4),
              Text('Nov 01 - Monthly Reserve Release (KSh 45,200)'),
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
            Row(children: [
              Expanded(child: TextField(decoration: InputDecoration(labelText: 'From', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 12),
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
    csv.writeln('Rent Payment,Unit 4B - Savannah Estates,Oct 18 2023,+ KSh 85,000,SUCCESS');
    csv.writeln('Withdrawal,Standard Chartered (A/C ...4521),Oct 15 2023,- KSh 300,000,SUCCESS');
    csv.writeln('Service Fee,Maintenance: Plumbing Repair,Oct 12 2023,- KSh 4,500,SUCCESS');
    csv.writeln('Rent Payment,Unit 1A - Savannah Estates,Oct 10 2023,+ KSh 120,000,PENDING');
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
