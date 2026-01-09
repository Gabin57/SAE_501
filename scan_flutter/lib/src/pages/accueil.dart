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
  List<Map<String, dynamic>> _categories = []; // New categories list
  String? _selectedCategory; // Selected category for filter
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload panels when returning to this page
    // Skip first load (when _panneaux is empty and _isLoading is true)
    if (!_isLoading) {
      _loadPanneaux();
    }
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
      if (_isAuthenticated && _currentUserId != null) {
        // ... (Existing Authenticated Logic - unchanged for now, or minimal update) ...
        // Keeping the existing logic for authenticated user to assume they want to see their history
        // If we want categories here too, we'd need client-side filtering or new API

        // Get user's panels via LIAISONS_PANNEAUX
        print(
          '🔐 User authenticated, loading user panels only (ID: $_currentUserId)',
        );

        // Get all liaisons for this user
        final liaisons = List<Map<String, dynamic>>.from(
          await DAO.getAll('liaisons_panneaux'),
        );

        // Filter liaisons for current user
        final userLiaisons = liaisons
            .where((l) => l['id_compte'] == _currentUserId)
            .toList();

        // Get panel IDs
        final panelIds = userLiaisons.map((l) => l['id_panneau']).toSet();

        List<Map<String, dynamic>> userPanneaux = [];
        if (panelIds.isNotEmpty) {
          final allPanneaux = List<Map<String, dynamic>>.from(
            await DAO.getAll('panneaux'),
          );
          userPanneaux = allPanneaux
              .where((p) => panelIds.contains(p['id'] ?? p['num']))
              .toList();
        }

        // Sort
        userPanneaux.sort((a, b) {
          final rawIdA = a['id'] ?? a['num'];
          final rawIdB = b['id'] ?? b['num'];
          final idA = rawIdA is int
              ? rawIdA
              : int.tryParse(rawIdA?.toString() ?? '') ?? 0;
          final idB = rawIdB is int
              ? rawIdB
              : int.tryParse(rawIdB?.toString() ?? '') ?? 0;
          return idA.compareTo(idB); // Ascending order
        });

        if (mounted) {
          setState(() {
            _panneaux = userPanneaux;
            _isLoading = false;
          });
        }
      } else {
        // Not authenticated: Categories View Logic

        if (_selectedCategory == null) {
          // 1. Load Categories
          print('🌐 Loading Categories...');
          final cats = await DAO.getCategories();
          final categories = List<Map<String, dynamic>>.from(cats);

          if (mounted) {
            setState(() {
              _categories = categories;
              _panneaux = []; // Clear panels when showing categories
              _isLoading = false;
            });
          }
        } else {
          // 2. Load Panels for Selected Category
          print('🌐 Loading Panels for category: $_selectedCategory');
          final results = await DAO.getAll(
            'panneaux',
            queryParams: {'categorie': _selectedCategory!},
          );

          var categoryPanneaux = List<Map<String, dynamic>>.from(results);

          // Sort
          categoryPanneaux.sort((a, b) {
            final rawIdA = a['id'] ?? a['num'];
            final rawIdB = b['id'] ?? b['num'];
            final idA = rawIdA is int
                ? rawIdA
                : int.tryParse(rawIdA?.toString() ?? '') ?? 0;
            final idB = rawIdB is int
                ? rawIdB
                : int.tryParse(rawIdB?.toString() ?? '') ?? 0;
            return idA.compareTo(idB); // Ascending order
          });

          if (mounted) {
            setState(() {
              _panneaux = categoryPanneaux;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      // En cas d'erreur, continuer avec une liste vide
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() {
          _panneaux = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur récupération données: $e'),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: _loadPanneaux,
            ),
          ),
        );
      }
    }
  }

  // Determine effective data list for grid
  List<dynamic> get _currentDataList {
    if (!_isAuthenticated && _selectedCategory == null) {
      return _categories;
    } else {
      return _filteredPanneaux;
    }
  }

  Widget _buildGridItem(BuildContext context, int index) {
    final dataList = _currentDataList;
    if (index >= dataList.length) return const SizedBox.shrink();

    final item = dataList[index];

    // Mode Catégories
    if (!_isAuthenticated && _selectedCategory == null) {
      final category = item as Map<String, dynamic>;
      final nom = category['nom'] ?? 'Autre';
      final count = category['count'] ?? 0;
      final image = category['last_image'];

      return GridCard(
        title: "$nom ($count)",
        imageUrl: image,
        tileColor: _tileBg,
        labelColor: _iconMuted,
        labelBg: _labelBg,
        placeholderBg: _placeholderBg,
        onTap: () {
          setState(() {
            _selectedCategory = nom;
            _isLoading = true;
          });
          _loadPanneaux();
        },
      );
    }
    // Mode Panneaux
    else {
      final panneau = item as Map<String, dynamic>;
      final rawId = panneau['id'] ?? panneau['num'];
      final int? panneauId = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '');

      if (panneauId == null) return const SizedBox.shrink();

      final panneauName = panneau['name'] ?? panneau['nom'] ?? 'Panneau';
      final imageUrl = panneau['image_url'];
      final imagePath = panneau['image_path'];

      return GridCard(
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
              showActions: false,
            ),
          );
        },
        onDelete: () => _deletePanneau(panneauId, panneauName),
      );
    }
  }

  Future<void> _deletePanneau(int panneauId, String panneauName) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le panneau ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "$panneauName" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('🗑️ Starting deletion of panel $panneauId');

        // Delete liaisons first
        final liaisons = await DAO.getAll('liaisons_panneaux');
        final panneauLiaisons = liaisons.where(
          (l) => l['id_panneau'] == panneauId,
        );

        print('🔗 Found ${panneauLiaisons.length} liaisons to delete');
        for (final liaison in panneauLiaisons) {
          print('🗑️ Deleting liaison ${liaison['num']}');
          await DAO.delete('liaisons_panneaux', liaison['num']);
        }

        // Delete panel
        print('🗑️ Deleting panel $panneauId');
        await DAO.delete('panneaux', panneauId);
        print('✅ Panel deleted successfully');

        // Reload panels
        await _loadPanneaux();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Panneau supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Error deleting panel: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gestion du bouton retour physique pour revenir aux catégories
    return WillPopScope(
      onWillPop: () async {
        if (_selectedCategory != null) {
          setState(() {
            _selectedCategory = null;
            _isLoading = true;
          });
          _loadPanneaux();
          return false; // Ne pas quitter l'app
        }
        return true; // Quitter l'app
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: _selectedCategory != null
              ? 'Catégorie: $_selectedCategory'
              : 'Code des Panneaux',
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Barre de recherche (cachée en mode catégories pure ?)
                  // On la laisse pour filtrer les catégories ou panneaux
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomSearchBar(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          onSubmitted: (_) {},
                        ),
                        // Bouton retour si catégorie sélectionnée
                        if (_selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 4,
                              bottom: 4,
                            ),
                            child: ActionChip(
                              avatar: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Retour aux catégories'),
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = null;
                                  _isLoading = true;
                                });
                                _loadPanneaux();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Empty state when search returns no results
                  if ((_isAuthenticated || _selectedCategory != null) &&
                      _filteredPanneaux.isEmpty &&
                      _searchQuery.isNotEmpty)
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
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildGridItem(context, index),
                          childCount: _currentDataList.length,
                        ),
                      ),
                    ),
                ],
              ),
        bottomNavigationBar: const AppBottomNavigation(),
      ),
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
    this.onDelete, // New parameter for delete callback
  });

  final String title;
  final Color tileColor;
  final Color labelColor;
  final Color labelBg;
  final Color placeholderBg;
  final String? imageUrl;
  final String? imagePath;
  final VoidCallback? onTap;
  final VoidCallback? onDelete; // New parameter

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
      child: Stack(
        // Wrap in Stack for delete button overlay
        children: [
          InkWell(
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
          // Delete button overlay (top-right corner)
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
