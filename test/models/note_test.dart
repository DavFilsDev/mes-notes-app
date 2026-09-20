import 'package:flutter_test/flutter_test.dart';
import 'package:mes_notes_app/models/note.dart';

void main() {
  group('Note', () {
    test('toMap sérialise toutes les propriétés', () {
      final Note note = Note(
        id: 1,
        userId: 2,
        title: 'Planification du sprint trim',
        content: 'Préparer le planning',
        isDone: false,
        createdAt: DateTime(2026, 5, 12, 14, 30),
      );

      final Map<String, dynamic> map = note.toMap();

      expect(map['id'], 1);
      expect(map['user_id'], 2);
      expect(map['title'], 'Planification du sprint trim');
      expect(map['content'], 'Préparer le planning');
      expect(map['is_done'], 0);
      expect(map['created_at'], '2026-05-12T14:30:00.000');
    });

    test('fromMap désérialise correctement une ligne', () {
      final Note note = Note.fromMap(<String, dynamic>{
        'id': 3,
        'user_id': 1,
        'title': 'Réunion client',
        'content': 'Compte rendu à préparer',
        'is_done': 1,
        'created_at': '2026-05-13T09:00:00.000',
      });

      expect(note.id, 3);
      expect(note.userId, 1);
      expect(note.title, 'Réunion client');
      expect(note.content, 'Compte rendu à préparer');
      expect(note.isDone, isTrue);
      expect(note.createdAt, DateTime(2026, 5, 13, 9, 0));
    });

    test('fromMap gère un contenu nul et une tâche non terminée', () {
      final Note note = Note.fromMap(<String, dynamic>{
        'id': 4,
        'user_id': 1,
        'title': 'Sans contenu',
        'is_done': 0,
        'created_at': '2026-05-14T08:00:00.000',
      });

      expect(note.content, isNull);
      expect(note.isDone, isFalse);
    });

    test('sansId construit une note sans identifiant', () {
      final Note note = Note.sansId(
        userId: 1,
        title: 'Nouvelle note',
        content: null,
        isDone: false,
        createdAt: DateTime(2026, 5, 15),
      );

      expect(note.id, isNull);
      expect(note.userId, 1);
      expect(note.title, 'Nouvelle note');
      expect(note.isDone, isFalse);
    });

    test('toMap convertit isDone en entier sqlite', () {
      final Note terminee = Note.sansId(
        userId: 1,
        title: 'Terminée',
        isDone: true,
        createdAt: DateTime(2026, 5, 16),
      );

      expect(terminee.toMap()['is_done'], 1);
    });

    test('copyWith applique uniquement les champs fournis', () {
      final Note originale = Note(
        id: 9,
        userId: 1,
        title: 'Originale',
        content: 'Contenu',
        isDone: false,
        createdAt: DateTime(2026, 5, 17),
      );

      final Note modifiee = originale.copyWith(title: 'Modifiée');

      expect(modifiee.id, 9);
      expect(modifiee.userId, 1);
      expect(modifiee.title, 'Modifiée');
      expect(modifiee.content, 'Contenu');
      expect(modifiee.isDone, isFalse);

      final Note basculee = originale.copyWith(isDone: true);
      expect(basculee.isDone, isTrue);
    });

    test('toMap et fromMap sont inverses', () {
      final Note original = Note(
        id: 11,
        userId: 5,
        title: 'Aller retour',
        content: 'Données',
        isDone: true,
        createdAt: DateTime(2026, 6, 1, 18, 45),
      );

      final Note reconstitue = Note.fromMap(original.toMap());

      expect(reconstitue.id, original.id);
      expect(reconstitue.userId, original.userId);
      expect(reconstitue.title, original.title);
      expect(reconstitue.content, original.content);
      expect(reconstitue.isDone, original.isDone);
      expect(reconstitue.createdAt, original.createdAt);
    });
  });
}
