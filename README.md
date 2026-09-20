# Mes Notes - Application de Gestion de Notes Locale

Application Flutter minimaliste et éco-conçue de gestion de notes et de tâches, 100% hors-ligne grâce à un stockage local SQLite. Développée dans le cadre de la formation **D-CLIC / OIF (Semaine 6 - Niveau Intermédiaire)**.

Ce document fait office de **cahier des charges**, de **documentation technique** et de **dossier de soutenance** pour le projet.

---

## Table des matières

- [Cahier des Charges](#cahier-des-charges)
- [Documentation & Mockups](#documentation--emplacements-des-mockups)
- [Stack Technique & Architecture](#stack-technique--architecture)
- [Modèle de Données (SQLite)](#modèle-de-données-sqlite)
- [Plateformes Supportées](#plateformes-supportées)
- [Plateforme de Test](#plateforme-de-test)
- [Installation & Lancement](#installation--lancement)
- [Principes d'Écoconception](#principes-décoconception)

---

## Cahier des Charges

### 1. Contexte du projet

| Rubrique | Détail |
| :--- | :--- |
| **Intitulé** | Mes Notes - Application de gestion de notes et de tâches |
| **Formation** | D-CLIC / Organisation internationale de la Francophonie (OIF) |
| **Session** | Semaine 6 - Niveau Intermédiaire |
| **Objectif pédagogique** | Concevoir un produit Flutter complet : modélisation de données, stockage local, écrans navigables, tests et documentation |
| **Utilisateur cible** | Apprenants, professionnels et particuliers souhaitant organiser leurs notes sans dépendance réseau |

### 2. Objectif général

Développer une application mobile de gestion de notes **entièrement locale** permettant à un utilisateur de s'authentifier puis de créer, consulter, modifier, rechercher et supprimer ses propres notes de façon sécurisée et intuitive.

### 3. Portée du projet

#### a. Authentification utilisateur

| Identifiant | Description |
| :--- | :--- |
| **Inscription** | Création d'un compte local : nom d'utilisateur (≥ 3 caractères, unique), mot de passe (≥ 6 caractères) et confirmation. Vérification en base de l'unicité du nom. |
| **Connexion** | Accès à l'application par couple nom d'utilisateur / mot de passe vérifié en base SQLite. |
| **Compte de démonstration** | Compte pré-rempli à la première ouverture : `alex.morgan` / `secret` (via `seedDefaultUserIfEmpty`). |
| **Gestion de session** | Aucune session persistante : l'application démarre toujours sur l'écran de connexion. |
| **Déconnexion** | Bouton disponible dans l'écran Profil ; retour à l'écran de connexion avec purge de la pile de navigation. |

#### b. Gestion des notes (CRUD + filtrage)

| Fonctionnalité | Description |
| :--- | :--- |
| **Consultation (Read)** | Liste des notes de l'utilisateur connecté, triées par date de création décroissante. |
| **Création (Create)** | Création d'une note via un dialogue de saisie (titre + contenu). |
| **Modification (Update)** | Édition du titre, du contenu et bascule du statut de complétion (checkbox). |
| **Suppression (Delete)** | Suppression après confirmation dans une boîte de dialogue explicite. |
| **Statut de complétion** | Chaque note possède un statut *À faire* / *Terminée* stocké en base (`is_done`). |
| **Recherche** | Barre de recherche dynamique sur le titre et le contenu (`LIKE` insensible à la casse). |
| **Filtres rapides** | Filtres *Toutes*, *À faire* et *Terminées* basés sur le statut. |
| **Horodatage** | Date et heure de création automatiques, stockées et affichées pour chaque note. |

#### c. Gestion du profil utilisateur

| Fonctionnalité | Description |
| :--- | :--- |
| **Informations du compte** | Affichage du nom d'utilisateur connecté. |
| **Statistiques locales** | Nombre total de notes, notes terminées et notes à faire. |
| **Déconnexion** | Retour sécurisé à l'écran de connexion. |

### 4. Règles de gestion

- Chaque note appartient exclusivement à l'utilisateur connecté (`user_id` en clé étrangère logique).
- Le nom d'utilisateur est unique en base (contrainte `UNIQUE`).
- Aucune donnée n'est envoyée sur le réseau : 100% des données restent sur le terminal (SQLite).
- Messages d'erreur et dialogues de confirmation explicites pour toute action destructive.

### 5. Contraintes de développement

- **Aucun commentaire** dans les fichiers Dart.
- Conformité stricte à `flutter analyze` (zéro erreur, zéro avertissement).
- Suite de tests complète : `test/models/`, `test/services/`, `test/screens/`.

---

## Documentation & Emplacements des Mockups

Tous les maquettes de conception (mockups Figma) et les documents requis pour la soumission sont stockés dans le répertoire **`/docs/mockup/`** :

| Fichier | Écran |
| :--- | :--- |
| `/docs/mockup/01_connexion.png` | Écran de connexion |
| `/docs/mockup/02_inscription.png` | Écran d'inscription |
| `/docs/mockup/03_liste_notes.png` | Liste des notes (recherche + filtres) |
| `/docs/mockup/04_dialogue_note.png` | Dialogue de création / édition d'une note |
| `/docs/mockup/05_profil.png` | Profil utilisateur et statistiques |

### Aperçu des interfaces

| Connexion | Inscription | Liste des Notes | Dialogue de Note | Mon Profil |
| :---: | :---: | :---: | :---: | :---: |
| ![Connexion](docs/mockup/01_connexion.png) | ![Inscription](docs/mockup/02_inscription.png) | ![Liste](docs/mockup/03_liste_notes.png) | ![Dialogue](docs/mockup/04_dialogue_note.png) | ![Profil](docs/mockup/05_profil.png) |

---

## Stack Technique & Architecture

### Stack

| Composant | Choix technique |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev/) (Dart) |
| **Base de données locale** | [SQLite](https://pub.dev/packages/sqflite) (`sqflite`) |
| **SQLite sur desktop/web** | `sqflite_common_ffi` (tests/Linux) et `sqflite_common_ffi_web` (web/WASM) |
| **Design & UI** | Material Design 3 |
| **Gestion de version** | Git avec conventions *Conventional Commits* |

### Architecture (pattern MVC)

L'application suit un découpage **Modèle - Vue - Contrôleur** léger :

- **Modèle** : classes Dart pures avec mapping `Map` (`fromMap` / `toMap`), identifiant nullable et fabrique `.sansId`.
  - `lib/models/user.dart`
  - `lib/models/note.dart`
- **Contrôleur / Service** : singleton `DatabaseManager` centralisant toute la couche d'accès aux données SQLite.
  - `lib/services/database_manager.dart`
  - `lib/services/database_factory.dart` (+ variantes `_io.dart` / `_web.dart` par import conditionnel)
- **Vues** : écrans `StatefulWidget` + `setState`, sans package de gestion d'état externe.
  - `lib/screens/connexion_screen.dart`
  - `lib/screens/inscription_screen.dart`
  - `lib/screens/notes_list_screen.dart`
  - `lib/screens/profile_screen.dart`
- **Point d'entrée** : `lib/main.dart`

```
lib/
├── main.dart
├── models/
│   ├── user.dart
│   └── note.dart
├── services/
│   ├── database_manager.dart
│   ├── database_factory.dart
│   ├── database_factory_io.dart
│   └── database_factory_web.dart
└── screens/
    ├── connexion_screen.dart
    ├── inscription_screen.dart
    ├── notes_list_screen.dart
    └── profile_screen.dart
```

---

## Plateformes Supportées

L'application est conçue pour être exécutée sur l'ensemble des plateformes Flutter. Le choix du moteur SQLite est **automatique** selon la plateforme, via un import conditionnel (`if (dart.library.js_interop)`) et le flag `kIsWeb` :

| Plateforme | Statut | Moteur SQLite |
| :--- | :--- | :--- |
| **Linux (Ubuntu desktop)** | ✅ Testé et validé | `sqflite_common_ffi` (FFI natif) |
| **Android** | ✅ Supporté (build APK vérifié) | `sqflite` (plugin natif) |
| **Web** (Chrome/WASM) | ✅ Supporté (build web vérifié) | `sqflite_common_ffi_web` (WASM + IndexedDB) |
| **iOS** | ⚠️ Prévu, non testé | `sqflite` (plugin natif) |
| **macOS** | ⚠️ Prévu, non testé | `sqflite_common_ffi` (FFI natif) |
| **Windows** | ⚠️ Prévu, non testé | `sqflite_common_ffi` (FFI natif) |

Détails techniques par plateforme :

- **Linux/macOS/Windows** (desktop) : fichier de base `mes_notes.db` stocké dans le répertoire applicatif de la plateforme (`getDatabasesPath()`).
- **Android/iOS** : plugin natif `sqflite`, fichier `mes_notes.db` dans le répertoire de données de l'application.
- **Web** : fichier `mes_notes_web.db` géré en **IndexedDB** via `sqflite_common_ffi_web`. La base étant rattachée à l'origine du site, **les données dépendent du port** utilisé en développement (`localhost:8080` ≠ `localhost:8081`).

---

## Modèle de Données (SQLite)

Deux tables principales :

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL
);

CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER REFERENCES users(id),
  title TEXT NOT NULL,
  content TEXT,
  is_done INTEGER DEFAULT 0,
  created_at TEXT NOT NULL
);
```

### API du `DatabaseManager`

| Méthode | Rôle |
| :--- | :--- |
| `insertUser(user)` | Crée un compte utilisateur (nom unique). |
| `findUserByUsername(username)` | Recherche un utilisateur par nom. |
| `authenticate(username, password)` | Vérifie les identifiants lors de la connexion. |
| `seedDefaultUserIfEmpty()` | Insère le compte de démonstration si la base est vide. |
| `insertNote(note)` | Crée une note. |
| `getNotesByUser(userId)` | Liste les notes d'un utilisateur (tri décroissant). |
| `searchNotes(userId, query)` | Recherche par mot-clé sur titre et contenu. |
| `getNotesByUserAndStatus(userId, isDone)` | Filtre les notes par statut de complétion. |
| `updateNote(note)` | Modifie une note. |
| `deleteNote(id)` | Supprime une note. |
| `countNotes(userId)` | Compte les notes d'un utilisateur. |
| `close()` | Ferme la connexion à la base courante. |

---

## Plateforme de Test

Le projet a été **testé et validé sur Linux (Ubuntu desktop)** en utilisant **SQLite via FFI** (`sqflite_common_ffi`), avec l'intégralité des contrôles de qualité automatisés au vert :

| Contrôle | Commande | Résultat |
| :--- | :--- | :--- |
| **Analyse statique** | `flutter analyze` | ✅ Aucun problème détecté (0 erreur, 0 avertissement) |
| **Tests unitaires & widgets** | `flutter test` | ✅ 46 tests sur 46 réussis (100%) |

### Couverture des tests (46 tests)

| Fichier de test | Nombre de tests | Couverture |
| :--- | :---: | :--- |
| `test/models/note_test.dart` | 7 | Sérialisation du modèle Note |
| `test/models/user_test.dart` | 5 | Sérialisation du modèle User |
| `test/services/database_manager_test.dart` | 15 | CRUD, recherche, filtres, connexion, seed |
| `test/screens/connexion_screen_test.dart` | 5 | Écran de connexion (widget) |
| `test/screens/inscription_screen_test.dart` | 6 | Écran d'inscription (widget) |
| `test/screens/notes_list_screen_test.dart` | 8 | Liste, recherche, filtres, dialogues (widget) |

> Les tests d'interface reposent sur une base SQLite en mémoire (`inMemoryDatabasePath`) avec la factory FFI, garantissant des tests déterministes et rapides.

---

## Installation & Lancement

### Prérequis

- Flutter SDK (Channel stable) — **Linux (Ubuntu desktop)** et/ou Android studio pour les builds mobiles.

### Étapes

```bash
# 1. Cloner le projet
git clone <url-du-depot>
cd mes_notes_app

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application (Linux desktop : SQLite FFI)
flutter run -d linux

# 4. Lancer l'application (Android)
flutter run -d <id-appareil>

# 5. Lancer l'application (Web/WASM)
flutter run -d chrome
```

### Contrôles de qualité

```bash
flutter analyze          # 0 problème attendu
flutter test             # 46/46 attendus
```

---

## Principes d'Écoconception

- **Stockage 100% local :** aucune requête réseau, empreinte carbone réseau nulle (SQLite embarqué).
- **Composants épurés :** optimisation des reconstructions de widgets (`setState` ciblé) pour réduire l'utilisation CPU et batterie.
- **Base de données légère :** requêtes SQL paramétrées et indexées, données créées avec horodatage minimal (`created_at`).
- **Transactions réduites :** écritures uniquement lors des actions utilisateur explicites.

---

## Contribution & Conventions

- Messages de commit au format *Conventional Commits* : `feat:`, `fix:`, `docs:`, `test:`, `chore:`.
- Pipeline CI (GitHub Actions) exécute `dart format --set-exit-if-changed`, `flutter analyze` et `flutter test`.
- Toute modification doit respecter la contrainte **« aucun commentaire dans les fichiers Dart »** et maintenir les 46 tests au vert.