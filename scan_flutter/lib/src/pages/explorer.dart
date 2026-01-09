import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:scan_flutter/src/pages/scan/resultat.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/widgets/custom_app_bar.dart';
import 'package:scan_flutter/src/widgets/search_bar.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';
import '../../dao.class.dart';

class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});
  static const routeName = '/explorer';

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  List<Map<String, dynamic>> _panneaux = [];
  List<Map<String, dynamic>> _categories = []; // New categories list
  String? _selectedCategory; // Selected category for filter
  bool _isLoading = true;
  String _searchQuery = '';

  // Palette et tailles centralisées
  static const _tileBg = AppColors.tileBg;
  static const _iconMuted = AppColors.iconMuted;
  static const _labelBg = AppColors.labelBg;
  static const _placeholderBg = AppColors.placeholderBg;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (_selectedCategory == null) {
        // 1. Load Categories
        print('🌐 [EXPLORER] Loading Categories...');
        final cats = await DAO.getCategories();
        final categories = List<Map<String, dynamic>>.from(cats);

        if (mounted) {
          setState(() {
            _categories = categories;
            _panneaux = [];
            _isLoading = false;
          });
        }
      } else {
        // 2. Load Panels for Selected Category
        print('🌐 [EXPLORER] Loading Panels for category: $_selectedCategory');
        final results = await DAO.getAll(
          'panneaux',
          queryParams: {'categorie': _selectedCategory!},
        );

        final allPanneaux = List<Map<String, dynamic>>.from(results);

        // Sort by ID descending (newest first)
        allPanneaux.sort((a, b) {
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
            _panneaux = allPanneaux;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _panneaux = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(label: 'Réessayer', onPressed: _loadData),
          ),
        );
      }
    }
  }

  // Getter for filtered panels based on search query
  List<Map<String, dynamic>> get _filteredPanneaux {
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

  // Determine effective data list for grid
  List<dynamic> get _currentDataList {
    if (_selectedCategory == null) {
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
    if (_selectedCategory == null) {
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
          _loadData();
        },
      );
    }
    // Mode Panneaux
    else {
      final panneau = item as Map<String, dynamic>;
      final rawId = panneau['id'] ?? panneau['num'];
      // Ensure we have a valid int ID
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
              'panneaux',
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
        print('🗑️ [EXPLORER] Starting deletion of panel $panneauId');

        // Delete liaisons first
        final liaisons = await DAO.getAll('liaisons_panneaux');
        final panneauLiaisons = liaisons.where(
          (l) => l['id_panneau'] == panneauId,
        );

        print(
          '🔗 [EXPLORER] Found ${panneauLiaisons.length} liaisons to delete',
        );
        for (final liaison in panneauLiaisons) {
          print('🗑️ [EXPLORER] Deleting liaison ${liaison['num']}');
          await DAO.delete('liaisons_panneaux', liaison['num']);
        }

        // Delete panel
        print('🗑️ [EXPLORER] Deleting panel $panneauId');
        await DAO.delete('panneaux', panneauId);
        print('✅ [EXPLORER] Panel deleted successfully');

        // Reload panels
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Panneau supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ [EXPLORER] Error deleting panel: $e');
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
    return WillPopScope(
      onWillPop: () async {
        if (_selectedCategory != null) {
          setState(() {
            _selectedCategory = null;
            _isLoading = true;
          });
          _loadData();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: _selectedCategory != null
              ? 'Catégorie: $_selectedCategory'
              : 'Explorer',
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Barre de recherche
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
                                _loadData();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Empty state when search returns no results
                  if (_selectedCategory != null &&
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

// GridCard widget (copied from accueil.dart)
class GridCard extends StatelessWidget {
  final String title;
  final String? subtitle; // New parameter
  final Color tileColor;
  final Color labelColor;
  final Color labelBg;
  final Color placeholderBg;
  final String? imageUrl;
  final String? imagePath;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GridCard({
    super.key,
    required this.title,
    this.subtitle, // New parameter
    required this.tileColor,
    required this.labelColor,
    required this.labelBg,
    required this.placeholderBg,
    this.imageUrl,
    this.imagePath,
    this.onTap,
    this.onDelete,
  });

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
