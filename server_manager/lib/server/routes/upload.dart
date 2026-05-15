import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../storage/json_storage.dart';
import '../middleware/auth.dart';

Handler uploadRoutes(JsonStorage storage) {
  final router = Router();
  final uuid = Uuid();

  // POST /api/upload
  router.post('/', Pipeline().addMiddleware(requireAuth(storage)).addHandler((Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      final String? fileName = data['fileName'];
      final String? base64Data = data['data']; // Contenido en base64

      if (fileName == null || base64Data == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Falta fileName o data (base64)'}),
          headers: {'Content-Type': 'application/json'}
        );
      }

      // Limpiar prefijo "data:image/jpeg;base64," si existe (común en web)
      String cleanBase64 = base64Data;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      // Generar nombre único para evitar colisiones
      final ext = fileName.split('.').last;
      final uniqueName = '${uuid.v4()}.$ext';
      
      final publicDir = Directory('public/media');
      if (!publicDir.existsSync()) {
        publicDir.createSync(recursive: true);
      }

      final file = File('public/media/$uniqueName');
      print('[Upload] Guardando archivo en: ${file.absolute.path}');
      
      final bytes = base64Decode(cleanBase64.replaceAll('\n', '').replaceAll('\r', ''));
      file.writeAsBytesSync(bytes);

      return Response.ok(
        jsonEncode({
          'success': true,
          'url': 'public/media/$uniqueName', // Ruta relativa al servidor
          'fileName': uniqueName
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error al guardar la imagen: $e'}),
        headers: {'Content-Type': 'application/json'}
      );
    }
  }));

  return router.call;
}
