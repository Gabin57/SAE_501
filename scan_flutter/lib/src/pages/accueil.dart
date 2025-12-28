import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:scan_flutter/src/pages/connexion.dart';
import 'package:scan_flutter/src/pages/connecte/profil.dart';
import 'package:scan_flutter/src/pages/scan/resultat.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/widgets/search_bar.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';
import 'package:scan_flutter/src/services/local_profile_service.dart';
import '../../dao.class.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});
  static const routeName = '/';

  final String title = "Accueil";

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  List<List<Map<String, String>>> donnes = [];
  List<Map<String, dynamic>> _panneaux = [];
  bool _isLoading = true;

  // Palette et tailles centralisées
  static const _appBarBg = AppColors.appBarBg;
  static const _tileBg = AppColors.tileBg;
  static const _iconMuted = AppColors.iconMuted;
  static const _labelBg = AppColors.labelBg;
  static const _placeholderBg = AppColors.placeholderBg;
  static const _textDark = AppColors.textDark;

  @override
  void initState() {
    super.initState();
    _loadPanneaux();
  }

  Future<void> _loadPanneaux() async {
    try {
      // Ajouter un timeout pour éviter que l'application reste bloquée
      final panneaux = await DAO.getAll('panneaux')
          .timeout(const Duration(seconds: 10));
      
      if (mounted) {
        setState(() {
          _panneaux = List<Map<String, dynamic>>.from(panneaux);
          _isLoading = false;
        });
      }
    } catch (e) {
      // En cas d'erreur, continuer avec une liste vide plutôt que de bloquer l'application
      if (mounted) {
        setState(() {
          _panneaux = []; // Liste vide si l'API n'est pas disponible
          _isLoading = false;
        });
        
        // Afficher un message d'erreur moins intrusif
        final errorMessage = e.toString().contains('Failed to fetch') || 
                            e.toString().contains('ClientException')
            ? 'Impossible de se connecter à l\'API. Vérifiez votre connexion réseau.'
            : 'Erreur lors du chargement des panneaux: ${e.toString().split(':').last.trim()}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: _loadPanneaux,
            ),
          ),
        );
      }
    }
  }

  List<Widget> _buildGridItems() {
    final items = <Widget>[];
    
    // Ajouter la carte tutoriel en premier
    items.add(
      GridCard(
        title: 'Tutoriel',
        imageUrl:
            'https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=640',
        tileColor: _tileBg,
        labelColor: _iconMuted,
        labelBg: _labelBg,
        placeholderBg: _placeholderBg,
        onTap: () {
          Navigator.pushNamed(
            context,
            ResultatPage.routeName,
            arguments: ResultatArguments(0, "panneaux"),
          );
        },
      ),
    );

    // Ajouter les panneaux chargés depuis la base de données
    for (final panneau in _panneaux) {
      final panneauId = panneau['id'] ?? panneau['num'];
      final panneauName = panneau['name'] ?? panneau['nom'] ?? 'Panneau';
      final imageUrl = panneau['image_url'];
      final imagePath = panneau['image_path'];
      
      items.add(
        GridCard(
          title: panneauName,
          imageUrl: imageUrl,
          imagePath: imagePath,
          tileColor: _tileBg,
          labelColor: _iconMuted,
          labelBg: _labelBg,
          placeholderBg: _placeholderBg,
          onTap: () {
            Navigator.pushNamed(
              context,
              ResultatPage.routeName,
              arguments: ResultatArguments(panneauId, "panneaux"),
            );
          },
        ),
      );
    }

    return items;
  }

  // Réservé pour les futures données

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
        backgroundColor: _appBarBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textDark,
        iconTheme: const IconThemeData(color: _textDark),
        automaticallyImplyLeading: false,
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: _textDark),
        title: const Text('Code des Panneaux'),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              // Vérifier si l'utilisateur est authentifié
              final profile = await LocalProfileService.getProfile();
              final isAuthenticated = profile['name'] != null && profile['name']!.isNotEmpty;
              
              if (!mounted) return;
              
              // Naviguer vers la page appropriée
              if (isAuthenticated) {
                Navigator.pushNamed(context, ProfilPage.routeName);
              } else {
                Navigator.pushNamed(context, ConnexionPage.routeName);
              }
            },
            iconSize: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            icon: const Icon(Icons.person_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Barre de recherche qui défile avec le contenu
                SliverToBoxAdapter(
                  child: CustomSearchBar(
                    onSubmitted: (value) {
                      // TODO: brancher la logique de recherche
                    },
                  ),
                ),
                // Grille de cartes
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildListDelegate(_buildGridItems()),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNavigation(),
      /* floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), */
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// Anciennes versions remplacées par _GridCard

// Rendu public pour les tests
class GridCard extends StatelessWidget {
  const GridCard({
    required this.title,
    required this.tileColor,
    required this.labelColor,
    required this.labelBg,
    required this.placeholderBg,
    this.imageUrl,
    this.imagePath,
    this.onTap,
  });

  final String title;
  final Color tileColor;
  final Color labelColor;
  final Color labelBg;
  final Color placeholderBg;
  final String? imageUrl;
  final String? imagePath;
  final VoidCallback? onTap;

  Widget _buildImage() {
    // Sur Web, on ne peut pas utiliser File(), on doit utiliser l'URL réseau
    // Si on n'est pas sur le web et qu'on a un chemin local, on l'utilise
    if (!kIsWeb && imagePath != null) {
      // Afficher l'image depuis le chemin local (fichier système)
      final file = File(imagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          ),
        );
      } else {
        return _buildPlaceholder();
      }
    } else if (imageUrl != null) {
      // Vérifier si c'est un SVG
      if (imageUrl!.toLowerCase().endsWith('.svg')) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Padding pour ne pas toucher les bords
            child: SvgPicture.network(
              imageUrl!,
              fit: BoxFit.contain, // Ajuster pour voir le panneau entier
              width: double.infinity,
              placeholderBuilder: (BuildContext context) => _buildPlaceholder(),
            ),
          ),
        );
      }
      
      // Afficher l'image depuis l'URL (JPG/PNG/etc)
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.network(
            imageUrl!,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          ),
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: placeholderBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 28,
          color: labelColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildImage(),
              ),
              Container(
                height: 36,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: labelColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
