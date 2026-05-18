import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/kodi_pay_logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _message;
  String? _devToken;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your account email.')),
      );
      return;
    }

    final result = await context
        .read<AuthProvider>()
        .requestPasswordReset(_emailController.text);

    if (!mounted) return;
    setState(() {
      _message = result.message;
      _devToken = result.resetToken;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  void _continueWithDevToken() {
    Navigator.pushNamed(context, '/reset-password', arguments: _devToken);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: KodiPayLogo(iconSize: 64, fontSize: 30)),
              const SizedBox(height: 34),
              const Text('Forgot Password', style: AppStyles.heading1),
              const SizedBox(height: 8),
              const Text(
                'Enter your account email and we will send reset instructions.',
                style: AppStyles.bodyMedium,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _requestReset,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Send Reset Link'),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 18),
                _ResetInfoCard(message: _message!),
              ],
              if (_devToken != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _continueWithDevToken,
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text('Continue to Reset Password'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetInfoCard extends StatelessWidget {
  final String message;

  const _ResetInfoCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kodiBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kodiBlue.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.kodiBlue),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: AppStyles.bodyMedium)),
        ],
      ),
    );
  }
}
