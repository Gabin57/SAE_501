import 'package:flutter/material.dart';
import 'package:scan_flutter/src/pages/profil.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  final String title = "Accueil";

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  List<List<Map<String, String>>> donnes = [];

  ListView _afficheDonnee() {
    setState(() {
      var donneesAAfficher = _getDonnees();
    });
    return ListView();
  }

  void _getDonnees() {}

  /* void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  } */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const ProfilPage(),
                  ),
                );
              }, // TO DO : Modifier le système pour gérer l'affichage de l'overlay des filtres
              icon: Icon(Icons.sort_outlined)),
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const ProfilPage(),
                  ),
                );
              },
              icon: Icon(Icons.person_outlined)),
        ],
      ),
      body: Center(
        child: Column(
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // TO DO : BARRE DE RECHERCHE ?
            _afficheDonnee()

            /* Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ), */
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined)),
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined)),
        BottomNavigationBarItem(icon: Icon(Icons.explore_outlined)),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz_outlined)),
      ]),
      /* floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), */ // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
