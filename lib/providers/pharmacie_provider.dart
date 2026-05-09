/// Provider pour la gestion des pharmacies
///
/// Gère :
/// - La liste de toutes les pharmacies
/// - La pharmacie actuellement sélectionnée
/// - Le CRUD des pharmacies
library;

import 'package:flutter/foundation.dart';
import '../models/pharmacie.dart';
import '../services/database_service.dart';

class PharmacieProvider extends ChangeNotifier {
  // ============================================================
  // 📦 ÉTAT
  // ============================================================

  final DatabaseService _db = DatabaseService();

  /// Liste de toutes les pharmacies
  List<Pharmacie> _pharmacies = [];

  /// Pharmacie actuellement sélectionnée
  Pharmacie? _pharmacieSelectionnee;

  /// Indicateur de chargement
  bool _isLoading = false;

  // ============================================================
  // 🔍 GETTERS
  // ============================================================

  List<Pharmacie> get pharmacies => List.unmodifiable(_pharmacies);
  Pharmacie? get pharmacieSelectionnee => _pharmacieSelectionnee;
  bool get isLoading => _isLoading;
  bool get hasPharmacies => _pharmacies.isNotEmpty;

  // ============================================================
  // 🎬 ACTIONS
  // ============================================================

  /// Charge toutes les pharmacies depuis la BDD
  Future<void> chargerPharmacies() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pharmacies = await _db.getAllPharmacies();
    } catch (e) {
      debugPrint('Erreur chargement pharmacies: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sélectionne une pharmacie (change le contexte actif)
  void selectionnerPharmacie(Pharmacie pharmacie) {
    _pharmacieSelectionnee = pharmacie;
    notifyListeners();
  }

  /// Désélectionne la pharmacie courante (retour à la liste)
  void deselectionnnerPharmacie() {
    _pharmacieSelectionnee = null;
    notifyListeners();
  }

  /// Crée une nouvelle pharmacie
  Future<Pharmacie?> creerPharmacie({
    required String nom,
    String? adresse,
    String? telephone,
  }) async {
    final pharmacie = Pharmacie(
      nom: nom,
      adresse: adresse?.isEmpty == true ? null : adresse,
      telephone: telephone?.isEmpty == true ? null : telephone,
    );

    try {
      final id = await _db.insertPharmacie(pharmacie);
      final nouvelle = pharmacie.copyWith(id: id);
      await chargerPharmacies();
      return nouvelle;
    } catch (e) {
      debugPrint('Erreur création pharmacie: $e');
      return null;
    }
  }

  /// Met à jour une pharmacie existante
  Future<bool> mettreAJourPharmacie(Pharmacie pharmacie) async {
    try {
      await _db.updatePharmacie(pharmacie);
      // Mettre à jour dans la liste locale
      final index = _pharmacies.indexWhere((p) => p.id == pharmacie.id);
      if (index != -1) {
        _pharmacies[index] = pharmacie;
      }
      // Mettre à jour la sélection courante si c'est celle-ci
      if (_pharmacieSelectionnee?.id == pharmacie.id) {
        _pharmacieSelectionnee = pharmacie;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur mise à jour pharmacie: $e');
      return false;
    }
  }

  /// Supprime une pharmacie (et tous ses contrôles via cascade)
  Future<bool> supprimerPharmacie(int id) async {
    try {
      await _db.deletePharmacie(id);
      if (_pharmacieSelectionnee?.id == id) {
        _pharmacieSelectionnee = null;
      }
      await chargerPharmacies();
      return true;
    } catch (e) {
      debugPrint('Erreur suppression pharmacie: $e');
      return false;
    }
  }

  /// Retourne le nombre de contrôles pour une pharmacie donnée
  Future<int> nbControles(int pharmacieId) async {
    return await _db.countControlesByPharmacie(pharmacieId);
  }
}
