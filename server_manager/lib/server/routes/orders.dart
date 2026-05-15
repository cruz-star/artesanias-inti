import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../storage/json_storage.dart';
import '../middleware/auth.dart';

Handler orderRoutes(JsonStorage storage) {
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

  // GET /api/orders/ - Protegido (solo admin puede ver todos los pedidos)
  router.get('/', (Request request) async {
    final authError = await checkAuth(request);
    if (authError != null) return authError;

    final orders = storage.findAll('orders').map((json) => Order.fromJson(json).toJson()).toList();
    // Sort by newest first
    orders.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
    return Response.ok(jsonEncode(orders), headers: {'Content-Type': 'application/json'});
  });

  // POST /api/orders/ - Público (cualquier cliente puede hacer un pedido)
  router.post('/', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      final items = (data['items'] as List).map((e) {
        final itemMap = e as Map<String, dynamic>;
        return OrderItem(
          productId: itemMap['productId'],
          name: itemMap['name'],
          quantity: itemMap['quantity'],
          price: (itemMap['price'] as num).toDouble(),
        );
      }).toList();

      final totalAmount = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

      final order = Order(
        id: uuid.v4(),
        customerName: data['customerName'] ?? 'Invitado',
        customerEmail: data['customerEmail'] ?? '',
        customerPhone: data['customerPhone'] ?? '',
        shippingAddress: data['shippingAddress'] ?? '',
        shippingCity: data['shippingCity'] ?? '',
        shippingZip: data['shippingZip'] ?? '',
        items: items,
        totalAmount: totalAmount,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      storage.insert('orders', order.id, order.toJson());
      print('📢 [NOTIFICACIÓN] ¡Nuevo pedido recibido! De: ${order.customerName} - Total: \$${order.totalAmount}');
      return Response.ok(jsonEncode(order.toJson()), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': 'Invalid payload: $e'}), headers: {'Content-Type': 'application/json'});
    }
  });

  // PUT /api/orders/<id>/status - Protegido
  router.put('/<id>/status', (Request request, String id) async {
    final authError = await checkAuth(request);
    if (authError != null) return authError;

    final existingJson = storage.findById('orders', id);
    if (existingJson == null) {
      return Response.notFound(jsonEncode({'error': 'Order not found'}), headers: {'Content-Type': 'application/json'});
    }

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      final existing = Order.fromJson(existingJson);
      final updated = Order(
        id: existing.id,
        customerName: existing.customerName,
        customerEmail: existing.customerEmail,
        customerPhone: existing.customerPhone,
        shippingAddress: existing.shippingAddress,
        shippingCity: existing.shippingCity,
        shippingZip: existing.shippingZip,
        items: existing.items,
        totalAmount: existing.totalAmount,
        status: data['status'] ?? existing.status,
        createdAt: existing.createdAt,
      );

      storage.update('orders', id, updated.toJson());
      return Response.ok(jsonEncode(updated.toJson()), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': 'Invalid payload: $e'}), headers: {'Content-Type': 'application/json'});
    }
  });

  return router.call;
}
