import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scan_flutter/src/pages/scan/resultat.dart';
import 'package:scan_flutter/src/pages/connexion.dart';
import '../mocks/mock_connexion_page.dart';

void main() {
  testWidgets("Loads arguments and displays data", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          ResultatPage.routeName: (_) => const ResultatPage(),
          ConnexionPage.routeName: (_) => const ConnexionPage(),
          MockConnexionPage.routeName: (_) => const MockConnexionPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == ResultatPage.routeName) {
            return MaterialPageRoute(
              builder: (_) => const ResultatPage(),
              settings: RouteSettings(
                name: ResultatPage.routeName,
                arguments: ResultatArguments(10, "mainDb"),
              ),
            );
          }
          return null;
        },
        initialRoute: ResultatPage.routeName,
      ),
    );

    await tester.pumpAndSettle();

    // Check that placeholder UI loads
    // With id=10, the fallback name is "Image 10"
    expect(find.text("Image 10"), findsOneWidget);
    expect(find.text("100%"), findsOneWidget);
    // "Scanné par" was removed from UI
    // expect(find.text("Scanné par : Vous"), findsOneWidget);
  });

  testWidgets("Navigates to ConnexionPage when icon pressed", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          ResultatPage.routeName: (_) => const ResultatPage(),
          ConnexionPage.routeName: (_) => const ConnexionPage(),
          MockConnexionPage.routeName: (_) => const MockConnexionPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == ResultatPage.routeName) {
            return MaterialPageRoute(
              builder: (_) => const ResultatPage(),
              settings: RouteSettings(
                name: ResultatPage.routeName,
                arguments: ResultatArguments(5, "db"),
              ),
            );
          }
          return null;
        },
        initialRoute: ResultatPage.routeName,
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outlined));
    await tester.pumpAndSettle();

    expect(find.text("Connexion"), findsAtLeastNWidgets(1));
  });
}
