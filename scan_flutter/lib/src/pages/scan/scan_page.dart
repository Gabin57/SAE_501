import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scan_flutter/src/pages/scan/resultat.dart';
import 'package:scan_flutter/src/services/object_detection_service.dart';
import 'package:scan_flutter/src/services/local_profile_service.dart';
import 'package:scan_flutter/src/widgets/custom_app_bar.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/style/dimensions.dart';
import 'package:scan_flutter/dao.class.dart';
import 'package:scan_flutter/src/widgets/bounding_box_painter.dart';
// Conditional import for Web Camera
import 'web_camera_stub.dart' if (dart.library.html) 'web_camera_view.dart';

class ScanPage extends StatefulWidget {
  static const routeName = '/scan';

  final List<CameraDescription> cameras;

  const ScanPage({Key? key, required this.cameras}) : super(key: key);

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  final ObjectDetectionService _detectionService = ObjectDetectionService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  File? _imageFile;
  List<DetectionResult> _detections = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  Timer? _detectionTimer;
  bool _isDetecting = false;

  // Web specific variables
  dynamic _webVideoElement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel(); // Cancel timer
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (kIsWeb) {
        // On Web, we use WebCameraView which handles initialization internally
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
        return;
      } else {
        // Mobile implementation
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus != PermissionStatus.granted) {
          if (mounted) {
            setState(() => _isCameraInitialized = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Les permissions de la caméra sont requises. Vous pouvez utiliser la galerie à la place.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        if (widget.cameras.isEmpty) {
          if (mounted) {
            setState(() => _isCameraInitialized = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Aucune caméra disponible. Utilisez la galerie pour sélectionner une image.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        await _initializeCameraController(_selectedCameraIndex);
      }
    } catch (e) {
      // Gérer gracieusement l'erreur de caméra
      if (mounted) {
        setState(() => _isCameraInitialized = false);
        final errorMessage =
            e.toString().contains('hardware error') ||
                e.toString().contains('not readable')
            ? 'La caméra n\'est pas disponible. Utilisez la galerie pour sélectionner une image.'
            : 'Erreur lors de l\'initialisation de la caméra: $e';

        print('❌ [CAMERA] Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _startRealtimeDetection() {
    // Detect every 500ms
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (_isDetecting) return;

      if (kIsWeb) {
        if (_webVideoElement != null) {
          _isDetecting = true;
          await _detectInCurrentFrame();
          _isDetecting = false;
        }
      } else {
        if (_cameraController != null &&
            _cameraController!.value.isInitialized) {
          _isDetecting = true;
          await _detectInCurrentFrame();
          _isDetecting = false;
        }
      }
    });
  }

  Future<void> _detectInCurrentFrame() async {
    try {
      Uint8List bytes;

      if (kIsWeb) {
        // Web capture
        if (_webVideoElement == null) return;
        // Use conditional import function
        final List<int> capturedBytes = await captureFrame(_webVideoElement);
        bytes = Uint8List.fromList(capturedBytes);
      } else {
        // Mobile capture
        if (_cameraController == null ||
            !_cameraController!.value.isInitialized) {
          return;
        }
        final image = await _cameraController!.takePicture();
        bytes = await image.readAsBytes();
      }

      // Skip detection if image is too small or invalid
      if (bytes.isEmpty) return;

      // Make sure we are still mounted before using service
      if (!mounted) return;

      final detections = await _detectionService.detectObjectsFromBytes(
        bytes,
        conf: 0.5, // Higher confidence for real-time
      );

      if (mounted) {
        setState(() {
          _detections = detections;
        });
      }
    } catch (e) {
      print('⚠️ [REALTIME] Detection error: $e');
    }
  }

  Future<void> _initializeCameraController(int cameraIndex) async {
    if (cameraIndex >= widget.cameras.length) {
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
      return;
    }

    _cameraController = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController?.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      // Gérer l'erreur sans bloquer l'application
      if (mounted) {
        setState(() => _isCameraInitialized = false);
        // Propager l'erreur pour qu'elle soit gérée dans _initializeCamera
        // avec un message utilisateur approprié
        rethrow;
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (widget.cameras.length < 2) return;

    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    });

    await _cameraController?.dispose();
    await _initializeCameraController(_selectedCameraIndex);
  }

  Future<void> _takePicture() async {
    // Check initialization based on platform
    if (kIsWeb) {
      if (_webVideoElement == null) return;
    } else {
      if (!_isCameraInitialized ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }
    }

    try {
      setState(() => _isLoading = true);

      if (kIsWeb) {
        // Capture frame for Web
        final List<int> capturedBytes = await captureFrame(_webVideoElement);
        final bytes = Uint8List.fromList(capturedBytes);
        await _processWebCapture(bytes);
      } else {
        // Capture for Mobile
        final XFile picture = await _cameraController!.takePicture();
        final File imageFile = File(picture.path);
        await _detectObjects(imageFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processWebCapture(Uint8List bytes) async {
    try {
      print('🎯 [SCAN] Processing Web Capture');

      final detections = await _detectionService.detectObjectsFromBytes(
        bytes,
        conf: 0.5,
      );

      if (detections.isNotEmpty) {
        // Sort by confidence
        detections.sort((a, b) => b.confidence.compareTo(a.confidence));
        final bestDetection = detections.first;

        if (mounted) {
          Navigator.pushNamed(
            context,
            ResultatPage.routeName,
            arguments: PendingScanArguments(
              detection: bestDetection,
              imageBytes: bytes,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun panneau détecté')),
          );
        }
      }
    } catch (e) {
      print('Error processing web capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Sur le web, on ne peut pas utiliser File(image.path)
        // On utilise directement XFile
        if (kIsWeb) {
          await _detectObjectsFromXFile(image);
        } else {
          await _detectObjects(File(image.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _detectObjects(File imageFile) async {
    try {
      print('🎯 [SCAN] Début du processus de détection');
      print('📁 [SCAN] Fichier sélectionné: ${imageFile.path}');

      setState(() {
        _isLoading = true;
        _imageFile = imageFile;
        _detections = [];
      });

      // Vérifier si le fichier image existe
      if (!await imageFile.exists()) {
        throw Exception('Le fichier image n\'existe pas');
      }

      print('✅ [SCAN] Fichier image existe');
      print('🔄 [SCAN] Appel du service de détection...');

      // Utiliser le service de détection avec le modèle YOLO
      // Essayer d'abord avec un seuil de confiance de 0.25
      var detections = await _detectionService.detectObjects(
        imageFile,
        conf: 0.25,
      );

      // Si aucune détection, essayer avec un seuil plus bas (0.1)
      if (detections.isEmpty) {
        print(
          '⚠️ [SCAN] Aucune détection avec conf=0.25, nouvelle tentative avec conf=0.1...',
        );
        detections = await _detectionService.detectObjects(
          imageFile,
          conf: 0.1,
        );
      }

      print('📊 [SCAN] Détections reçues: ${detections.length}');

      if (detections.isEmpty) {
        print('⚠️ [SCAN] Aucun panneau détecté');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aucun panneau détecté dans l\'image. Essayez avec une autre image ou assurez-vous que le panneau est bien visible.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Prendre la première détection (la plus confiante)
      final bestDetection = detections.first;
      print(
        '🏆 [SCAN] Meilleure détection: ${bestDetection.label} (confiance: ${(bestDetection.confidence * 100).toStringAsFixed(1)}%)',
      );

      if (mounted) {
        setState(() {
          _detections = detections;
        });
      }

      // Show confirmation page for ALL users (authenticated or not)
      print('⏸️ [SCAN] Showing confirmation page for scan');
      final imageBytes = await imageFile.readAsBytes();

      if (mounted) {
        Navigator.of(context).pushNamed(
          ResultatPage.routeName,
          arguments: PendingScanArguments(
            detection: bestDetection,
            imageFile: imageFile,
            imageBytes: imageBytes,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ [SCAN] Erreur lors de la détection: $e');
      print('❌ [SCAN] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la détection: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _detectObjectsFromXFile(XFile imageFile) async {
    try {
      print('🎯 [SCAN-WEB] Début du processus de détection (Web)');
      print('📁 [SCAN-WEB] Fichier sélectionné: ${imageFile.name}');

      setState(() {
        _isLoading = true;
        _detections = [];
      });

      // Sur le web, on utilise les bytes directement depuis XFile
      final bytes = await imageFile.readAsBytes();
      print('📊 [SCAN-WEB] Taille du fichier: ${bytes.length} bytes');

      print('🔄 [SCAN-WEB] Appel du service de détection...');

      // Utiliser le service de détection avec les bytes
      // Essayer d'abord avec un seuil de confiance de 0.25
      var detections = await _detectionService.detectObjectsFromBytes(
        bytes,
        conf: 0.25,
      );

      // Si aucune détection, essayer avec un seuil plus bas (0.1)
      if (detections.isEmpty) {
        print(
          '⚠️ [SCAN-WEB] Aucune détection avec conf=0.25, nouvelle tentative avec conf=0.1...',
        );
        detections = await _detectionService.detectObjectsFromBytes(
          bytes,
          conf: 0.1,
        );
      }

      print('📊 [SCAN-WEB] Détections reçues: ${detections.length}');

      if (detections.isEmpty) {
        print('⚠️ [SCAN-WEB] Aucun panneau détecté');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aucun panneau détecté dans l\'image. Essayez avec une autre image ou assurez-vous que le panneau est bien visible.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Prendre la première détection (la plus confiante)
      final bestDetection = detections.first;
      print(
        '🏆 [SCAN-WEB] Meilleure détection: ${bestDetection.label} (confiance: ${(bestDetection.confidence * 100).toStringAsFixed(1)}%)',
      );

      if (mounted) {
        setState(() {
          _detections = detections;
        });
      }

      // Show confirmation page for web scans (same as camera scans)
      print('⏸️ [SCAN-WEB] Showing confirmation page');

      if (mounted) {
        Navigator.of(context).pushNamed(
          ResultatPage.routeName,
          arguments: PendingScanArguments(
            detection: bestDetection,
            imageFile: null, // No File object for web
            imageBytes: Uint8List.fromList(bytes),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ [SCAN-WEB] Erreur lors de la détection: $e');
      print('❌ [SCAN-WEB] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la détection: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePanneau(DetectionResult detection, File imageFile) async {
    try {
      // Préparer les données du panneau
      final panneauData = {
        'name': detection.label,
        'description':
            'Panneau détecté automatiquement avec confiance ${(detection.confidence * 100).toStringAsFixed(1)}%',
        'type': 'detection_automatique',
        'source_url':
            'https://fr.wikibooks.org/wiki/Code_de_la_route/Liste_des_panneaux',
        'image_path': imageFile.path,
      };

      // Sauvegarder le panneau dans la base de données
      final panneauResponse = await DAO.create('panneaux', panneauData);

      // Extraire l'ID du panneau créé
      final panneauId =
          panneauResponse['id'] ??
          panneauResponse['num'] ??
          panneauResponse['id_panneau'];

      if (panneauId == null) {
        throw Exception('Impossible de récupérer l\'ID du panneau créé');
      }

      // Create liaison with user account if authenticated
      final profile = await LocalProfileService.getProfile();
      final userId = profile['num'];

      if (userId != null) {
        try {
          await DAO.create('liaisons_panneaux', {
            'id_compte': userId,
            'id_panneau': panneauId,
          });
          print('✅ [SCAN] Liaison created: user $userId -> panel $panneauId');
        } catch (e) {
          print('⚠️ [SCAN] Could not create liaison: $e');
        }
      }

      if (mounted) {
        // Naviguer vers la page de détails du panneau créé
        Navigator.pushReplacementNamed(
          context,
          ResultatPage.routeName,
          arguments: ResultatArguments(
            panneauId,
            'panneaux',
            showActions: false, // Don't show buttons for auto-saved scans
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  Future<void> _savePanneauFromBytes(
    DetectionResult detection,
    List<int> imageBytes,
    String imageName,
  ) async {
    try {
      // Upload l'image au serveur d'abord
      print('📤 Uploading image to server...');
      final imageUrl = await DAO.uploadImage(
        Uint8List.fromList(imageBytes),
        'web_upload_$imageName',
      );

      // Préparer les données du panneau
      final panneauData = {
        'name': detection.label,
        'description':
            'Panneau détecté automatiquement avec confiance ${(detection.confidence * 100).toStringAsFixed(1)}%',
        'type': 'detection_automatique',
        'source_url':
            'https://fr.wikibooks.org/wiki/Code_de_la_route/Liste_des_panneaux',
      };

      // Ajouter l'URL de l'image si l'upload a réussi
      if (imageUrl != null) {
        panneauData['image_url'] = imageUrl;
        panneauData['image_path'] = 'web_upload_$imageName';
      } else {
        // Si l'upload échoue, sauvegarder quand même le panneau sans image
        print('⚠️ Image upload failed, saving panel without image');
        panneauData['image_path'] = 'web_upload_$imageName';
      }

      // Sauvegarder le panneau dans la base de données
      final panneauResponse = await DAO.create('panneaux', panneauData);

      // Extraire l'ID du panneau créé
      final panneauId =
          panneauResponse['id'] ??
          panneauResponse['num'] ??
          panneauResponse['id_panneau'];

      if (panneauId == null) {
        throw Exception('Impossible de récupérer l\'ID du panneau créé');
      }

      if (mounted) {
        // Naviguer vers la page de détails du panneau créé
        Navigator.pushReplacementNamed(
          context,
          ResultatPage.routeName,
          arguments: ResultatArguments(panneauId, 'panneaux'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scanner un panneau',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (kIsWeb)
            Stack(
              fit: StackFit.expand,
              children: [
                WebCameraView(
                  onCameraReady: (video) {
                    _webVideoElement = video;
                    _startRealtimeDetection();
                  },
                  onError: (err) {
                    print('Web Camera Error: $err');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur caméra web: $err')),
                    );
                  },
                ),
                if (_detections.isNotEmpty)
                  CustomPaint(
                    painter: BoundingBoxPainter(_detections),
                    child: Container(),
                  ),
              ],
            )
          else if (_isCameraInitialized && _cameraController != null)
            Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController!),
                if (_detections.isNotEmpty)
                  CustomPaint(
                    painter: BoundingBoxPainter(_detections),
                    child: Container(),
                  ),
              ],
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Caméra non disponible',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Utilisez la galerie pour sélectionner une image',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          // Afficher l'overlay uniquement si la caméra est disponible
          if (_isCameraInitialized && _cameraController != null)
            _buildScanOverlay(),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildCameraControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Stack(
      children: [
        // Couche sombre semi-transparente
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              // Zone de scan transparente
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Texte d'instruction
        Positioned(
          top: MediaQuery.of(context).size.height * 0.2,
          left: 0,
          right: 0,
          child: const Text(
            'Placez le panneau dans le cadre',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton de capture principal
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Effet de halo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              // Bouton de capture (désactivé si caméra non disponible)
              GestureDetector(
                onTap:
                    (kIsWeb ||
                        (_isCameraInitialized && _cameraController != null))
                    ? _takePicture
                    : null,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (kIsWeb ||
                            (_isCameraInitialized && _cameraController != null))
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Ligne avec les boutons secondaires
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Bouton galerie
            _buildIconButton(
              icon: Icons.photo_library,
              label: 'Galerie',
              onPressed: _pickImage,
            ),
            const SizedBox(width: 40),
            // Bouton caméra avant/arrière
            _buildIconButton(
              icon: Icons.cameraswitch,
              label: 'Retourner',
              onPressed: _toggleCamera,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 28, color: Colors.white),
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
