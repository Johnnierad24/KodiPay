import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _role = 'tenant';
  bool _loadedRouteRole = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRouteRole) return;
    final role = ModalRoute.of(context)?.settings.arguments;
    if (role is String && ['landlord', 'tenant', 'caretaker'].contains(role)) {
      _role = role;
    }
    _loadedRouteRole = true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields. Password must be at least 6 characters.')),
      );
      return;
    }

    final success = await context.read<AuthProvider>().register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _role,
      phone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Email may already be in use.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final roles = ['tenant', 'landlord', 'caretaker'];
    final roleIcons = [Icons.person_outline, Icons.business_outlined, Icons.engineering_outlined];
    final roleNames = ['Tenant', 'Landlord', 'Caretaker'];

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_outlined), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/kodipay_logo.png',
                  width: 75, height: 50, fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const Text('Create Account', style: AppStyles.heading1),
              const SizedBox(height: 4),
              const Text('Choose your role in the KodiPay ecosystem.', style: AppStyles.bodySmall),
              const SizedBox(height: 24),
              // Role chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(roles.length, (i) {
                    final selected = _role == roles[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        selected: selected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcons[i], size: 18),
                            const SizedBox(width: 6),
                            Text(roleNames[i]),
                          ],
                        ),
                        onSelected: (v) => setState(() => _role = roles[i]),
                        selectedColor: AppColors.kodiBlue.withValues(alpha: 0.12),
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.kodiBlue : AppColors.textLight),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First name'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last name'))),
                ],
              ),
              const SizedBox(height: 14),
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address')),
              const SizedBox(height: 14),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleRegister,
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                    TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
