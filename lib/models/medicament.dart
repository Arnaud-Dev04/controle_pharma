/// Modèle de données pour un médicament dans le système de contrôle
///
/// Chaque médicament contient :
/// - Les informations de base (nom, forme, quantités, prix)
/// - Le conditionnement hiérarchique (cartons → boîtes → plaquettes → unités)
/// - Les prix d'achat et de vente par niveau de conditionnement
/// - La date d'entrée en stock
/// - Les champs calculés automatiquement (restant, PV total, bénéfice, écart)
///
/// Ce modèle est conçu pour l'audit/contrôle, PAS pour la vente.
library;

/// Formes galéniques disponibles
enum FormeGalenique {
  comprime('Comprimé', '💊'),
  gelule('Gélule', '💊'),
  sirop('Sirop', '🧴'),
  injectable('Injectable / Ampoule', '💉'),
  pommade('Pommade / Crème', '🧴'),
  suppositoire('Suppositoire', '💊'),
  collyre('Collyre (gouttes)', '💧'),
  sachet('Sachet / Poudre', '📦'),
  suspension('Suspension', '🧴'),
  ovule('Ovule', '💊'),
  autre('Autre', '➕');

  final String label;
  final String emoji;
  const FormeGalenique(this.label, this.emoji);

  /// Label de l'unité élémentaire (comprimé, flacon, tube, ampoule…)
  String get uniteLabel => switch (this) {
    FormeGalenique.comprime     => 'Comprimé',
    FormeGalenique.gelule       => 'Gélule',
    FormeGalenique.sirop        => 'Flacon',
    FormeGalenique.injectable   => 'Ampoule',
    FormeGalenique.pommade      => 'Tube',
    FormeGalenique.suppositoire => 'Suppositoire',
    FormeGalenique.collyre      => 'Flacon',
    FormeGalenique.sachet       => 'Sachet',
    FormeGalenique.suspension   => 'Flacon',
    FormeGalenique.ovule        => 'Ovule',
    FormeGalenique.autre        => 'Unité',
  };

  /// Label du niveau intermédiaire (plaquette pour comprimés, pas applicable pour liquides)
  String get intermediaireLabel => switch (this) {
    FormeGalenique.comprime     => 'Plaquette',
    FormeGalenique.gelule       => 'Plaquette',
    FormeGalenique.suppositoire => 'Plaquette',
    FormeGalenique.ovule        => 'Plaquette',
    _                           => 'Boîte',
  };

  /// Indique si la forme utilise le niveau intermédiaire (plaquette)
  /// Les liquides et semi-solides n'ont pas de plaquette
  bool get hasNiveauIntermediaire => switch (this) {
    FormeGalenique.comprime     => true,
    FormeGalenique.gelule       => true,
    FormeGalenique.suppositoire => true,
    FormeGalenique.ovule        => true,
    _                           => false,
  };

  /// Label pour le champ "unités par plaquette" adapté à la forme
  /// Ex: "Comprimés par plaquette" ou "Flacons par boîte"
  String get unitesParIntermediaireLabel => hasNiveauIntermediaire
    ? '${uniteLabel}s par plaquette'
    : '${uniteLabel}s par boîte';

  /// Trouve une forme par son nom stocké en BDD
  static FormeGalenique fromString(String? value) {
    if (value == null) return FormeGalenique.comprime;
    return FormeGalenique.values.firstWhere(
      (f) => f.name == value,
      orElse: () => FormeGalenique.autre,
    );
  }
}

class Medicament {
  // ============================================================
  // 🔑 IDENTIFIANT
  // ============================================================

  /// Identifiant unique du médicament (auto-généré par SQLite)
  final int? id;

  /// Identifiant du contrôle parent
  final int? controleId;

  // ============================================================
  // 📋 CHAMPS DE BASE (saisis par l'utilisateur)
  // ============================================================

  /// Nom du médicament
  /// Exemple : "Paracétamol 500mg"
  String nom;

  /// Forme galénique du médicament
  FormeGalenique forme;

  /// Quantité initiale en stock au début du contrôle
  /// Peut être calculée automatiquement depuis le conditionnement
  int quantiteInitiale;

  /// Quantité vendue pendant la période de contrôle
  int quantiteVendue;

  /// Prix unitaire d'achat par comprimé/unité (coût d'acquisition)
  double prixUnitaire;

  /// Prix de vente unitaire par comprimé/unité au public
  double prixVente;

  /// Stock réel compté physiquement
  int? stockReel;

  // ============================================================
  // 📅 DATE D'ENTRÉE EN STOCK
  // ============================================================

  /// Date d'entrée du médicament dans le stock
  DateTime? dateEntreeStock;

  // ============================================================
  // 📦 CONDITIONNEMENT HIÉRARCHIQUE
  // ============================================================

  /// Nombre de cartons
  int? nbCartons;

  /// Nombre de boîtes par carton (ou nombre total de boîtes si pas de carton)
  int? boitesParCarton;

  /// Nombre de plaquettes par boîte
  int? plaquettesParBoite;

  /// Nombre d'unités (comprimés, gélules…) par plaquette
  int? unitesParPlaquette;

  // ============================================================
  // 💰 PRIX PAR NIVEAU DE CONDITIONNEMENT
  // ============================================================

  /// Prix d'achat d'un carton entier
  double? prixAchatCarton;

  /// Prix d'achat d'une boîte
  double? prixAchatBoite;

  /// Prix d'achat d'une plaquette
  double? prixAchatPlaquette;

  /// Prix de vente d'un carton entier
  double? prixVenteCarton;

  /// Prix de vente d'une boîte
  double? prixVenteBoite;

  /// Prix de vente d'une plaquette
  double? prixVentePlaquette;

  // ============================================================
  // 📊 GETTERS CALCULÉS (automatiques)
  // ============================================================

  /// Meilleur prix de vente unitaire disponible
  /// Cherche dans l'ordre : unité → plaquette → boîte → carton
  double get bestPrixVente {
    if (prixVente > 0) return prixVente;
    if (prixVentePlaquette != null && prixVentePlaquette! > 0) {
      return prixVentePlaquette! / (unitesParPlaquette ?? 1);
    }
    if (prixVenteBoite != null && prixVenteBoite! > 0) {
      return prixVenteBoite! / ((unitesParPlaquette ?? 1) * (plaquettesParBoite ?? 1));
    }
    if (prixVenteCarton != null && prixVenteCarton! > 0) {
      return prixVenteCarton! / ((unitesParPlaquette ?? 1) * (plaquettesParBoite ?? 1) * (boitesParCarton ?? 1));
    }
    return 0;
  }

  /// Meilleur prix d'achat unitaire disponible
  /// Cherche dans l'ordre : unité → plaquette → boîte → carton
  double get bestPrixAchat {
    if (prixUnitaire > 0) return prixUnitaire;
    if (prixAchatPlaquette != null && prixAchatPlaquette! > 0) {
      return prixAchatPlaquette! / (unitesParPlaquette ?? 1);
    }
    if (prixAchatBoite != null && prixAchatBoite! > 0) {
      return prixAchatBoite! / ((unitesParPlaquette ?? 1) * (plaquettesParBoite ?? 1));
    }
    if (prixAchatCarton != null && prixAchatCarton! > 0) {
      return prixAchatCarton! / ((unitesParPlaquette ?? 1) * (plaquettesParBoite ?? 1) * (boitesParCarton ?? 1));
    }
    return 0;
  }

  /// Quantité restante théorique = quantité initiale - quantité vendue
  int get quantiteRestante => quantiteInitiale - quantiteVendue;

  /// Prix de vente total = meilleur prix de vente unitaire × quantité vendue
  double get pvTotal => bestPrixVente * quantiteVendue;

  /// Bénéfice par comprimé/unité
  double get beneficeParComprime => bestPrixVente - bestPrixAchat;

  /// Bénéfice total = (meilleur PV - meilleur PA) × quantité vendue
  double get benefice => (bestPrixVente - bestPrixAchat) * quantiteVendue;

  /// Bénéfice par carton
  double get beneficeParCarton =>
      (prixVenteCarton ?? 0) - (prixAchatCarton ?? 0);

  /// Bénéfice par boîte
  double get beneficeParBoite =>
      (prixVenteBoite ?? 0) - (prixAchatBoite ?? 0);

  /// Bénéfice par plaquette
  double get beneficeParPlaquette =>
      (prixVentePlaquette ?? 0) - (prixAchatPlaquette ?? 0);

  /// Marge % par comprimé
  double get margeComprimePercent =>
      bestPrixAchat > 0 ? (beneficeParComprime / bestPrixAchat) * 100 : 0;

  /// Marge % par carton
  double get margeCartonPercent =>
      (prixAchatCarton ?? 0) > 0
          ? (beneficeParCarton / prixAchatCarton!) * 100
          : 0;

  /// Marge % par boîte
  double get margeBoitePercent =>
      (prixAchatBoite ?? 0) > 0
          ? (beneficeParBoite / prixAchatBoite!) * 100
          : 0;

  /// Marge % par plaquette
  double get margePlaquettePercent =>
      (prixAchatPlaquette ?? 0) > 0
          ? (beneficeParPlaquette / prixAchatPlaquette!) * 100
          : 0;

  /// Écart = stock réel - quantité restante théorique
  int? get ecart => stockReel != null ? stockReel! - quantiteRestante : null;

  /// Valeur de la perte = écart × meilleur prix d'achat unitaire
  double? get valeurEcart =>
      ecart != null ? ecart! * bestPrixAchat : null;

  /// Calcule la quantité totale depuis le conditionnement
  /// Retourne null si les champs ne sont pas tous remplis
  int? get quantiteDepuisConditionnement {
    if (unitesParPlaquette == null || unitesParPlaquette == 0) return null;

    final plaquettes = plaquettesParBoite ?? 1;
    final boites = boitesParCarton ?? 1;
    final cartons = nbCartons ?? 1;

    return cartons * boites * plaquettes * unitesParPlaquette!;
  }

  /// Résumé texte du conditionnement
  String get resumeConditionnement {
    final parts = <String>[];
    if (nbCartons != null && nbCartons! > 0) {
      parts.add('$nbCartons crt');
    }
    if (boitesParCarton != null && boitesParCarton! > 0) {
      parts.add('$boitesParCarton bte');
    }
    if (forme.hasNiveauIntermediaire) {
      if (plaquettesParBoite != null && plaquettesParBoite! > 0) {
        parts.add('$plaquettesParBoite ${forme.intermediaireLabel.substring(0, 3).toLowerCase()}');
      }
      if (unitesParPlaquette != null && unitesParPlaquette! > 0) {
        parts.add('$unitesParPlaquette ${forme.uniteLabel.substring(0, 3).toLowerCase()}');
      }
    } else {
      // Pour liquides/semi-solides : plaquettesParBoite = unités par boîte
      if (plaquettesParBoite != null && plaquettesParBoite! > 0) {
        parts.add('$plaquettesParBoite ${forme.uniteLabel.substring(0, 3).toLowerCase()}');
      }
    }
    return parts.isEmpty ? 'Quantité directe' : parts.join(' × ');
  }

  /// Indique si le conditionnement détaillé est renseigné
  bool get hasConditionnement =>
      unitesParPlaquette != null && unitesParPlaquette! > 0;

  /// Indique si les prix par niveau sont renseignés
  bool get hasPrixParNiveau =>
      prixAchatCarton != null || prixVenteCarton != null;

  // ============================================================
  // 🏗️ CONSTRUCTEUR
  // ============================================================

  Medicament({
    this.id,
    this.controleId,
    required this.nom,
    this.forme = FormeGalenique.comprime,
    required this.quantiteInitiale,
    this.quantiteVendue = 0,
    required this.prixUnitaire,
    required this.prixVente,
    this.stockReel,
    this.dateEntreeStock,
    this.nbCartons,
    this.boitesParCarton,
    this.plaquettesParBoite,
    this.unitesParPlaquette,
    this.prixAchatCarton,
    this.prixAchatBoite,
    this.prixAchatPlaquette,
    this.prixVenteCarton,
    this.prixVenteBoite,
    this.prixVentePlaquette,
  });

  // ============================================================
  // 🔄 SÉRIALISATION (pour SQLite)
  // ============================================================

  /// Convertit le médicament en Map pour l'insertion en base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'controle_id': controleId,
      'nom': nom,
      'forme': forme.name,
      'quantite_initiale': quantiteInitiale,
      'quantite_vendue': quantiteVendue,
      'prix_unitaire': prixUnitaire,
      'prix_vente': prixVente,
      'stock_reel': stockReel,
      'date_entree_stock': dateEntreeStock?.toIso8601String(),
      'nb_cartons': nbCartons,
      'boites_par_carton': boitesParCarton,
      'plaquettes_par_boite': plaquettesParBoite,
      'unites_par_plaquette': unitesParPlaquette,
      'prix_achat_carton': prixAchatCarton,
      'prix_achat_boite': prixAchatBoite,
      'prix_achat_plaquette': prixAchatPlaquette,
      'prix_vente_carton': prixVenteCarton,
      'prix_vente_boite': prixVenteBoite,
      'prix_vente_plaquette': prixVentePlaquette,
    };
  }

  /// Crée un Medicament à partir d'un Map (lecture depuis la base de données)
  factory Medicament.fromMap(Map<String, dynamic> map) {
    return Medicament(
      id: map['id'] as int?,
      controleId: map['controle_id'] as int?,
      nom: map['nom'] as String,
      forme: FormeGalenique.fromString(map['forme'] as String?),
      quantiteInitiale: map['quantite_initiale'] as int,
      quantiteVendue: map['quantite_vendue'] as int? ?? 0,
      prixUnitaire: (map['prix_unitaire'] as num).toDouble(),
      prixVente: (map['prix_vente'] as num).toDouble(),
      stockReel: map['stock_reel'] as int?,
      dateEntreeStock: map['date_entree_stock'] != null
          ? DateTime.tryParse(map['date_entree_stock'] as String)
          : null,
      nbCartons: map['nb_cartons'] as int?,
      boitesParCarton: map['boites_par_carton'] as int?,
      plaquettesParBoite: map['plaquettes_par_boite'] as int?,
      unitesParPlaquette: map['unites_par_plaquette'] as int?,
      prixAchatCarton: (map['prix_achat_carton'] as num?)?.toDouble(),
      prixAchatBoite: (map['prix_achat_boite'] as num?)?.toDouble(),
      prixAchatPlaquette: (map['prix_achat_plaquette'] as num?)?.toDouble(),
      prixVenteCarton: (map['prix_vente_carton'] as num?)?.toDouble(),
      prixVenteBoite: (map['prix_vente_boite'] as num?)?.toDouble(),
      prixVentePlaquette: (map['prix_vente_plaquette'] as num?)?.toDouble(),
    );
  }

  /// Crée une copie du médicament avec des modifications
  Medicament copyWith({
    int? id,
    int? controleId,
    String? nom,
    FormeGalenique? forme,
    int? quantiteInitiale,
    int? quantiteVendue,
    double? prixUnitaire,
    double? prixVente,
    int? stockReel,
    DateTime? dateEntreeStock,
    int? nbCartons,
    int? boitesParCarton,
    int? plaquettesParBoite,
    int? unitesParPlaquette,
    double? prixAchatCarton,
    double? prixAchatBoite,
    double? prixAchatPlaquette,
    double? prixVenteCarton,
    double? prixVenteBoite,
    double? prixVentePlaquette,
  }) {
    return Medicament(
      id: id ?? this.id,
      controleId: controleId ?? this.controleId,
      nom: nom ?? this.nom,
      forme: forme ?? this.forme,
      quantiteInitiale: quantiteInitiale ?? this.quantiteInitiale,
      quantiteVendue: quantiteVendue ?? this.quantiteVendue,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      prixVente: prixVente ?? this.prixVente,
      stockReel: stockReel ?? this.stockReel,
      dateEntreeStock: dateEntreeStock ?? this.dateEntreeStock,
      nbCartons: nbCartons ?? this.nbCartons,
      boitesParCarton: boitesParCarton ?? this.boitesParCarton,
      plaquettesParBoite: plaquettesParBoite ?? this.plaquettesParBoite,
      unitesParPlaquette: unitesParPlaquette ?? this.unitesParPlaquette,
      prixAchatCarton: prixAchatCarton ?? this.prixAchatCarton,
      prixAchatBoite: prixAchatBoite ?? this.prixAchatBoite,
      prixAchatPlaquette: prixAchatPlaquette ?? this.prixAchatPlaquette,
      prixVenteCarton: prixVenteCarton ?? this.prixVenteCarton,
      prixVenteBoite: prixVenteBoite ?? this.prixVenteBoite,
      prixVentePlaquette: prixVentePlaquette ?? this.prixVentePlaquette,
    );
  }

  @override
  String toString() {
    return 'Medicament(nom: $nom, forme: ${forme.label}, qi: $quantiteInitiale, '
        'qv: $quantiteVendue, pu: $prixUnitaire, pv: $prixVente, '
        'stockReel: $stockReel, restant: $quantiteRestante, '
        'ecart: $ecart, benefice: $benefice)';
  }
}
