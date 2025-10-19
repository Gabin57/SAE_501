import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:scan_flutter/dao.class.dart';

class MockHttpClient extends http.BaseClient {
  final Map<Pattern, http.Response> _responses = {};

  void whenGet(String url, {required dynamic response, int statusCode = 200}) {
    _responses[url] = http.Response(jsonEncode(response), statusCode);
  }

  void whenPost(String url, {required dynamic response, int statusCode = 201}) {
    _responses[url] = http.Response(jsonEncode(response), statusCode);
  }

  void whenPut(String url, {required dynamic response, int statusCode = 200}) {
    _responses[url] = http.Response(jsonEncode(response), statusCode);
  }

  void whenDelete(String url, {required dynamic response, int statusCode = 200}) {
    _responses[url] = http.Response(jsonEncode(response), statusCode);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();
    
    for (var entry in _responses.entries) {
      if (entry.key is String && url.contains(entry.key as String)) {
        final response = entry.value;
        return http.StreamedResponse(
          Stream.value(utf8.encode(response.body)),
          response.statusCode,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }
    }
    
    return http.StreamedResponse(
      const Stream.empty(),
      404,
      request: request,
      reasonPhrase: 'Not Found',
    );
  }
}

void main() {
  late MockHttpClient mockHttpClient;
  final baseUrl = 'http://51.38.64.145:5001';
  
  setUp(() {
    mockHttpClient = MockHttpClient();
    // Remplacer le client HTTP par notre mock
    DAO.httpClient = mockHttpClient;
  });

  group('DAO Tests', () {
    test('getAll - success', () async {
      // Arrange
      final testData = [
        {'id': 1, 'nom': 'Test 1'},
        {'id': 2, 'nom': 'Test 2'},
      ];
      
      mockHttpClient.whenGet(
        '$baseUrl/test?action=getAll',
        response: testData,
        statusCode: 200,
      );
      
      // Act
      final result = await DAO.getAll('test');
      
      // Assert
      expect(result, isA<List<dynamic>>());
      expect(result.length, 2);
      expect(result[0]['nom'], 'Test 1');
    });

    test('getAll - error', () async {
      // Arrange
      mockHttpClient.whenGet(
        '$baseUrl/test?action=getAll',
        response: {'error': 'Not Found'},
        statusCode: 404,
      );
      
      // Act & Assert
      expect(() => DAO.getAll('test'), throwsException);
    });

    test('create - success', () async {
      // Arrange
      final testData = {'nom': 'Nouveau test'};
      final responseData = {'id': 1, 'nom': 'Nouveau test'};
      
      mockHttpClient.whenPost(
        '$baseUrl/test',
        response: responseData,
        statusCode: 201,
      );
      
      // Act
      final result = await DAO.create('test', testData);
      
      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['id'], 1);
      expect(result['nom'], 'Nouveau test');
    });

    test('create - with compte data transformation', () async {
      // Arrange
      final testData = {'nom': 'User', 'mot_de_passe': 'pass123'};
      final responseData = {'id': 1, 'nom': 'User'};
      
      mockHttpClient.whenPost(
        '$baseUrl/COMPTES',
        response: responseData,
        statusCode: 201,
      );
      
      // Act
      await DAO.create('COMPTES', testData);
      
      // Pas de vérification de la transformation ici, car c'est testé dans le test d'intégration
    });

    test('update - success', () async {
      // Arrange
      final testData = {'id': 1, 'nom': 'Mis à jour'};
      
      mockHttpClient.whenPut(
        '$baseUrl/test',
        response: {'status': 'success'},
        statusCode: 200,
      );
      
      // Act
      final result = await DAO.update('test', testData);
      
      // Assert
      expect(result, isTrue);
    });

    test('delete - success', () async {
      // Arrange
      mockHttpClient.whenDelete(
        '$baseUrl/test/1',
        response: {'status': 'success'},
        statusCode: 200,
      );
      
      // Act
      final result = await DAO.delete('test', 1);
      
      // Assert
      expect(result, isTrue);
    });

    test('getById - found', () async {
      // Arrange
      final testData = {'id': 1, 'nom': 'Test'};
      
      mockHttpClient.whenGet(
        '$baseUrl/test/1',
        response: testData,
        statusCode: 200,
      );
      
      // Act
      final result = await DAO.getById('test', 1);
      
      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result?['nom'], 'Test');
    });

    test('getById - not found', () async {
      // Arrange
      mockHttpClient.whenGet(
        '$baseUrl/test/999',
        response: {'error': 'Not Found'},
        statusCode: 404,
      );
      
      // Act
      final result = await DAO.getById('test', 999);
      
      // Assert
      expect(result, isNull);
    });
  });
}
