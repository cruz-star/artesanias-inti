import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../storage/json_storage.dart';
import '../middleware/auth.dart';

Handler configRoutes(JsonStorage storage) {
  final router = Router();

  // GET /api/config
  router.get('/', (Request request) {
    final config = storage.findById('config', 'main');
    if (config == null) {
      return Response.ok(jsonEncode({}), headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(jsonEncode(config), headers: {'Content-Type': 'application/json'});
  });

  // POST /api/sync
  router.post('/sync', Pipeline().addMiddleware(requireAuth(storage)).addHandler((Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      // 1. Guardar Configuración y Pagos
      final configData = {
        'contact': data['contact'],
        'appConfig': data['appConfig'],
        'payment': data['payment'], // CBU, Titular, etc.
        'lastUpdate': data['lastUpdate'],
      };
      
      if (storage.findById('config', 'main') == null) {
        storage.insert('config', 'main', configData, push: false);
      } else {
        storage.update('config', 'main', configData, push: false);
      }
      
      // 2. Guardar Productos
      if (data['products'] != null) {
        storage.clearCollection('products', push: false);
        final List<dynamic> products = data['products'];
        for (var p in products) {
          final pMap = p as Map<String, dynamic>;
          storage.insert('products', pMap['id'].toString(), pMap, push: false);
        }
      }

      // 3. Empujar a GitHub (una sola vez por colección)
      await storage.forcePush('config');
      await storage.forcePush('products');

      return Response.ok(
        jsonEncode({'success': true, 'message': 'Sincronización exitosa'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error en la sincronización: $e'}),
        headers: {'Content-Type': 'application/json'}
      );
    }
  });

  return router.call;
}
