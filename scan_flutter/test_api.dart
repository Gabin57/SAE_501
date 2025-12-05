import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'http://51.38.64.145:5001';
  
  print('Test de connexion à l\'API...\n');
  
  // Test 1: Endpoint panneaux
  print('1. Test endpoint /panneaux?action=getAll');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/panneaux?action=getAll'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));
    
    print('   Status: ${response.statusCode}');
    print('   Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
  } catch (e) {
    print('   ❌ Erreur: $e');
  }
  
  print('\n2. Test endpoint /detect (GET pour vérifier la disponibilité)');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/detect'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));
    
    print('   Status: ${response.statusCode}');
    print('   Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
  } catch (e) {
    print('   ❌ Erreur: $e');
  }
  
  print('\n3. Test de ping simple');
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(baseUrl))
        .timeout(const Duration(seconds: 5));
    final response = await request.close()
        .timeout(const Duration(seconds: 5));
    print('   ✅ Serveur accessible (Status: ${response.statusCode})');
    client.close();
  } catch (e) {
    print('   ❌ Serveur inaccessible: $e');
  }
  
  print('\nTest terminé.');
}

