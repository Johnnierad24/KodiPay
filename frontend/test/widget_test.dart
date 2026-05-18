import 'package:flutter_test/flutter_test.dart';
import 'package:kodipay/main.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';

void main() {
  testWidgets('Welcome to onboarding smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const KodiPayApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the welcome screen appears first.
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify that onboarding screen content is present after starting.
    expect(find.text('Managing rent made easy'), findsOneWidget);
    expect(find.text('I am a Tenant'), findsOneWidget);
    expect(find.text('I am a Landlord'), findsOneWidget);
  });
}
