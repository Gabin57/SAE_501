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
      // Load ALL panels without filtering
      final panneaux = await DAO
          .getAll('panneaux')
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _panneaux = List<Map<String, dynamic>>.from(panneaux);
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
              arguments: ResultatArguments(panneauId, 'panneaux'),
            );
          },
        ),
      );
    }

    return items;
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
  final String? imageUrl;
  final String? imagePath;
  final Color tileColor;
  final Color labelColor;
  final Color labelBg;
  final Color placeholderBg;
  final VoidCallback onTap;

  const GridCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.imagePath,
    required this.tileColor,
    required this.labelColor,
    required this.labelBg,
    required this.placeholderBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image container
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(),
                ),
              ),
            ),
            // Label
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Sur Web ou si on a un chemin local, essayer de l'utiliser
    if (!kIsWeb && imagePath != null) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        );
      }
    }

    // Sinon, utiliser l'URL réseau
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final urlString = imageUrl!;

      // Check if SVG
      if (urlString.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(
          urlString,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => _buildPlaceholder(),
        );
      }

      // Regular image
      return Image.network(
        urlString,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: placeholderBg,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: labelColor.withOpacity(0.3),
        ),
      ),
    );
  }
}
