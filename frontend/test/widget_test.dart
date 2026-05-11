import 'package:flutter_test/flutter_test.dart';
import 'package:kodipay/main.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';

void main() {
  testWidgets('Onboarding screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const KodiPayApp(),
      ),
    );

    // Verify that onboarding screen content is present.
    expect(find.text('Managing rent made easy'), findsOneWidget);
    expect(find.text('I am a Tenant'), findsOneWidget);
    expect(find.text('I am a Landlord'), findsOneWidget);
  });
}
