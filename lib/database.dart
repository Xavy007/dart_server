import 'package:sqlite3/sqlite3.dart';

class DatabaseHelper {
  final Database _db;

  // Constructor
  DatabaseHelper() : _db = sqlite3.open('database.db') {
    // Crear tabla de usuarios
    _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL
      );
    ''');

    // Crear tabla de mensajes
    _db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }

  // Insertar un mensaje en la base de datos
  Future<void> insertMessage(String username, String message) async {
    final stmt = _db.prepare('INSERT INTO messages (username, message) VALUES (?, ?)');
    stmt.execute([username, message]);
    stmt.dispose();
  }

  // Obtener todos los mensajes, ordenados por la fecha (timestamp)
  Future<List<Map>> getMessages() async {
    final stmt = _db.prepare('SELECT * FROM messages ORDER BY timestamp DESC');
    final result = stmt.select([]);
    stmt.dispose();
    return result;
  }

  // Verificar si un usuario existe en la base de datos
  Future<bool> userExists(String username) async {
    final stmt = _db.prepare('SELECT COUNT(*) FROM users WHERE username = ?');
    final result = stmt.select([username]);
    stmt.dispose();
    // Verificar si existe al menos un usuario con ese nombre de usuario
    return result.first[0] > 0;
  }

  // Agregar un usuario a la base de datos si no existe
  Future<void> addUser(String username) async {
    final stmt = _db.prepare('INSERT OR IGNORE INTO users (username) VALUES (?)');
    stmt.execute([username]);
    stmt.dispose();
  }

  // Cerrar la base de datos
  void close() {
    _db.dispose();
  }
}
