import 'dart:convert';
import 'dart:io';
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
  // Utiliser la même URL de base que le DAO
  static const String _baseUrl = 'http://51.38.64.145:5001';

  Future<List<DetectionResult>> detectObjects(
    File imageFile, {
    double conf = 0.5,
  }) async {
    try {
      // Convertir l'image en base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Envoyer la requête à l'API Python avec le modèle YOLO
      // L'API doit être configurée pour utiliser /var/www/nounours/API/python-api/models/best.pt
      final response = await http.post(
        Uri.parse('$_baseUrl/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': 'data:image/jpeg;base64,$base64Image',
          'conf': conf, // Seuil de confiance pour YOLO
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Format attendu de l'API YOLO (adapté selon votre implémentation)
        // Le modèle YOLO retourne généralement une liste de résultats
        if (data['success'] == true || data.containsKey('results')) {
          // Si l'API retourne directement les résultats YOLO
          List<dynamic> detections;
          if (data.containsKey('results')) {
            // Format direct depuis YOLO: results[0].boxes.data contient [x1, y1, x2, y2, conf, class]
            detections = data['results'] is List ? data['results'] : [];
          } else if (data.containsKey('detections')) {
            detections = data['detections'];
          } else {
            // Format alternatif: adapter selon votre API
            detections = [];
          }

          return detections.map((d) => DetectionResult.fromJson(d)).toList();
        } else {
          throw Exception(
            data['error'] ?? 'Erreur inconnue lors de la détection',
          );
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Échec de la détection d\'objets: $e');
    }
  }

  /// Détecte les objets à partir de bytes (pour le web)
  Future<List<DetectionResult>> detectObjectsFromBytes(
    List<int> imageBytes, {
    double conf = 0.5,
  }) async {
    try {
      // Convertir les bytes en base64
      final base64Image = base64Encode(imageBytes);

      // Envoyer la requête à l'API Python avec le modèle YOLO
      final response = await http.post(
        Uri.parse('$_baseUrl/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': 'data:image/jpeg;base64,$base64Image',
          'conf': conf,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true || data.containsKey('results')) {
          List<dynamic> detections;
          if (data.containsKey('results')) {
            detections = data['results'] is List ? data['results'] : [];
          } else if (data.containsKey('detections')) {
            detections = data['detections'];
          } else {
            detections = [];
          }

          return detections.map((d) => DetectionResult.fromJson(d)).toList();
        } else {
          throw Exception(
            data['error'] ?? 'Erreur inconnue lors de la détection',
          );
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
    final resizedFile = File(
      '${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await resizedFile.writeAsBytes(img.encodeJpg(resizedImage));

    return resizedFile;
  }
}
