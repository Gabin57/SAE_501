import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:scan_flutter/src/pages/accueil.dart';
import 'package:scan_flutter/src/pages/scan/resultat.dart';
import 'package:scan_flutter/src/pages/connexion.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp() {
    return MaterialApp(
      initialRoute: AccueilPage.routeName,
      routes: {
        AccueilPage.routeName: (_) => const AccueilPage(),
        ResultatPage.routeName: (_) => const Placeholder(), // Replace with real page if needed
        ConnexionPage.routeName: (_) => const Placeholder(),
      },
    );
  }

  testWidgets('Tap grid card → navigate to ResultatPage', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final firstCard = find.byType(GridCard).first;
    await tester.tap(firstCard);
    await tester.pumpAndSettle();

    expect(find.byType(Placeholder), findsOneWidget);
  });

  testWidgets('Tap profile button → navigate to ConnexionPage', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(Placeholder), findsOneWidget);
  });
}
