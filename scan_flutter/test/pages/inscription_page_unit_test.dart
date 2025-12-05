import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scan_flutter/src/pages/inscription.dart';

void main() {
  group('InscriptionPage - Unit Tests', () {
    testWidgets('Password visibility toggles on icon press', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InscriptionPage(),
        ),
      );

      // Initial should show "visibility_off" icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      // Icon must change to "visibility"
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
