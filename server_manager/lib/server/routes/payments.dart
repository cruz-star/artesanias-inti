import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';

import '../storage/json_storage.dart';
import '../models/models.dart';

final env = DotEnv(includePlatformEnvironment: true)..load();

Handler paymentRoutes(JsonStorage storage) {
  final router = Router();
  final String? mpToken = env['MERCADOPAGO_ACCESS_TOKEN'];

  // POST /api/payments/create-preference
  // Crea una preferencia de pago en Mercado Pago y devuelve el init_point
  router.post('/create-preference', (Request request) async {
    if (mpToken == null || mpToken.isEmpty || mpToken.startsWith('TEST-')) {
      print('[Payment] ⚠️ MP Token no configurado o es de prueba. Usando modo simulado.');
    }

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final orderId = data['orderId'] as String;
      
      final orderJson = storage.findById('orders', orderId);
      if (orderJson == null) {
        return Response.notFound(jsonEncode({'error': 'Order not found'}));
      }
      
      final order = Order.fromJson(orderJson);

      // 1. Preparar items para Mercado Pago
      final items = order.items.map((item) => {
        'title': item.name,
        'quantity': item.quantity,
        'unit_price': item.price,
        'currency_id': 'ARS'
      }).toList();

      // 2. Llamar a la API de Mercado Pago
      final mpUrl = Uri.parse('https://api.mercadopago.com/checkout/preferences');
      final mpResponse = await http.post(
        mpUrl,
        headers: {
          'Authorization': 'Bearer $mpToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'items': items,
          'external_reference': orderId,
          'back_urls': {
            'success': 'http://localhost:8080/store/success.html',
            'pending': 'http://localhost:8080/store/pending.html',
            'failure': 'http://localhost:8080/store/failure.html',
          },
          'auto_return': 'approved',
          'notification_url': 'https://your-public-url.com/api/payments/webhook', // Nota: requiere HTTPS público
        }),
      );

      if (mpResponse.statusCode == 200 || mpResponse.statusCode == 201) {
        final mpData = jsonDecode(mpResponse.body);
        return Response.ok(jsonEncode({
          'preferenceId': mpData['id'],
          'initPoint': mpData['init_point'],
          'sandboxInitPoint': mpData['sandbox_init_point'],
        }), headers: {'Content-Type': 'application/json'});
      } else {
        print('[Payment] Error de Mercado Pago: ${mpResponse.body}');
        // Modo simulado si falla la API (por token inválido)
        return Response.ok(jsonEncode({
          'preferenceId': 'simulated_pref_${orderId}',
          'initPoint': 'http://localhost:8080/store/success.html?orderId=$orderId',
          'simulated': true
        }), headers: {'Content-Type': 'application/json'});
      }
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': e.toString()}));
    }
  });

  // POST /api/payments/webhook
  // Recibe notificaciones de Mercado Pago sobre cambios en el estado del pago
  router.post('/webhook', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      print('[Payment Webhook] Recibido: $data');

      if (data['type'] == 'payment') {
        final paymentId = data['data']['id'];
        
        // Consultar estado del pago
        final paymentUrl = Uri.parse('https://api.mercadopago.com/v1/payments/$paymentId');
        final paymentRes = await http.get(paymentUrl, headers: {'Authorization': 'Bearer $mpToken'});
        
        if (paymentRes.statusCode == 200) {
          final paymentData = jsonDecode(paymentRes.body);
          final orderId = paymentData['external_reference'];
          final status = paymentData['status'];

          if (orderId != null) {
            final orderJson = storage.findById('orders', orderId);
            if (orderJson != null) {
              final order = Order.fromJson(orderJson);
              final updatedOrder = Order(
                id: order.id,
                userId: order.userId,
                customerName: order.customerName,
                customerEmail: order.customerEmail,
                customerPhone: order.customerPhone,
                shippingAddress: order.shippingAddress,
                shippingCity: order.shippingCity,
                shippingZip: order.shippingZip,
                items: order.items,
                totalAmount: order.totalAmount,
                status: status == 'approved' ? 'paid' : 'pending',
                paymentMethod: 'MercadoPago',
                paymentId: paymentId.toString(),
                createdAt: order.createdAt,
              );
              storage.update('orders', orderId, updatedOrder.toJson());
              print('[Payment] Orden $orderId actualizada a estado: ${updatedOrder.status}');
            }
          }
        }
      }
      
      return Response.ok('OK');
    } catch (e) {
      print('[Payment Webhook] Error: $e');
      return Response.internalServerError();
    }
  });

  return router.call;
}
