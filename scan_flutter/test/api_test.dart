import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:scan_flutter/dao.class.dart';

void main() {
  group('Tests DAO', () {
    // Test de récupération de tous les comptes
    test('Récupération de tous les comptes', () async {
      try {
        final comptes = await DAO.getAll('COMPTES');
        print('Comptes récupérés: ${comptes.length}');
        expect(comptes, isA<List>());
      } catch (e) {
        fail('Erreur lors de la récupération des comptes: $e');
      }
    });

    // Test de création d'un nouveau compte
    test('Création et suppression d\'un compte', () async {
      final testUser = {
        'identifiant': 'TestUser${DateTime.now().millisecondsSinceEpoch}',
        'email': 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        'motdepasse': 'test123',
        'num': DateTime.now().millisecondsSinceEpoch % 10000
      };

      // Test de création
      final nouveauCompte = await DAO.create('COMPTES', testUser);
      print('Nouveau compte créé: ${nouveauCompte.toString()}');
      expect(nouveauCompte, isA<Map>());
      expect(nouveauCompte, contains('id'));

      final id = nouveauCompte['id'];
      
      // Test de récupération par ID
      final compteRecupere = await DAO.getById('COMPTES', id);
      print('Compte récupéré: ${compteRecupere.toString()}');
      expect(compteRecupere, isNotNull);
      expect(compteRecupere['identifiant'], testUser['identifiant']);
      expect(compteRecupere['email'], testUser['email']);

      // Test de mise à jour
      final donneesMiseAJour = {
        'id': id,
        'email': 'update${DateTime.now().millisecondsSinceEpoch}@example.com'
      };
      
      final miseAJourReussie = await DAO.update('COMPTES', donneesMiseAJour);
      print('Mise à jour réussie: $miseAJourReussie');
      expect(miseAJourReussie, isTrue);

      // Vérification de la mise à jour
      final compteMiseAJour = await DAO.getById('COMPTES', id);
      expect(compteMiseAJour['email'], donneesMiseAJour['email']);

      // Test de suppression
      final suppressionReussie = await DAO.delete('COMPTES', id);
      print('Suppression réussie: $suppressionReussie');
      expect(suppressionReussie, isTrue);

      // Vérification de la suppression
      final compteSupprime = await DAO.getById('COMPTES', id);
      expect(compteSupprime, isNull);
    });

    // Test des méthodes spécifiques pour rétrocompatibilité
    test('Méthodes spécifiques de comptes', () async {
      // Test de création avec la méthode spécifique
      final testUser = {
        'identifiant': 'TestUser${DateTime.now().millisecondsSinceEpoch}',
        'email': 'specific${DateTime.now().millisecondsSinceEpoch}@example.com',
        'motdepasse': 'test123',
        'num': DateTime.now().millisecondsSinceEpoch % 10000
      };

      final nouveauCompte = await DAO.createCompte(testUser);
      final id = nouveauCompte['id'];
      
      // Test de récupération par ID avec la méthode spécifique
      final compte = await DAO.getCompteById(id);
      expect(compte, isNotNull);
      
      // Test de suppression avec la méthode spécifique
      final suppressionReussie = await DAO.deleteCompte(id);
      expect(suppressionReussie, isTrue);
    });
  });
}
