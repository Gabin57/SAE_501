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
      print('🔍 [DETECTION] Début de la détection d\'objets');
      print('📁 [DETECTION] Fichier: ${imageFile.path}');

      // Vérifier que le fichier existe
      if (!await imageFile.exists()) {
        throw Exception('Le fichier image n\'existe pas: ${imageFile.path}');
      }

      // Convertir l'image en base64
      final bytes = await imageFile.readAsBytes();
      print('📊 [DETECTION] Taille de l\'image: ${bytes.length} bytes');

      final base64Image = base64Encode(bytes);
      print('📊 [DETECTION] Taille base64: ${base64Image.length} caractères');

      final requestBody = {
        'image': 'data:image/jpeg;base64,$base64Image',
        'conf': conf,
      };

      print('🌐 [DETECTION] Envoi de la requête à: $_baseUrl/detect');
      print('⚙️ [DETECTION] Seuil de confiance: $conf');

      // Envoyer la requête à l'API Python avec le modèle YOLO avec timeout
      final response = await http
          .post(
            Uri.parse('$_baseUrl/detect'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Timeout: L\'API n\'a pas répondu dans les 30 secondes',
              );
            },
          );

      print('📥 [DETECTION] Réponse reçue - Status: ${response.statusCode}');
      print('📥 [DETECTION] Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [DETECTION] Réponse parsée avec succès');
        print('📋 [DETECTION] Clés de la réponse: ${data.keys.toList()}');

        // Format attendu de l'API YOLO (adapté selon votre implémentation)
        if (data['success'] == true || data.containsKey('results')) {
          List<dynamic> detections;
          if (data.containsKey('results')) {
            detections = data['results'] is List ? data['results'] : [];
            print('📊 [DETECTION] Nombre de résultats: ${detections.length}');
          } else if (data.containsKey('detections')) {
            detections = data['detections'];
            print('📊 [DETECTION] Nombre de détections: ${detections.length}');
          } else {
            detections = [];
            print(
              '⚠️ [DETECTION] Aucune clé "results" ou "detections" trouvée',
            );
          }

          if (detections.isEmpty) {
            print('⚠️ [DETECTION] Liste de détections vide');
            return [];
          }

          print('🔄 [DETECTION] Conversion des détections en objets...');
          final results = detections.map((d) {
            print('   - Détection: $d');
            return DetectionResult.fromJson(d);
          }).toList();

          print(
            '✅ [DETECTION] ${results.length} détection(s) convertie(s) avec succès',
          );
          return results;
        } else {
          final errorMsg =
              data['error'] ?? 'Erreur inconnue lors de la détection';
          print('❌ [DETECTION] Erreur API: $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        print('❌ [DETECTION] Erreur HTTP ${response.statusCode}');
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [DETECTION] Exception: $e');
      print('❌ [DETECTION] Stack trace: ${StackTrace.current}');
      throw Exception('Échec de la détection d\'objets: $e');
    }
  }

  /// Détecte les objets à partir de bytes (pour le web)
  Future<List<DetectionResult>> detectObjectsFromBytes(
    List<int> imageBytes, {
    double conf = 0.5,
  }) async {
    try {
      // print('🔍 [DETECTION-BYTES] Début de la détection...');

      final base64Image = base64Encode(imageBytes);

      final requestBody = {
        'image': 'data:image/jpeg;base64,$base64Image',
        'conf': conf,
      };

      // Envoyer la requête à l'API Python avec le modèle YOLO avec timeout
      final response = await http
          .post(
            Uri.parse('$_baseUrl/detect'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Timeout: L\'API n\'a pas répondu dans les 30 secondes',
              );
            },
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

          if (detections.isEmpty) {
            // print('⚠️ [DETECTION-BYTES] Liste de détections vide');
            return [];
          }

          final results = detections.map((d) {
            return DetectionResult.fromJson(d);
          }).toList();

          print(
            '✅ [DETECTION-BYTES] ${results.length} détection(s) trouvée(s)',
          );
          return results;
        } else {
          final errorMsg =
              data['error'] ?? 'Erreur inconnue lors de la détection';
          print('❌ [DETECTION-BYTES] Erreur API: $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        print('❌ [DETECTION-BYTES] Erreur HTTP ${response.statusCode}');
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [DETECTION-BYTES] Exception: $e');
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
