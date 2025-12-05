import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scan_flutter/src/pages/profil.dart';
import '../mocks/mock_local_profile_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget createApp() {
    return MaterialApp(
      initialRoute: ProfilPage.routeName,
      routes: {
        ProfilPage.routeName: (_) => const ProfilPage(),
        '/connexion': (_) => const Placeholder(),
      },
    );
  }

  setUp(() async {
    // Initialize mock SharedPreferences to avoid MissingPluginException
    SharedPreferences.setMockInitialValues({
      'profile_name': 'Alice',
      'profile_email': 'alice@example.com',
      'profile_theme': 'system',
    });
    
    MockLocalProfileService.setMockData({
      'name': 'Alice',
      'email': 'alice@example.com',
      'theme': 'system',
    });
  });

  tearDown(() {
    MockLocalProfileService.clear();
  });

  testWidgets('Full profile edit -> save -> logout flow', (tester) async {
    await tester.pumpWidget(createApp());
    await tester.pumpAndSettle();

    // Enter edit mode
    await tester.tap(find.byKey(const Key('profil_edit')));
    await tester.pumpAndSettle();

    // Edit email - find the email field (second TextFormField)
    final emailFields = find.byType(TextFormField);
    expect(emailFields, findsNWidgets(2)); // Name and Email fields
    await tester.enterText(emailFields.at(1), 'new@example.com'); // Email is the second field
    await tester.pump();

    // Save
    await tester.tap(find.byKey(const Key('profil_save')));
    await tester.pumpAndSettle();

    // Verify that SharedPreferences was updated (the actual service used)
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile_email'), 'new@example.com');

    // Logout
    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();

    expect(find.byType(Placeholder), findsOneWidget);
  });
}
