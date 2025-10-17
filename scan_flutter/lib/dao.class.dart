import 'dart:convert';
import 'package:http/http.dart' as http;

class DAO {
  // URL de base de votre API
  static const String baseUrl = 'http://51.38.64.145:5001';  
  // Pour émulateur Android
  // Pour émulateur iOS ou appareil physique, utilisez l'IP de votre machine :
  // static const String baseUrl = 'http://VOTRE_IP_LOCALE:5000';
  // Pour une API en production :
  // static const String baseUrl = 'https://votre-domaine.com/api';

  // Client HTTP personnalisable pour les tests
  static http.Client _httpClient = http.Client();

  // Getter et setter pour le client HTTP (pour les tests)
  static http.Client get httpClient => _httpClient;
  static set httpClient(http.Client client) => _httpClient = client;

  // Endpoints - en minuscules pour correspondre aux noms des tables
  static const String comptesEndpoint = '$baseUrl/comptes';
  static const String panneauxEndpoint = '$baseUrl/panneaux';
  static const String liaisonsPanneauxEndpoint = '$baseUrl/liaisons_panneaux';

  // Headers communs
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Méthode générique pour récupérer tous les éléments d'une table
  static Future<List<dynamic>> getAll(String table) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/$table?action=getAll'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Échec du chargement des données: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la connexion à l\'API: $e');
    }
  }

  // Méthode générique pour créer un nouvel élément
  static Future<dynamic> create(String table, Map<String, dynamic> data) async {
    try {
      // Nettoyer les données avant envoi
      final cleanedData = Map<String, dynamic>.from(data);
      
      // Gestion spécifique par table
      switch (table.toUpperCase()) {
        case 'COMPTES':
          // S'assurer que le mot de passe utilise le bon nom de champ
          if (data.containsKey('mot_de_passe')) {
            cleanedData['motdepasse'] = cleanedData.remove('mot_de_passe');
          }
          // Ajouter un numéro unique si nécessaire
          if (!cleanedData.containsKey('num')) {
            cleanedData['num'] = DateTime.now().millisecondsSinceEpoch % 1000000;
          }
          break;
          
        case 'PANNEAUX':
          // Supprimer le champ code s'il n'existe pas
          if (data.containsKey('code') && !data.containsKey('nom')) {
            cleanedData['nom'] = cleanedData.remove('code');
          }
          break;
          
        case 'LIAISONS_PANNEAUX':
          // Corriger le nom du champ si nécessaire
          if (data.containsKey('id_panneau_1')) {
            cleanedData['id_panneau1'] = cleanedData.remove('id_panneau_1');
          }
          if (data.containsKey('id_panneau_2')) {
            cleanedData['id_panneau2'] = cleanedData.remove('id_panneau_2');
          }
          break;
      }

      print('Envoi des données à l\'API: $cleanedData'); // Debug
      
      final response = await httpClient.post(
        Uri.parse('$baseUrl/$table'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(cleanedData),
      );
      
      print('Réponse de l\'API: ${response.statusCode} - ${response.body}'); // Debug
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Échec de la création (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la création: $e'); // Debug
      throw Exception('Erreur lors de la connexion à l\'API: $e');
    }
  }

  // Méthode générique pour mettre à jour un élément
  static Future<bool> update(String table, Map<String, dynamic> data) async {
    try {
      final response = await httpClient.put(
        Uri.parse('$baseUrl/$table'),
        headers: headers,
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      } else {
        throw Exception('Échec de la mise à jour: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la connexion à l\'API: $e');
    }
  }

  // Méthode générique pour supprimer un élément
  static Future<bool> delete(String table, dynamic id) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/$table/$id'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      } else {
        throw Exception('Échec de la suppression: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la connexion à l\'API: $e');
    }
  }

  // Méthode générique pour récupérer un élément par son ID
  static Future<dynamic> getById(String table, dynamic id) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/$table/$id'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null; // Non trouvé
      } else {
        throw Exception('Échec de la récupération: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la connexion à l\'API: $e');
    }
  }
}