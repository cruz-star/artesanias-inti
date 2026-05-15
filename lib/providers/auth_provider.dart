import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/secrets.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('user_data');
    if (_token != null && userJson != null) {
      _user = jsonDecode(userJson);
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<bool> loginAsSeller(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${Secrets.serverUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user'];
        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(_user));

        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> tryAutoLogin() async {
    if (_token == null) return false;
    
    // Validar token con el servidor (opcional, pero recomendado por seguridad)
    try {
      final response = await http.get(
        Uri.parse('${Secrets.serverUrl}/api/health'), // O un endpoint de /me
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {}
    
    // Si falla la validación pero tenemos token, asumimos que está bien por ahora 
    // (el servidor rechazará las peticiones reales si el token expiró)
    return _isLoggedIn;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    notifyListeners();
  }
}
