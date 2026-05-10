import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';

class GitHubService {
  static const String owner = 'cruz-star';
  static const String repo = 'artesanias-inti';
  static const String path = 'productos.json';
  static const String token = Secrets.githubToken;

  Future<bool> uploadJson(String jsonContent) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    
    try {
      // 1. Intentar obtener el SHA del archivo (si existe)
      String? sha;
      final getRes = await http.get(
        url,
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (getRes.statusCode == 200) {
        final body = jsonDecode(getRes.body);
        sha = body['sha'];
      }
      // Si es 404, simplemente sha queda como null y seguimos para crear el archivo

      // 2. Subir o Actualizar el archivo
      final putRes = await http.put(
        url,
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'Sincronización desde App Artesanías Inti',
          'content': base64Encode(utf8.encode(jsonContent)),
          if (sha != null) 'sha': sha,
        }),
      );

      print('GitHub Response: ${putRes.statusCode}');
      print('GitHub Body: ${putRes.body}');

      return putRes.statusCode == 200 || putRes.statusCode == 201;
    } catch (e) {
      print('Error crítico en GitHubService: $e');
      return false;
    }
  }

  Future<String?> fetchJson() async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final content = body['content'] as String;
        // El contenido está en Base64, hay que decodificarlo
        final decoded = utf8.decode(base64.decode(content.replaceAll('\n', '')));
        return decoded;
      }
      return null;
    } catch (e) {
      print('Error al descargar JSON de GitHub: $e');
      return null;
    }
  }
}
