import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_work_rounded, size: 100, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'Welcome to KodiPay',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Simplifying rental management for everyone. Choose your role to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              _buildRoleButton(
                context,
                'I am a Tenant',
                Icons.person_pin_rounded,
                Colors.blue
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                'I am a Landlord',
                Icons.business_center_rounded,
                Colors.indigo
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String title, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/login'),
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
