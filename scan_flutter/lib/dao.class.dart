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

  // Endpoints
  static const String comptesEndpoint = '$baseUrl/COMPTES';
  static const String panneauxEndpoint = '$baseUrl/PANNEAUX';
  static const String liaisonsPanneauxEndpoint = '$baseUrl/LIAISONS_PANNEAUX';

  // Headers communs
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Méthode générique pour récupérer tous les éléments d'une table
  static Future<List<dynamic>> getAll(String table) async {
    try {
      final response = await http.get(
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
      final response = await http.post(
        Uri.parse('$baseUrl/$table'),
        headers: headers,
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Échec de la création: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la connexion à l\'API: $e');
    }
  }

  // Méthode générique pour mettre à jour un élément
  static Future<bool> update(String table, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
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
      final response = await http.delete(
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
      final response = await http.get(
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

  // Méthodes spécifiques pour rétrocompatibilité
  static Future<List<dynamic>> getAllComptes() => getAll('COMPTES');
  static Future<dynamic> createCompte(Map<String, dynamic> data) => create('COMPTES', data);
  static Future<bool> updateCompte(Map<String, dynamic> data) => update('COMPTES', data);
  static Future<bool> deleteCompte(dynamic id) => delete('COMPTES', id);
  static Future<dynamic> getCompteById(dynamic id) => getById('COMPTES', id);
  
  // Ajoutez ici d'autres méthodes spécifiques si nécessaire...
}