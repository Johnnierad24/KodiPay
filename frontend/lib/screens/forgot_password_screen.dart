import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 0;
  bool _obscurePassword = true;
  String? _error;
  String? _devOtpHint;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email address.');
      return;
    }
    setState(() => _error = null);
    final result = await context.read<AuthProvider>().sendOtp(identifier: email, method: 'email');
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _step = 1;
        _devOtpHint = result['dev_otp'] as String?;
        _error = null;
      });
      if (_devOtpHint == null) {
        Navigator.pushNamed(context, '/check-email');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] as String? ?? 'OTP sent to $email')));
    } else {
      setState(() => _error = result['message'] as String? ?? 'Failed to send OTP.');
    }
  }

  Future<void> _verifyAndReset() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (otp.isEmpty) { setState(() => _error = 'Enter the OTP code.'); return; }
    if (password.length < 6) { setState(() => _error = 'Password must be at least 6 characters.'); return; }
    if (password != confirm) { setState(() => _error = 'Passwords do not match.'); return; }
    setState(() => _error = null);

    final result = await context.read<AuthProvider>().resetPasswordWithOtp(identifier: email, otp: otp, password: password);
    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful. Log in with your new password.')));
    } else {
      setState(() => _error = result['message'] as String? ?? 'Password reset failed.');
    }
  }

  Future<void> _resendOtp() async {
    final email = _emailController.text.trim();
    final result = await context.read<AuthProvider>().sendOtp(identifier: email, method: 'email');
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _devOtpHint = result['dev_otp'] as String?);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: SafeArea(
        child: isWide ? _wideLayout(auth) : _narrowLayout(auth),
      ),
    );
  }

  Widget _wideLayout(AuthProvider auth) {
    return Row(
      children: [
        const Expanded(child: _HeroSide()),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_step == 0 ? 'Forgot Password?' : 'Enter OTP Code', style: AppStyles.headlineLg.copyWith(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  _step == 0 ? 'Enter your email to receive a reset link.' : 'Enter the 6-digit code sent to your email.',
                  style: AppStyles.bodySm,
                ),
                const SizedBox(height: 28),
                if (_step == 0) _buildRequestStep(auth),
                if (_step == 1) _buildResetStep(auth),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))),
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 20),
                if (_step == 0)
                  _buildBackToLogin(),
                if (_step == 1)
                  Center(
                    child: TextButton(
                      onPressed: _resendOtp,
                      child: const Text('Resend Code', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                const SizedBox(height: 32),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout(AuthProvider auth) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 180, child: _HeroSide(compact: true)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_step == 0 ? 'Forgot Password?' : 'Enter OTP Code', style: AppStyles.headlineLg.copyWith(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  _step == 0 ? 'Enter your email to receive a reset link.' : 'Enter the 6-digit code sent to your email.',
                  style: AppStyles.bodySm,
                ),
                const SizedBox(height: 22),
                if (_step == 0) _buildRequestStep(auth),
                if (_step == 1) _buildResetStep(auth),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))),
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 16),
                if (_step == 0) _buildBackToLogin(),
                if (_step == 1)
                  Center(
                    child: TextButton(
                      onPressed: _resendOtp,
                      child: const Text('Resend Code', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLogin() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
        child: const Text('← Back to Login', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: AppColors.border),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8, runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            TextButton(onPressed: () => Navigator.pushNamed(context, '/terms'), child: const Text('Terms', style: TextStyle(fontSize: 12, color: AppColors.muted, decoration: TextDecoration.underline))),
            const Text('•', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/privacy'), child: const Text('Privacy', style: TextStyle(fontSize: 12, color: AppColors.muted, decoration: TextDecoration.underline))),
            const Text('•', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/contact'), child: const Text('Contact', style: TextStyle(fontSize: 12, color: AppColors.muted, decoration: TextDecoration.underline))),
          ],
        ),
        const SizedBox(height: 8),
        const Text('© 2026 KodiPay Kenya. All rights reserved.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }

  Widget _buildRequestStep(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _requestOtp,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiBlue),
            child: auth.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Send Reset Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildResetStep(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_devOtpHint != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.infoSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.info.withValues(alpha: 0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DEV MODE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.info, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(_devOtpHint!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.info, letterSpacing: 4)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          decoration: const InputDecoration(
            labelText: 'OTP Code',
            hintText: '6-digit code',
            prefixIcon: Icon(Icons.pin_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmController,
          obscureText: _obscurePassword,
          decoration: const InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: Icon(Icons.lock_reset_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _verifyAndReset,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiBlue),
            child: auth.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

class _HeroSide extends StatelessWidget {
  final bool compact;
  const _HeroSide({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 180 : double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/welcome_bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF041627),
              Color(0x99041627),
              Color(0x44001633),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            Spacer(flex: compact ? 1 : 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/kodipay_logo.png',
                width: 57, height: 38, fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text('KodiPay', style: TextStyle(fontSize: compact ? 20 : 24, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Lexend')),
            const SizedBox(height: 6),
            Text('Securing Your\nProperty Investments', style: TextStyle(fontSize: compact ? 12 : 14, color: Colors.white.withValues(alpha: 0.7), height: 1.5)),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
