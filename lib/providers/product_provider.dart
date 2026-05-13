import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];
  final ApiService _apiService = ApiService();
  
  // Datos de contacto
  String _contacto = 'Artesanías Inti';
  String _email = 'contacto@artesaniasinti.com';
  String _telefono = '+54 9 11 1234 5678';
  
  // Datos de pago (Nuevos campos)
  String _cbu = '';
  String _alias = '';
  String _titular = '';

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
  
  String get cbu => _cbu;
  String get alias => _alias;
  String get titular => _titular;

  ProductProvider() {
    _loadSeedData();
    syncFromServer(); // Intentar cargar datos remotos al iniciar
  }

  void _loadSeedData() {
    _products.addAll([
      Product(
        id: '1',
        name: 'Vasija de Barro Pintada a Mano',
        description:
            'Hermosa vasija de barro cocido con diseños tradicionales andinos pintados completamente a mano. Ideal para decoración.',
        price: 45000.00,
        category: 'Cerámica',
        isAvailable: true,
      ),
      Product(
        id: '2',
        name: 'Tapiz Andino Tejido',
        description:
            'Tapiz tejido en telar tradicional con lana de alpaca. Colores naturales y diseños geométricos ancestrales.',
        price: 120000.00,
        category: 'Textiles',
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

  void updatePaymentInfo({
    required String cbu,
    required String alias,
    required String titular,
  }) {
    _cbu = cbu;
    _alias = alias;
    _titular = titular;
    notifyListeners();
  }

  Future<bool> publishToWeb() async {
    _isPublishing = true;
    notifyListeners();

    try {
      // 1. Subir imágenes pendientes antes de sincronizar el JSON
      for (int i = 0; i < _products.length; i++) {
        final p = _products[i];
        if (p.imageBytes != null && p.imageUrl == null) {
          print('Subiendo imagen para ${p.name}...');
          final url = await _apiService.uploadImage(
            p.imageFileName ?? 'product_${p.id}.jpg',
            p.imageBytes!,
          );
          if (url != null) {
            _products[i] = p.copyWith(imageUrl: url);
          }
        }
      }

      // 2. Preparar el JSON de sincronización
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
        'payment': {
          'cbu': _cbu,
          'alias': _alias,
          'titular': _titular,
        },
        'products': _products.map((p) => p.toMap()).toList(),
      };

      // 3. Sincronizar con el Servidor
      final success = await _apiService.syncData(data);
      
      if (success) {
        print('Datos publicados en el servidor correctamente');
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

  Future<bool> syncFromServer() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Cargar Configuración
      final config = await _apiService.fetchConfig();
      if (config != null) {
        if (config['appConfig'] != null) {
          final latest = config['appConfig']['latestVersion'] as String?;
          if (latest != null && latest != _currentAppVersion) {
            _newVersionAvailable = latest;
            _updateUrl = config['appConfig']['updateUrl'];
          }
        }
        if (config['contact'] != null) {
          _contacto = config['contact']['name'] ?? _contacto;
          _email = config['contact']['email'] ?? _email;
          _telefono = config['contact']['phone'] ?? _telefono;
        }
        if (config['payment'] != null) {
          _cbu = config['payment']['cbu'] ?? '';
          _alias = config['payment']['alias'] ?? '';
          _titular = config['payment']['titular'] ?? '';
        }
      }

      // 2. Cargar Productos
      final productsList = await _apiService.fetchProducts();
      if (productsList != null) {
        _products.clear();
        for (var pMap in productsList) {
          _products.add(Product.fromMap(pMap));
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error al sincronizar desde el servidor: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
