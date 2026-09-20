import 'package:flutter_test/flutter_test.dart';
import 'package:mes_notes_app/models/note.dart';
import 'package:mes_notes_app/models/user.dart';
import 'package:mes_notes_app/services/database_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseManager manager;

  setUp(() async {
    manager = DatabaseManager(path: inMemoryDatabasePath);
    await manager.database;
  });

  tearDown(() async {
    await manager.close();
  });

  group('DatabaseManager', () {
    test('créé les tables users et notes', () async {
      final Database db = await manager.database;
      final List<Map<String, Object?>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name IN ('users', 'notes') "
        'ORDER BY name',
      );

      expect(tables.length, 2);
      expect(tables[0]['name'], 'notes');
      expect(tables[1]['name'], 'users');
    });

    test('insertUser insère et attribue un identifiant', () async {
      final User user = await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );

      expect(user.id, isNotNull);

      final User? trouve = await manager.findUserByUsername('alex.morgan');
      expect(trouve, isNotNull);
      expect(trouve!.id, user.id);
      expect(trouve.username, 'alex.morgan');
      expect(trouve.password, 'secret');
    });

    test('findUserByUsername retourne null pour un nom inconnu', () async {
      final User? trouve = await manager.findUserByUsername('inconnu');

      expect(trouve, isNull);
    });

    test('authenticate accepte les bons identifiants', () async {
      await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );

      final User? user = await manager.authenticate('alex.morgan', 'secret');

      expect(user, isNotNull);
      expect(user!.username, 'alex.morgan');
    });

    test('authenticate refuse les mauvais identifiants', () async {
      await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );

      final User? mauvaisMotDePasse = await manager.authenticate(
        'alex.morgan',
        'mauvais',
      );
      final User? mauvaisNom = await manager.authenticate('inconnu', 'secret');

      expect(mauvaisMotDePasse, isNull);
      expect(mauvaisNom, isNull);
    });

    test('seedDefaultUserIfEmpty crée un utilisateur par défaut', () async {
      await manager.seedDefaultUserIfEmpty();

      final User? user = await manager.findUserByUsername('alex.morgan');
      expect(user, isNotNull);
    });

    test('insertNote puis getNotesByUser retourne les notes triées', () async {
      final User user = await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Planification du sprint',
          content: 'Préparer le planning',
          isDone: false,
          createdAt: DateTime(2026, 5, 12, 14, 30),
        ),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Réunion client',
          content: 'Préparer le compte rendu',
          isDone: true,
          createdAt: DateTime(2026, 5, 13, 9, 0),
        ),
      );

      final List<Note> notes = await manager.getNotesByUser(user.id!);

      expect(notes.length, 2);
      expect(notes.first.title, 'Réunion client');
      expect(notes.last.title, 'Planification du sprint');
      expect(notes.first.isDone, isTrue);
    });

    test('getNotesByUser isole les notes par utilisateur', () async {
      final User userA = await manager.insertUser(
        const User.sansId(username: 'alice', password: 'a'),
      );
      final User userB = await manager.insertUser(
        const User.sansId(username: 'bob', password: 'b'),
      );
      await manager.insertNote(
        Note.sansId(
          userId: userA.id,
          title: 'Note de Alice',
          isDone: false,
          createdAt: DateTime(2026, 5, 12),
        ),
      );

      final List<Note> notesB = await manager.getNotesByUser(userB.id!);

      expect(notesB, isEmpty);
    });

    test('updateNote modifie le titre et le statut', () async {
      final User user = await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
      final Note inseree = await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Avant',
          content: 'Contenu',
          isDone: false,
          createdAt: DateTime(2026, 5, 12, 10, 0),
        ),
      );

      final Note miseAJour = inseree.copyWith(
        title: 'Après',
        content: 'Contenu modifié',
        isDone: true,
      );
      final int count = await manager.updateNote(miseAJour);

      expect(count, 1);

      final List<Note> notes = await manager.getNotesByUser(user.id!);
      expect(notes.single.title, 'Après');
      expect(notes.single.content, 'Contenu modifié');
      expect(notes.single.isDone, isTrue);
    });

    test('deleteNote supprime une note existante', () async {
      final User user = await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
      final Note note = await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'À supprimer',
          isDone: false,
          createdAt: DateTime(2026, 5, 12),
        ),
      );

      final int count = await manager.deleteNote(note.id!);

      expect(count, 1);

      final List<Note> notes = await manager.getNotesByUser(user.id!);
      expect(notes, isEmpty);
    });

    test('searchNotes filtre par mot-clé dans le titre', () async {
      final User user = await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Planification du sprint trim',
          content: 'Détails du planning',
          isDone: false,
          createdAt: DateTime(2026, 5, 12, 14, 30),
        ),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Réunion client',
          content: 'Préparer le compte rendu',
          isDone: true,
          createdAt: DateTime(2026, 5, 13, 9, 0),
        ),
      );

      final List<Note> resultats = await manager.searchNotes(
        user.id!,
        'sprint',
      );

      expect(resultats.length, 1);
      expect(resultats.single.title, 'Planification du sprint trim');
    });

    test('searchNotes filtre par mot-clé dans le contenu', () async {
      final User user = await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Planification',
          content: 'Préparer le compte rendu',
          isDone: false,
          createdAt: DateTime(2026, 5, 12),
        ),
      );

      final List<Note> resultats = await manager.searchNotes(
        user.id!,
        'compte rendu',
      );

      expect(resultats.length, 1);
      expect(resultats.single.title, 'Planification');
    });

    test('searchNotes retourne une liste vide sans correspondance', () async {
      final User user = await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Planification',
          isDone: false,
          createdAt: DateTime(2026, 5, 12),
        ),
      );

      final List<Note> resultats = await manager.searchNotes(
        user.id!,
        'introuvable',
      );

      expect(resultats, isEmpty);
    });

    test('getNotesByUserAndStatus filtre selon le statut', () async {
      final User user = await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Terminée',
          isDone: true,
          createdAt: DateTime(2026, 5, 12),
        ),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'À faire',
          isDone: false,
          createdAt: DateTime(2026, 5, 13),
        ),
      );

      final List<Note> aFaire = await manager.getNotesByUserAndStatus(
        user.id!,
        false,
      );
      final List<Note> terminees = await manager.getNotesByUserAndStatus(
        user.id!,
        true,
      );

      expect(aFaire.length, 1);
      expect(aFaire.single.title, 'À faire');
      expect(terminees.length, 1);
      expect(terminees.single.title, 'Terminée');
    });

    test('countNotes compte les notes de l\'utilisateur', () async {
      final User user = await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Un',
          isDone: false,
          createdAt: DateTime(2026, 5, 12),
        ),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Deux',
          isDone: true,
          createdAt: DateTime(2026, 5, 13),
        ),
      );

      final int total = await manager.countNotes(user.id!);

      expect(total, 2);
    });
  });
}
