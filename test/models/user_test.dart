import 'package:flutter_test/flutter_test.dart';
import 'package:mes_notes_app/models/user.dart';

void main() {
  group('User', () {
    test('toMap sérialise toutes les propriétés', () {
      const User user = User(
        id: 1,
        username: 'alex.morgan',
        password: 'motdepasse',
      );

      final Map<String, dynamic> map = user.toMap();

      expect(map['id'], 1);
      expect(map['username'], 'alex.morgan');
      expect(map['password'], 'motdepasse');
    });

    test('fromMap désérialise correctement une ligne', () {
      final User user = User.fromMap(<String, dynamic>{
        'id': 2,
        'username': 'john.doe',
        'password': 'secret123',
      });

      expect(user.id, 2);
      expect(user.username, 'john.doe');
      expect(user.password, 'secret123');
    });

    test('fromMap gère un id nul', () {
      final User user = User.fromMap(<String, dynamic>{
        'username': 'alex.morgan',
        'password': 'motdepasse',
      });

      expect(user.id, isNull);
      expect(user.username, 'alex.morgan');
    });

    test('sansId construit un utilisateur sans identifiant', () {
      const User user = User.sansId(
        username: 'alex.morgan',
        password: 'motdepasse',
      );

      expect(user.id, isNull);
      expect(user.username, 'alex.morgan');
      expect(user.password, 'motdepasse');
    });

    test('toMap et fromMap sont inverses', () {
      const User original = User(id: 7, username: 'sophie.b', password: 'abc');

      final User reconstitue = User.fromMap(original.toMap());

      expect(reconstitue.id, original.id);
      expect(reconstitue.username, original.username);
      expect(reconstitue.password, original.password);
    });
  });
}
