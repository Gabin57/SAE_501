import 'package:flutter/material.dart';
import 'package:scan_flutter/src/pages/connexion.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';

class ResultatArguments {
  final int id;
  final String database;
  final String imagePath;
  final String signName;
  final double confidence;
  final String description;

  ResultatArguments(
    this.id,
    this.database, {
    required this.imagePath,
    required this.signName,
    required this.confidence,
    required this.description,
  });
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
  late String imagePath;
  late String signName;
  late double confidence;
  late String description;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)!.settings.arguments as ResultatArguments;

    id = args.id;
    database = args.database;
    imagePath = args.imagePath;
    signName = args.signName;
    confidence = args.confidence;
    description = args.description;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2B47),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Résultat',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, ConnexionPage.routeName);
            },
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image du panneau détecté
            Container(
              height: 250,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath), // Utiliser FileImage pour les images du téléphone
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Contenu
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du panneau
                  Text(
                    signName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // Pourcentage de correspondance
                  const SizedBox(height: 8),
                  Text(
                    '${(confidence * 100).toStringAsFixed(1)}% de correspondance',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  // Description
                  const SizedBox(height: 30),
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  
                  // Bouton "En savoir plus"
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Naviguer vers la page de détails complète
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5AF1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'En savoir plus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
