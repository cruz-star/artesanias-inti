import 'package:flutter/material.dart';

enum UserRole { seller }

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;

  static const String _sellerPassword = 'inti2024';
  bool get isLoggedIn => _isLoggedIn;

  bool loginAsSeller(String password) {
    if (password == _sellerPassword) {
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
