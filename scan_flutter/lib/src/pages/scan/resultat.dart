import 'dart:io';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Résultat',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, ConnexionPage.routeName);
            },
            icon: const Icon(Icons.person_outline, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du panneau détecté
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: DecorationImage(
                  image: imagePath.startsWith('assets/')
                      ? AssetImage(imagePath) as ImageProvider
                      : FileImage(File(imagePath)) as ImageProvider,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // Contenu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du panneau
                  Text(
                    signName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  
                  // Pourcentage de correspondance
                  const SizedBox(height: 8),
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}% de correspondance',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  // Ligne de séparation
                  const Divider(height: 40, color: Color(0xFFE0E0E0)),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  
                  // Bouton "En savoir plus"
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Naviguer vers la page de détails complète
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5AF1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'En savoir plus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
