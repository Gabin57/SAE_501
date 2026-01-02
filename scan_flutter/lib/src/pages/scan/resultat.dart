import 'package:flutter/material.dart';
import 'package:scan_flutter/src/pages/connexion.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';
import 'package:scan_flutter/dao.class.dart';

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
  bool _isLoading = true;
  Map<String, dynamic>? _panneauData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is ResultatArguments) {
      id = args.id;
      database = args.database;
      _loadPanneauData();
    }
  }

  Future<void> _loadPanneauData() async {
    try {
      final data = await DAO.getById(database, id);
      if (mounted) {
        setState(() {
          _panneauData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement du panneau: $e');
      // Utiliser des données de test si l'API n'est pas accessible
      if (mounted) {
        setState(() {
          _panneauData = {
            'id': id,
            'name': 'Image $id',
            'description':
                'Description description description description description description description description description description description description',
            'image_url':
                'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/France_road_sign_AB4.svg/200px-France_road_sign_AB4.svg.png',
            'image_path': null,
          };
          _isLoading = false;
        });
      }
    }
  }

  void _handleAjouter() {
    // Rediriger vers la page de connexion si non connecté
    Navigator.pushNamed(context, ConnexionPage.routeName);
  }

  void _handleSupprimer() {
    // Afficher un message indiquant qu'il faut être connecté
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vous devez être connecté pour supprimer un panneau'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFB0BEC5,
      ), // Gris-bleu comme dans la maquette
      appBar: AppBar(
        backgroundColor: const Color(0xFFB0BEC5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nouveau Panneau',
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, ConnexionPage.routeName);
            },
            icon: const Icon(Icons.person_outline, color: Colors.black87),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image du panneau
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 250,
                          color: const Color(0xFFE8E8E8),
                          child: _buildPanneauImage(),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label et pourcentage
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    _panneauData?['name'] ?? 'Image $id',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '100%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Description
                            Text(
                              _panneauData?['description'] ??
                                  'Description description description description description description description description description description description description',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Boutons d'action
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Bouton Ajouter
                                _buildActionButton(
                                  icon: Icons.add,
                                  label: 'Ajouter',
                                  onPressed: _handleAjouter,
                                ),

                                // Bouton Supprimer
                                _buildActionButton(
                                  icon: Icons.delete_outline,
                                  label: 'Supprimer',
                                  onPressed: _handleSupprimer,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _buildPanneauImage() {
    final imageUrl = _panneauData?['image_url'];
    final imagePath = _panneauData?['image_path'];

    // Priorité: image_url > image_path > placeholder
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      // Vérifier si c'est un SVG
      if (imageUrl.toString().toLowerCase().endsWith('.svg')) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder();
            },
          ),
        );
      }

      // Image normale (JPG/PNG)
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
        ),
      );
    } else if (imagePath != null && imagePath.toString().isNotEmpty) {
      // Essayer d'afficher depuis le chemin local
      // Note: Sur web, cela ne fonctionnera pas, mais on essaie quand même
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Image.network(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
        ),
      );
    } else {
      return _buildImagePlaceholder();
    }
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF6D7278),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image, size: 50, color: Colors.white),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(icon, size: 24),
            onPressed: onPressed,
            color: Colors.black87,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
