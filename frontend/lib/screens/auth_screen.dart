import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

const Map<String, ({String label, IconData icon, Color color})> roleMeta = {
  'landlord': (label: 'Landlord', icon: Icons.business_rounded, color: AppColors.kodiGreen),
  'tenant': (label: 'Tenant', icon: Icons.home_rounded, color: AppColors.kodiBlue),
  'caretaker': (label: 'Caretaker', icon: Icons.handyman_rounded, color: AppColors.kodiOrange),
};

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String? _role;
  bool _loadedRouteRole = false;

  bool _isSignUp = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRouteRole) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && roleMeta.containsKey(arg)) {
      _role = arg;
    }
    _loadedRouteRole = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Role display metadata; mirrors the onboarding screen.
  Color get _accent => _role != null ? roleMeta[_role]!.color : AppColors.kodiBlue;

  Future<void> _handleLogin() async {
    final success = await context.read<AuthProvider>().login(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      _showSnack('Login failed. Please check your credentials.');
    }
  }

  Future<void> _handleSignUp() async {
    if (_role == null) {
      _showSnack('Please choose your role to continue.');
      return;
    }
    if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty || _passwordController.text.length < 6) {
      _showSnack('Enter your details and a 6+ character password.');
      return;
    }
    final success = await context.read<AuthProvider>().register(
      firstName: _firstNameController.text, lastName: _lastNameController.text,
      email: _emailController.text, phone: _phoneController.text,
      password: _passwordController.text, role: _role!,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      _showSnack('Registration failed. Please try again.');
    }
  }

  void _handleGoogle() {
    _showSnack('Google sign-in is coming soon.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return isWide ? _wideLayout(auth) : _narrowLayout(auth);
        },
      ),
    );
  }

  Widget _wideLayout(AuthProvider auth) {
    return Row(
      children: [
        SizedBox(
          width: 400,
          child: _BrandSide(role: _role, onBack: () => Navigator.pop(context)),
        ),
        Expanded(
          child: _FormSide(
            isSignUp: _isSignUp,
            onToggle: () => setState(() => _isSignUp = !_isSignUp),
            role: _role,
            accent: _accent,
            auth: auth,
            emailCtl: _emailController,
            passwordCtl: _passwordController,
            firstNameCtl: _firstNameController,
            lastNameCtl: _lastNameController,
            phoneCtl: _phoneController,
            obscurePassword: _obscurePassword,
            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
            onLogin: _handleLogin,
            onSignUp: _handleSignUp,
            onGoogle: _handleGoogle,
            onRoleChanged: (r) => setState(() => _role = r),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout(AuthProvider auth) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _BrandSide(role: _role, compact: true, onBack: () => Navigator.pop(context)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _FormSide(
              isSignUp: _isSignUp,
              onToggle: () => setState(() => _isSignUp = !_isSignUp),
              role: _role,
              accent: _accent,
              auth: auth,
              emailCtl: _emailController,
              passwordCtl: _passwordController,
              firstNameCtl: _firstNameController,
              lastNameCtl: _lastNameController,
              phoneCtl: _phoneController,
              obscurePassword: _obscurePassword,
              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
              onLogin: _handleLogin,
              onSignUp: _handleSignUp,
              onGoogle: _handleGoogle,
              onRoleChanged: (r) => setState(() => _role = r),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandSide extends StatelessWidget {
  final String? role;
  final bool compact;
  final VoidCallback onBack;

  const _BrandSide({this.role, this.compact = false, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 260 : double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF041627), Color(0xFF001A33)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Spacer(flex: compact ? 1 : 2),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('K', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.kodiGreen))),
          ),
          const SizedBox(height: 16),
          Text('KodiPay', style: TextStyle(fontSize: compact ? 22 : 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Lexend')),
          const SizedBox(height: 6),
          Text('Pay Rent. Stay Worry-Free.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: compact ? 13 : 15)),
          if (role != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleMeta[role]!.icon, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(roleMeta[role]!.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ],
          if (!compact) ...[
            const Spacer(),
            Row(
              children: [
                _trustBadge(Icons.security_outlined, 'SSL'),
                const SizedBox(width: 16),
                _trustBadge(Icons.verified_user_outlined, 'PCI DSS'),
                const SizedBox(width: 16),
                _trustBadge(Icons.security_outlined, '256-bit'),
              ],
            ),
          ],
          SizedBox(height: compact ? 0 : 16),
        ],
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.kodiGreen.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF8192A7))),
      ],
    );
  }
}

class _FormSide extends StatelessWidget {
  final bool isSignUp;
  final VoidCallback onToggle;
  final String? role;
  final Color accent;
  final AuthProvider auth;
  final TextEditingController emailCtl;
  final TextEditingController passwordCtl;
  final TextEditingController firstNameCtl;
  final TextEditingController lastNameCtl;
  final TextEditingController phoneCtl;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  final VoidCallback onGoogle;
  final ValueChanged<String> onRoleChanged;

  const _FormSide({
    required this.isSignUp, required this.onToggle, required this.role, required this.accent,
    required this.auth, required this.emailCtl, required this.passwordCtl,
    required this.firstNameCtl, required this.lastNameCtl, required this.phoneCtl,
    required this.obscurePassword, required this.onTogglePassword,
    required this.onLogin, required this.onSignUp, required this.onGoogle, required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isSignUp ? 'Create Account' : 'Welcome Back', style: AppStyles.headlineLg),
          const SizedBox(height: 6),
          Text(isSignUp ? 'Set up your KodiPay profile to get started.' : 'Log in to manage rent, tasks, and payments.',
              style: AppStyles.bodyMedium),
          const SizedBox(height: 24),
          _ToggleTab(isSignUp: isSignUp, onToggle: onToggle, accent: accent),
          const SizedBox(height: 24),
          if (isSignUp && role == null) _buildRolePicker(),
          if (isSignUp) ...[
            _TextField(controller: firstNameCtl, label: 'First Name', icon: Icons.person_outline_rounded),
            const SizedBox(height: 14),
            _TextField(controller: lastNameCtl, label: 'Last Name', icon: Icons.person_outline_rounded),
            const SizedBox(height: 14),
            _TextField(controller: emailCtl, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _TextField(controller: phoneCtl, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          ] else ...[
            _TextField(controller: emailCtl, label: 'Email or Phone', icon: Icons.email_outlined),
          ],
          const SizedBox(height: 14),
          _TextField(
            controller: passwordCtl, label: 'Password', icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword, suffix: _PasswordToggle(obscure: obscurePassword, onTap: onTogglePassword),
          ),
          if (!isSignUp) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                style: TextButton.styleFrom(foregroundColor: AppColors.kodiBlue),
                child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : (isSignUp ? onSignUp : onLogin),
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: auth.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isSignUp ? 'Create Account' : 'Login', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          if (isSignUp) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: onToggle,
                child: const Text('Already have an account? Log in', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or continue with', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onGoogle,
              icon: Container(
                width: 20, height: 20, alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(4)),
                child: const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 13, color: AppColors.kodiGreen),
                const SizedBox(width: 6),
                Text('Secured with end-to-end encryption', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRolePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('I am a', style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
        const SizedBox(height: 8),
        Row(
          children: roleMeta.entries.map((entry) {
            final selected = role == entry.key;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onRoleChanged(entry.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? entry.value.color.withValues(alpha: 0.1) : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? entry.value.color : AppColors.border, width: selected ? 1.5 : 1),
                    ),
                    child: Column(
                      children: [
                        Icon(entry.value.icon, color: selected ? entry.value.color : AppColors.textLight, size: 20),
                        const SizedBox(height: 4),
                        Text(entry.value.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? entry.value.color : AppColors.textLight)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final bool isSignUp;
  final VoidCallback onToggle;
  final Color accent;
  const _ToggleTab({required this.isSignUp, required this.onToggle, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(child: _Tab(label: 'Log In', selected: !isSignUp, accent: accent, onTap: () { if (isSignUp) onToggle(); })),
          Expanded(child: _Tab(label: 'Sign Up', selected: isSignUp, accent: accent, onTap: () { if (!isSignUp) onToggle(); })),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textLight, fontSize: 13)),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  const _TextField({required this.controller, required this.label, required this.icon, this.obscureText = false, this.keyboardType, this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}

class _PasswordToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _PasswordToggle({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
      onPressed: onTap,
    );
  }
}
