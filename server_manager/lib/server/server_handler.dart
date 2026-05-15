import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import 'middleware/auth.dart';
import 'routes/payments.dart';
import 'routes/auth.dart';
import 'routes/products.dart';
import 'routes/orders.dart';
import 'routes/config.dart';
import 'routes/upload.dart';
import 'storage/json_storage.dart';
import 'server_config.dart';

class IntiServer {
  final JsonStorage storage;
  final int port;
  final String publicDir;
  final String? storefrontDir;

  IntiServer({
    required this.storage,
    required this.port,
    required this.publicDir,
    this.storefrontDir,
  });

  Future<HttpServer> start() async {
    final router = Router();

    // Ensure public directory exists
    final mediaDir = Directory('$publicDir/media');
    if (!mediaDir.existsSync()) {
      mediaDir.createSync(recursive: true);
    }

    router.get('/', _rootHandler);
    router.get('/api/health', _healthHandler);

    router.mount('/api/auth/', authRoutes(storage));
    router.mount('/api/products/', productRoutes(storage));
    router.mount('/api/orders/', orderRoutes(storage));
    router.mount('/api/config/', configRoutes(storage));
    router.mount('/api/upload/', uploadRoutes(storage));
    router.mount('/api/payments/', paymentRoutes(storage));

    // Serve static files from the storefront directory if provided
    if (storefrontDir != null && Directory(storefrontDir!).existsSync()) {
      final staticHandler = createStaticHandler(storefrontDir!, defaultDocument: 'index.html', listDirectories: true);
      router.mount('/store/', staticHandler);
    }

    // Serve media files from the public directory
    final mediaHandler = createStaticHandler(publicDir, listDirectories: true);
    router.mount('/public/', mediaHandler);

    final handler = Pipeline()
        .addMiddleware(_loggingMiddleware())
        .addMiddleware(_corsMiddleware())
        .addHandler(router);

    final server = await io.serve(handler, '0.0.0.0', port);
    
    ServerConfig().log('Artesanías Inti Server running on port ${server.port}');
    ServerConfig().isRunning = true;
    ServerConfig().server = server;

    return server;
  }

  Response _rootHandler(Request request) {
    return Response.ok(
      jsonEncode({'name': 'Artesanías Inti API', 'version': '1.0.1', 'platform': Platform.operatingSystem}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _healthHandler(Request request) {
    return Response.ok(
      jsonEncode({'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Middleware _loggingMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);
        ServerConfig().log('${request.method} ${request.requestedUri.path} -> ${response.statusCode}');
        return response;
      };
    };
  }

  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok(null, headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          });
        }

        final response = await innerHandler(request);

        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
        });
      };
    };
  }
}
