import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';

class ApiService {
  static const String fallbackUrl = Secrets.serverUrl;
  static String? _dynamicBaseUrl;

  Future<String> _getDiscoveryUrl() async {
    if (_dynamicBaseUrl != null) return _dynamicBaseUrl!;
    
    try {
      // Intentamos obtener la IP más reciente desde GitHub
      final response = await http.get(
        Uri.parse('https://raw.githubusercontent.com/cruz-star/artesanias-inti/main/config.json')
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _dynamicBaseUrl = data['url'];
        print('📡 Servidor detectado automáticamente en: $_dynamicBaseUrl');
        return _dynamicBaseUrl!;
      }
    } catch (e) {
      print('⚠️ No se pudo obtener IP dinámica de GitHub, usando fallback: $e');
    }
    
    return fallbackUrl;
  }

  // Sincronización masiva (Botón Publicar)
  Future<bool> syncData(Map<String, dynamic> data, {String? token}) async {
    final baseUrl = await _getDiscoveryUrl();
    final url = Uri.parse('$baseUrl/api/config/sync');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));

      print('Sync Response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error en ApiService.syncData: $e');
      return false;
    }
  }

  // Subir imagen al servidor
  Future<String?> uploadImage(String fileName, List<int> bytes, {String? token}) async {
    final baseUrl = await _getDiscoveryUrl();
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
      ).timeout(const Duration(seconds: 5));

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
    final baseUrl = await _getDiscoveryUrl();
    final url = Uri.parse('$baseUrl/api/config');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
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
    final baseUrl = await _getDiscoveryUrl();
    final url = Uri.parse('$baseUrl/api/products');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
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
