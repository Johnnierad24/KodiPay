import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _remember = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final success = await context.read<AuthProvider>().login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please check your credentials.')),
      );
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
          child: _FormSide(
            auth: auth,
            emailCtl: _emailController,
            passwordCtl: _passwordController,
            obscurePassword: _obscurePassword,
            remember: _remember,
            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
            onToggleRemember: (v) => setState(() => _remember = v),
            onLogin: _handleLogin,
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout(AuthProvider auth) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.22,
            child: _HeroSide(compact: true),
          ),
          _FormSide(
            auth: auth,
            emailCtl: _emailController,
            passwordCtl: _passwordController,
            obscurePassword: _obscurePassword,
            remember: _remember,
            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
            onToggleRemember: (v) => setState(() => _remember = v),
            onLogin: _handleLogin,
          ),
        ],
      ),
    );
  }
}

class _HeroSide extends StatelessWidget {
  final bool compact;
  const _HeroSide({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? null : double.infinity,
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
        padding: EdgeInsets.all(compact ? 20 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Spacer(flex: compact ? 1 : 3),
            Container(
              width: compact ? 40 : 48, height: compact ? 40 : 48,
              decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text('K', style: TextStyle(fontSize: compact ? 20 : 24, fontWeight: FontWeight.w900, color: AppColors.kodiGreen))),
            ),
            SizedBox(height: compact ? 12 : 16),
            Text('KodiPay', style: TextStyle(fontSize: compact ? 20 : 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Lexend')),
            SizedBox(height: compact ? 6 : 8),
            Text('Secure Property Management\nStarts Here', style: TextStyle(fontSize: compact ? 12 : 15, color: Colors.white.withValues(alpha: 0.7), height: 1.4)),
            Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

}

class _FormSide extends StatelessWidget {
  final AuthProvider auth;
  final TextEditingController emailCtl;
  final TextEditingController passwordCtl;
  final bool obscurePassword;
  final bool remember;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onToggleRemember;
  final VoidCallback onLogin;

  const _FormSide({
    required this.auth, required this.emailCtl, required this.passwordCtl,
    required this.obscurePassword, required this.remember,
    required this.onTogglePassword, required this.onToggleRemember, required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width <= 768;
    final horizontalPad = isNarrow ? 24.0 : 40.0;
    final verticalPad = isNarrow ? 32.0 : 48.0;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome back', style: AppStyles.headlineLg.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          const Text('Log in to your KodiPay account', style: AppStyles.bodySm),
          const SizedBox(height: 32),
          TextField(
            controller: emailCtl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordCtl,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                onPressed: onTogglePassword,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 20, width: 20,
                    child: Checkbox(
                      value: remember,
                      onChanged: (v) => onToggleRemember(v ?? true),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Remember this device', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: const Text('Forgot Password?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : onLogin,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.kodiBlue),
              child: auth.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Log In to Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or continue with', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in coming soon'))),
              icon: Container(
                width: 20, height: 20, alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(4)),
                child: const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Don't have an account yet?", style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Register', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('SECURE & ENCRYPTED', style: TextStyle(fontSize: 12, color: AppColors.muted, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security_outlined, size: 14, color: AppColors.kodiGreen.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  const Text('SSL', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: AppColors.kodiGreen.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  const Text('PCI DSS', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security_outlined, size: 14, color: AppColors.kodiGreen.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  const Text('256-bit', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
