import 'dart:io';
import 'dart:convert';

void main() async {
  final socket = await Socket.connect('127.0.0.1', 3001);

  // Leer la respuesta del servidor
  socket.listen((List<int> data) {
    print(utf8.decode(data));
  });

  // Enviar nombre de usuario
  socket.write('johndoe\n');

  // Enviar mensaje al servidor
  socket.write('¡Hola desde el cliente!\n');

  // Cerrar la conexión
  socket.close();
}
