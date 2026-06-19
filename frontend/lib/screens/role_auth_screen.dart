import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_icons.dart';
import '../utils/constants.dart';
import '../widgets/animations.dart';

enum _AuthMode { login, signup }

/// Role-specific auth screen reached from onboarding. Defaults to login, with a
/// sign-up toggle and Google sign-in. Styled to match the welcome/onboarding
/// screens (photo background + dark scrim + frosted glass), themed by role.
class RoleAuthScreen extends StatefulWidget {
  const RoleAuthScreen({super.key});

  static const String _heroImage = 'assets/images/onboarding_hero.png';

  @override
  State<RoleAuthScreen> createState() => _RoleAuthScreenState();
}

class _RoleAuthScreenState extends State<RoleAuthScreen> {
  static const List<Shadow> _textShadow = [
    Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  String _role = 'tenant';
  bool _loadedRole = false;
  _AuthMode _mode = _AuthMode.login;
  bool _obscure = true;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRole) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && const ['landlord', 'tenant', 'caretaker'].contains(arg)) {
      _role = arg;
    }
    _loadedRole = true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  ({Color color, IconData icon, String label}) get _meta {
    switch (_role) {
      case 'landlord':
        return (
          color: AppColors.kodiGreen,
          icon: AppIcons.business_rounded,
          label: 'Landlord',
        );
      case 'caretaker':
        return (
          color: AppColors.kodiOrange,
          icon: AppIcons.handyman_rounded,
          label: 'Caretaker',
        );
      default:
        return (
          color: AppColors.kodiBlue,
          icon: AppIcons.home_rounded,
          label: 'Tenant',
        );
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogin() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _snack('Enter your email/phone and password.');
      return;
    }
    final ok = await context
        .read<AuthProvider>()
        .login(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else {
      _snack('Login failed. Please check your credentials.');
    }
  }

  Future<void> _handleSignup() async {
    if (_firstName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 6) {
      _snack('Enter your details and a 6+ character password.');
      return;
    }
    final ok = await context.read<AuthProvider>().register(
          firstName: _firstName.text,
          lastName: _lastName.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
          role: _role,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else {
      _snack('Registration failed. Please try again.');
    }
  }

  Future<void> _handleGoogle() async {
    final res = await context.read<AuthProvider>().loginWithGoogle(role: _role);
    if (!mounted) return;
    if (res.success) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else {
      _snack(res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final meta = _meta;
    final isLogin = _mode == _AuthMode.login;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            RoleAuthScreen._heroImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: AppColors.kodiNavy),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB3001022),
                  Color(0x80001022),
                  Color(0xD9001022),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(AppIcons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      tooltip: 'Back',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(child: _RoleHeader(meta: meta)),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: FadeSlideIn.stagger(1),
                    child: _GlassPanel(
                      child: Column(
                        children: [
                          _ModeToggle(
                            isLogin: isLogin,
                            color: meta.color,
                            onChanged: (mode) => setState(() => _mode = mode),
                          ),
                          const SizedBox(height: 18),
                          if (!isLogin) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _GlassField(
                                    controller: _firstName,
                                    label: 'First name',
                                    icon: AppIcons.person_outline_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _GlassField(
                                    controller: _lastName,
                                    label: 'Last name',
                                    icon: AppIcons.person_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          _GlassField(
                            controller: _email,
                            label: isLogin ? 'Email or phone' : 'Email',
                            icon: AppIcons.email_outlined,
                            keyboardType: isLogin
                                ? TextInputType.text
                                : TextInputType.emailAddress,
                          ),
                          if (!isLogin) ...[
                            const SizedBox(height: 12),
                            _GlassField(
                              controller: _phone,
                              label: 'Phone number',
                              icon: AppIcons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _GlassField(
                            controller: _password,
                            label: 'Password',
                            icon: AppIcons.lock_outline_rounded,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? AppIcons.visibility_outlined
                                    : AppIcons.visibility_off_outlined,
                                color: Colors.white70,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          if (isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/forgot-password'),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: meta.color,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: auth.isLoading
                                  ? null
                                  : (isLogin ? _handleLogin : _handleSignup),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(isLogin ? 'Log In' : 'Create Account'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _OrDivider(),
                          const SizedBox(height: 16),
                          _GoogleButton(
                            onPressed: auth.isLoading ? null : _handleGoogle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleHeader extends StatelessWidget {
  final ({Color color, IconData icon, String label}) meta;
  const _RoleHeader({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: meta.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: meta.color.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(meta.icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Continue as',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  shadows: _RoleAuthScreenState._textShadow,
                ),
              ),
              Text(
                meta.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  shadows: _RoleAuthScreenState._textShadow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A frosted-glass container for the auth form.
class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isLogin;
  final Color color;
  final ValueChanged<_AuthMode> onChanged;

  const _ModeToggle({
    required this.isLogin,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment('Log In', isLogin, () => onChanged(_AuthMode.login)),
          _segment('Sign Up', !isLogin, () => onChanged(_AuthMode.signup)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _GlassField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: white),
      cursorColor: white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle: const TextStyle(color: white),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: white, width: 1.4),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: Colors.white.withValues(alpha: 0.3), thickness: 1),
    );
    return Row(
      children: [
        line,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: Colors.white70)),
        ),
        line,
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        icon: const Icon(AppIcons.google, color: Color(0xFF4285F4)),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
