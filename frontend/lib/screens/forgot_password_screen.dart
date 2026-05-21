import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _method = 'email';
  int _step = 0;
  bool _obscurePassword = true;
  String? _error;
  String? _devOtpHint;

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final id = _identifierController.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Enter your email or phone number.');
      return;
    }
    setState(() => _error = null);

    final result = await context.read<AuthProvider>().sendOtp(
      identifier: id,
      method: _method,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _step = 1;
        _devOtpHint = result['dev_otp'] as String?;
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] as String? ?? 'OTP sent.')),
      );
    } else {
      setState(() => _error = result['message'] as String? ?? 'Failed to send OTP.');
    }
  }

  Future<void> _verifyAndReset() async {
    final id = _identifierController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (otp.isEmpty) {
      setState(() => _error = 'Enter the OTP sent to your $_method.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() => _error = null);
    final auth = context.read<AuthProvider>();

    final result = await auth.resetPasswordWithOtp(
      identifier: id,
      otp: otp,
      password: password,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.kodiGreen, size: 42),
          title: const Text('Password Updated'),
          content: const Text('You can now log in with your new password.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              },
              child: const Text('Go Back to Login'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _error = result['message'] as String? ?? 'Password reset failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () {
            if (_step > 0) {
              setState(() {
                _step = 0;
                _error = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
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
              Text(
                _step == 0 ? 'Reset Password' : 'Enter OTP',
                style: AppStyles.heading1,
              ),
              const SizedBox(height: 8),
              Text(
                _step == 0
                    ? 'Choose email or phone to receive a reset code.'
                    : 'Enter the 6-digit code sent to your $_method.',
                style: AppStyles.bodyMedium,
              ),
              const SizedBox(height: 28),

              if (_step == 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: _MethodChip(
                        label: 'Email',
                        icon: Icons.email_outlined,
                        selected: _method == 'email',
                        onTap: () => setState(() => _method = 'email'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MethodChip(
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                        selected: _method == 'phone',
                        onTap: () => setState(() => _method = 'phone'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _identifierController,
                  keyboardType: _method == 'email' ? TextInputType.emailAddress : TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _method == 'email' ? 'Email Address' : 'Phone Number',
                    prefixIcon: Icon(
                      _method == 'email' ? Icons.email_outlined : Icons.phone_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _sendOtp,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Send Reset Code'),
                  ),
                ),
              ],

              if (_step == 1) ...[
                if (_devOtpHint != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.kodiBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.kodiBlue.withValues(alpha: 0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DEV MODE OTP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.kodiBlue)),
                        const SizedBox(height: 4),
                        Text(_devOtpHint!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.kodiBlue, letterSpacing: 4)),
                      ],
                    ),
                  ),
                if (_devOtpHint != null) const SizedBox(height: 14),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    prefixIcon: Icon(Icons.pin_outlined),
                    hintText: '6-digit code',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _verifyAndReset,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Reset Password'),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _sendOtp,
                    child: const Text('Resend Code'),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ),
              ],

              if (_step == 0) ...[
                const SizedBox(height: 28),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
                    child: const Text('Back to Login'),
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

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.kodiBlue : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.kodiBlue : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.textLight,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
