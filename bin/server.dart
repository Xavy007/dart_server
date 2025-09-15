import 'dart:async';
import 'dart:io';
import 'package:socket_io/socket_io.dart';

Future<void> main() async {
  // Render inyecta PORT, usa eso (fallback 3000 para local)
  final port = int.parse(Platform.environment['PORT'] ?? '3000');

  // 1) HTTP server para health check y para adjuntar Socket.IO
  final http = await HttpServer.bind(InternetAddress.anyIPv4, port);
  http.listen((HttpRequest req) {
    // health check
    if (req.uri.path == '/' || req.uri.path == '/health' || req.uri.path == '/healthz') {
      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.text
        ..write('OK')
        ..close();
      return;
    }
    // cualquier otra ruta 404 (socket.io usa /socket.io/*)
    req.response
      ..statusCode = 404
      ..write('Not found')
      ..close();
  });

  // 2) Socket.IO sobre el mismo HttpServer
  final io = Server();
  io.attach(http); // importante: adjuntar al http server existente

  io.on('connection', (client) {
    print('⚡ client connected: ${client.id}');

    client.on('stream', (data) => print('📥 from ${client.id}: $data'));

    // Enviar algo a los 5s (si sigue conectado)
    Timer(const Duration(seconds: 5), () {
      try {
        client.emit('msg', 'Hello from server');
      } catch (e) {
        // si ya se desconectó, ignoramos
        print('skip emit (disconnected): $e');
      }
    });

    client.on('disconnect', (_) => print('👋 client disconnected: ${client.id}'));
  });

  print('✅ Listening on 0.0.0.0:$port (HTTP + Socket.IO)');
}
