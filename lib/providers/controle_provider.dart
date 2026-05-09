/// Provider principal pour la gestion d'état des contrôles
///
/// Gère :
/// - La liste des médicaments du contrôle en cours
/// - L'ajout, la modification et la suppression de médicaments
/// - Les mises à jour des ventes et du stock réel
/// - Les calculs automatiques en temps réel
/// - La persistance SQLite filtrée par pharmacie
/// - L'import de médicaments depuis un contrôle précédent
library;

import 'package:flutter/foundation.dart';
import '../models/medicament.dart';
import '../models/controle.dart';
import '../services/database_service.dart';

class ControleProvider extends ChangeNotifier {
  // ============================================================
  // 📦 ÉTAT
  // ============================================================

  /// Service de base de données
  final DatabaseService _db = DatabaseService();

  /// Contrôle actuellement en cours d'édition
  Controle? _controleActuel;

  /// Liste de tous les contrôles (historique de la pharmacie courante)
  List<Controle> _controles = [];

  /// ID de la pharmacie courante
  int? _pharmacieId;

  /// Indicateur de chargement
  bool _isLoading = false;

  // ============================================================
  // 🔍 GETTERS
  // ============================================================

  /// Contrôle en cours
  Controle? get controleActuel => _controleActuel;

  /// Liste des médicaments du contrôle en cours
  List<Medicament> get medicaments =>
      _controleActuel?.medicaments ?? [];

  /// Historique des contrôles
  List<Controle> get controles => List.unmodifiable(_controles);

  /// Indique si un contrôle est en cours
  bool get hasControleActuel => _controleActuel != null;

  /// Indicateur de chargement
  bool get isLoading => _isLoading;

  /// ID de la pharmacie courante
  int? get pharmacieId => _pharmacieId;

  // ============================================================
  // 📊 TOTAUX GLOBAUX
  // ============================================================

  /// Total du chiffre d'affaires
  double get totalPVTotal =>
      _controleActuel?.totalPVTotal ?? 0;

  /// Total des bénéfices
  double get totalBenefice =>
      _controleActuel?.totalBenefice ?? 0;

  /// Nombre d'écarts détectés
  int get nombreEcarts =>
      _controleActuel?.nombreEcarts ?? 0;

  /// Valeur totale des écarts
  double get totalValeurEcarts =>
      _controleActuel?.totalValeurEcarts ?? 0;

  /// Total des quantités vendues
  int get totalQuantiteVendue =>
      medicaments.fold(0, (sum, m) => sum + m.quantiteVendue);

  // ============================================================
  // 🎬 ACTIONS - PHARMACIE
  // ============================================================

  /// Initialise le provider pour une pharmacie donnée.
  /// Auto-crée ou charge le contrôle actif (en_cours) pour cette pharmacie.
  Future<void> initialiserPourPharmacie(int pharmacieId) async {
    if (_pharmacieId != pharmacieId) {
      _controleActuel = null;
      _controles = [];
      _pharmacieId = pharmacieId;
    }
    await chargerHistorique();

    // Auto-charger ou créer le contrôle actif
    final enCours = _controles.where((c) => c.statut == 'en_cours').toList();
    if (enCours.isNotEmpty) {
      _controleActuel = enCours.first;
    } else {
      // Créer automatiquement un contrôle persistant
      await creerNouveauControle('Inventaire');
    }
    notifyListeners();
  }

  /// Réinitialise complètement le provider (lors du changement de pharmacie)
  void reinitialiser() {
    _controleActuel = null;
    _controles = [];
    _pharmacieId = null;
    notifyListeners();
  }

  // ============================================================
  // 🎬 ACTIONS - CONTRÔLE
  // ============================================================

  /// Charge l'historique des contrôles de la pharmacie courante
  Future<void> chargerHistorique() async {
    if (_pharmacieId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _controles = await _db.getAllControlesByPharmacie(_pharmacieId!);
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Crée un nouveau contrôle et le sauvegarde en BDD
  Future<void> creerNouveauControle(String titre) async {
    if (_pharmacieId == null) return;

    final controle = Controle(
      titre: titre,
      pharmacieId: _pharmacieId,
      dateCreation: DateTime.now(),
    );

    try {
      final id = await _db.insertControle(controle);
      _controleActuel = controle.copyWith(id: id);
      await chargerHistorique();
    } catch (e) {
      debugPrint('Erreur création contrôle: $e');
      _controleActuel = controle;
    }

    notifyListeners();
  }

  /// Charge un contrôle existant (depuis l'historique)
  void chargerControle(Controle controle) {
    _controleActuel = controle;
    notifyListeners();
  }

  /// Décharge le contrôle actuel sans le terminer
  void dechargerControle() {
    _controleActuel = null;
    notifyListeners();
  }

  /// Termine le contrôle en cours et sauvegarde
  Future<void> terminerControle() async {
    if (_controleActuel == null) return;

    _controleActuel!.statut = 'termine';
    _controleActuel!.dateModification = DateTime.now();

    await _sauvegarderControleActuel();
    await chargerHistorique();

    notifyListeners();
  }

  /// Sauvegarde automatique du contrôle en cours
  Future<void> _sauvegarderControleActuel() async {
    if (_controleActuel == null) return;

    try {
      if (_controleActuel!.id != null) {
        await _db.updateControle(_controleActuel!);
        await _db.saveMedicaments(
          _controleActuel!.id!,
          _controleActuel!.medicaments,
        );
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde: $e');
    }
  }

  // ============================================================
  // 🎬 ACTIONS - MÉDICAMENTS
  // ============================================================

  /// Ajoute un médicament au contrôle en cours
  /// - Même nom + mêmes prix (tous niveaux) + même date → fusionne les quantités
  /// - Même nom + prix différents OU date différente → nouveau lot (ligne séparée)
  /// - Nouveau nom → nouvelle ligne
  Future<void> ajouterMedicament(Medicament medicament) async {
    if (_controleActuel == null) return;

    // Chercher un doublon par nom ET mêmes prix (TOUS les niveaux) ET même date
    final nomLower = medicament.nom.toLowerCase().trim();
    final existingIndex = _controleActuel!.medicaments.indexWhere(
      (m) {
        if (m.nom.toLowerCase().trim() != nomLower) return false;

        // Comparer les dates
        final sameDate = m.dateEntreeStock == medicament.dateEntreeStock ||
            (m.dateEntreeStock != null &&
                medicament.dateEntreeStock != null &&
                m.dateEntreeStock!.year == medicament.dateEntreeStock!.year &&
                m.dateEntreeStock!.month == medicament.dateEntreeStock!.month &&
                m.dateEntreeStock!.day == medicament.dateEntreeStock!.day);
        if (!sameDate) return false;

        // Comparer TOUS les prix
        final samePA = m.prixUnitaire == medicament.prixUnitaire &&
            m.prixAchatPlaquette == medicament.prixAchatPlaquette &&
            m.prixAchatBoite == medicament.prixAchatBoite &&
            m.prixAchatCarton == medicament.prixAchatCarton;
        final samePV = m.prixVente == medicament.prixVente &&
            m.prixVentePlaquette == medicament.prixVentePlaquette &&
            m.prixVenteBoite == medicament.prixVenteBoite &&
            m.prixVenteCarton == medicament.prixVenteCarton;

        return samePA && samePV;
      },
    );

    if (existingIndex >= 0) {
      // Même nom + mêmes prix + même date → fusionner les quantités
      final existing = _controleActuel!.medicaments[existingIndex];
      _controleActuel!.medicaments[existingIndex] = existing.copyWith(
        quantiteInitiale: existing.quantiteInitiale + medicament.quantiteInitiale,
        stockReel: existing.stockReel != null
            ? existing.stockReel! + medicament.quantiteInitiale
            : null,
      );
    } else {
      // Nouveau médicament ou prix/date différents → nouvelle ligne
      _controleActuel!.medicaments.add(medicament);
    }

    _controleActuel!.dateModification = DateTime.now();
    await _sauvegarderControleActuel();
    notifyListeners();
  }

  /// Met à jour un médicament à l'index donné
  Future<void> mettreAJourMedicament(int index, Medicament medicament) async {
    if (_controleActuel == null) return;
    if (index < 0 || index >= _controleActuel!.medicaments.length) return;
    _controleActuel!.medicaments[index] = medicament;
    _controleActuel!.dateModification = DateTime.now();

    await _sauvegarderControleActuel();
    notifyListeners();
  }

  /// Supprime un médicament à l'index donné
  Future<void> supprimerMedicament(int index) async {
    if (_controleActuel == null) return;
    if (index < 0 || index >= _controleActuel!.medicaments.length) return;
    _controleActuel!.medicaments.removeAt(index);
    _controleActuel!.dateModification = DateTime.now();

    await _sauvegarderControleActuel();
    notifyListeners();
  }

  /// Met à jour la quantité vendue d'un médicament
  Future<void> mettreAJourQuantiteVendue(int index, int quantiteVendue) async {
    if (_controleActuel == null) return;
    if (index < 0 || index >= _controleActuel!.medicaments.length) return;

    final med = _controleActuel!.medicaments[index];
    _controleActuel!.medicaments[index] = med.copyWith(
      quantiteVendue: quantiteVendue,
    );
    _controleActuel!.dateModification = DateTime.now();

    await _sauvegarderControleActuel();
    notifyListeners();
  }

  /// Met à jour le stock réel d'un médicament
  /// Synchronise aussi quantiteVendue = quantiteInitiale - stockReel
  Future<void> mettreAJourStockReel(int index, int stockReel) async {
    if (_controleActuel == null) return;
    if (index < 0 || index >= _controleActuel!.medicaments.length) return;

    final med = _controleActuel!.medicaments[index];
    final qteVendue = med.quantiteInitiale - stockReel;
    _controleActuel!.medicaments[index] = med.copyWith(
      stockReel: stockReel,
      quantiteVendue: qteVendue > 0 ? qteVendue : 0,
    );
    _controleActuel!.dateModification = DateTime.now();

    await _sauvegarderControleActuel();
    notifyListeners();
  }

  /// Réapprovisionne un médicament existant (ajoute des unités au stock)
  /// Optionnellement met à jour les prix si [nouveauPA] ou [nouveauPV] sont fournis
  Future<void> reapprovisionner(
    int index, {
    required int quantiteAjoutee,
    double? nouveauPA,
    double? nouveauPV,
  }) async {
    if (_controleActuel == null) return;
    if (index < 0 || index >= _controleActuel!.medicaments.length) return;

    final med = _controleActuel!.medicaments[index];
    _controleActuel!.medicaments[index] = med.copyWith(
      quantiteInitiale: med.quantiteInitiale + quantiteAjoutee,
      prixUnitaire: nouveauPA ?? med.prixUnitaire,
      prixVente: nouveauPV ?? med.prixVente,
      // Recalculer stockReel si déjà saisi
      stockReel: med.stockReel != null
          ? med.stockReel! + quantiteAjoutee
          : null,
    );
    _controleActuel!.dateModification = DateTime.now();

    await _sauvegarderControleActuel();
    notifyListeners();
  }

  /// Valide le contrôle en cours :
  /// 1. Synchronise quantiteVendue pour chaque médicament ayant un stockReel
  /// 2. Marque le contrôle comme 'termine'
  /// 3. Sauvegarde la date de validation
  Future<bool> validerControle() async {
    if (_controleActuel == null) return false;

    // Vérifier qu'au moins un médicament a un stock réel saisi
    final nbSaisis = _controleActuel!.medicaments
        .where((m) => m.stockReel != null)
        .length;
    if (nbSaisis == 0) return false;

    // Synchroniser quantiteVendue pour chaque médicament
    for (int i = 0; i < _controleActuel!.medicaments.length; i++) {
      final med = _controleActuel!.medicaments[i];
      if (med.stockReel != null) {
        final qteVendue = med.quantiteInitiale - med.stockReel!;
        _controleActuel!.medicaments[i] = med.copyWith(
          quantiteVendue: qteVendue > 0 ? qteVendue : 0,
        );
      }
    }

    // Marquer comme terminé
    _controleActuel!.statut = 'termine';
    _controleActuel!.dateModification = DateTime.now();

    await _sauvegarderControleActuel();
    await chargerHistorique();
    notifyListeners();
    return true;
  }

  /// Vérifie si le contrôle est validé
  bool get isControleValide => _controleActuel?.statut == 'termine';

  /// Date de dernière validation
  DateTime? get dateValidation =>
      isControleValide ? _controleActuel?.dateModification : null;

  /// Crée un nouveau contrôle basé sur les résultats du contrôle validé.
  /// Le stockReel de chaque médicament devient la nouvelle quantitéInitiale.
  /// Si stockReel n'est pas saisi, on utilise quantiteRestante.
  Future<bool> creerNouveauControleDepuisPrecedent() async {
    if (_controleActuel == null || _pharmacieId == null) return false;
    if (_controleActuel!.statut != 'termine') return false;

    // Sauvegarder les médicaments de l'ancien contrôle
    final anciensMeds = List<Medicament>.from(_controleActuel!.medicaments);

    // Créer un nouveau contrôle
    final controle = Controle(
      titre: 'Inventaire',
      pharmacieId: _pharmacieId,
      dateCreation: DateTime.now(),
    );

    try {
      final id = await _db.insertControle(controle);
      _controleActuel = controle.copyWith(id: id);

      // Copier les médicaments avec stockReel comme nouvelle quantitéInitiale
      for (final ancien in anciensMeds) {
        final newQI = ancien.stockReel ?? ancien.quantiteRestante;
        if (newQI > 0) {
          final nouveau = Medicament(
            controleId: id,
            nom: ancien.nom,
            forme: ancien.forme,
            quantiteInitiale: newQI,
            quantiteVendue: 0,
            prixUnitaire: ancien.prixUnitaire,
            prixVente: ancien.prixVente,
            stockReel: null,
            dateEntreeStock: ancien.dateEntreeStock,
            nbCartons: ancien.nbCartons,
            boitesParCarton: ancien.boitesParCarton,
            plaquettesParBoite: ancien.plaquettesParBoite,
            unitesParPlaquette: ancien.unitesParPlaquette,
            prixAchatCarton: ancien.prixAchatCarton,
            prixAchatBoite: ancien.prixAchatBoite,
            prixAchatPlaquette: ancien.prixAchatPlaquette,
            prixVenteCarton: ancien.prixVenteCarton,
            prixVenteBoite: ancien.prixVenteBoite,
            prixVentePlaquette: ancien.prixVentePlaquette,
          );
          _controleActuel!.medicaments.add(nouveau);
        }
      }

      await _sauvegarderControleActuel();
      await chargerHistorique();
    } catch (e) {
      debugPrint('Erreur création nouveau contrôle: $e');
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Supprime un contrôle de l'historique
  Future<void> supprimerControle(int id) async {
    try {
      await _db.deleteControle(id);
      if (_controleActuel?.id == id) {
        _controleActuel = null;
      }
      await chargerHistorique();
    } catch (e) {
      debugPrint('Erreur suppression contrôle: $e');
    }
    notifyListeners();
  }

  // ============================================================
  // 📦 IMPORT — MÉDICAMENTS DEPUIS CONTRÔLE PRÉCÉDENT
  // ============================================================

  /// Vérifie si des médicaments sont disponibles pour l'import
  Future<bool> hasImportDisponible() async {
    if (_pharmacieId == null) return false;
    final meds = await _db.getMedicamentsDernierControle(_pharmacieId!);
    return meds.isNotEmpty;
  }

  /// Importe les médicaments du dernier contrôle terminé
  /// dans le contrôle actuel (avec réinitialisation des quantités vendues)
  Future<int> importerMedicamentsPrecedents() async {
    if (_controleActuel == null || _pharmacieId == null) return 0;

    try {
      final medsImportes =
          await _db.getMedicamentsDernierControle(_pharmacieId!);

      if (medsImportes.isEmpty) return 0;

      // Noms existants (pour éviter les doublons)
      final nomsExistants = _controleActuel!.medicaments
          .map((m) => m.nom.toLowerCase().trim())
          .toSet();

      int compteur = 0;
      for (final med in medsImportes) {
        // Éviter les doublons par nom
        if (nomsExistants.contains(med.nom.toLowerCase().trim())) continue;

        // Créer une copie avec quantités réinitialisées
        final medImporte = med.copyWith(
          id: null,
          controleId: _controleActuel!.id,
          quantiteVendue: 0,
          stockReel: null,
        );

        _controleActuel!.medicaments.add(medImporte);
        nomsExistants.add(med.nom.toLowerCase().trim());
        compteur++;
      }

      if (compteur > 0) {
        _controleActuel!.dateModification = DateTime.now();
        await _sauvegarderControleActuel();
        notifyListeners();
      }

      return compteur;
    } catch (e) {
      debugPrint('Erreur import médicaments: $e');
      return 0;
    }
  }

  // ============================================================
  // 🔍 RECHERCHE & FILTRAGE
  // ============================================================

  /// Retourne les médicaments avec un écart détecté
  List<Medicament> get medicamentsAvecEcart =>
      medicaments.where((m) => m.ecart != null && m.ecart != 0).toList();

  /// Retourne les médicaments sans stock réel saisi
  List<Medicament> get medicamentsNonControles =>
      medicaments.where((m) => m.stockReel == null).toList();

  /// Recherche un médicament par nom
  List<Medicament> rechercherMedicament(String query) {
    final lowerQuery = query.toLowerCase();
    return medicaments
        .where((m) => m.nom.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // ============================================================
  // 🔍 AUTO-COMPLÉTION — MÉDICAMENTS HISTORIQUE
  // ============================================================

  /// Récupère tous les médicaments uniques de tous les contrôles
  /// de la pharmacie courante, pour l'auto-complétion du formulaire
  Future<List<Medicament>> getMedicamentsHistorique() async {
    if (_pharmacieId == null) return [];
    try {
      return await _db.getAllMedicamentsForPharmacie(_pharmacieId!);
    } catch (e) {
      debugPrint('Erreur récup historique médicaments: $e');
      return [];
    }
  }
}
