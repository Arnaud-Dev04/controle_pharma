/// Modèle de données pour une session de contrôle
///
/// Un contrôle représente une session d'audit complète contenant :
/// - Une date de création
/// - Un titre/description
/// - Une liste de médicaments contrôlés
/// - Les totaux calculés automatiquement
library;

import 'medicament.dart';

class Controle {
  // ============================================================
  // 🔑 IDENTIFIANT
  // ============================================================

  /// Identifiant unique du contrôle (auto-généré par SQLite)
  final int? id;

  /// Identifiant de la pharmacie propriétaire de ce contrôle
  final int? pharmacieId;

  // ============================================================
  // 📋 CHAMPS DE BASE
  // ============================================================

  /// Titre du contrôle
  /// Exemple : "Contrôle mensuel - Avril 2026"
  String titre;

  /// Date de création du contrôle
  final DateTime dateCreation;

  /// Date de dernière modification
  DateTime dateModification;

  /// Liste des médicaments inclus dans ce contrôle
  List<Medicament> medicaments;

  /// Statut du contrôle : 'en_cours' ou 'termine'
  String statut;

  // ============================================================
  // 📊 GETTERS CALCULÉS (totaux globaux)
  // ============================================================

  /// Total du chiffre d'affaires (somme de tous les PV totaux)
  double get totalPVTotal =>
      medicaments.fold(0.0, (sum, m) => sum + m.pvTotal);

  /// Total des bénéfices
  double get totalBenefice =>
      medicaments.fold(0.0, (sum, m) => sum + m.benefice);

  /// Nombre total de médicaments avec écart
  int get nombreEcarts =>
      medicaments.where((m) => m.ecart != null && m.ecart != 0).length;

  /// Nombre de médicaments contrôlés (ayant un stock réel saisi)
  int get nombreControles =>
      medicaments.where((m) => m.stockReel != null).length;

  /// Valeur totale des écarts (pertes)
  double get totalValeurEcarts =>
      medicaments.fold(0.0, (sum, m) => sum + (m.valeurEcart ?? 0));

  /// Nombre total de médicaments
  int get nombreMedicaments => medicaments.length;

  /// Pourcentage de contrôle effectué
  double get progressionControle =>
      nombreMedicaments > 0 ? nombreControles / nombreMedicaments : 0;

  // ============================================================
  // 🏗️ CONSTRUCTEUR
  // ============================================================

  Controle({
    this.id,
    this.pharmacieId,
    required this.titre,
    DateTime? dateCreation,
    DateTime? dateModification,
    List<Medicament>? medicaments,
    this.statut = 'en_cours',
  })  : dateCreation = dateCreation ?? DateTime.now(),
        dateModification = dateModification ?? DateTime.now(),
        medicaments = medicaments ?? [];

  // ============================================================
  // 🔄 SÉRIALISATION (pour SQLite)
  // ============================================================

  /// Convertit le contrôle en Map pour l'insertion en BDD
  /// Note : les médicaments sont gérés séparément (table liée)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pharmacie_id': pharmacieId,
      'titre': titre,
      'date_creation': dateCreation.toIso8601String(),
      'date_modification': dateModification.toIso8601String(),
      'statut': statut,
    };
  }

  /// Crée un Controle à partir d'un Map (lecture BDD)
  factory Controle.fromMap(Map<String, dynamic> map,
      {List<Medicament>? medicaments}) {
    return Controle(
      id: map['id'] as int?,
      pharmacieId: map['pharmacie_id'] as int?,
      titre: map['titre'] as String,
      dateCreation: DateTime.parse(map['date_creation'] as String),
      dateModification: DateTime.parse(map['date_modification'] as String),
      statut: map['statut'] as String? ?? 'en_cours',
      medicaments: medicaments,
    );
  }

  /// Crée une copie avec modifications
  Controle copyWith({
    int? id,
    int? pharmacieId,
    String? titre,
    DateTime? dateCreation,
    DateTime? dateModification,
    List<Medicament>? medicaments,
    String? statut,
  }) {
    return Controle(
      id: id ?? this.id,
      pharmacieId: pharmacieId ?? this.pharmacieId,
      titre: titre ?? this.titre,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      medicaments: medicaments ?? this.medicaments,
      statut: statut ?? this.statut,
    );
  }

  @override
  String toString() {
    return 'Controle(titre: $titre, medicaments: ${medicaments.length}, '
        'benefice: $totalBenefice, ecarts: $nombreEcarts)';
  }
}
