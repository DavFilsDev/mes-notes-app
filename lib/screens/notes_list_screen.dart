import 'package:flutter/material.dart';

import '../models/note.dart';
import '../models/user.dart';
import '../services/database_manager.dart';
import 'profile_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key, required this.user});

  final User user;

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Note> _notes = <Note>[];
  int _filterIndex = 0;

  static const List<String> _mois = <String>[
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  @override
  void initState() {
    super.initState();
    _chargerNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Note> get _notesFiltrees {
    switch (_filterIndex) {
      case 1:
        return _notes.where((Note note) => !note.isDone).toList();
      case 2:
        return _notes.where((Note note) => note.isDone).toList();
      default:
        return _notes;
    }
  }

  void _afficherMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _chargerNotes() async {
    final int? userId = widget.user.id;
    if (userId == null) {
      return;
    }
    List<Note> resultat;
    final String query = _searchController.text.trim();
    try {
      if (query.isEmpty) {
        resultat = await DatabaseManager.instance.getNotesByUser(userId);
      } else {
        resultat = await DatabaseManager.instance.searchNotes(userId, query);
      }
    } catch (_) {
      resultat = <Note>[];
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _notes
        ..clear()
        ..addAll(resultat);
    });
  }

  void _rechercherNotes(String query) {
    setState(() {});
    _chargerNotes();
  }

  void _viderRecherche() {
    _searchController.clear();
    setState(() {});
    _chargerNotes();
  }

  void _changerFiltre(int index) {
    setState(() {
      _filterIndex = index;
    });
  }

  Future<void> _ajouterNote(String titre, String contenu) async {
    if (titre.trim().isEmpty) {
      _afficherMessage('Le titre est requis.');
      return;
    }
    final int? userId = widget.user.id;
    try {
      await DatabaseManager.instance.insertNote(
        Note.sansId(
          userId: userId,
          title: titre.trim(),
          content: contenu.trim().isEmpty ? null : contenu.trim(),
          isDone: false,
          createdAt: DateTime.now(),
        ),
      );
      await _chargerNotes();
      _afficherMessage('Note ajoutée avec succès.');
    } catch (_) {
      _afficherMessage('Erreur lors de l\'ajout de la note.');
    }
  }

  Future<void> _modifierNote(Note note, String titre, String contenu) async {
    if (titre.trim().isEmpty) {
      _afficherMessage('Le titre est requis.');
      return;
    }
    final Note miseAJour = note.copyWith(
      title: titre.trim(),
      content: contenu.trim().isEmpty ? null : contenu.trim(),
    );
    try {
      await DatabaseManager.instance.updateNote(miseAJour);
      await _chargerNotes();
      _afficherMessage('Note modifiée avec succès.');
    } catch (_) {
      _afficherMessage('Erreur lors de la modification de la note.');
    }
  }

  Future<void> _supprimerNote(Note note) async {
    final int? id = note.id;
    if (id == null) {
      return;
    }
    try {
      await DatabaseManager.instance.deleteNote(id);
      await _chargerNotes();
      _afficherMessage('Note supprimée.');
    } catch (_) {
      _afficherMessage('Erreur lors de la suppression de la note.');
    }
  }

  Future<void> _basculerNote(Note note) async {
    final Note miseAJour = note.copyWith(isDone: !note.isDone);
    try {
      await DatabaseManager.instance.updateNote(miseAJour);
      await _chargerNotes();
    } catch (_) {
      _afficherMessage('Erreur lors de la mise à jour de la note.');
    }
  }

  Future<void> _montrerDialogueAjout() async {
    final TextEditingController titreController = TextEditingController();
    final TextEditingController contenuController = TextEditingController();
    final bool? enregistrer = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Ajouter une note',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: titreController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Titre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contenuController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Contenu',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    if (enregistrer == true) {
      await _ajouterNote(titreController.text, contenuController.text);
    }
    titreController.dispose();
    contenuController.dispose();
  }

  Future<void> _montrerDialogueEdition(Note note) async {
    final TextEditingController titreController = TextEditingController(
      text: note.title,
    );
    final TextEditingController contenuController = TextEditingController(
      text: note.content ?? '',
    );
    final bool? enregistrer = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Modifier la note',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: titreController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Titre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contenuController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Contenu',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    if (enregistrer == true) {
      await _modifierNote(note, titreController.text, contenuController.text);
    }
    titreController.dispose();
    contenuController.dispose();
  }

  Future<void> _montrerDialogueSuppression(Note note) async {
    final bool? confirmer = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Supprimer la note',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette note ?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
    if (confirmer == true) {
      await _supprimerNote(note);
    }
  }

  String _formaterDate(DateTime date) {
    final String jour = date.day.toString();
    final String heure = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$jour ${_mois[date.month - 1]}, $heure:$minute';
  }

  Widget _construireCarteNote(Note note) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Checkbox(
                  value: note.isDone,
                  activeColor: Colors.blue,
                  onChanged: (_) => _basculerNote(note),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              note.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: note.isDone
                                    ? Colors.grey
                                    : Colors.black87,
                                decoration: note.isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formaterDate(note.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (note.content != null && note.content!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            note.content!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              decoration: note.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  tooltip: 'Modifier',
                  onPressed: () => _montrerDialogueEdition(note),
                  icon: const Icon(Icons.edit, color: Colors.amber),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  onPressed: () => _montrerDialogueSuppression(note),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construireOptionFiltre(int index, String label) {
    final bool selected = _filterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changerFiltre(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade600,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _construireEtatVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.sticky_note_2_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune note trouvée.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Note> notes = _notesFiltrees;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mes Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Mon Profil',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProfileScreen(user: widget.user),
              ),
            ),
            icon: const Icon(Icons.account_circle, size: 32),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(28),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _rechercherNotes,
              decoration: InputDecoration(
                hintText: 'Rechercher une note...',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        onPressed: _viderRecherche,
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: <Widget>[
                _construireOptionFiltre(0, 'Toutes'),
                _construireOptionFiltre(1, 'À faire'),
                _construireOptionFiltre(2, 'Terminées'),
              ],
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? _construireEtatVide()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 96),
                    itemCount: notes.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _construireCarteNote(notes[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _montrerDialogueAjout,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une note'),
      ),
    );
  }
}
