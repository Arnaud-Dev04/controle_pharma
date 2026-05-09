/// Contrôle simplifié des ventes
///
/// L'utilisateur choisit le niveau (Comprimé/Plaquette/Boîte/Carton)
/// puis saisit la quantité restante à ce niveau.
/// Le système adapte le stock initial et calcule les ventes/bénéfices.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/medicament.dart';
import '../providers/controle_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

enum NiveauControle { comprime, plaquette, boite, carton }

extension NiveauControleExt on NiveauControle {
  String get label => switch (this) {
    NiveauControle.comprime  => 'Comprimé',
    NiveauControle.plaquette => 'Plaquette',
    NiveauControle.boite     => 'Boîte',
    NiveauControle.carton    => 'Carton',
  };

  IconData get icon => switch (this) {
    NiveauControle.comprime  => Icons.medication_rounded,
    NiveauControle.plaquette => Icons.view_column_rounded,
    NiveauControle.boite     => Icons.inventory_2_rounded,
    NiveauControle.carton    => Icons.widgets_rounded,
  };
}

class ControleSimplifieScreen extends StatefulWidget {
  const ControleSimplifieScreen({super.key});

  @override
  State<ControleSimplifieScreen> createState() => _ControleSimplifieScreenState();
}

class _ControleSimplifieScreenState extends State<ControleSimplifieScreen> {
  final Map<int, TextEditingController> _controllers = {};
  NiveauControle _niveau = NiveauControle.comprime;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getCtrl(int index) {
    _controllers[index] ??= TextEditingController();
    return _controllers[index]!;
  }

  /// Nombre d'unités par niveau pour un médicament donné
  int _unitesParNiveau(Medicament med) {
    final uPlq = med.unitesParPlaquette ?? 1;
    final plqBte = med.plaquettesParBoite ?? 1;
    final bteCrt = med.boitesParCarton ?? 1;
    return switch (_niveau) {
      NiveauControle.comprime  => 1,
      NiveauControle.plaquette => uPlq,
      NiveauControle.boite     => uPlq * plqBte,
      NiveauControle.carton    => uPlq * plqBte * bteCrt,
    };
  }

  /// Stock initial converti au niveau choisi
  int _stockInitialNiveau(Medicament med) {
    final diviseur = _unitesParNiveau(med);
    return diviseur > 0 ? med.quantiteInitiale ~/ diviseur : med.quantiteInitiale;
  }

  /// Prix de vente unitaire au niveau choisi
  double _prixVenteNiveau(Medicament med) {
    return switch (_niveau) {
      NiveauControle.comprime  => _bestPV(med),
      NiveauControle.plaquette => med.prixVentePlaquette ?? _bestPV(med) * (med.unitesParPlaquette ?? 1),
      NiveauControle.boite     => med.prixVenteBoite ?? _bestPV(med) * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1),
      NiveauControle.carton    => med.prixVenteCarton ?? _bestPV(med) * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1),
    };
  }

  /// Prix d'achat unitaire au niveau choisi
  double _prixAchatNiveau(Medicament med) {
    return switch (_niveau) {
      NiveauControle.comprime  => _bestPA(med),
      NiveauControle.plaquette => med.prixAchatPlaquette ?? _bestPA(med) * (med.unitesParPlaquette ?? 1),
      NiveauControle.boite     => med.prixAchatBoite ?? _bestPA(med) * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1),
      NiveauControle.carton    => med.prixAchatCarton ?? _bestPA(med) * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1),
    };
  }

  double _bestPV(Medicament med) {
    if (med.prixVente > 0) return med.prixVente;
    if (med.prixVentePlaquette != null && med.prixVentePlaquette! > 0) {
      return med.prixVentePlaquette! / (med.unitesParPlaquette ?? 1);
    }
    if (med.prixVenteBoite != null && med.prixVenteBoite! > 0) {
      return med.prixVenteBoite! / ((med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1));
    }
    if (med.prixVenteCarton != null && med.prixVenteCarton! > 0) {
      return med.prixVenteCarton! / ((med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1));
    }
    return 0;
  }

  double _bestPA(Medicament med) {
    if (med.prixUnitaire > 0) return med.prixUnitaire;
    if (med.prixAchatPlaquette != null && med.prixAchatPlaquette! > 0) {
      return med.prixAchatPlaquette! / (med.unitesParPlaquette ?? 1);
    }
    if (med.prixAchatBoite != null && med.prixAchatBoite! > 0) {
      return med.prixAchatBoite! / ((med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1));
    }
    if (med.prixAchatCarton != null && med.prixAchatCarton! > 0) {
      return med.prixAchatCarton! / ((med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1));
    }
    return 0;
  }

  /// Vider les controllers quand on change de niveau
  void _onNiveauChanged(NiveauControle n) {
    setState(() {
      _niveau = n;
      for (final c in _controllers.values) {
        c.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contrôle des ventes')),
      body: Consumer<ControleProvider>(
        builder: (context, provider, _) {
          if (provider.medicaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fact_check_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: kPaddingM),
                  Text('Aucun médicament', style: GoogleFonts.inter(fontSize: kFontSizeL, color: kTextSecondary)),
                ],
              ),
            );
          }

          // Calcul des totaux
          int totalVendus = 0;
          double totalPV = 0;
          double totalBen = 0;
          for (int i = 0; i < provider.medicaments.length; i++) {
            final m = provider.medicaments[i];
            final ctrl = _getCtrl(i);
            final restant = int.tryParse(ctrl.text);
            if (restant != null) {
              final stockNiv = _stockInitialNiveau(m);
              final vendus = stockNiv - restant;
              final qv = vendus > 0 ? vendus : 0;
              final pvN = _prixVenteNiveau(m);
              final paN = _prixAchatNiveau(m);
              totalVendus += qv;
              totalPV += qv * pvN;
              totalBen += qv * (pvN - paN);
            }
          }

          return Column(
            children: [
              // Sélecteur de niveau
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: kPaddingM, vertical: 10),
                color: kPrimaryColor.withAlpha(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau de contrôle :',
                      style: GoogleFonts.inter(fontSize: kFontSizeS, color: kPrimaryColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: NiveauControle.values.map((n) {
                        final selected = _niveau == n;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onNiveauChanged(n),
                            child: Container(
                              margin: EdgeInsets.only(right: n != NiveauControle.carton ? 6 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? kPrimaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected ? kPrimaryColor : kBorderColor,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(n.icon, size: 16, color: selected ? Colors.white : kTextSecondary),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: selected ? Colors.white : kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Tableau header
              Container(
                color: kPrimaryColor.withAlpha(20),
                padding: const EdgeInsets.symmetric(horizontal: kPaddingS, vertical: kPaddingS),
                child: Row(
                  children: [
                    _headerCell('Médicament', flex: 3),
                    _headerCell('Stock\n(${_niveau.label})', flex: 2),
                    _headerCell('PA\n(${_niveau.label})', flex: 2),
                    _headerCell('PV\n(${_niveau.label})', flex: 2),
                    _headerCell('Restant', flex: 2),
                    _headerCell('Vendus', flex: 1),
                    _headerCell('PV Total', flex: 2),
                    _headerCell('Bénéfice', flex: 2),
                  ],
                ),
              ),

              // Liste
              Expanded(
                child: Builder(
                  builder: (context) {
                    final allMeds = provider.medicaments;

                    // Grouper les médicaments par nom
                    final grouped = <String, List<int>>{};
                    final groupOrder = <String>[];
                    for (int i = 0; i < allMeds.length; i++) {
                      final key = allMeds[i].nom.toLowerCase();
                      if (!grouped.containsKey(key)) {
                        grouped[key] = [];
                        groupOrder.add(key);
                      }
                      grouped[key]!.add(i);
                    }

                    // Construire la liste plate d'items
                    final items = <({String type, int medIndex, int lotNum, List<int> groupIndices})>[];
                    for (final groupKey in groupOrder) {
                      final indices = grouped[groupKey]!;
                      if (indices.length > 1) {
                        items.add((type: 'header', medIndex: indices.first, lotNum: 0, groupIndices: indices));
                        for (int j = 0; j < indices.length; j++) {
                          items.add((type: 'lot', medIndex: indices[j], lotNum: j + 1, groupIndices: indices));
                        }
                      } else {
                        items.add((type: 'single', medIndex: indices.first, lotNum: 1, groupIndices: indices));
                      }
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: kPaddingXS),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: kBorderColor),
                      itemBuilder: (context, itemIdx) {
                        final item = items[itemIdx];

                        // === EN-TÊTE DE GROUPE ===
                        if (item.type == 'header') {
                          final firstMed = allMeds[item.medIndex];
                          int groupQI = 0;
                          for (final idx in item.groupIndices) {
                            groupQI += _stockInitialNiveau(allMeds[idx]);
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Row(children: [
                                      Expanded(child: Text(
                                        firstMed.nom,
                                        style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w700, color: kPrimaryDarkColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(color: Colors.deepPurple.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                                        child: Text('${item.groupIndices.length} lots', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
                                      ),
                                    ]),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Text('$groupQI', style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w700, color: kPrimaryDarkColor)),
                                    ),
                                  ),
                                  const Expanded(flex: 2, child: SizedBox()),
                                  const Expanded(flex: 2, child: SizedBox()),
                                  const Expanded(flex: 2, child: SizedBox()),
                                  const Expanded(flex: 1, child: SizedBox()),
                                  const Expanded(flex: 2, child: SizedBox()),
                                  const Expanded(flex: 2, child: SizedBox()),
                                ],
                              ),
                            ),
                          );
                        }

                        // === LOT INDIVIDUEL ou MÉDICAMENT SEUL ===
                        final index = item.medIndex;
                        final med = allMeds[index];
                        final ctrl = _getCtrl(index);
                        final isLot = item.type == 'lot';

                        final stockNiv = _stockInitialNiveau(med);
                        final restant = int.tryParse(ctrl.text);
                        final hasInput = restant != null;
                        final vendus = hasInput ? (stockNiv - restant) : 0;
                        final qVendus = vendus > 0 ? vendus : 0;
                        final pvN = _prixVenteNiveau(med);
                        final paN = _prixAchatNiveau(med);
                        final pvVente = qVendus * pvN;
                        final benefice = qVendus * (pvN - paN);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            color: isLot ? Colors.deepPurple.withAlpha(6) : null,
                            child: Row(
                            children: [
                              // Nom
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    isLot
                                      ? Row(children: [
                                          Text('  ↳ ', style: GoogleFonts.inter(fontSize: 10, color: Colors.deepPurple)),
                                          Text('Lot ${item.lotNum}', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.deepPurple)),
                                        ])
                                      : Text(
                                          med.nom,
                                          style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    Row(children: [
                                      if (isLot) const SizedBox(width: 16),
                                      Text(med.forme.label, style: GoogleFonts.inter(fontSize: 9, color: kTextSecondary)),
                                      if (med.dateEntreeStock != null) ...[
                                        const SizedBox(width: 4),
                                        Text('• ${med.dateEntreeStock!.day.toString().padLeft(2, '0')}/${med.dateEntreeStock!.month.toString().padLeft(2, '0')}', style: GoogleFonts.inter(fontSize: 8, color: kTextSecondary)),
                                      ],
                                    ]),
                                  ],
                                ),
                              ),
                              // Stock initial au niveau
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text('$stockNiv', style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w600, color: kTextPrimary)),
                                ),
                              ),
                              // PA
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(formatNumber(paN), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
                                ),
                              ),
                              // PV
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(formatNumber(pvN), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimaryColor)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 36,
                                  child: TextFormField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      isDense: true,
                                      hintText: '$stockNiv',
                                      hintStyle: GoogleFonts.inter(fontSize: kFontSizeS, color: kTextSecondary.withAlpha(80)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final stock = int.tryParse(val);
                                      if (stock != null) {
                                        final unites = stock * _unitesParNiveau(med);
                                        provider.mettreAJourStockReel(index, unites);
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                              // Q.Vendues
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Text(
                                    hasInput ? '$qVendus' : '-',
                                    style: GoogleFonts.inter(
                                      fontSize: kFontSizeS,
                                      fontWeight: FontWeight.w600,
                                      color: qVendus > 0 ? Colors.orange.shade700 : kTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              // PV Total
                              Expanded(
                                flex: 2,
                                child: Text(
                                  hasInput ? formatNumber(pvVente) : '-',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w600, color: kPrimaryColor),
                                ),
                              ),
                              // Bénéfice
                              Expanded(
                                flex: 2,
                                child: Text(
                                  hasInput ? formatNumber(benefice) : '-',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    fontSize: kFontSizeS,
                                    fontWeight: FontWeight.w700,
                                    color: benefice >= 0 ? kSuccessColor : kDangerColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Totaux
              Container(
                padding: const EdgeInsets.all(kPaddingM),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withAlpha(15),
                  border: Border(top: BorderSide(color: kPrimaryColor.withAlpha(50), width: 2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.summarize_rounded, color: kPrimaryColor, size: 18),
                        const SizedBox(width: 6),
                        Text('TOTAUX', style: GoogleFonts.inter(fontSize: kFontSizeM, fontWeight: FontWeight.w800, color: kPrimaryDarkColor)),
                        const Spacer(),
                        Text(
                          'En ${_niveau.label.toLowerCase()}s',
                          style: GoogleFonts.inter(fontSize: kFontSizeXS, color: kTextSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _totalCard('Qté Vendue', '$totalVendus', Colors.orange.shade700),
                        const SizedBox(width: 8),
                        _totalCard('PV Total', formatCurrency(totalPV), kPrimaryColor),
                        const SizedBox(width: 8),
                        _totalCard('Bénéfice', formatCurrency(totalBen), totalBen >= 0 ? kSuccessColor : kDangerColor),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Statut de validation
                    if (provider.isControleValide) ...[
                      GestureDetector(
                        onTap: () => _showControleDetails(context, provider),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kSuccessColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: kSuccessColor.withAlpha(50)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: kSuccessColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Contrôle validé ✓', style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w700, color: kSuccessColor)),
                                    if (provider.dateValidation != null)
                                      Text(
                                        'Le ${provider.dateValidation!.day.toString().padLeft(2, '0')}/${provider.dateValidation!.month.toString().padLeft(2, '0')}/${provider.dateValidation!.year} à ${provider.dateValidation!.hour.toString().padLeft(2, '0')}:${provider.dateValidation!.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.inter(fontSize: 10, color: kSuccessColor.withAlpha(180)),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: kSuccessColor, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmerNouveauControle(context, provider),
                          icon: const Icon(Icons.add_circle_rounded, size: 18),
                          label: Text('Nouveau contrôle', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmerValidation(context, provider),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text('Valider le contrôle', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccessColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showControleDetails(BuildContext context, ControleProvider provider) {
    final meds = provider.medicaments;
    final date = provider.dateValidation;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(kPaddingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(children: [
                const Icon(Icons.fact_check_rounded, color: kSuccessColor, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Détails du contrôle', style: GoogleFonts.inter(fontSize: kFontSizeL, fontWeight: FontWeight.w700, color: kPrimaryDarkColor)),
                    if (date != null)
                      Text('Validé le ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(fontSize: kFontSizeXS, color: kTextSecondary)),
                  ],
                )),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
              ]),
              const Divider(),

              // Tableau
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(kPrimaryColor.withAlpha(15)),
                      headingTextStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kPrimaryDarkColor),
                      dataTextStyle: GoogleFonts.inter(fontSize: 10, color: kTextPrimary),
                      columnSpacing: 12,
                      horizontalMargin: 6,
                      columns: const [
                        DataColumn(label: Text('Médicament')),
                        DataColumn(label: Text('Stock\nInitial'), numeric: true),
                        DataColumn(label: Text('Stock\nRéel'), numeric: true),
                        DataColumn(label: Text('Qté\nVendue'), numeric: true),
                        DataColumn(label: Text('PV\nTotal'), numeric: true),
                        DataColumn(label: Text('Bénéfice'), numeric: true),
                        DataColumn(label: Text('Statut')),
                      ],
                      rows: meds.map((m) {
                        final hasControl = m.stockReel != null;
                        final qv = m.quantiteVendue;
                        final pvT = m.pvTotal;
                        final ben = m.benefice;
                        return DataRow(cells: [
                          DataCell(SizedBox(width: 90, child: Text(m.nom, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w500)))),
                          DataCell(Text('${m.quantiteInitiale}')),
                          DataCell(Text(hasControl ? '${m.stockReel}' : '-', style: GoogleFonts.inter(color: hasControl ? kTextPrimary : kTextSecondary))),
                          DataCell(Text('$qv', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: qv > 0 ? Colors.orange.shade700 : kTextSecondary))),
                          DataCell(Text(formatNumber(pvT), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: kPrimaryColor))),
                          DataCell(Text(formatNumber(ben), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ben >= 0 ? kSuccessColor : kDangerColor))),
                          DataCell(Icon(
                            hasControl ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: hasControl ? kSuccessColor : kTextSecondary,
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const Divider(),

              // Résumé
              Row(children: [
                _totalCard('Contrôlés', '${meds.where((m) => m.stockReel != null).length}/${meds.length}', kPrimaryColor),
                const SizedBox(width: 8),
                _totalCard('PV Total', formatCurrency(meds.fold(0.0, (s, m) => s + m.pvTotal)), Colors.orange.shade700),
                const SizedBox(width: 8),
                _totalCard('Bénéfice', formatCurrency(meds.fold(0.0, (s, m) => s + m.benefice)), kSuccessColor),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmerValidation(BuildContext context, ControleProvider provider) {
    final nbSaisis = provider.medicaments.where((m) => m.stockReel != null).length;
    final total = provider.medicaments.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.check_circle_rounded, color: kSuccessColor),
          const SizedBox(width: 8),
          Text('Valider le contrôle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$nbSaisis / $total médicaments contrôlés', style: GoogleFonts.inter(fontSize: kFontSizeM, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Cette action va :\n• Calculer les quantités vendues\n• Mettre à jour le stock\n• Sauvegarder la date de validation',
              style: GoogleFonts.inter(fontSize: kFontSizeS, color: kTextSecondary),
            ),
            if (nbSaisis < total) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.warning_rounded, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${total - nbSaisis} médicament(s) non contrôlé(s)', style: GoogleFonts.inter(fontSize: kFontSizeXS, color: Colors.orange.shade900))),
                ]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: GoogleFonts.inter(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.validerControle();
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Contrôle validé avec succès ✓', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  backgroundColor: kSuccessColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kSuccessColor),
            child: Text('Valider', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmerNouveauControle(BuildContext context, ControleProvider provider) {
    // Compter les médicaments avec stock réel saisi
    final nbAvecStock = provider.medicaments.where((m) => m.stockReel != null).length;
    final nbTotal = provider.medicaments.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.add_circle_rounded, color: kPrimaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text('Nouveau contrôle', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Un nouveau contrôle sera créé à partir du stock réel actuel.',
              style: GoogleFonts.inter(fontSize: kFontSizeM),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryColor.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPrimaryColor.withAlpha(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ce qui va se passer :', style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w700, color: kPrimaryDarkColor)),
                  const SizedBox(height: 6),
                  Text('• Le stock réel → nouvelle quantité initiale', style: GoogleFonts.inter(fontSize: kFontSizeS, color: kTextSecondary)),
                  Text('• Les ventes sont remises à zéro', style: GoogleFonts.inter(fontSize: kFontSizeS, color: kTextSecondary)),
                  Text('• L\'ancien contrôle reste dans l\'historique', style: GoogleFonts.inter(fontSize: kFontSizeS, color: kTextSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$nbAvecStock/$nbTotal médicaments ont un stock réel saisi',
              style: GoogleFonts.inter(fontSize: kFontSizeXS, color: kTextSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: GoogleFonts.inter(color: kTextSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.creerNouveauControleDepuisPrecedent();
              if (context.mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Nouveau contrôle créé ✓', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    backgroundColor: kSuccessColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur lors de la création', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    backgroundColor: kDangerColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ));
                }
              }
            },
            icon: const Icon(Icons.add_circle_rounded, size: 18),
            label: Text('Créer', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kPrimaryDarkColor),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _totalCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
