import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_notes_app/models/user.dart';
import 'package:mes_notes_app/screens/connexion_screen.dart';
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

  Future<void> afficherConnexion(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConnexionScreen()));
    await tester.pump();
  }

  Future<void> remplirFormulaire(
    WidgetTester tester, {
    required String username,
    required String password,
  }) async {
    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), password);
  }

  group('ConnexionScreen', () {
    testWidgets('affiche les champs du formulaire de connexion', (
      WidgetTester tester,
    ) async {
      await preparerBase(tester);
      await afficherConnexion(tester);

      expect(find.text('Mes Notes'), findsOneWidget);
      expect(find.text('Connectez-vous à votre compte'), findsOneWidget);
      expect(find.text('Nom d\'utilisateur'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Connexion'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.textContaining('incorrect'), findsNothing);
    });

    testWidgets('affiche un bandeau d\'erreur en cas d\'échec', (
      WidgetTester tester,
    ) async {
      await preparerBase(tester);
      await afficherConnexion(tester);

      await remplirFormulaire(
        tester,
        username: 'alex.morgan',
        password: 'mauvais',
      );
      await tester.tap(find.text('Connexion'));
      await laisserAsyncTerminer(tester);
      await tester.pump();

      expect(
        find.textContaining('Nom d\'utilisateur ou mot de passe incorrect'),
        findsOneWidget,
      );
    });

    testWidgets('affiche un bandeau d\'erreur si le formulaire est vide', (
      WidgetTester tester,
    ) async {
      await preparerBase(tester);
      await afficherConnexion(tester);

      await tester.tap(find.text('Connexion'));
      await tester.pump();

      expect(find.textContaining('incorrect'), findsOneWidget);
    });

    testWidgets('navigue vers la liste des notes en cas de succès', (
      WidgetTester tester,
    ) async {
      await preparerBase(tester);
      await afficherConnexion(tester);

      await remplirFormulaire(
        tester,
        username: 'alex.morgan',
        password: 'secret',
      );
      await tester.tap(find.text('Connexion'));
      await laisserAsyncTerminer(tester);
      await tester.pumpAndSettle();

      expect(find.byType(NotesListScreen), findsOneWidget);
    });

    testWidgets('bascule la visibilité du mot de passe', (
      WidgetTester tester,
    ) async {
      await preparerBase(tester);
      await afficherConnexion(tester);

      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue,
      );

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isFalse,
      );
    });
  });
}
