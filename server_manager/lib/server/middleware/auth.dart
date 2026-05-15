import 'package:shelf/shelf.dart';
import '../storage/json_storage.dart';
import '../models/models.dart';

Request authenticateRequest(Request request, JsonStorage storage) {
  final authHeader = request.headers['Authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return request.change(context: {'authenticated': false});
  }

  final token = authHeader.substring('Bearer '.length);
  final sessions = storage.findAll('sessions');
  final sessionData = sessions.where((s) => s['id'] == token).firstOrNull;

  if (sessionData == null) {
    return request.change(context: {'authenticated': false});
  }

  final session = Session.fromJson(sessionData);
  if (session.isExpired) {
    return request.change(context: {'authenticated': false});
  }

  final userData = storage.findById('users', session.userId);
  if (userData == null) {
    return request.change(context: {'authenticated': false});
  }

  final user = User.fromJson(userData);
  return request.change(context: {
    'authenticated': true,
    'userId': user.id,
    'user': user,
  });
}

Middleware authMiddleware(JsonStorage storage) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authenticatedRequest = authenticateRequest(request, storage);
      return innerHandler(authenticatedRequest);
    };
  };
}

Middleware requireAuth(JsonStorage storage) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authenticatedRequest = authenticateRequest(request, storage);
      final isAuthenticated =
          authenticatedRequest.context['authenticated'] as bool? ?? false;

      if (!isAuthenticated) {
        return Response.forbidden(
          '{"error": "Authentication required"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      return innerHandler(authenticatedRequest);
    };
  };
}
