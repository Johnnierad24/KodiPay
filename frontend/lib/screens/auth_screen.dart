import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

/// Role-aware authentication screen reached after a user picks their role on
/// the onboarding screen. Defaults to the login view, with a toggle to sign up
/// and a (currently UI-only) "Continue with Google" option. The chosen role is
/// carried in via route arguments and locked in for sign-up; login is
/// role-agnostic (the backend is the source of truth for an account's role).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const String _backgroundAsset = 'assets/images/welcome_bg.jpg';

  // null until route arguments are read; once read, may still be null when the
  // user arrived via the generic "Already have an account?" link (no role).
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
    if (arg is String && _roleMeta.containsKey(arg)) {
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
  static const Map<String, ({String label, IconData icon, Color color})>
      _roleMeta = {
    'landlord': (
      label: 'Landlord',
      icon: Icons.business_rounded,
      color: AppColors.kodiGreen,
    ),
    'tenant': (
      label: 'Tenant',
      icon: Icons.home_rounded,
      color: AppColors.kodiBlue,
    ),
    'caretaker': (
      label: 'Caretaker',
      icon: Icons.handyman_rounded,
      color: AppColors.kodiOrange,
    ),
  };

  Color get _accent =>
      _role != null ? _roleMeta[_role]!.color : AppColors.kodiBlue;

  Future<void> _handleLogin() async {
    final success = await context.read<AuthProvider>().login(
          _emailController.text.trim(),
          _passwordController.text,
        );
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
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.length < 6) {
      _showSnack('Enter your details and a 6+ character password.');
      return;
    }

    final success = await context.read<AuthProvider>().register(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          role: _role!,
        );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      _showSnack('Registration failed. Please try again.');
    }
  }

  void _handleGoogle() {
    // Google sign-in is intentionally UI-only for now. The backend /auth/google
    // endpoint and OAuth credentials are a separate follow-up task.
    _showSnack('Google sign-in is coming soon.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final media = MediaQuery.of(context);
    final headerHeight = media.size.height * 0.30;
    const topBarHeight = 56.0;
    // Force the white sheet to reach the bottom of the screen so the background
    // photo never peeks through below the form.
    final sheetMinHeight = media.size.height -
        media.padding.top -
        topBarHeight -
        headerHeight;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed branded background (matches the welcome screen).
          Image.asset(
            _backgroundAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.kodiBlue, AppColors.kodiNavy],
                ),
              ),
            ),
          ),
          // Scrim so the header text stays legible over the photo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66001220), Color(0x99001220)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: media.size.height - media.padding.top,
                ),
                child: Column(
                  children: [
                    SizedBox(height: topBarHeight, child: _buildTopBar()),
                    SizedBox(
                      height: headerHeight,
                      child: _buildHeader(),
                    ),
                    _buildSheet(auth, sheetMinHeight),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    final meta = _role != null ? _roleMeta[_role] : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meta != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(meta.icon, color: AppColors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    meta.label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Text(
            _isSignUp ? 'Create your account' : 'Welcome back',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isSignUp
                ? 'Set up your KodiPay profile to get started.'
                : 'Log in to manage rent, tasks, and payments.',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheet(AuthProvider auth, double minHeight) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToggle(),
          const SizedBox(height: 22),
          if (_isSignUp && _role == null) ...[
            _buildRolePicker(),
            const SizedBox(height: 16),
          ],
          if (_isSignUp) ..._buildSignUpFields() else ..._buildLoginFields(),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              onPressed: auth.isLoading
                  ? null
                  : (_isSignUp ? _handleSignUp : _handleLogin),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(_isSignUp ? 'Create Account' : 'Login'),
            ),
          ),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildGoogleButton(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _toggleTab('Log In', !_isSignUp, () {
            if (_isSignUp) setState(() => _isSignUp = false);
          }),
          _toggleTab('Sign Up', _isSignUp, () {
            if (!_isSignUp) setState(() => _isSignUp = true);
          }),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.white : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLoginFields() {
    return [
      _AuthField(
        controller: _emailController,
        label: 'Email or Phone',
        icon: Icons.email_outlined,
      ),
      const SizedBox(height: 14),
      _AuthField(
        controller: _passwordController,
        label: 'Password',
        icon: Icons.lock_outline_rounded,
        obscureText: _obscurePassword,
        suffixIcon: _passwordToggle(),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
          child: const Text('Forgot Password?'),
        ),
      ),
    ];
  }

  List<Widget> _buildSignUpFields() {
    return [
      Row(
        children: [
          Expanded(
            child: _AuthField(
              controller: _firstNameController,
              label: 'First Name',
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AuthField(
              controller: _lastNameController,
              label: 'Last Name',
              icon: Icons.person_outline_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _AuthField(
        controller: _emailController,
        label: 'Email',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 14),
      _AuthField(
        controller: _phoneController,
        label: 'Phone Number',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 14),
      _AuthField(
        controller: _passwordController,
        label: 'Password',
        icon: Icons.lock_outline_rounded,
        obscureText: _obscurePassword,
        suffixIcon: _passwordToggle(),
      ),
    ];
  }

  Widget _passwordToggle() {
    return IconButton(
      icon: Icon(
        _obscurePassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: AppColors.muted,
      ),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );
  }

  // Compact role picker, only shown when the user reached this screen without
  // a role (via the "Already have an account?" link) and switched to Sign Up.
  Widget _buildRolePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('I am a', style: AppStyles.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: _roleMeta.entries.map((entry) {
            final selected = _role == entry.key;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _role = entry.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? entry.value.color.withValues(alpha: 0.1)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? entry.value.color : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(entry.value.icon,
                            color: entry.value.color, size: 22),
                        const SizedBox(height: 6),
                        Text(
                          entry.value.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? entry.value.color
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or continue with', style: AppStyles.caption),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _handleGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const _GoogleLogo(),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Lightweight Google "G" mark placeholder until the official asset is wired in
/// alongside the real OAuth flow.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.muted),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
