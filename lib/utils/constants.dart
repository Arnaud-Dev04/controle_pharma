/// Constantes de l'application Contrôle Pharma
/// Contient les couleurs, les styles et les configurations globales
library;

import 'package:flutter/material.dart';

// ============================================================
// 🎨 COULEURS DE L'APPLICATION
// ============================================================

/// Couleur primaire - Bleu pharma professionnel
const Color kPrimaryColor = Color(0xFF1565C0);

/// Couleur primaire foncée
const Color kPrimaryDarkColor = Color(0xFF0D47A1);

/// Couleur primaire claire
const Color kPrimaryLightColor = Color(0xFF42A5F5);

/// Couleur de bénéfice / stock cohérent
const Color kSuccessColor = Color(0xFF2E7D32);

/// Couleur de perte / écart négatif
const Color kDangerColor = Color(0xFFC62828);

/// Couleur d'avertissement
const Color kWarningColor = Color(0xFFF9A825);

/// Couleur de fond principale
const Color kBackgroundColor = Color(0xFFF5F7FA);

/// Couleur de fond des cartes
const Color kCardColor = Color(0xFFFFFFFF);

/// Couleur du texte principal
const Color kTextPrimary = Color(0xFF212121);

/// Couleur du texte secondaire
const Color kTextSecondary = Color(0xFF757575);

/// Couleur des bordures
const Color kBorderColor = Color(0xFFE0E0E0);

// ============================================================
// 📐 ESPACEMENTS
// ============================================================

const double kPaddingXS = 4.0;
const double kPaddingS = 8.0;
const double kPaddingM = 16.0;
const double kPaddingL = 24.0;
const double kPaddingXL = 32.0;

// ============================================================
// 🔤 TAILLES DE POLICE
// ============================================================

const double kFontSizeXS = 10.0;
const double kFontSizeS = 12.0;
const double kFontSizeM = 14.0;
const double kFontSizeL = 16.0;
const double kFontSizeXL = 20.0;
const double kFontSizeXXL = 24.0;
const double kFontSizeTitle = 28.0;

// ============================================================
// 📊 CONFIGURATION DU TABLEAU
// ============================================================

/// Largeurs des colonnes du tableau de contrôle
const double kColNom = 120.0;
const double kColQuantite = 60.0;
const double kColPrix = 80.0;
const double kColTotal = 100.0;
const double kColEcart = 70.0;

// ============================================================
// 📝 TEXTES DE L'APPLICATION
// ============================================================

const String kAppName = 'Contrôle Pharma';
const String kAppSubtitle = 'Audit & Contrôle Financier';

// Labels des colonnes du tableau de contrôle
const String kLabelNom = 'Nom';
const String kLabelQI = 'Q.I';
const String kLabelPU = 'P.U';
const String kLabelPV = 'P.V';
const String kLabelQVendue = 'Q.Vendue';
const String kLabelPVTotal = 'PV Total';
const String kLabelQRestante = 'Q.Rest';
const String kLabelStockReel = 'Stock Réel';
const String kLabelEcart = 'Écart';
const String kLabelBenefice = 'Bénéfice';

// Labels des colonnes du tableau des prix par niveau
const String kLabelPACarton = 'PA Crt';
const String kLabelPABoite = 'PA Bte';
const String kLabelPAPlaquette = 'PA Plq';
const String kLabelPAUnite = 'PA Unit';
const String kLabelPVCarton = 'PV Crt';
const String kLabelPVBoite = 'PV Bte';
const String kLabelPVPlaquette = 'PV Plq';
const String kLabelPVUnite = 'PV Unit';
const String kLabelBenCarton = 'Bén Crt';
const String kLabelBenBoite = 'Bén Bte';
const String kLabelBenPlaquette = 'Bén Plq';
const String kLabelBenUnite = 'Bén Unit';
