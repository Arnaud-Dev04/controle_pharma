/// Modèle de données pour une Pharmacie
///
/// Une pharmacie regroupe des contrôles qui lui sont dédiés.
/// Plusieurs pharmacies peuvent coexister, chacune avec son propre
/// historique de contrôles indépendant.
library;

class Pharmacie {
  // ============================================================
  // 🔑 IDENTIFIANT
  // ============================================================

  /// Identifiant unique (auto-généré par SQLite)
  final int? id;

  // ============================================================
  // 📋 CHAMPS
  // ============================================================

  /// Nom de la pharmacie (obligatoire)
  String nom;

  /// Adresse optionnelle
  String? adresse;

  /// Téléphone optionnel
  String? telephone;

  /// Date de création de l'enregistrement
  final DateTime dateCreation;

  // ============================================================
  // 🏗️ CONSTRUCTEUR
  // ============================================================

  Pharmacie({
    this.id,
    required this.nom,
    this.adresse,
    this.telephone,
    DateTime? dateCreation,
  }) : dateCreation = dateCreation ?? DateTime.now();

  // ============================================================
  // 🔄 SÉRIALISATION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'telephone': telephone,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  factory Pharmacie.fromMap(Map<String, dynamic> map) {
    return Pharmacie(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      adresse: map['adresse'] as String?,
      telephone: map['telephone'] as String?,
      dateCreation: DateTime.parse(map['date_creation'] as String),
    );
  }

  Pharmacie copyWith({
    int? id,
    String? nom,
    String? adresse,
    String? telephone,
    DateTime? dateCreation,
  }) {
    return Pharmacie(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  String toString() => 'Pharmacie(id: $id, nom: $nom)';
}
