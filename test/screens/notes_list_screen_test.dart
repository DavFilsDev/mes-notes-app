import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_notes_app/models/note.dart';
import 'package:mes_notes_app/models/user.dart';
import 'package:mes_notes_app/screens/notes_list_screen.dart';
import 'package:mes_notes_app/services/database_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  DatabaseManager? dernierManager;

  Future<User> preparerBase(WidgetTester tester) async {
    late User user;
    await tester.runAsync(() async {
      if (dernierManager != null) {
        await dernierManager!.close();
      }
      final DatabaseManager manager = DatabaseManager(
        path: inMemoryDatabasePath,
      );
      dernierManager = manager;
      DatabaseManager.instance = manager;
      user = await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
      await manager.insertNote(
        Note.sansId(
          userId: user.id,
          title: 'Planification du sprint trim',
          content: 'Préparer le planning pour le sprint',
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
    });
    return user;
  }

  Future<void> laisserAsyncTerminer(WidgetTester tester) async {
    for (int i = 0; i < 8; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }
  }

  Future<void> afficherListeNotes(WidgetTester tester, User user) async {
    await tester.pumpWidget(MaterialApp(home: NotesListScreen(user: user)));
    await laisserAsyncTerminer(tester);
    await tester.pump();
  }

  group('NotesListScreen', () {
    testWidgets('affiche la liste des notes', (WidgetTester tester) async {
      final User user = await preparerBase(tester);
      await afficherListeNotes(tester, user);

      expect(find.text('Planification du sprint trim'), findsOneWidget);
      expect(find.text('Réunion client'), findsOneWidget);
      expect(find.text('Préparer le planning pour le sprint'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('filtre les notes via la recherche', (
      WidgetTester tester,
    ) async {
      final User user = await preparerBase(tester);
      await afficherListeNotes(tester, user);

      await tester.enterText(find.byType(TextField), 'Réunion');
      await laisserAsyncTerminer(tester);
      await tester.pump();

      expect(find.text('Réunion client'), findsOneWidget);
      expect(find.text('Planification du sprint trim'), findsNothing);
    });

    testWidgets('filtre les notes selon le statut', (
      WidgetTester tester,
    ) async {
      final User user = await preparerBase(tester);
      await afficherListeNotes(tester, user);

      await tester.tap(find.text('À faire'));
      await tester.pump();

      expect(find.text('Planification du sprint trim'), findsOneWidget);
      expect(find.text('Réunion client'), findsNothing);

      await tester.tap(find.text('Terminées'));
      await tester.pump();

      expect(find.text('Réunion client'), findsOneWidget);
      expect(find.text('Planification du sprint trim'), findsNothing);
    });

    testWidgets('bascule le statut d\'une note via la case', (
      WidgetTester tester,
    ) async {
      final User user = await preparerBase(tester);
      await afficherListeNotes(tester, user);

      final Finder cases = find.byType(Checkbox);
      expect(tester.widget<Checkbox>(cases.at(1)).value, isFalse);

      await tester.tap(cases.at(1));
      await laisserAsyncTerminer(tester);
      await tester.pump();

      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isTrue,
      );
    });

    testWidgets('ouvre le dialogue d\'ajout de note', (
      WidgetTester tester,
    ) async {
      final User user = await preparerBase(tester);
      await afficherListeNotes(tester, user);

      await tester.tap(find.text('Ajouter une note'));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter une note'), findsNWidgets(2));
      expect(find.text('Titre'), findsOneWidget);
      expect(find.text('Contenu'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
    });

    testWidgets('ajoute une note depuis le dialogue', (
      WidgetTester tester,
    ) async {
      final User user = await preparerBase(tester);
      await afficherListeNotes(tester, user);

      await tester.tap(find.text('Ajouter une note'));
      await tester.pumpAndSettle();

      final Finder champsDialogue = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(champsDialogue.at(0), 'Nouvelle note');
      await tester.enterText(champsDialogue.at(1), 'Contenu de la note');
      await tester.tap(find.text('Enregistrer'));
      await laisserAsyncTerminer(tester);
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle note'), findsOneWidget);
      expect(find.text('Contenu de la note'), findsOneWidget);
    });

    testWidgets('ouvre le dialogue d\'édition pré-rempli', (
      WidgetTester tester,
    ) async {
      final User user = await preparerBase(tester);
      await afficherListeNotes(tester, user);

      await tester.tap(find.byIcon(Icons.edit).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Modifier la note'), findsOneWidget);
      final Finder champsDialogue = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      final TextField titre = tester.widget<TextField>(champsDialogue.at(0));
      expect(titre.controller!.text, 'Planification du sprint trim');
    });

    testWidgets('supprime une note après confirmation', (
      WidgetTester tester,
    ) async {
      final User user = await preparerBase(tester);
      await afficherListeNotes(tester, user);

      expect(find.text('Réunion client'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(find.text('Supprimer la note'), findsOneWidget);

      await tester.tap(find.text('Supprimer'));
      await laisserAsyncTerminer(tester);
      await tester.pumpAndSettle();

      expect(find.text('Réunion client'), findsNothing);
    });
  });
}
