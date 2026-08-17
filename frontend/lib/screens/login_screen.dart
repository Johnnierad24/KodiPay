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
    return Stack(
      children: [
        // Full-screen background hero image
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/welcome_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Dark overlay so the content stays readable
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.72),
                  Colors.black.withValues(alpha: 0.66),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),
        // Content on top
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand: logo + KodiPay + tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/kodipay_logo.png',
                          width: 44, height: 30, fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('KodiPay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Lexend')),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Secure Property Management Starts Here',
                    style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                  ),
                ),
                const SizedBox(height: 28),
                // Form (no card on narrow screens so it uses the full width)
                _FormSide(
                  auth: auth,
                  dark: true,
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
          ),
        ),
      ],
    );
  }
}

class _HeroSide extends StatelessWidget {
  const _HeroSide();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
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
            const Spacer(flex: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/kodipay_logo.png',
                width: 66, height: 44, fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Text('KodiPay', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Lexend')),
            const SizedBox(height: 8),
            Text('Secure Property Management\nStarts Here', style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.7), height: 1.4)),
            const Spacer(flex: 2),
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
  final bool dark;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onToggleRemember;
  final VoidCallback onLogin;

  const _FormSide({
    required this.auth, required this.emailCtl, required this.passwordCtl,
    required this.obscurePassword, required this.remember,
    this.dark = false,
    required this.onTogglePassword, required this.onToggleRemember, required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width <= 768;
    final isDark = dark;
    final horizontalPad = isNarrow ? 18.0 : 40.0;
    final verticalPad = isNarrow ? 16.0 : 48.0;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome back', style: AppStyles.headlineLg.copyWith(fontSize: 28, color: isDark ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 4),
          Text('Log in to your KodiPay account', style: AppStyles.bodySm.copyWith(color: isDark ? Colors.white70 : null)),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
                  Text('Remember this device', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textLight)),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: Text('Forgot Password?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : null)),
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
          Row(
            children: [
              Expanded(child: Divider(color: isDark ? Colors.white24 : AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or continue with', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.muted)),
              ),
              Expanded(child: Divider(color: isDark ? Colors.white24 : AppColors.border)),
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
              label: Text(
                'Continue with Google',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: isNarrow ? 12 : 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                backgroundColor: isDark ? Colors.white : null,
                side: isDark ? BorderSide.none : const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Don't have an account yet?", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textLight)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text('Register', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : null)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('SECURE & ENCRYPTED', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.muted, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security_outlined, size: 14, color: AppColors.kodiGreen.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Text('SSL', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.muted)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: AppColors.kodiGreen.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Text('PCI DSS', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.muted)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security_outlined, size: 14, color: AppColors.kodiGreen.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Text('256-bit', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.muted)),
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
