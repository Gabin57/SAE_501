import 'package:flutter/material.dart';
import 'package:scan_flutter/src/pages/connexion.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';

class ResultatArguments {
  final int id;
  final String database;
  ResultatArguments(this.id, this.database);
}


class ResultatPage extends StatefulWidget {
  static const routeName = '/resultat';

  const ResultatPage({super.key});

  @override
  State<ResultatPage> createState() => _ResultatPageState();
}

class _ResultatPageState extends State<ResultatPage> {
  late int id;
  late String database;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)!.settings.arguments as ResultatArguments;

    id = args.id;
    database = args.database;

    // Load data here (not in build)
    _getDonnees();
  }

  List<List<Map<String, String>>> donnes = [];

  void _getDonnees() {
    // TODO: Charger les données depuis la BDD
    print("Changement des données de la capture $id depuis la base de données $database");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Détails"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, ConnexionPage.routeName);
              },
              icon: const Icon(Icons.person_outlined)),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Text("ID reçu : $id"),
            Text("DB reçue : $database"),

            const SizedBox(height: 20),

            // Placeholder before you build real UI
            Expanded(
              child: ListView(
                children: [
                  Text("Vos données seront affichées ici."),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}
