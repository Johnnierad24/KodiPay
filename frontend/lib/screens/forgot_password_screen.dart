import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/glass.dart';

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
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.white),
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
                const SizedBox(height: 12),
                Text(
                  _step == 0 ? 'Reset Password' : 'Enter OTP',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == 0
                      ? 'Choose email or phone to receive a reset code.'
                      : 'Enter the 6-digit code sent to your $_method.',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 22),
                GlassPanel(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_step == 0) ..._buildRequestStep(auth),
                      if (_step == 1) ..._buildResetStep(auth),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _buildErrorBox(),
                      ],
                      if (_step == 0) ...[
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (_) => false),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.white),
                            child: const Text('Back to Login'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRequestStep(AuthProvider auth) {
    return [
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
      GlassTextField(
        controller: _identifierController,
        label: _method == 'email' ? 'Email Address' : 'Phone Number',
        icon: _method == 'email' ? Icons.email_outlined : Icons.phone_outlined,
        keyboardType: _method == 'email'
            ? TextInputType.emailAddress
            : TextInputType.phone,
      ),
      const SizedBox(height: 22),
      SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _sendOtp,
          child: auth.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Send Reset Code'),
        ),
      ),
    ];
  }

  List<Widget> _buildResetStep(AuthProvider auth) {
    return [
      if (_devOtpHint != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DEV MODE OTP',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: AppColors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 4),
              Text(_devOtpHint!,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      letterSpacing: 4)),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      GlassTextField(
        controller: _otpController,
        label: 'OTP Code',
        icon: Icons.pin_outlined,
        keyboardType: TextInputType.number,
        hintText: '6-digit code',
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
      ),
      const SizedBox(height: 14),
      GlassTextField(
        controller: _passwordController,
        label: 'New Password',
        icon: Icons.lock_outline_rounded,
        obscureText: _obscurePassword,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
      const SizedBox(height: 14),
      GlassTextField(
        controller: _confirmPasswordController,
        label: 'Confirm Password',
        icon: Icons.lock_reset_rounded,
        obscureText: _obscurePassword,
      ),
      const SizedBox(height: 22),
      SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _verifyAndReset,
          child: auth.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Reset Password'),
        ),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: _sendOtp,
        style: TextButton.styleFrom(foregroundColor: AppColors.white),
        child: const Text('Resend Code'),
      ),
    ];
  }

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Text(_error!,
          style: const TextStyle(color: AppColors.white, fontSize: 13)),
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
          color: selected
              ? AppColors.kodiBlue
              : AppColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.kodiBlue
                : AppColors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.white
                    : AppColors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
