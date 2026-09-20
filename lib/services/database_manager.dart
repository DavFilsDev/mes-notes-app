import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note.dart';
import '../models/user.dart';

class DatabaseManager {
  DatabaseManager({this.path});

  DatabaseManager._singleton() : path = null;

  static DatabaseManager instance = DatabaseManager._singleton();

  final String? path;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    final Database db = await _open();
    _database = db;
    return db;
  }

  Future<Database> _open() async {
    final String path =
        this.path ?? join(await getDatabasesPath(), 'mes_notes.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE users ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'username TEXT NOT NULL UNIQUE, '
      'password TEXT NOT NULL'
      ')',
    );
    await db.execute(
      'CREATE TABLE notes ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'user_id INTEGER, '
      'title TEXT NOT NULL, '
      'content TEXT, '
      'is_done INTEGER DEFAULT 0, '
      'created_at TEXT NOT NULL'
      ')',
    );
  }

  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<User> insertUser(User user) async {
    final Database db = await database;
    final int id = await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return User(id: id, username: user.username, password: user.password);
  }

  Future<List<User>> getAllUsers() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query('users');
    return rows.map(User.fromMap).toList();
  }

  Future<User?> findUserByUsername(String username) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: <Object?>[username],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return User.fromMap(rows.first);
  }

  Future<User?> authenticate(String username, String password) async {
    final User? user = await findUserByUsername(username);
    if (user == null || user.password != password) {
      return null;
    }
    return user;
  }

  Future<void> seedDefaultUserIfEmpty() async {
    final List<User> users = await getAllUsers();
    if (users.isEmpty) {
      await insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
    }
  }

  Future<Note> insertNote(Note note) async {
    final Database db = await database;
    final int id = await db.insert('notes', note.toMap());
    return Note(
      id: id,
      userId: note.userId,
      title: note.title,
      content: note.content,
      isDone: note.isDone,
      createdAt: note.createdAt,
    );
  }

  Future<List<Note>> getNotesByUser(int userId) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<List<Note>> searchNotes(int userId, String query) async {
    final Database db = await database;
    final String like = '%$query%';
    final List<Map<String, Object?>> rows = await db.query(
      'notes',
      where: 'user_id = ? AND (title LIKE ? OR content LIKE ?)',
      whereArgs: <Object?>[userId, like, like],
      orderBy: 'created_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<List<Note>> getNotesByUserAndStatus(int userId, bool isDone) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'notes',
      where: 'user_id = ? AND is_done = ?',
      whereArgs: <Object?>[userId, isDone ? 1 : 0],
      orderBy: 'created_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<int> updateNote(Note note) async {
    final Database db = await database;
    final Map<String, Object?> values = note.toMap()..remove('id');
    return db.update(
      'notes',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final Database db = await database;
    return db.delete('notes', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<int> countNotes(int userId) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM notes WHERE user_id = ?',
      <Object?>[userId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
