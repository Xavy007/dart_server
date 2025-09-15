import 'dart:io';
import 'dart:convert';

void sendToAll(Set<Socket> clients, String text, {Socket? except}) {
  final bytes = utf8.encode('$text\n');
  final toRemove = <Socket>[];

  for (final client in clients) {
    if (except != null && identical(client, except)) continue;
    try {
      client.add(bytes);
    } catch (e) {
      print('Error enviando a $client: $e');
      toRemove.add(client);
    }
  }

  // Limpiar conexiones rotas
  for (final c in toRemove) {
    clients.remove(c);
    try {
      c.destroy();
    } catch (_) {}
  }
}
