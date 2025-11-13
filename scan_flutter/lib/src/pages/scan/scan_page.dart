import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
      // Vérifier les permissions de la caméra
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Les permissions de la caméra sont requises')),
          );
        }
        return;
      }

      // Vérifier si des caméras sont disponibles
      if (widget.cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune caméra disponible')),
          );
        }
        return;
      }

      // Initialiser la caméra arrière par défaut
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
      
      // Prendre une photo
      final XFile picture = await _cameraController!.takePicture();
      final File imageFile = File(picture.path);
      
      // Détecter les objets dans l'image
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

      // Détecter les objets
      final detections = await _detectionService.detectObjects(imageFile);
      
      if (mounted) {
        setState(() {
          _detections = detections;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un panneau'),
        actions: [
          if (_isCameraInitialized && widget.cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.switch_camera),
              onPressed: _toggleCamera,
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitFadingCircle(
              color: Colors.blue,
              size: 50.0,
            ),
            SizedBox(height: 16),
            Text('Traitement en cours...'),
          ],
        ),
      );
    }

    if (_imageFile != null) {
      return Stack(
        children: [
          Center(
            child: Image.file(
              _imageFile!,
              fit: BoxFit.contain,
            ),
          ),
          ..._buildBoundingBoxes(),
        ],
      );
    }

    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(_cameraController!);
  }

  List<Widget> _buildBoundingBoxes() {
    if (_detections.isEmpty) return [];

    return _detections.map((detection) {
      final box = detection.box;
      final left = box['x1']?.toDouble() ?? 0.0;
      final top = box['y1']?.toDouble() ?? 0.0;
      final width = (box['x2']?.toDouble() ?? 0.0) - left;
      final height = (box['y2']?.toDouble() ?? 0.0) - top;

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.red,
              width: 2.0,
            ),
          ),
          child: Text(
            '${detection.label} (${(detection.confidence * 100).toStringAsFixed(1)}%)',
            style: const TextStyle(
              color: Colors.red,
              backgroundColor: Colors.black54,
              fontSize: 12.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget? _buildFloatingActionButton() {
    if (_isLoading) return null;

    if (_imageFile != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'retake',
            onPressed: () {
              setState(() {
                _imageFile = null;
                _detections = [];
              });
            },
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'gallery',
            onPressed: _pickImage,
            child: const Icon(Icons.photo_library),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: 'capture',
          onPressed: _takePicture,
          child: const Icon(Icons.camera_alt),
        ),
        const SizedBox(width: 20),
        FloatingActionButton(
          heroTag: 'gallery',
          onPressed: _pickImage,
          child: const Icon(Icons.photo_library),
        ),
      ],
    );
  }
}