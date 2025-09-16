// bin/server.dart
import 'dart:async';
import 'dart:io';
import 'package:socket_io/socket_io.dart';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '3000');

  final io = Server();

  io.on('connection', (client) {
    print('⚡ connected: ${client.id}');

    client.on('stream', (data) {
      print('📥 from ${client.id}: $data');
    });

    // Ejemplo: mensaje a los 5s (solo si sigue conectado)
    Timer(const Duration(seconds: 5), () {
      try {
        if (client.connected == true) {
          client.emit('msg', 'Hello from server');
        }
      } catch (e) {
        // Evita crash si el socket ya cerró
        print('emit skipped: $e');
      }
    });

    client.on('disconnect', (_) => print('👋 disconnected: ${client.id}'));
  });

  // 👉 deja que socket_io gestione su server HTTP interno
  io.listen(port);

  print('✅ Socket.IO listening on 0.0.0.0:$port');
}
