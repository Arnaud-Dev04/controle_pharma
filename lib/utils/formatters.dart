/// Utilitaires de formatage pour l'application Contrôle Pharma
/// Formatage des nombres, devises et pourcentages
library;

import 'package:intl/intl.dart';

// ============================================================
// 💰 FORMATAGE DES DEVISES
// ============================================================

/// Formate un montant en devise (FBu par défaut)
/// Exemple : 1500.0 → "1 500 FBu"
String formatCurrency(double amount) {
  final formatter = NumberFormat('#,##0', 'fr_FR');
  return '${formatter.format(amount)} FBu';
}

/// Formate un montant court (sans devise)
/// Exemple : 1500.0 → "1 500"
String formatNumber(double amount) {
  final formatter = NumberFormat('#,##0', 'fr_FR');
  return formatter.format(amount);
}

/// Formate un entier
/// Exemple : 1500 → "1 500"
String formatInt(int value) {
  final formatter = NumberFormat('#,##0', 'fr_FR');
  return formatter.format(value);
}

// ============================================================
// 📅 FORMATAGE DES DATES
// ============================================================

/// Formate une date complète
/// Exemple : "24 avril 2026 à 06:30"
String formatDateTime(DateTime date) {
  final formatter = DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR');
  return formatter.format(date);
}

/// Formate une date courte
/// Exemple : "24/04/2026"
String formatDateShort(DateTime date) {
  final formatter = DateFormat('dd/MM/yyyy', 'fr_FR');
  return formatter.format(date);
}

// ============================================================
// 📊 FORMATAGE DES ÉCARTS
// ============================================================

/// Formate un écart avec signe + ou -
/// Exemple : 5 → "+5", -3 → "-3"
String formatEcart(int ecart) {
  if (ecart > 0) return '+$ecart';
  return '$ecart';
}

/// Formate un pourcentage
/// Exemple : 0.156 → "15,6%"
String formatPercentage(double value) {
  final formatter = NumberFormat('0.0', 'fr_FR');
  return '${formatter.format(value * 100)}%';
}
