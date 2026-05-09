import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/tenant_dashboard.dart';
import 'screens/landlord_dashboard.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const KodiPayApp(),
    ),
  );
}

class KodiPayApp extends StatelessWidget {
  const KodiPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KodiPay',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isAuthenticated) {
      if (auth.user?.role == 'landlord') {
        return const LandlordDashboard();
      } else {
        return const TenantDashboard();
      }
    }

    return const OnboardingScreen();
  }
}
