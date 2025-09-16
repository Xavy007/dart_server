import 'dart:async';
import 'dart:io';
import 'package:socket_io/socket_io.dart';

void main() {
  final port = int.parse(Platform.environment['PORT'] ?? '3000');
  final io = Server();

  // Mapa: socketId -> nombre
  final names = <String, String>{};

  String _uniqueName(String raw) {
    var base = (raw.trim().isEmpty ? 'Anon' : raw.trim());
    final taken = names.values.map((e) => e.toLowerCase()).toSet();
    var candidate = base;
    var i = 1;
    while (taken.contains(candidate.toLowerCase())) {
      i++;
      candidate = '$base#$i';
    }
    return candidate;
  }

  void _broadcastUsers() {
    final users = names.entries.map((e) => {'id': e.key, 'name': e.value}).toList();
    io.emit('online_users', users);
  }

  io.on('connection', (client) {
    print('⚡ connected: ${client.id}');
    // Por defecto, entra como "Anon"
    names[client.id] = 'Anon';
    _broadcastUsers();

    // Cliente envía su nombre
    client.on('set_name', (data) {
      try {
        final raw = (data is Map && data['name'] is String) ? data['name'] as String : '';
        final unique = _uniqueName(raw);
        final old = names[client.id];
        names[client.id] = unique;

        client.emit('name_accepted', {'name': unique}); // respuesta al que puso nombre
        client.broadcast.emit('user_joined', {'id': client.id, 'name': unique}); // para el resto
        _broadcastUsers();
        print('👤 ${client.id} name: $old -> $unique');
      } catch (_) {
        client.emit('name_error', {'message': 'Nombre inválido'});
      }
    });

    // Mensaje público
    client.on('send_message', (data) {
      final text = (data is Map && data['text'] is String) ? (data['text'] as String).trim() : '';
      if (text.isEmpty) return;
      final name = names[client.id] ?? 'Anon';
      final payload = {
        'fromId': client.id,
        'from': name,
        'text': text,
        'ts': DateTime.now().toUtc().toIso8601String(),
      };
      io.emit('chat_message', payload); // broadcast a todos (incluido el emisor)
    });

    // Ejemplo: saludo automático a los 5s (solo si sigue conectado)
    Timer(const Duration(seconds: 5), () {
      try {
        if (client.connected == true) client.emit('msg', 'Hello from server');
      } catch (_) {}
    });

    client.on('disconnect', (_) {
      final name = names.remove(client.id);
      io.emit('user_left', {'id': client.id, 'name': name});
      _broadcastUsers();
      print('👋 disconnected: ${client.id} ($name)');
    });
  });

  // **OJO**: esto levanta el servidor HTTP interno de Socket.IO.
  // No hay ruta "/", así que el health check de Render debe apuntar a /socket.io?...
  io.listen(port);
  print('✅ Socket.IO v2 listening on 0.0.0.0:$port (path: /socket.io/)');
}


/*import 'dart:async';
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
*/


