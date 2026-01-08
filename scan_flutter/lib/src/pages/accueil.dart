import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:scan_flutter/src/pages/scan/resultat.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/widgets/custom_app_bar.dart';
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
  String _searchQuery = '';
  bool _isAuthenticated = false;
  int? _currentUserId;

  // Getter for filtered panels based on search query
  List<Map<String, dynamic>> get _filteredPanneaux {
    // Return empty list if panels haven't loaded yet
    if (_panneaux.isEmpty) {
      return [];
    }

    if (_searchQuery.isEmpty) {
      return _panneaux;
    }

    return _panneaux.where((panneau) {
      final name = (panneau['name'] ?? '').toString().toLowerCase();
      final description = (panneau['description'] ?? '')
          .toString()
          .toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || description.contains(query);
    }).toList();
  }

  // Palette et tailles centralisées
  static const _tileBg = AppColors.tileBg;
  static const _iconMuted = AppColors.iconMuted;
  static const _labelBg = AppColors.labelBg;
  static const _placeholderBg = AppColors.placeholderBg;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadPanneaux();
  }

  Future<void> _checkAuthAndLoadPanneaux() async {
    // Check authentication
    final profile = await LocalProfileService.getProfile();
    print('📋 Profile data: $profile');

    final isAuth = profile['name'] != null && profile['name']!.isNotEmpty;
    final userId =
        profile['num'] as int?; // Using 'num' as user ID from COMPTES table

    print('🔐 Authentication status: $isAuth, User ID: $userId');

    setState(() {
      _isAuthenticated = isAuth;
      _currentUserId = userId;
    });

    await _loadPanneaux();
  }

  Future<void> _loadPanneaux() async {
    try {
      List<Map<String, dynamic>> panneauxToDisplay;

      if (_isAuthenticated && _currentUserId != null) {
        // Get user's panels via LIAISONS_PANNEAUX
        print(
          '🔐 User authenticated, loading user panels only (ID: $_currentUserId)',
        );

        // Get all liaisons for this user
        final liaisons = List<Map<String, dynamic>>.from(
          await DAO.getAll('liaisons_panneaux'),
        );

        print('📊 Total liaisons in database: ${liaisons.length}');
        if (liaisons.isNotEmpty) {
          print('📊 Sample liaison: ${liaisons.first}');
        }

        // Filter liaisons for current user
        final userLiaisons = liaisons
            .where((l) => l['id_compte'] == _currentUserId)
            .toList();

        print('👤 User liaisons found: ${userLiaisons.length}');
        if (userLiaisons.isNotEmpty) {
          print('👤 Sample user liaison: ${userLiaisons.first}');
        }

        // Get panel IDs
        final panelIds = userLiaisons.map((l) => l['id_panneau']).toSet();

        print('🆔 Panel IDs for user: $panelIds');

        if (panelIds.isEmpty) {
          print('ℹ️ No panels found for user');
          panneauxToDisplay = [];
        } else {
          // Get all panels and filter by user's panel IDs
          final allPanneaux = List<Map<String, dynamic>>.from(
            await DAO.getAll('panneaux'),
          );
          panneauxToDisplay = allPanneaux
              .where((p) => panelIds.contains(p['id'] ?? p['num']))
              .toList();
          print('✅ Loaded ${panneauxToDisplay.length} user panels');
        }
      } else {
        // Not authenticated: show all panels
        print('🌐 User not authenticated, loading all panels');
        panneauxToDisplay = List<Map<String, dynamic>>.from(
          await DAO.getAll('panneaux').timeout(const Duration(seconds: 10)),
        );
      }

      if (mounted) {
        setState(() {
          _panneaux = List<Map<String, dynamic>>.from(panneauxToDisplay);
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
        final errorMessage =
            e.toString().contains('Failed to fetch') ||
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

    // Ajouter les panneaux chargés depuis la base de données (filtrés par recherche)
    for (final panneau in _filteredPanneaux) {
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
              arguments: ResultatArguments(
                panneauId,
                "panneaux",
                showActions:
                    false, // Don't show buttons when navigating from home
              ),
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
      appBar: const CustomAppBar(title: 'Code des Panneaux'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Barre de recherche qui défile avec le contenu
                SliverToBoxAdapter(
                  child: CustomSearchBar(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onSubmitted: (value) {
                      // Search is already handled by onChanged
                      // This just unfocuses the keyboard
                    },
                  ),
                ),
                // Empty state when search returns no results
                if (_filteredPanneaux.isEmpty && _searchQuery.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.iconMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun panneau trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'pour "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Grille de cartes
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
            padding: const EdgeInsets.all(
              16.0,
            ), // Padding pour ne pas toucher les bords
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
        child: Icon(Icons.image_outlined, size: 28, color: labelColor),
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
              Expanded(child: _buildImage()),
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
