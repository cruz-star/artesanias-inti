import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'server/server_handler.dart';
import 'server/storage/json_storage.dart';
import 'server/server_config.dart';

void main() {
  runApp(const IntiServerApp());
}

class IntiServerApp extends StatelessWidget {
  const IntiServerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inti Server Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB35A38), // Terracotta
          primary: const Color(0xFFB35A38),
          secondary: const Color(0xFFD98E73),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const ServerHomePage(),
    );
  }
}

class ServerHomePage extends StatefulWidget {
  const ServerHomePage({super.key});

  @override
  State<ServerHomePage> createState() => _ServerHomePageState();
}

class _ServerHomePageState extends State<ServerHomePage> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  String? _ipAddress;
  late ServerConfig _config;

  @override
  void initState() {
    super.initState();
    _config = ServerConfig();
    _config.logStream.listen((message) {
      if (mounted) {
        setState(() {
          _logs.add(message);
        });
        _scrollToBottom();
      }
    });
    _getIpAddress();
    _config.log('Iniciando Panel de Control en ${Platform.operatingSystem}...');
  }

  Future<void> _getIpAddress() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    setState(() {
      _ipAddress = ip ?? 'No detectada';
      _config.localIp = _ipAddress;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startServer() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dataPath = p.join(appDocDir.path, 'ArtesaniasInti', 'data');
      final publicPath = p.join(appDocDir.path, 'ArtesaniasInti', 'public');

      _config.log('Configurando almacenamiento en: $dataPath');
      
      final storage = JsonStorage(basePath: dataPath);
      await storage.init();

      final server = IntiServer(
        storage: storage,
        port: _config.port,
        publicDir: publicPath,
      );

      await server.start();
      if (_ipAddress != null && _ipAddress != 'No detectada') {
        _updateDiscoveryInfo(_ipAddress!);
      }
      setState(() {});
    } catch (e) {
      _config.log('Error al iniciar servidor: $e');
    }
  }

  void _stopServer() {
    _config.stop();
    setState(() {});
  }

  Future<void> _updateDiscoveryInfo(String ip) async {
    _config.log('Publicando dirección de conexión en GitHub para sincronización remota...');
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dataPath = p.join(appDocDir.path, 'ArtesaniasInti', 'data');
      final storage = JsonStorage(basePath: dataPath);
      await storage.init();

      final discoveryData = {
        'url': 'http://$ip:${_config.port}',
        'lastUpdate': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'status': 'online'
      };

      // Guardar local y empujar a GitHub
      storage.insert('config', 'discovery', discoveryData, push: true);
      _config.log('🚀 ¡Conexión global activada! La App ya puede encontrarte.');
    } catch (e) {
      _config.log('⚠️ No se pudo publicar la IP en GitHub: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.dns, color: Colors.white), // Ícono de Servidor
        title: const Text('Artesanías Inti - Server Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _getIpAddress,
            tooltip: 'Refrescar IP',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _config.isRunning ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _config.isRunning ? Icons.sensors : Icons.sensors_off,
                        color: _config.isRunning ? Colors.green : Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _config.isRunning ? 'Servidor Activo' : 'Servidor Detenido',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _config.isRunning 
                              ? 'Escuchando en http://$_ipAddress:${_config.port}'
                              : 'Presiona el botón para iniciar',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _config.isRunning,
                      onChanged: (value) {
                        if (value) {
                          _startServer();
                        } else {
                          _stopServer();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Info Grid
            Row(
              children: [
                Expanded(
                  child: _infoItem(
                    Icons.lan,
                    'IP Local',
                    _ipAddress ?? 'Cargando...',
                    context,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoItem(
                    Icons.settings_input_component,
                    'Puerto',
                    _config.port.toString(),
                    context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _infoItem(
                    Icons.devices,
                    'Plataforma',
                    Platform.operatingSystem.toUpperCase(),
                    context,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoItem(
                    Icons.storage,
                    'Almacenamiento',
                    'Local JSON',
                    context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Log Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Consola de Actividad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _logs.clear()),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Log Console
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!_config.isRunning) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El servidor debe estar activo para sincronizar.')),
            );
            return;
          }
          _config.log('Iniciando sincronización manual con GitHub...');
          try {
            final appDocDir = await getApplicationDocumentsDirectory();
            final dataPath = p.join(appDocDir.path, 'ArtesaniasInti', 'data');
            final storage = JsonStorage(basePath: dataPath);
            await storage.init();
            
            await storage.forcePush('products');
            await storage.forcePush('orders');
            await storage.forcePush('config');
            
            _config.log('✅ Sincronización manual completada con éxito.');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sincronización completada.')),
              );
            }
          } catch (e) {
            _config.log('❌ Error en sincronización manual: $e');
          }
        },
        icon: const Icon(Icons.sync),
        label: const Text('Sincronizar Web'),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value, BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
