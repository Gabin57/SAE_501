import 'package:flutter/material.dart';

class MockConnexionPage extends StatelessWidget {
  static const routeName = '/connexion';

  const MockConnexionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Mock Connexion")));
  }
}
