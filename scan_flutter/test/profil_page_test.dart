import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_flutter/src/pages/profil.dart';

void main() {
  testWidgets('ProfilPage renders and allows editing', (WidgetTester tester) async {
    // Initialize mock SharedPreferences to avoid async waits
    SharedPreferences.setMockInitialValues({
      'profile_name': '',
      'profile_email': '',
      'profile_theme': 'light',
    });

    await tester.pumpWidget(const MaterialApp(home: ProfilPage()));

    // Should display title
    expect(find.text('Profil'), findsOneWidget);

  // Initially shows edit button in the AppBar
  expect(find.byKey(const Key('profil_edit')), findsOneWidget);

  // Tap edit (AppBar IconButton)
  await tester.tap(find.byKey(const Key('profil_edit')));
    await tester.pumpAndSettle();


    // Enter name and email
    await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
    await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');

  // Now save IconButton in AppBar should be visible
  expect(find.byKey(const Key('profil_save')), findsOneWidget);

  // Save via AppBar save IconButton
  await tester.tap(find.byKey(const Key('profil_save')));
    await tester.pumpAndSettle();

    // After save, editing should be false and edit IconButton (AppBar) visible again
    expect(find.byKey(const Key('profil_edit')), findsOneWidget);
  });
}
