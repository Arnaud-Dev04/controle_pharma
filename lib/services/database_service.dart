/// Service de base de données SQLite pour Contrôle Pharma
///
/// Gère la persistance complète des données :
/// - Création et migration des tables
/// - CRUD pour les pharmacies
/// - CRUD pour les contrôles et médicaments (filtrés par pharmacie)
/// - Historique des sessions de contrôle
/// - Import de médicaments depuis un contrôle précédent
library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/controle.dart';
import '../models/medicament.dart';
import '../models/pharmacie.dart';

class DatabaseService {
  // ============================================================
  // 🔒 SINGLETON
  // ============================================================
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  /// Obtenir l'instance de la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // ============================================================
  // 🏗️ INITIALISATION
  // ============================================================

  /// Initialise la base de données SQLite
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'controle_pharma.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Crée les tables de la base de données (version 4)
  Future<void> _createDB(Database db, int version) async {
    // Table des pharmacies
    await db.execute('''
      CREATE TABLE pharmacies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        adresse TEXT,
        telephone TEXT,
        date_creation TEXT NOT NULL
      )
    ''');

    // Table des contrôles (sessions d'audit) — liés à une pharmacie
    await db.execute('''
      CREATE TABLE controles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pharmacie_id INTEGER,
        titre TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        date_modification TEXT NOT NULL,
        statut TEXT NOT NULL DEFAULT 'en_cours',
        FOREIGN KEY (pharmacie_id) REFERENCES pharmacies (id) ON DELETE CASCADE
      )
    ''');

    // Table des médicaments (liés à un contrôle)
    await db.execute('''
      CREATE TABLE medicaments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        controle_id INTEGER NOT NULL,
        nom TEXT NOT NULL,
        forme TEXT DEFAULT 'comprime',
        quantite_initiale INTEGER NOT NULL,
        quantite_vendue INTEGER NOT NULL DEFAULT 0,
        prix_unitaire REAL NOT NULL,
        prix_vente REAL NOT NULL,
        stock_reel INTEGER,
        date_entree_stock TEXT,
        nb_cartons INTEGER,
        boites_par_carton INTEGER,
        plaquettes_par_boite INTEGER,
        unites_par_plaquette INTEGER,
        prix_achat_carton REAL,
        prix_achat_boite REAL,
        prix_achat_plaquette REAL,
        prix_vente_carton REAL,
        prix_vente_boite REAL,
        prix_vente_plaquette REAL,
        FOREIGN KEY (controle_id) REFERENCES controles (id) ON DELETE CASCADE
      )
    ''');

    // Index pour les recherches rapides
    await db.execute(
        'CREATE INDEX idx_medicaments_controle ON medicaments (controle_id)');
    await db.execute(
        'CREATE INDEX idx_controles_pharmacie ON controles (pharmacie_id)');
  }

  /// Migration de la base de données
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajout des colonnes conditionnement + forme
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN forme TEXT DEFAULT \'comprime\'');
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN nb_cartons INTEGER');
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN boites_par_carton INTEGER');
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN plaquettes_par_boite INTEGER');
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN unites_par_plaquette INTEGER');
    }

    if (oldVersion < 3) {
      // Ajout de la table pharmacies
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pharmacies (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          adresse TEXT,
          telephone TEXT,
          date_creation TEXT NOT NULL
        )
      ''');

      // Créer une pharmacie par défaut pour les anciens contrôles
      final now = DateTime.now().toIso8601String();
      final defaultId = await db.insert('pharmacies', {
        'nom': 'Pharmacie Principale',
        'adresse': null,
        'telephone': null,
        'date_creation': now,
      });

      // Ajout de la colonne pharmacie_id dans controles
      await db.execute(
          'ALTER TABLE controles ADD COLUMN pharmacie_id INTEGER REFERENCES pharmacies(id) ON DELETE CASCADE');

      // Rattacher les anciens contrôles à la pharmacie par défaut
      await db.execute(
          'UPDATE controles SET pharmacie_id = $defaultId WHERE pharmacie_id IS NULL');

      // Créer l'index
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_controles_pharmacie ON controles (pharmacie_id)');
    }

    if (oldVersion < 4) {
      // v4 : Ajout date d'entrée stock + prix par niveau de conditionnement
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN date_entree_stock TEXT');
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN prix_achat_carton REAL');
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN prix_achat_boite REAL');
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN prix_achat_plaquette REAL');
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN prix_vente_carton REAL');
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN prix_vente_boite REAL');
      await db.execute(
          'ALTER TABLE medicaments ADD COLUMN prix_vente_plaquette REAL');
    }
  }

  // ============================================================
  // 🏥 CRUD — PHARMACIES
  // ============================================================

  /// Insère une nouvelle pharmacie et retourne son ID
  Future<int> insertPharmacie(Pharmacie pharmacie) async {
    final db = await database;
    return await db.insert('pharmacies', pharmacie.toMap()..remove('id'));
  }

  /// Met à jour une pharmacie existante
  Future<int> updatePharmacie(Pharmacie pharmacie) async {
    final db = await database;
    return await db.update(
      'pharmacies',
      pharmacie.toMap(),
      where: 'id = ?',
      whereArgs: [pharmacie.id],
    );
  }

  /// Supprime une pharmacie et tous ses contrôles (cascade)
  Future<int> deletePharmacie(int id) async {
    final db = await database;
    return await db.delete('pharmacies', where: 'id = ?', whereArgs: [id]);
  }

  /// Récupère toutes les pharmacies
  Future<List<Pharmacie>> getAllPharmacies() async {
    final db = await database;
    final maps = await db.query('pharmacies', orderBy: 'date_creation ASC');
    return maps.map((m) => Pharmacie.fromMap(m)).toList();
  }

  /// Récupère le nombre de contrôles d'une pharmacie
  Future<int> countControlesByPharmacie(int pharmacieId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM controles WHERE pharmacie_id = ?',
      [pharmacieId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============================================================
  // 📋 CRUD — CONTRÔLES
  // ============================================================

  /// Insère un nouveau contrôle et retourne son ID
  Future<int> insertControle(Controle controle) async {
    final db = await database;
    return await db.insert('controles', controle.toMap()..remove('id'));
  }

  /// Met à jour un contrôle existant
  Future<int> updateControle(Controle controle) async {
    final db = await database;
    return await db.update(
      'controles',
      controle.toMap(),
      where: 'id = ?',
      whereArgs: [controle.id],
    );
  }

  /// Supprime un contrôle et tous ses médicaments
  Future<int> deleteControle(int id) async {
    final db = await database;
    await db.delete('medicaments', where: 'controle_id = ?', whereArgs: [id]);
    return await db.delete('controles', where: 'id = ?', whereArgs: [id]);
  }

  /// Récupère tous les contrôles d'une pharmacie avec leurs médicaments
  Future<List<Controle>> getAllControlesByPharmacie(int pharmacieId) async {
    final db = await database;
    final controlesMaps = await db.query(
      'controles',
      where: 'pharmacie_id = ?',
      whereArgs: [pharmacieId],
      orderBy: 'date_modification DESC',
    );

    List<Controle> controles = [];
    for (final controleMap in controlesMaps) {
      final medicamentsMaps = await db.query(
        'medicaments',
        where: 'controle_id = ?',
        whereArgs: [controleMap['id']],
      );
      final medicaments =
          medicamentsMaps.map((m) => Medicament.fromMap(m)).toList();
      controles.add(Controle.fromMap(controleMap, medicaments: medicaments));
    }
    return controles;
  }

  /// Récupère un seul contrôle par ID avec ses médicaments
  Future<Controle?> getControle(int id) async {
    final db = await database;
    final maps =
        await db.query('controles', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final medicamentsMaps = await db.query(
      'medicaments',
      where: 'controle_id = ?',
      whereArgs: [id],
    );
    final medicaments =
        medicamentsMaps.map((m) => Medicament.fromMap(m)).toList();
    return Controle.fromMap(maps.first, medicaments: medicaments);
  }

  // ============================================================
  // 💊 CRUD — MÉDICAMENTS
  // ============================================================

  /// Insère un médicament et retourne son ID
  Future<int> insertMedicament(Medicament medicament) async {
    final db = await database;
    return await db.insert('medicaments', medicament.toMap()..remove('id'));
  }

  /// Met à jour un médicament existant
  Future<int> updateMedicament(Medicament medicament) async {
    final db = await database;
    return await db.update(
      'medicaments',
      medicament.toMap(),
      where: 'id = ?',
      whereArgs: [medicament.id],
    );
  }

  /// Supprime un médicament par ID
  Future<int> deleteMedicament(int id) async {
    final db = await database;
    return await db.delete('medicaments', where: 'id = ?', whereArgs: [id]);
  }

  /// Supprime tous les médicaments d'un contrôle
  Future<int> deleteMedicamentsByControle(int controleId) async {
    final db = await database;
    return await db.delete(
      'medicaments',
      where: 'controle_id = ?',
      whereArgs: [controleId],
    );
  }

  /// Sauvegarde tous les médicaments d'un contrôle
  /// (supprime les anciens puis insère les nouveaux)
  Future<void> saveMedicaments(
      int controleId, List<Medicament> medicaments) async {
    final db = await database;
    await db.transaction((txn) async {
      // Supprimer les anciens
      await txn.delete(
        'medicaments',
        where: 'controle_id = ?',
        whereArgs: [controleId],
      );
      // Insérer les nouveaux
      for (final med in medicaments) {
        await txn.insert('medicaments', {
          'controle_id': controleId,
          'nom': med.nom,
          'forme': med.forme.name,
          'quantite_initiale': med.quantiteInitiale,
          'quantite_vendue': med.quantiteVendue,
          'prix_unitaire': med.prixUnitaire,
          'prix_vente': med.prixVente,
          'stock_reel': med.stockReel,
          'date_entree_stock': med.dateEntreeStock?.toIso8601String(),
          'nb_cartons': med.nbCartons,
          'boites_par_carton': med.boitesParCarton,
          'plaquettes_par_boite': med.plaquettesParBoite,
          'unites_par_plaquette': med.unitesParPlaquette,
          'prix_achat_carton': med.prixAchatCarton,
          'prix_achat_boite': med.prixAchatBoite,
          'prix_achat_plaquette': med.prixAchatPlaquette,
          'prix_vente_carton': med.prixVenteCarton,
          'prix_vente_boite': med.prixVenteBoite,
          'prix_vente_plaquette': med.prixVentePlaquette,
        });
      }
    });
  }

  // ============================================================
  // 📦 IMPORT — MÉDICAMENTS DEPUIS CONTRÔLE PRÉCÉDENT
  // ============================================================

  /// Récupère les médicaments du dernier contrôle terminé d'une pharmacie
  /// pour permettre l'import dans un nouveau contrôle
  Future<List<Medicament>> getMedicamentsDernierControle(
      int pharmacieId) async {
    final db = await database;

    // Trouver le dernier contrôle terminé de cette pharmacie
    final controles = await db.query(
      'controles',
      where: 'pharmacie_id = ? AND statut = ?',
      whereArgs: [pharmacieId, 'termine'],
      orderBy: 'date_modification DESC',
      limit: 1,
    );

    if (controles.isEmpty) return [];

    final controleId = controles.first['id'] as int;

    // Récupérer ses médicaments
    final medicamentsMaps = await db.query(
      'medicaments',
      where: 'controle_id = ?',
      whereArgs: [controleId],
    );

    return medicamentsMaps.map((m) => Medicament.fromMap(m)).toList();
  }

  // ============================================================
  // 🔍 AUTO-COMPLÉTION — TOUS LES MÉDICAMENTS D'UNE PHARMACIE
  // ============================================================

  /// Récupère tous les médicaments uniques de tous les contrôles
  /// d'une pharmacie, dédupliqués par nom (le plus récent gagne)
  Future<List<Medicament>> getAllMedicamentsForPharmacie(
      int pharmacieId) async {
    final db = await database;

    // Récupérer tous les contrôles de la pharmacie
    final controles = await db.query(
      'controles',
      where: 'pharmacie_id = ?',
      whereArgs: [pharmacieId],
      orderBy: 'date_modification DESC',
    );

    if (controles.isEmpty) return [];

    final controleIds = controles.map((c) => c['id'] as int).toList();
    final placeholders = controleIds.map((_) => '?').join(',');

    // Récupérer tous les médicaments de ces contrôles
    final medMaps = await db.query(
      'medicaments',
      where: 'controle_id IN ($placeholders)',
      whereArgs: controleIds,
    );

    // Dédupliquer par nom (garder le plus récent = premier trouvé car ORDER BY DESC)
    final seen = <String>{};
    final result = <Medicament>[];
    for (final map in medMaps) {
      final nom = (map['nom'] as String).toLowerCase().trim();
      if (!seen.contains(nom)) {
        seen.add(nom);
        result.add(Medicament.fromMap(map));
      }
    }

    return result;
  }

  // ============================================================
  // 🔧 UTILITAIRES
  // ============================================================

  /// Ferme la base de données
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
