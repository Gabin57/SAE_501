import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/object_detection_service.dart';
import '../../../dao.class.dart';
import 'resultat.dart';

class ScanPage extends StatefulWidget {
  static const routeName = '/scan';
  
  final List<CameraDescription> cameras;
  
  const ScanPage({
    Key? key,
    required this.cameras,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        if (mounted) {
          setState(() => _isCameraInitialized = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les permissions de la caméra sont requises. Vous pouvez utiliser la galerie à la place.'),
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
              content: Text('Aucune caméra disponible. Utilisez la galerie pour sélectionner une image.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      await _initializeCameraController(_selectedCameraIndex);
    } catch (e) {
      // Gérer gracieusement l'erreur de caméra (notamment dans les navigateurs web)
      if (mounted) {
        setState(() => _isCameraInitialized = false);
        final errorMessage = e.toString().contains('hardware error') || 
                            e.toString().contains('not readable')
            ? 'La caméra n\'est pas disponible. Utilisez la galerie pour sélectionner une image.'
            : 'Erreur lors de l\'initialisation de la caméra. Utilisez la galerie à la place.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      final XFile picture = await _cameraController!.takePicture();
      final File imageFile = File(picture.path);
      await _detectObjects(imageFile);
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
          SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
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
      setState(() {
        _isLoading = true;
        _imageFile = imageFile;
        _detections = [];
      });

      // Vérifier si le fichier image existe
      if (!await imageFile.exists()) {
        throw Exception('Le fichier image n\'existe pas');
      }

      // Utiliser le service de détection avec le modèle YOLO
      final detections = await _detectionService.detectObjects(imageFile, conf: 0.5);
      
      if (detections.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun panneau détecté dans l\'image')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Prendre la première détection (la plus confiante)
      final bestDetection = detections.first;
      
      if (mounted) {
        setState(() {
          _detections = detections;
        });
      }

      // Sauvegarder le panneau dans la base de données et naviguer
      await _savePanneau(bestDetection, imageFile);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la détection: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _detectObjectsFromXFile(XFile imageFile) async {
    try {
      setState(() {
        _isLoading = true;
        _detections = [];
      });

      // Sur le web, on utilise les bytes directement depuis XFile
      final bytes = await imageFile.readAsBytes();
      
      // Utiliser le service de détection avec les bytes
      final detections = await _detectionService.detectObjectsFromBytes(bytes, conf: 0.5);
      
      if (detections.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun panneau détecté dans l\'image')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Prendre la première détection (la plus confiante)
      final bestDetection = detections.first;
      
      if (mounted) {
        setState(() {
          _detections = detections;
        });
      }

      // Sauvegarder le panneau dans la base de données et naviguer
      await _savePanneauFromBytes(bestDetection, bytes, imageFile.name);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la détection: $e')),
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
        'description': 'Panneau détecté automatiquement avec confiance ${(detection.confidence * 100).toStringAsFixed(1)}%',
        'type': 'detection_automatique',
        'source_url': 'https://fr.wikibooks.org/wiki/Code_de_la_route/Liste_des_panneaux',
        'image_path': imageFile.path,
      };

      // Sauvegarder le panneau dans la base de données
      final panneauResponse = await DAO.create('panneaux', panneauData);
      
      // Extraire l'ID du panneau créé
      final panneauId = panneauResponse['id'] ?? panneauResponse['num'] ?? panneauResponse['id_panneau'];
      
      if (panneauId == null) {
        throw Exception('Impossible de récupérer l\'ID du panneau créé');
      }

      // TODO: Créer la liaison avec le compte utilisateur si connecté
      // Pour l'instant, on navigue directement vers la page de détails
      
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

  Future<void> _savePanneauFromBytes(DetectionResult detection, List<int> imageBytes, String imageName) async {
    try {
      // Préparer les données du panneau (sans image_path car on est sur le web)
      final panneauData = {
        'name': detection.label,
        'description': 'Panneau détecté automatiquement avec confiance ${(detection.confidence * 100).toStringAsFixed(1)}%',
        'type': 'detection_automatique',
        'source_url': 'https://fr.wikibooks.org/wiki/Code_de_la_route/Liste_des_panneaux',
        // Sur le web, on ne peut pas sauvegarder le chemin du fichier
        'image_path': 'web_upload_$imageName',
      };

      // Sauvegarder le panneau dans la base de données
      final panneauResponse = await DAO.create('panneaux', panneauData);
      
      // Extraire l'ID du panneau créé
      final panneauId = panneauResponse['id'] ?? panneauResponse['num'] ?? panneauResponse['id_panneau'];
      
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
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
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
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
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
                onTap: (_isCameraInitialized && _cameraController != null) 
                    ? _takePicture 
                    : null,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_isCameraInitialized && _cameraController != null)
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
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}