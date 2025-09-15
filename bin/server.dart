import 'dart:io';
import 'dart:convert';
import 'package:my_server/database.dart';
import 'package:my_server/logic.dart';

void main() async {
  final dbHelper = DatabaseHelper();

  // Establecer el puerto en el que escuchará el servidor
  const port = 3001;
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

  // Escuchar el nombre de usuario
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

    // Escuchar los mensajes enviados por el cliente
    stream.listen(
      (line) async {
        final text = line.trimRight();
        if (text.isEmpty) return;

        // Almacenar el mensaje en la base de datos
        await dbHelper.insertMessage(username, text);

        // Enviar el mensaje a todos los demás clientes
        final payload = '[$username] $text';
        sendToAll(clients, payload, except: client);
      },
      onDone: () {
        // Cuando el cliente se desconecta, limpia y registra la desconexión
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
  });
});



}

