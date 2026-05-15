import 'dart:async';
import 'dart:io';

class ServerConfig {
  static final ServerConfig _instance = ServerConfig._internal();
  factory ServerConfig() => _instance;
  ServerConfig._internal();

  int port = 8080;
  String? localIp;
  bool isRunning = false;
  HttpServer? server;
  
  final StreamController<String> _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  // Seguimiento de actividad
  DateTime? lastAppActivity;
  DateTime? lastWebActivity;

  void log(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    _logController.add('[$timestamp] $message');
    print('[$timestamp] $message');
  }

  void stop() {
    server?.close(force: true);
    isRunning = false;
    log('Servidor detenido.');
  }
}
