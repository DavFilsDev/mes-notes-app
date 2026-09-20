import 'package:flutter/material.dart';

import 'screens/connexion_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MesNotesApp());
}

class MesNotesApp extends StatelessWidget {
  const MesNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mes Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const ConnexionScreen(),
    );
  }
}
