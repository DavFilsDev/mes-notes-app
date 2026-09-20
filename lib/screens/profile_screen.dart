import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/database_manager.dart';
import 'connexion_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalNotes = 0;

  @override
  void initState() {
    super.initState();
    _chargerTotalNotes();
  }

  Future<void> _chargerTotalNotes() async {
    final int? userId = widget.user.id;
    if (userId == null) {
      return;
    }
    try {
      final int total = await DatabaseManager.instance.countNotes(userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _totalNotes = total;
      });
    } catch (_) {}
  }

  void _deconnexion() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ConnexionScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 16),
            const Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                widget.user.username,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '@${widget.user.username}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: Colors.blue,
                    ),
                    title: const Text('Nom d\'utilisateur'),
                    trailing: Text(
                      widget.user.username,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  const ListTile(
                    leading: Icon(Icons.storage, color: Colors.blue),
                    title: Text('Statut de la base de données'),
                    trailing: Text(
                      'SQLite Locale',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.notes, color: Colors.blue),
                    title: const Text('Nombre total de notes'),
                    trailing: Text(
                      '$_totalNotes',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _deconnexion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Déconnexion',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
