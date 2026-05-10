import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../services/github_service.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];
  final GitHubService _githubService = GitHubService();
  String _contacto = 'Artesanías Inti';
  String _email = 'contacto@artesaniasinti.com';
  String _telefono = '+54 9 11 1234 5678';
  bool _isPublishing = false;
  bool _isLoading = false;
  
  // Versión actual de la App
  final String _currentAppVersion = '1.0.1'; 
  String? _newVersionAvailable;
  String? _updateUrl;

  bool get isLoading => _isLoading;
  String get currentAppVersion => _currentAppVersion;
  String? get newVersionAvailable => _newVersionAvailable;
  String? get updateUrl => _updateUrl;

  List<Product> get products => List.unmodifiable(_products);
  bool get isPublishing => _isPublishing;
  List<Product> get availableProducts =>
      _products.where((p) => p.isAvailable).toList();

  String get contacto => _contacto;
  String get email => _email;
  String get telefono => _telefono;

  ProductProvider() {
    _loadSeedData();
    syncFromGitHub(); // Intentar cargar datos remotos al iniciar
  }

  void _loadSeedData() {
    _products.addAll([
      Product(
        id: '1',
        name: 'Vasija de Barro Pintada a Mano',
        description:
            'Hermosa vasija de barro cocido con diseños tradicionales andinos pintados completamente a mano. Ideal para decoración.',
        price: 45.00,
        category: 'Cerámica',
        isAvailable: true,
      ),
      Product(
        id: '2',
        name: 'Tapiz Andino Tejido',
        description:
            'Tapiz tejido en telar tradicional con lana de alpaca. Colores naturales y diseños geométricos ancestrales.',
        price: 120.00,
        category: 'Textiles',
        isAvailable: true,
      ),
      Product(
        id: '3',
        name: 'Collares de Semillas',
        description:
            'Collares artesanales elaborados con semillas naturales de la región. Cada pieza es única.',
        price: 25.00,
        category: 'Joyería',
        isAvailable: true,
      ),
      Product(
        id: '4',
        name: 'Máscara de Diablada',
        description:
            'Máscara tradicional de la diablada boliviana, tallada y pintada a mano con detalles en brillo.',
        price: 200.00,
        category: 'Arte',
        isAvailable: true,
      ),
      Product(
        id: '5',
        name: 'Poncho de Alpaca',
        description:
            'Poncho confeccionado en fibra de alpaca baby. Suave, abrigador y con diseños tradicionales.',
        price: 250.00,
        category: 'Textiles',
        isAvailable: true,
      ),
      Product(
        id: '6',
        name: 'Cestería de Mimbre',
        description:
            'Cestos decorativos tejidos a mano con mimbre natural. Variedad de tamaños disponibles.',
        price: 35.00,
        category: 'Artesanía',
        isAvailable: true,
      ),
    ]);
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void updateContactInfo({
    required String contacto,
    required String email,
    required String telefono,
  }) {
    _contacto = contacto;
    _email = email;
    _telefono = telefono;
    notifyListeners();
  }

  Future<bool> publishToWeb() async {
    _isPublishing = true;
    notifyListeners();

    try {
      // 1. Preparar la "Base de Datos" (JSON)
      final data = {
        'lastUpdate': DateTime.now().toIso8601String(),
        'appConfig': {
          'latestVersion': _currentAppVersion,
          'updateUrl': 'https://github.com/cruz-star/artesanias-inti/releases/latest/download/app-release.apk',
        },
        'contact': {
          'name': _contacto,
          'email': _email,
          'phone': _telefono,
        },
        'products': _products.where((p) => p.isAvailable).map((p) => p.toMap()).toList(),
      };

      final jsonBody = jsonEncode(data);

      // Sincronizar con GitHub
      final success = await _githubService.uploadJson(jsonBody);
      
      if (success) {
        print('Datos publicados en GitHub correctamente');
      }
      return success;
    } catch (e) {
      print('Error al publicar: $e');
      return false;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  Future<bool> syncFromGitHub() async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = await _githubService.fetchJson();
      if (jsonString != null) {
        final data = jsonDecode(jsonString);
        
        // Verificar actualización de la App
        if (data['appConfig'] != null) {
          final latest = data['appConfig']['latestVersion'] as String?;
          if (latest != null && latest != _currentAppVersion) {
            _newVersionAvailable = latest;
            _updateUrl = data['appConfig']['updateUrl'];
          }
        }

        // Actualizar info de contacto
        if (data['contact'] != null) {
          _contacto = data['contact']['name'] ?? _contacto;
          _email = data['contact']['email'] ?? _email;
          _telefono = data['contact']['phone'] ?? _telefono;
        }

        // Actualizar productos
        if (data['products'] != null) {
          final List<dynamic> productsList = data['products'];
          _products.clear();
          for (var pMap in productsList) {
            _products.add(Product.fromMap(pMap));
          }
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al sincronizar desde GitHub: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
