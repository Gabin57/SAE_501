import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class DetectionResult {
  final String label;
  final double confidence;
  final Map<String, dynamic> box;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.box,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      label: json['class'],
      confidence: (json['confidence'] as num).toDouble(),
      box: Map<String, dynamic>.from(json['box']),
    );
  }
}

class ObjectDetectionService {
  static const String _baseUrl = 'http://votre-serveur:5001';
  
  Future<List<DetectionResult>> detectObjects(File imageFile) async {
    try {
      // Convertir l'image en base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Envoyer la requête à l'API
      final response = await http.post(
        Uri.parse('$_baseUrl/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': 'data:image/jpeg;base64,$base64Image'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> detections = data['detections'];
          return detections
              .map((d) => DetectionResult.fromJson(d))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Erreur inconnue lors de la détection');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Échec de la détection d\'objets: $e');
    }
  }
  
  // Méthode utilitaire pour redimensionner l'image si nécessaire
  Future<File> resizeImageIfNeeded(File imageFile, {int maxSize = 1024}) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Impossible de décoder l\'image');
    }
    
    // Vérifier si un redimensionnement est nécessaire
    if (image.width <= maxSize && image.height <= maxSize) {
      return imageFile;
    }
    
    // Calculer les nouvelles dimensions en conservant le ratio
    int newWidth, newHeight;
    if (image.width > image.height) {
      newWidth = maxSize;
      newHeight = (image.height * maxSize / image.width).round();
    } else {
      newHeight = maxSize;
      newWidth = (image.width * maxSize / image.height).round();
    }
    
    // Redimensionner l'image
    final resizedImage = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
    );
    
    // Enregistrer l'image redimensionnée
    final tempDir = await getTemporaryDirectory();
    final resizedFile = File('${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await resizedFile.writeAsBytes(img.encodeJpg(resizedImage));
    
    return resizedFile;
  }
}
