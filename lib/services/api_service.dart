import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';

class ApiService {
  static const String baseUrl = Secrets.serverUrl;

  // Sincronización masiva (Botón Publicar)
  Future<bool> syncData(Map<String, dynamic> data, {String? token}) async {
    final url = Uri.parse('$baseUrl/api/config/sync');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      print('Sync Response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error en ApiService.syncData: $e');
      return false;
    }
  }

  // Subir imagen al servidor
  Future<String?> uploadImage(String fileName, List<int> bytes, {String? token}) async {
    final url = Uri.parse('$baseUrl/api/upload');
    
    try {
      final base64Data = base64Encode(bytes);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fileName': fileName,
          'data': base64Data,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['url']; // Ej: "public/media/uuid.jpg"
      }
      return null;
    } catch (e) {
      print('Error en ApiService.uploadImage: $e');
      return null;
    }
  }

  // Descargar configuración (incluye pagos y contacto)
  Future<Map<String, dynamic>?> fetchConfig() async {
    final url = Uri.parse('$baseUrl/api/config');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error en ApiService.fetchConfig: $e');
      return null;
    }
  }

  // Descargar productos
  Future<List<dynamic>?> fetchProducts() async {
    final url = Uri.parse('$baseUrl/api/products');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return null;
    } catch (e) {
      print('Error en ApiService.fetchProducts: $e');
      return null;
    }
  }
}
