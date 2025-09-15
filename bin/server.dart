import 'dart:io';
import 'dart:convert';
import 'package:my_server/database.dart';

void main() async {
  final dbHelper = DatabaseHelper();

  // Establecer el puerto en el que escuchará el servidor
  const port = 3050;
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
  print('Servidor escuchando en ${server.address.address}:${server.port}');

  final clients = <Socket>{};

  // Escuchar nuevas conexiones de clientes
  server.listen((client) async {
    clients.add(client);
    print('Conectado: ${client.remoteAddress.address}:${client.remotePort}');

    // Solicitar nombre de usuario
    client.write('Ingrese su nombre de usuario: ');

    var stream = client.cast<List<int>>().transform(utf8.decoder).transform(LineSplitter()).asBroadcastStream();

    // Escuchar el nombre de usuario del cliente
    stream.listen((line) async {
      final username = line.trim();
      if (username.isEmpty) {
        client.write('Nombre de usuario no válido.\n');
        client.close();
        return;
      }

      if (!await dbHelper.userExists(username)) {
        await dbHelper.addUser(username);
        client.write('¡Bienvenido $username!\n');
      } else {
        client.write('Bienvenido de nuevo, $username!\n');
      }

      // Ahora que el usuario se ha registrado, comenzamos a escuchar continuamente los mensajes
      // Escuchar los mensajes enviados por el cliente de manera continua
      listenForMessages(client, username, stream, clients, dbHelper);
    });
  });
}

// Función para escuchar mensajes después de que el cliente se haya registrado
void listenForMessages(Socket client, String username, Stream<String> stream, Set<Socket> clients, DatabaseHelper dbHelper) {
  // Mantener el stream abierto y escuchar continuamente los mensajes
  stream.listen(
    (line) async {
      final text = line.trimRight();
      if (text.isEmpty) return;

      // Imprimir mensaje recibido en el servidor
      print('Mensaje recibido de $username: $text');

      // Almacenar el mensaje en la base de datos
      await dbHelper.insertMessage(username, text);

      // Enviar el mensaje a todos los demás clientes
      final payload = '[$username] $text';
      sendToAll(clients, payload, except: client);
    },
    onDone: () {
      // Cuando el cliente se desconecta, limpiamos y registramos la desconexión
      clients.remove(client);
      print('Desconectado: ${client.remoteAddress.address}:${client.remotePort}');
      client.close();
    },
    onError: (e) {
      // Maneja el error y asegura que la conexión se cierre correctamente
      clients.remove(client);
      print('Error con ${client.remoteAddress.address}:${client.remotePort}: $e');
      client.close();
    },
    cancelOnError: true,
  );
}

/// Enviar mensaje a todos los clientes excepto al emisor
void sendToAll(Set<Socket> clients, String message, {Socket? except}) {
  for (final client in clients) {
    if (client != except) {
      try {
        // Imprimir mensaje que se enviará a todos los clientes
        print('Enviando mensaje a ${client.remoteAddress.address}: $message');
        client.write(message);
      } catch (e) {
        print('Error enviando mensaje a ${client.remoteAddress.address}: $e');
        clients.remove(client); // Eliminar cliente desconectado
      }
    }
  }
}

