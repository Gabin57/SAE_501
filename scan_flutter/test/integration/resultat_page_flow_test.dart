import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scan_flutter/src/pages/scan/resultat.dart';
import 'package:scan_flutter/src/pages/connexion.dart';
import '../mocks/mock_connexion_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Full navigation flow into ResultatPage",
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          ResultatPage.routeName: (_) => const ResultatPage(),
          ConnexionPage.routeName: (_) => const ConnexionPage(),
          MockConnexionPage.routeName: (_) => const MockConnexionPage(),
        },
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (_) => Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            ResultatPage.routeName,
                            arguments: ResultatArguments(99, "main"),
                          );
                        },
                        child: const Text("Go"),
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return null;
        },
      ),
    );

    await tester.pumpAndSettle();

    // Go to ResultatPage
    await tester.tap(find.text("Go"));
    await tester.pumpAndSettle();

    expect(find.text("Capture tutoriel"), findsOneWidget);
    expect(find.text("100%"), findsOneWidget);

    // Navigate to connexion
    await tester.tap(find.byIcon(Icons.person_outlined));
    await tester.pumpAndSettle();

    expect(find.text("Connexion"), findsAtLeastNWidgets(1));
  });
}
