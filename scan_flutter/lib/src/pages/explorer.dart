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
    _loadAllPanneaux();
  }

  Future<void> _loadAllPanneaux() async {
    try {
      // Load ALL data needed concurrently
      final results = await Future.wait([
        DAO.getAll('panneaux'),
      ]).timeout(const Duration(seconds: 10));

      final allPanneaux = List<Map<String, dynamic>>.from(results[0]);

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
        return idB.compareTo(idA);
      });

      if (mounted) {
        setState(() {
          _panneaux = allPanneaux;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _panneaux = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des panneaux: $e'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: _loadAllPanneaux,
            ),
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

  List<Widget> _buildGridItems() {
    final items = <Widget>[];

    for (final panneau in _filteredPanneaux) {
      final rawId = panneau['id'] ?? panneau['num'];
      // Ensure we have a valid int ID
      final int? panneauId = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '');

      if (panneauId == null) continue; // Skip invalid panels

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
                'panneaux',
                showActions: false,
              ),
            );
          },
          onDelete: () =>
              _deletePanneau(panneauId, panneauName), // Add delete callback
        ),
      );
    }

    return items;
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
        await _loadAllPanneaux();

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
    return Scaffold(
      appBar: const CustomAppBar(title: 'Explorer'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Barre de recherche
                SliverToBoxAdapter(
                  child: CustomSearchBar(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onSubmitted: (value) {
                      // Search is already handled by onChanged
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
