import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../storage/json_storage.dart';
import '../middleware/auth.dart';

Handler productRoutes(JsonStorage storage) {
  final router = Router();
  final uuid = Uuid();

  // Middleware opcional para verificar auth en rutas protegidas
  Future<Response?> checkAuth(Request request) async {
    final authRequest = authenticateRequest(request, storage);
    final isAuthenticated = authRequest.context['authenticated'] as bool? ?? false;
    if (!isAuthenticated) {
      return Response.forbidden(
        jsonEncode({'error': 'Authentication required. Admin only.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return null; // Todo bien
  }

  // GET /api/products/ - Público
  router.get('/', (Request request) {
    final products = storage.findAll('products').map((json) => Product.fromJson(json).toJson()).toList();
    return Response.ok(jsonEncode(products), headers: {'Content-Type': 'application/json'});
  });

  // GET /api/products/<id> - Público
  router.get('/<id>', (Request request, String id) {
    final productJson = storage.findById('products', id);
    if (productJson == null) {
      return Response.notFound(jsonEncode({'error': 'Product not found'}), headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(jsonEncode(productJson), headers: {'Content-Type': 'application/json'});
  });

  // POST /api/products/ - Protegido
  router.post('/', (Request request) async {
    final authError = await checkAuth(request);
    if (authError != null) return authError;

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      final product = Product(
        id: uuid.v4(),
        name: data['name'],
        description: data['description'],
        price: (data['price'] as num).toDouble(),
        category: data['category'] ?? 'General',
        mediaUrls: (data['mediaUrls'] as List?)?.map((e) => e as String).toList() ?? [],
        stock: data['stock'] ?? 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      storage.insert('products', product.id, product.toJson());
      return Response.ok(jsonEncode(product.toJson()), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': 'Invalid payload: $e'}), headers: {'Content-Type': 'application/json'});
    }
  });

  // PUT /api/products/<id> - Protegido
  router.put('/<id>', (Request request, String id) async {
    final authError = await checkAuth(request);
    if (authError != null) return authError;

    final existingJson = storage.findById('products', id);
    if (existingJson == null) {
      return Response.notFound(jsonEncode({'error': 'Product not found'}), headers: {'Content-Type': 'application/json'});
    }

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final existing = Product.fromJson(existingJson);

      final updated = Product(
        id: existing.id,
        name: data['name'] ?? existing.name,
        description: data['description'] ?? existing.description,
        price: data['price'] != null ? (data['price'] as num).toDouble() : existing.price,
        category: data['category'] ?? existing.category,
        mediaUrls: data['mediaUrls'] != null ? (data['mediaUrls'] as List).map((e) => e as String).toList() : existing.mediaUrls,
        stock: data['stock'] ?? existing.stock,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      storage.update('products', id, updated.toJson());
      return Response.ok(jsonEncode(updated.toJson()), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': 'Invalid payload: $e'}), headers: {'Content-Type': 'application/json'});
    }
  });

  // DELETE /api/products/<id> - Protegido
  router.delete('/<id>', (Request request, String id) async {
    final authError = await checkAuth(request);
    if (authError != null) return authError;

    final deleted = storage.delete('products', id);
    if (!deleted) {
      return Response.notFound(jsonEncode({'error': 'Product not found'}), headers: {'Content-Type': 'application/json'});
    }

    return Response.ok(jsonEncode({'success': true}), headers: {'Content-Type': 'application/json'});
  });

  return router.call;
}
