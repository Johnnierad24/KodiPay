import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'pay_rent_screen.dart';
import 'payment_success_screen.dart';

class PaymentBankScreen extends StatefulWidget {
  final RentDue due;
  const PaymentBankScreen({super.key, required this.due});

  @override
  State<PaymentBankScreen> createState() => _PaymentBankScreenState();
}

class _PaymentBankScreenState extends State<PaymentBankScreen> {
  final _nameController = TextEditingController();
  final _refController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isSubmitting = false;
  bool _confirmed = false;
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _nameController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  void _removeFile() {
    setState(() => _pickedFile = null);
  }

  Future<void> _submitBankPayment() async {
    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'tenancy_id': widget.due.tenancyId,
        'amount': widget.due.rentAmount,
        'payment_method': 'bank_transfer',
        'payer_name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        'transaction_ref': _refController.text.trim().isNotEmpty ? _refController.text.trim() : null,
      };
      final response = await _api.post('/payments', body);
      if (!mounted) return;

      if (response.statusCode == 201) {
        if (_pickedFile != null) {
          await _uploadProof(_extractPaymentId(response.body));
        }
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              amount: widget.due.rentAmount,
              method: 'Bank Transfer',
              transactionRef: _extractRef(response.body),
              propertyName: widget.due.propertyName,
              unitNumber: widget.due.unitNumber,
            ),
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
        _showSnack('Payment recording failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack('Error: $e');
    }
  }

  Future<void> _uploadProof(String paymentId) async {
    if (_pickedFile == null || paymentId.isEmpty) return;
    try {
      final bytes = _pickedFile!.bytes;
      if (bytes == null) return;
      await _api.uploadMultipart(
        '/payments/$paymentId/proof',
        fileBytes: bytes,
        fileName: _pickedFile!.name,
        fieldName: 'proof_of_payment',
      );
    } catch (_) {}
  }

  String _extractPaymentId(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['id']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _extractRef(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['transaction_ref']?.toString() ?? 'BNK-${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      return 'BNK-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final amount = 'KSh ${formatKsh(widget.due.rentAmount)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bank Transfer', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 18)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Bank Account Details
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.kodiBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.account_balance_rounded, color: AppColors.kodiBlue, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Text('Bank Account Details', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _DetailRow(label: 'Bank Name', value: 'Equity Bank Kenya'),
                  const _DetailRow(label: 'Account Name', value: 'KodiPay Solutions Ltd'),
                  const _DetailRow(label: 'Account Number', value: '1234567890'),
                  const _DetailRow(label: 'Branch', value: 'Upper Hill, Nairobi'),
                  _DetailRow(label: 'Amount to Pay', value: amount, highlight: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Reference info
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Use your name and unit number (${widget.due.unitNumber}) as the payment reference so we can identify your payment.',
                      style: TextStyle(fontSize: 13, color: AppColors.textLight.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Payer details form
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payer Details', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 15)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name on Bank Transfer',
                      hintText: 'e.g. John Kamau',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _refController,
                    decoration: const InputDecoration(
                      labelText: 'Bank Reference Number (optional)',
                      hintText: 'e.g. TRN123456',
                      prefixIcon: Icon(Icons.receipt_outlined, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Upload proof of payment
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.kodiOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.upload_file_rounded, color: AppColors.kodiOrange, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Proof of Payment', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 15)),
                            SizedBox(height: 2),
                            Text('Upload bank deposit slip, screenshot, or transaction confirmation', style: AppStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_pickedFile != null)
                    _FilePreview(name: _pickedFile!.name, size: _pickedFile!.size, onRemove: _removeFile)
                  else
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.outlineVariant, width: 2),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 42, color: AppColors.muted),
                            SizedBox(height: 12),
                            Text('Tap to upload file', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('JPG, PNG, or PDF (max 10MB)', style: AppStyles.caption),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Confirmation checkbox
            GestureDetector(
              onTap: () => setState(() => _confirmed = !_confirmed),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: _confirmed ? AppColors.kodiGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _confirmed ? AppColors.kodiGreen : AppColors.outlineVariant, width: 2),
                      ),
                      child: _confirmed ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I have made the bank transfer and uploaded proof of payment',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _confirmed ? AppColors.textDark : AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'After making the transfer, your payment will be marked pending until we confirm receipt. This usually takes 1–2 business days.',
                      style: TextStyle(fontSize: 13, color: AppColors.textLight.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || !_confirmed) ? null : _submitBankPayment,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Payment', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kodiBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.outlineVariant,
                  disabledForegroundColor: AppColors.muted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _DetailRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.caption),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.kodiBlue : AppColors.textDark,
                fontSize: highlight ? 16 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  final String name;
  final int size;
  final VoidCallback onRemove;
  const _FilePreview({required this.name, required this.size, required this.onRemove});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final ext = name.split('.').last.toLowerCase();
    final icon = ext == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded;
    final iconColor = ext == 'pdf' ? AppColors.danger : AppColors.kodiGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kodiGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 13)),
                const SizedBox(height: 3),
                Text(_formatSize(size), style: AppStyles.caption),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
