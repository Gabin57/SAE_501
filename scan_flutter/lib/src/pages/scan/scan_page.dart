import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/object_detection_service.dart';

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
  List<dynamic> _detections = [];
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Les permissions de la caméra sont requises')),
          );
        }
        return;
      }

      if (widget.cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune caméra disponible')),
          );
        }
        return;
      }

      await _initializeCameraController(_selectedCameraIndex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'initialisation de la caméra: $e')),
        );
      }
    }
  }

  Future<void> _initializeCameraController(int cameraIndex) async {
    if (cameraIndex >= widget.cameras.length) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'initialisation de la caméra: $e')),
        );
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
        await _detectObjects(File(image.path));
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

      // Simulation d'une détection
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _detections = []; // Remplacez par vos résultats de détection
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la détection: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            const Center(
              child: Text(
                'Caméra non disponible',
                style: TextStyle(color: Colors.white),
              ),
            ),
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
              // Bouton de capture
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
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