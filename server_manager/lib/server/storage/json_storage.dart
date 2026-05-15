import 'dart:convert';
import 'dart:io';
import 'github_sync.dart';

class JsonStorage {
  final String basePath;
  String? storefrontPath; // Opcional: para actualizar archivos locales de la web
  final Map<String, Map<String, dynamic>> _data = {};
  final GitHubSync _githubSync = GitHubSync();

  JsonStorage({required this.basePath, this.storefrontPath});

  Future<void> init() async {
    final dir = Directory(basePath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Descargar datos iniciales desde GitHub si no existen localmente
    await _pullCollection('config');
    await _pullCollection('products');
    await _pullCollection('orders');
    await _pullCollection('users');
  }

  Future<void> _pullCollection(String collection) async {
    final file = File(_collectionPath(collection));
    bool shouldPull = false;
    
    if (!file.existsSync()) {
      shouldPull = true;
    } else {
      final content = file.readAsStringSync().trim();
      if (content.isEmpty || content == '{}' || content == '[]') {
        shouldPull = true;
      }
    }

    if (shouldPull) {
      print('[JsonStorage] Descargando $collection.json inicial desde GitHub...');
      final pulledData = await _githubSync.pullData(collection);
      if (pulledData != null && pulledData.isNotEmpty) {
        _data[collection] = {};
        for (var item in pulledData) {
          final id = item['id'] as String? ?? (collection == 'config' ? 'main' : null);
          if (id != null) {
            _data[collection]![id] = item;
          }
        }
        // Guardar localmente
        file.writeAsStringSync(jsonEncode(_data[collection]));
        print('[JsonStorage] ✅ $collection.json guardado en caché local.');
      } else {
        print('[JsonStorage] ℹ️ No hay datos remotos para $collection, iniciando en blanco.');
      }
    }
  }

  String _collectionPath(String collection) {
    return '$basePath/$collection.json';
  }

  void _loadCollection(String collection) {
    if (_data.containsKey(collection)) return;

    final path = _collectionPath(collection);
    final file = File(path);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final decoded = jsonDecode(content);
        
        if (decoded is List) {
           _data[collection] = {};
           for (var item in decoded) {
             final itemMap = Map<String, dynamic>.from(item as Map);
             final id = itemMap['id'] as String? ?? (collection == 'config' ? 'main' : null);
             if (id != null) {
               _data[collection]![id] = itemMap;
             }
           }
        } else if (decoded is Map) {
           final rawMap = Map<String, dynamic>.from(decoded);
           _data[collection] = {};
           
           rawMap.forEach((key, value) {
             if (value is String) {
               // Caso legado: valores guardados como strings JSON
               try {
                 _data[collection]![key] = jsonDecode(value) as Map<String, dynamic>;
               } catch (_) {
                 // Si no es un JSON válido, lo guardamos como un mapa con un campo valor
                 _data[collection]![key] = {'value': value};
               }
             } else if (value is Map) {
               _data[collection]![key] = Map<String, dynamic>.from(value);
             }
           });
        }
      } catch (e) {
        print('[JsonStorage] Error al cargar $collection: $e');
        _data[collection] = {};
      }
    } else {
      _data[collection] = {};
    }
  }

  Future<void> forcePush(String collection) async {
    if (collection == 'products' || collection == 'orders' || collection == 'config' || collection == 'users') {
      // Guardar localmente en la carpeta de datos de la app
      final path = _collectionPath(collection);
      File(path).writeAsStringSync(jsonEncode(_data[collection]));

      // 1. Actualizar localmente la web del cliente (si está configurada la ruta)
      if (storefrontPath != null && collection != 'users' && collection != 'sessions') {
        try {
          final fileName = _githubSync.getFileName(collection);
          final file = File('$storefrontPath/$fileName');
          
          final List<Map<String, dynamic>> listData = _data[collection]!
              .values
              .map((e) => e as Map<String, dynamic>)
              .toList();
              
          final content = collection == 'config' && listData.isNotEmpty
              ? jsonEncode(listData.first)
              : jsonEncode(listData);
              
          file.writeAsStringSync(content);
          print('[JsonStorage] ✅ Archivo local de la web actualizado: $fileName');
        } catch (e) {
          print('[JsonStorage] ⚠️ No se pudo actualizar el archivo local de la web: $e');
        }
      }

      // 2. Empujar a GitHub (solo colecciones públicas)
      if (collection == 'products' || collection == 'orders' || collection == 'config') {
        await _githubSync.pushData(collection, _data);
        // Pequeña espera para evitar conflictos de concurrencia en GitHub (409)
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  // Wrapper para mantener compatibilidad con métodos sincrónicos
  void _saveCollection(String collection) {
    forcePush(collection); // Fire and forget
  }

  List<Map<String, dynamic>> findAll(String collection) {
    _loadCollection(collection);
    return _data[collection]!
        .values
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Map<String, dynamic>? findById(String collection, String id) {
    _loadCollection(collection);
    return _data[collection]?[id];
  }

  Map<String, dynamic> insert(String collection, String id, Map<String, dynamic> data, {bool push = true}) {
    _loadCollection(collection);
    _data[collection]![id] = data;
    if (push) {
      _saveCollection(collection);
    } else {
      final path = _collectionPath(collection);
      File(path).writeAsStringSync(jsonEncode(_data[collection]));
    }
    return data;
  }

  Map<String, dynamic>? update(String collection, String id, Map<String, dynamic> data, {bool push = true}) {
    _loadCollection(collection);
    if (!_data[collection]!.containsKey(id)) return null;
    _data[collection]![id] = data;
    if (push) {
      _saveCollection(collection);
    } else {
      final path = _collectionPath(collection);
      File(path).writeAsStringSync(jsonEncode(_data[collection]));
    }
    return data;
  }

  void clearCollection(String collection, {bool push = true}) {
    _loadCollection(collection);
    _data[collection]!.clear();
    if (push) {
      _saveCollection(collection);
    } else {
      final path = _collectionPath(collection);
      File(path).writeAsStringSync(jsonEncode(_data[collection]));
    }
  }

  bool delete(String collection, String id, {bool push = true}) {
    _loadCollection(collection);
    if (_data[collection]!.remove(id) != null) {
      if (push) {
        _saveCollection(collection);
      } else {
        final path = _collectionPath(collection);
        File(path).writeAsStringSync(jsonEncode(_data[collection]));
      }
      return true;
    }
    return false;
  }

  List<Map<String, dynamic>> findByField(
    String collection,
    String field,
    dynamic value,
  ) {
    _loadCollection(collection);
    return _data[collection]!
        .values
        .where((item) => item[field] == value)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
