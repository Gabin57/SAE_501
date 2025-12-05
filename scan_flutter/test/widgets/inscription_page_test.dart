import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scan_flutter/src/pages/connexion.dart';
import 'package:scan_flutter/src/pages/inscription.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';

void main() {
  Widget buildTestable() {
    return MaterialApp(
      initialRoute: InscriptionPage.routeName,
      routes: {
        InscriptionPage.routeName: (_) => const InscriptionPage(),
        ConnexionPage.routeName: (_) => const Placeholder(),
      },
    );
  }

  testWidgets('InscriptionPage displays all fields', (tester) async {
    await tester.pumpWidget(buildTestable());

    expect(find.text('Inscription'), findsAtLeastNWidgets(2)); 
    expect(find.text('Adresse mail'), findsOneWidget);
    expect(find.text('Identifiant'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);

    expect(find.byType(TextField), findsNWidgets(3));
  });

  testWidgets('Password visibility toggles', (tester) async {
    await tester.pumpWidget(buildTestable());

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('Connexion button navigates correctly', (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Connexion'));
    await tester.pumpAndSettle();

    expect(find.byType(Placeholder), findsOneWidget);
  });

  testWidgets('Bottom navigation bar exists', (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomNavigation), findsOneWidget);
  });
}
