import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';

final env = DotEnv(includePlatformEnvironment: true)..load();

class GitHubSync {
  final String owner = 'cruz-star';
  final String repo = 'artesanias-inti';
  // El path base que especificaste para los archivos:
  final String basePath = 'customer_web_v3'; 
  
  // Mapeo de colecciones a nombres de archivo reales en GitHub
  String getFileName(String collection) {
    if (collection == 'products') return 'productos.json';
    if (collection == 'orders') return 'pedidos.json';
    return '$collection.json';
  }
  String? get token => env['GITHUB_TOKEN'];

  Map<String, String> get _headers => {
        'Accept': 'application/vnd.github.v3+json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
        'Cache-Control': 'no-cache',
      };

  // Empuja los datos de una colección (como products o orders) a GitHub
  Future<void> pushData(String collection, Map<String, Map<String, dynamic>> fullData) async {
    if (token == null || token!.isEmpty) {
      print('[GitHubSync] ⚠️ Advertencia: GITHUB_TOKEN no está configurado. Los datos solo se guardaron localmente.');
      return;
    }

    // Convertimos el mapa interno a la estructura JSON real (lista de objetos, o un solo objeto para config)
    final List<Map<String, dynamic>> listData = fullData[collection]!
        .values
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final path = '$basePath/${getFileName(collection)}';
    // Codificando la URL por si tiene espacios (como "web del cliente")
    final encodedPath = Uri.encodeFull(path);
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$encodedPath');

    // 1. Obtener el SHA actual del archivo (GitHub lo requiere para poder actualizar un archivo existente)
    String? sha;
    try {
      final getRes = await http.get(url, headers: _headers);
      if (getRes.statusCode == 200) {
        final getBody = jsonDecode(getRes.body);
        sha = getBody['sha'];
      }
    } catch (e) {
      print('[GitHubSync] Error de red al obtener SHA: $e');
    }

    // 2. Preparar el contenido codificado en Base64
    final listJsonString = collection == 'config' && listData.isNotEmpty
        ? jsonEncode(listData.first)
        : jsonEncode(listData);
    final contentBytes = utf8.encode(listJsonString);
    final base64Content = base64Encode(contentBytes);

    // 3. Hacer el commit
    final String commitMessage = collection == 'products' 
        ? '📦 Catálogo actualizado: ${DateTime.now().toLocal()}'
        : collection == 'orders'
            ? '🛒 Nuevo pedido registrado: ${DateTime.now().toLocal()}'
            : '⚙️ Configuración actualizada: ${DateTime.now().toLocal()}';

    final Map<String, dynamic> commitData = {
      'message': commitMessage,
      'content': base64Content,
    };
    if (sha != null) {
      commitData['sha'] = sha; // Incluimos el SHA si el archivo ya existía
    }

    try {
      final putRes = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(commitData),
      );

      if (putRes.statusCode == 200 || putRes.statusCode == 201) {
        print('[GitHubSync] ✅ Éxito: $collection.json sincronizado con GitHub.');
      } else {
        print('[GitHubSync] ❌ Fallo al sincronizar: ${putRes.statusCode} - ${putRes.body}');
      }
    } catch (e) {
      print('[GitHubSync] ❌ Error crítico al sincronizar: $e');
    }
  }

  // Descarga los datos de una colección desde GitHub
  Future<List<Map<String, dynamic>>?> pullData(String collection) async {
    if (token == null || token!.isEmpty) {
      print('[GitHubSync] ⚠️ Advertencia: GITHUB_TOKEN no está configurado. No se puede descargar $collection.json de GitHub.');
      return null;
    }

    final path = '$basePath/${getFileName(collection)}';
    final encodedPath = Uri.encodeFull(path);
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$encodedPath');

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final content = body['content'] as String;
        // GitHub API devuelve el contenido en Base64 separado por saltos de línea
        final normalizedContent = content.replaceAll('\n', '');
        final decodedBytes = base64Decode(normalizedContent);
        final jsonString = utf8.decode(decodedBytes);
        
        final decodedData = jsonDecode(jsonString);
        if (decodedData is List) {
          return decodedData.map((e) => e as Map<String, dynamic>).toList();
        } else if (decodedData is Map) {
          return [decodedData as Map<String, dynamic>];
        }
      } else if (response.statusCode == 404) {
        print('[GitHubSync] ℹ️ El archivo $collection.json no existe aún en GitHub.');
        return [];
      } else {
        print('[GitHubSync] ❌ Fallo al descargar $collection.json: ${response.statusCode}');
      }
    } catch (e) {
      print('[GitHubSync] ❌ Error de red al descargar: $e');
    }
    return null;
  }
}
