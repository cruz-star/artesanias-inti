import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../storage/json_storage.dart';

Handler authRoutes(JsonStorage storage) {
  final router = Router();
  final uuid = Uuid();

  // POST /api/auth/register
  router.post('/register', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      final email = data['email'] as String;
      final name = data['name'] as String;
      final password = data['password'] as String;

      // Verificar si ya existe
      final existing = storage.findAll('users').any((u) => u['email'] == email);
      if (existing) {
        return Response.badRequest(body: jsonEncode({'error': 'Email already registered'}));
      }

      final userId = uuid.v4();
      final verificationToken = uuid.v4().substring(0, 8).toUpperCase(); // Token simple de 8 caracteres

      final user = User(
        id: userId,
        email: email,
        name: name,
        passwordHash: password, // En producción usar hashing real
        isVerified: false,
        verificationToken: verificationToken,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      storage.insert('users', userId, user.toJsonWithPassword());

      print('📧 [SIMULACIÓN] Enviando correo de verificación a $email con el código: $verificationToken');

      return Response.ok(jsonEncode({
        'message': 'User registered successfully. Please verify your email.',
        'userId': userId
      }), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': e.toString()}));
    }
  });

  // POST /api/auth/verify-email
  router.post('/verify-email', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final email = data['email'] as String;
      final token = data['token'] as String;

      final usersRaw = storage.findAll('users');
      Map<String, dynamic>? userMap;
      
      for (var u in usersRaw) {
        if (u['email'] == email) {
          userMap = u;
          break;
        }
      }

      if (userMap == null) {
        return Response.notFound(jsonEncode({'error': 'User not found'}));
      }

      if (userMap['verificationToken'] == token) {
        final user = User.fromJson(userMap);
        final verifiedUser = User(
          id: user.id,
          email: user.email,
          name: user.name,
          passwordHash: userMap['passwordHash'] as String? ?? '',
          isVerified: true,
          verificationToken: null,
          createdAt: user.createdAt,
          updatedAt: DateTime.now(),
        );
        storage.update('users', user.id, verifiedUser.toJsonWithPassword());
        return Response.ok(jsonEncode({'message': 'Email verified successfully'}));
      } else {
        return Response.badRequest(body: jsonEncode({'error': 'Invalid verification token'}));
      }
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': e.toString()}));
    }
  });

  // POST /api/auth/login
  router.post('/login', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      final email = data['email'] as String;
      final password = data['password'] as String;

      // Buscar usuario
      final allUsers = storage.findAll('users');
      Map<String, dynamic>? userMap;

      for (var u in allUsers) {
        if (u['email'] == email && u['passwordHash'] == password) {
          userMap = u;
          break;
        }
      }

      if (userMap == null) {
        return Response.forbidden(jsonEncode({'error': 'Invalid credentials'}));
      }

      final user = User.fromJson(userMap);
      if (!user.isVerified) {
         return Response.forbidden(jsonEncode({
           'error': 'Email not verified',
           'isVerified': false
         }));
      }

      final sessionId = uuid.v4();
      final session = Session(
        id: sessionId,
        userId: user.id,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      storage.insert('sessions', sessionId, session.toJson());

      return Response.ok(jsonEncode({
        'token': sessionId,
        'user': user.toJson()
      }), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': e.toString()}));
    }
  });

  return router.call;
}
