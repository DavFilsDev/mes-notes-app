import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_notes_app/models/user.dart';
import 'package:mes_notes_app/screens/connexion_screen.dart';
import 'package:mes_notes_app/screens/inscription_screen.dart';
import 'package:mes_notes_app/screens/notes_list_screen.dart';
import 'package:mes_notes_app/services/database_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  DatabaseManager? dernierManager;

  Future<void> preparerBase(WidgetTester tester) async {
    await tester.runAsync(() async {
      if (dernierManager != null) {
        await dernierManager!.close();
      }
      final DatabaseManager manager = DatabaseManager(
        path: inMemoryDatabasePath,
      );
      dernierManager = manager;
      DatabaseManager.instance = manager;
      await manager.insertUser(
        const User.sansId(username: 'alex.morgan', password: 'secret'),
      );
    });
  }

  Future<void> laisserAsyncTerminer(WidgetTester tester) async {
    for (int i = 0; i < 8; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }
  }

  Future<void> ouvrirInscription(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConnexionScreen()));
    await tester.pump();
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
  }

  Future<void> remplirInscription(
    WidgetTester tester, {
    required String username,
    required String password,
    required String confirmation,
  }) async {
    final Finder champs = find.descendant(
      of: find.byType(InscriptionScreen),
      matching: find.byType(TextField),
    );
    await tester.enterText(champs.at(0), username);
    await tester.enterText(champs.at(1), password);
    await tester.enterText(champs.at(2), confirmation);
  }

  group('InscriptionScreen', () {
    testWidgets('affiche les champs du formulaire d\'inscription', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: InscriptionScreen()));
      await tester.pump();

      expect(find.text('Mes Notes'), findsOneWidget);
      expect(find.text('Créez votre compte'), findsOneWidget);
      expect(find.text('Nom d\'utilisateur'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);
      expect(find.text('Créer mon compte'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('le lien de la connexion ouvre l\'inscription', (
      WidgetTester tester,
    ) async {
      await preparerBase(tester);
      await ouvrirInscription(tester);

      expect(find.byType(InscriptionScreen), findsOneWidget);
    });

    testWidgets('crée un compte puis se connecte', (WidgetTester tester) async {
      await preparerBase(tester);
      await ouvrirInscription(tester);

      await remplirInscription(
        tester,
        username: 'david',
        password: 'davidpassord',
        confirmation: 'davidpassord',
      );
      await tester.tap(find.text('Créer mon compte'));
      await laisserAsyncTerminer(tester);
      await tester.pumpAndSettle();

      expect(find.byType(InscriptionScreen), findsNothing);
      expect(find.byType(ConnexionScreen), findsOneWidget);
      expect(
        find.text('Compte créé avec succès. Connectez-vous.'),
        findsOneWidget,
      );

      final Finder champsConnexion = find.descendant(
        of: find.byType(ConnexionScreen),
        matching: find.byType(TextField),
      );
      await tester.enterText(champsConnexion.at(0), 'david');
      await tester.enterText(champsConnexion.at(1), 'davidpassord');
      await tester.tap(find.text('Connexion'));
      await laisserAsyncTerminer(tester);
      await tester.pumpAndSettle();

      expect(find.byType(NotesListScreen), findsOneWidget);
    });

    testWidgets('affiche une erreur si le nom est déjà utilisé', (
      WidgetTester tester,
    ) async {
      await preparerBase(tester);
      await ouvrirInscription(tester);

      await remplirInscription(
        tester,
        username: 'alex.morgan',
        password: 'secret',
        confirmation: 'secret',
      );
      await tester.tap(find.text('Créer mon compte'));
      await laisserAsyncTerminer(tester);
      await tester.pump();

      expect(find.textContaining('déjà utilisé'), findsOneWidget);
      expect(find.byType(InscriptionScreen), findsOneWidget);
    });

    testWidgets('affiche une erreur si les mots de passe diffèrent', (
      WidgetTester tester,
    ) async {
      await preparerBase(tester);
      await ouvrirInscription(tester);

      await remplirInscription(
        tester,
        username: 'david',
        password: 'abcdef',
        confirmation: 'abcdeg',
      );
      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();

      expect(find.textContaining('ne correspondent pas'), findsOneWidget);
    });

    testWidgets('affiche une erreur si le mot de passe est trop court', (
      WidgetTester tester,
    ) async {
      await preparerBase(tester);
      await ouvrirInscription(tester);

      await remplirInscription(
        tester,
        username: 'david',
        password: 'abc',
        confirmation: 'abc',
      );
      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();

      expect(find.textContaining('moins 6 caractères'), findsOneWidget);
    });
  });
}
