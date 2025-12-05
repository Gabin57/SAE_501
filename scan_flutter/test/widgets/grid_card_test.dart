import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scan_flutter/src/pages/accueil.dart';

void main() {
  group('GridCard - unit tests', () {
    testWidgets('renders title correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GridCard(
              title: 'Test Title',
              tileColor: Colors.white,
              labelColor: Colors.black,
              labelBg: Colors.grey,
              placeholderBg: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders placeholder when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GridCard(
              title: 'Placeholder',
              tileColor: Colors.white,
              labelColor: Colors.black,
              labelBg: Colors.grey,
              placeholderBg: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridCard(
              title: 'Tap Test',
              tileColor: Colors.white,
              labelColor: Colors.black,
              labelBg: Colors.grey,
              placeholderBg: Colors.blue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });
  });
}
