import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:scan_flutter/src/pages/inscription.dart';
import 'package:scan_flutter/src/pages/connexion.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp() {
    return MaterialApp(
      initialRoute: InscriptionPage.routeName,
      routes: {
        InscriptionPage.routeName: (_) => const InscriptionPage(),
        ConnexionPage.routeName: (_) => const Placeholder(),
      },
    );
  }

  testWidgets('Full inscription -> connexion flow', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Enter email
    await tester.enterText(
        find.widgetWithText(TextField, 'Votre adresse mail'),
        'test@example.com');

    // Enter identifiant
    await tester.enterText(
        find.widgetWithText(TextField, 'Votre identifiant'),
        'monId');

    // Enter password
    await tester.enterText(
        find.widgetWithText(TextField, 'Votre mot de passe'),
        'secret123');

    // Press Connexion
    await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
    await tester.pumpAndSettle();

    // Should navigate to ConnexionPage (placeholder for test)
    expect(find.byType(Placeholder), findsOneWidget);
  });
}
