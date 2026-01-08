import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:scan_flutter/dao.class.dart';
import 'package:scan_flutter/src/pages/connexion.dart';
import 'package:scan_flutter/src/pages/accueil.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/style/dimensions.dart';
import 'package:scan_flutter/src/widgets/custom_app_bar.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';
import 'package:scan_flutter/src/services/object_detection_service.dart';
import 'package:scan_flutter/src/services/local_profile_service.dart';

class ResultatArguments {
  final int id;
  final String database;
  final bool showActions;

  ResultatArguments(this.id, this.database, {this.showActions = true});
}

class PendingScanArguments {
  final DetectionResult detection;
  final File? imageFile;
  final Uint8List? imageBytes;

  PendingScanArguments({
    required this.detection,
    this.imageFile,
    this.imageBytes,
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
  bool _isLoading = true;
  bool _showActions = true;
  Map<String, dynamic>? _panneauData;

  // Pending scan fields
  bool _isPendingScan = false;
  DetectionResult? _pendingDetection;
  File? _pendingImageFile;
  Uint8List? _pendingImageBytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is PendingScanArguments) {
      // Pending scan mode - awaiting user confirmation
      _isPendingScan = true;
      _pendingDetection = args.detection;
      _pendingImageFile = args.imageFile;
      _pendingImageBytes = args.imageBytes;
      _showActions = true; // Always show buttons for pending scans
      _buildPendingPanneauData();
    } else if (args is ResultatArguments) {
      // View mode - existing panel from database
      _isPendingScan = false;
      id = args.id;
      database = args.database;
      _showActions = args.showActions;
      _loadPanneauData();
    }
  }

  Future<void> _buildPendingPanneauData() async {
    try {
      print(
        '🔍 Searching for real panel description for: ${_pendingDetection!.label}',
      );

      // Get all panels and search for matching name
      final allPanels = await DAO.getAll('panneaux');

      // Find panel with same name but not auto-detected
      final realPanel = allPanels.firstWhere(
        (p) =>
            p['name'] == _pendingDetection!.label &&
            p['type'] != 'detection_automatique',
        orElse: () => null,
      );

      String description;
      if (realPanel != null) {
        print('✅ Found real panel description');
        description = realPanel['description'];
      } else {
        print(
          '⚠️ No matching panel found in database, using auto-generated description',
        );
        // Show what was detected instead of generic "Panneau détecté"
        description =
            'Objet détecté : "${_pendingDetection!.label}" avec ${(_pendingDetection!.confidence * 100).toStringAsFixed(1)}% de confiance.\n\nCet objet ne correspond à aucun panneau de signalisation dans notre base de données.';
      }

      if (!mounted) return; // Check before setState

      setState(() {
        _panneauData = {
          'name': _pendingDetection!.label,
          'description': description,
          'type': 'detection_automatique',
          'confidence': _pendingDetection!.confidence,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching real panel description: $e');

      if (!mounted) return; // Check before setState

      // Fallback to auto-generated description
      setState(() {
        _panneauData = {
          'name': _pendingDetection!.label,
          'description':
              'Panneau détecté automatiquement avec confiance ${(_pendingDetection!.confidence * 100).toStringAsFixed(1)}%',
          'type': 'detection_automatique',
          'confidence': _pendingDetection!.confidence,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPanneauData() async {
    try {
      final data = await DAO.getById(database, id);
      if (!mounted) return;

      // If this is an auto-detected panel, fetch the real description from database
      if (data['type'] == 'detection_automatique' && data['name'] != null) {
        // First, extract and save the confidence from original description
        final originalDescription = data['description'] as String?;
        if (originalDescription != null) {
          // Utiliser une expression régulière plus permissive pour trouver la confiance
          // Cherche "93.0% de confiance" ou "confiance 93.0%"
          final regex = RegExp(
            r'(\d+\.?\d*)%\s+de\s+confiance|confiance\s+(\d+\.?\d*)%',
            caseSensitive: false,
          );
          final match = regex.firstMatch(originalDescription);
          if (match != null) {
            // Le groupe 1 est pour le premier motif, le groupe 2 pour le second
            final valString = match.group(1) ?? match.group(2) ?? '100';
            // Fix: Store as decimal (0.94) not percentage (94.0) because _getConfidence multiplies by 100
            data['confidence'] = (double.tryParse(valString) ?? 100.0) / 100.0;
          }
        }

        try {
          print('🔍 Searching for real panel description for: ${data['name']}');

          // Get all panels and search for matching name
          final allPanels = await DAO.getAll('panneaux');

          // Find panel with same name but not auto-detected
          final realPanel = allPanels.firstWhere(
            (p) =>
                p['name'] == data['name'] &&
                p['type'] != 'detection_automatique',
            orElse: () => null,
          );

          if (realPanel != null) {
            print('✅ Found real panel description');
            // Replace auto-generated description with real one
            data['description'] = realPanel['description'];
            // Save real panel image URL as fallback if user's image fails to load
            if (realPanel['image_url'] != null &&
                realPanel['image_url'].toString().isNotEmpty) {
              data['fallback_image_url'] = realPanel['image_url'];
            }
          } else {
            print('⚠️ No matching panel found in database');
          }
        } catch (e) {
          print('❌ Error fetching real panel description: $e');
        }
      }

      // Construct image URL from image_path if needed
      if (data['image_path'] != null &&
          (data['image_url'] == null || data['image_url'].toString().isEmpty)) {
        data['image_url'] =
            'http://51.38.64.145:5001/images/${data['image_path']}';
      }

      setState(() {
        _panneauData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Fallback to mock data if API fails
      setState(() {
        _panneauData = {
          'name': 'Image $id',
          'description':
              'Description description description description description description description description',
          'image_url': null,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAjouter() async {
    if (_isPendingScan) {
      // Save the pending scan
      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sauvegarde en cours...')));

        // Upload image if we have bytes
        String? imageUrl;
        if (_pendingImageBytes != null) {
          imageUrl = await DAO.uploadImage(
            _pendingImageBytes!,
            'scan_${DateTime.now().millisecondsSinceEpoch}.jpg', // Add .jpg extension
          );
        }

        // Create panel
        final panneauData = {
          'name': _pendingDetection!.label,
          'description': _panneauData!['description'],
          'type': 'detection_automatique',
          'source_url':
              'https://fr.wikibooks.org/wiki/Code_de_la_route/Liste_des_panneaux',
        };

        if (imageUrl != null) {
          panneauData['image_url'] = imageUrl;
        }

        final panneauResponse = await DAO.create('panneaux', panneauData);
        final panneauId = panneauResponse['id'] ?? panneauResponse['num'];
        print('📦 Panel created with ID: $panneauId');

        // Create liaison (link to user)
        final profile = await LocalProfileService.getProfile();
        var userId = profile['num'];

        // Safety Fallback: If local ID is missing, try to fetch it from API
        if (userId == null &&
            (profile['email'].isNotEmpty || profile['name'].isNotEmpty)) {
          print('⚠️ Local ID missing, attempting to resolve from API...');
          try {
            final accounts = await DAO.getAll('comptes');
            final account = accounts.firstWhere(
              (a) =>
                  (a['email'] ?? '').toString().toLowerCase() ==
                      profile['email'].toString().toLowerCase() ||
                  (a['identifiant'] ?? '').toString().toLowerCase() ==
                      profile['name'].toString().toLowerCase(),
              orElse: () => {},
            );
            if (account.isNotEmpty) {
              final rawId = account['num'] ?? account['id'];
              userId = rawId is int
                  ? rawId
                  : int.tryParse(rawId?.toString() ?? '');

              // Opportunistically update local profile
              if (userId != null) {
                await LocalProfileService.saveProfile(
                  name: profile['name'],
                  email: profile['email'],
                  theme: profile['theme'],
                  num: userId,
                );
              }
            }
          } catch (e) {
            print('❌ Failed to resolve user ID: $e');
          }
        }

        print('👤 User profile: $profile');
        print('🆔 User ID for liaison: $userId');

        if (userId != null) {
          print('🔗 Creating liaison: user $userId -> panel $panneauId');
          try {
            final liaisonResponse = await DAO.create('liaisons_panneaux', {
              'id_compte': userId,
              'id_panneau': panneauId,
            });
            print('✅ Liaison created successfully: $liaisonResponse');

            // Update UI immediately (though we navigate away, valid state is good)
            // _scannedBy = profile['name'] ?? profile['identifiant'];
          } catch (e) {
            print('❌ Error creating liaison: $e');
          }
        } else {
          print('⚠️ No userId found - liaison not created');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Attention: Profil incomplet, scan marqué comme "Déconnecté"',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_pendingDetection!.label[0].toUpperCase()}${_pendingDetection!.label.substring(1).toLowerCase()} ajouté !',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacementNamed(AccueilPage.routeName);
      } catch (e) {
        print('❌ Error saving panel: $e');
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      // Not a pending scan - redirect to login
      Navigator.pushNamed(context, ConnexionPage.routeName);
    }
  }

  Future<void> _handleSupprimer() async {
    if (_isPendingScan) {
      // Cancel scan - just go back
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour supprimer un panneau'),
        ),
      );
    }
  }

  // Extract confidence percentage from description or data
  double _getConfidence() {
    // First try to get from 'confidence' field
    if (_panneauData?['confidence'] != null) {
      final confidence = (_panneauData!['confidence'] as num).toDouble();
      // Confidence is stored as decimal (0.99), convert to percentage (99.0)
      return confidence * 100;
    }

    // Otherwise, try to extract from description
    final description = _panneauData?['description'] as String?;
    if (description != null) {
      // Look for pattern like "93.0% de confiance" or "confiance 93.0%"
      final regex = RegExp(
        r'(\d+\.?\d*)%\s+de\s+confiance|confiance\s+(\d+\.?\d*)%',
        caseSensitive: false,
      );
      final match = regex.firstMatch(description);
      if (match != null) {
        final valString = match.group(1) ?? match.group(2) ?? '100';
        return double.tryParse(valString) ?? 100.0;
      }
    }

    // Default to 100% if not found
    return 100.0;
  }

  // Get clean description without the confidence text
  String _getCleanDescription() {
    final description = _panneauData?['description'] as String?;
    if (description == null) {
      return 'Description non disponible';
    }

    // Remove the auto-generated confidence text
    // Pattern: "automatiquement avec confiance XX.X%"
    final cleanDescription = description
        .replaceAll(
          RegExp(
            r'\s*automatiquement avec confiance \d+\.?\d*%\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    return cleanDescription.isNotEmpty
        ? cleanDescription
        : 'Description non disponible';
  }

  // Get color based on confidence percentage
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) {
      return AppColors.success; // Green for high confidence
    } else if (confidence >= 50) {
      return AppColors.warning; // Orange for medium confidence
    } else {
      return AppColors.error; // Red for low confidence
    }
  }

  @override
  Widget build(BuildContext context) {
    // Different title based on context:
    // - From home (showActions=false): Show panel name
    // - After scan (showActions=true): Show "Nouveau Panneau"
    final String appBarTitle = _isLoading
        ? 'Chargement...'
        : (_showActions
              ? 'Nouveau Panneau'
              : (_panneauData?['name'] ?? 'Panneau'));

    return Scaffold(
      backgroundColor: AppColors.appBarBg,
      appBar: CustomAppBar(
        title: appBarTitle,
        centerTitle: true,
        showProfileIcon: _showActions, // Show profile icon only after scan
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Image section - WHITE Background (Flex 4)
                Expanded(
                  flex: 4,
                  child: Container(
                    color: AppColors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    child: Center(child: _buildPanneauImage()),
                  ),
                ),

                // Info section - GRAY Background (Flex 5)
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    color: AppColors.placeholderBg,
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.medium,
                      AppDimens.large,
                      AppDimens.medium,
                      AppDimens.medium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show name + percentage after scan, only percentage from home
                        if (_showActions)
                          // After scan: Show panel name + percentage
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _panneauData?['name'] ?? 'Image $id',
                                  style: const TextStyle(
                                    fontSize: AppDimens.textExtraLarge,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              Text(
                                '${_getConfidence().toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: AppDimens.textExtraLarge,
                                  fontWeight: FontWeight.bold,
                                  color: _getConfidenceColor(_getConfidence()),
                                ),
                              ),
                            ],
                          )
                        else
                          // From home: Only percentage (name is in AppBar)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${_getConfidence().toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: AppDimens.textExtraLarge,
                                  fontWeight: FontWeight.bold,
                                  color: _getConfidenceColor(_getConfidence()),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 10),

                        // Description - Expanded to fill available space
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getCleanDescription(),
                                  style: const TextStyle(
                                    fontSize: AppDimens.textMedium,
                                    height: 1.4,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action buttons - Only show if _showActions is true
                        if (_showActions)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: Icons.add,
                                label: 'Ajouter',
                                onPressed: _handleAjouter,
                              ),
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
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _buildPanneauImage() {
    // For pending scans, display image from bytes
    if (_isPendingScan && _pendingImageBytes != null) {
      return Image.memory(_pendingImageBytes!, fit: BoxFit.contain);
    }

    final imagePath = _panneauData?['image_path'];
    final imageUrl = _panneauData?['image_url'];

    // Debug
    print('Image path: $imagePath');
    print('Image URL: $imageUrl');

    // Sur Web ou si on a un chemin local, essayer de l'utiliser
    if (!kIsWeb && imagePath != null) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading local image: $error');
            return _buildImagePlaceholder();
          },
        );
      }
    }

    // Sinon, utiliser l'URL réseau
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      final urlString = imageUrl.toString();

      // Check if SVG
      if (urlString.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(
          urlString,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => _buildImagePlaceholder(),
        );
      }

      // Regular image
      return Image.network(
        urlString,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          // If user's image fails (404), try fallback image from database
          final fallbackUrl = _panneauData?['fallback_image_url'];
          if (fallbackUrl != null && fallbackUrl.toString().isNotEmpty) {
            print('🔄 Using fallback image from database');
            return Image.network(
              fallbackUrl.toString(),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
            );
          }
          return _buildImagePlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.iconMuted,
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      ),
      child: const Icon(Icons.image, color: AppColors.white, size: 40),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 22),
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
