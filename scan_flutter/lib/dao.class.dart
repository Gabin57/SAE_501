import 'dart:convert';
import 'package:http/http.dart' as http;

class DAO {
  // URL de base de votre API
  static const String baseUrl = 'http://localhost:5000';  
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
      // Pour la table COMPTES, on utilise 'num' comme identifiant
      final idField = table == 'COMPTES' ? 'num' : 'id';
      
      if (!data.containsKey(idField)) {
        throw Exception('Le champ d\'identification ($idField) est requis pour la mise à jour');
      }
      
      final id = data[idField];
      
      // Créer une copie des données pour la mise à jour
      final updateData = Map<String, dynamic>.from(data);
      
      // Pour la table COMPTES, on utilise 'num' comme identifiant
      if (table == 'COMPTES') {
        // On s'assure que 'num' est présent dans les données
        if (!updateData.containsKey('num')) {
          updateData['num'] = id;
        }
        
        // On ajoute un ID factice pour satisfaire l'API
        updateData['id'] = id;
      }
      
      // Construire l'URL avec le paramètre d'action
      final url = '$baseUrl/$table?action=update';
      
      print('PUT $url');
      print('Data: $updateData');
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(updateData),
      );
      
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      } else {
        throw Exception('Échec de la mise à jour: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      final error = 'Erreur lors de la mise à jour: $e';
      print(error);
      throw Exception(error);
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
  static Future<Map<String, dynamic>?> getById(String table, dynamic id) async {
    try {
      // Pour la table COMPTES, on utilise 'num' comme identifiant
      final idField = table == 'COMPTES' ? 'num' : 'id';

      // D'abord, on récupère tous les éléments
      final allItems = await getAll(table);

      // Puis on filtre localement pour trouver l'élément avec l'ID correspondant
      final item = allItems.firstWhere(
        (item) => item[idField].toString() == id.toString(),
        orElse: () => null,
      );

      if (item == null) {
        print('Aucun élément trouvé avec l\'ID $id dans la table $table');
        return null;
      } else {
        print('Élément trouvé: $item');
        
        // Pour la table COMPTES, s'assurer que l'ID est inclus dans la réponse
        if (table == 'COMPTES' && idField == 'num' && item['id'] == null) {
          // Si l'ID n'est pas dans l'élément, on l'ajoute en tant que clé secondaire
          final itemWithId = Map<String, dynamic>.from(item);
          // On utilise l'index dans la liste + 1 comme ID temporaire si nécessaire
          // C'est une solution de contournement si l'API ne renvoie pas l'ID
          itemWithId['id'] = allItems.indexOf(item) + 1;
          return itemWithId;
        }
        
        return item as Map<String, dynamic>;
      }
    } catch (e) {
      final error = 'Erreur lors de la récupération de l\'élément: $e';
      print(error);
      throw Exception(error);
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