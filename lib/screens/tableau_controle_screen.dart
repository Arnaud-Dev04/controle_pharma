/// Tableau de contrôle récapitulatif (type Excel)
///
/// Affiche tous les médicaments sous forme de tableau avec :
/// - Sélecteur de niveau (Comprimé/Plaquette/Boîte/Carton)
/// - Colonnes adaptatives : Nom, Q.I, P.A, P.V, Q.Vendue, PV Total, Q.Rest, Stock Réel, Écart, Bénéfice
/// - Ligne de totaux en bas
/// - Code couleur rouge/vert pour les écarts
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/medicament.dart';
import '../providers/controle_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../screens/controle_simplifie_screen.dart';

class TableauControleScreen extends StatefulWidget {
  const TableauControleScreen({super.key});

  @override
  State<TableauControleScreen> createState() => _TableauControleScreenState();
}

class _TableauControleScreenState extends State<TableauControleScreen> {
  NiveauControle _niveau = NiveauControle.comprime;

  // ============================================================
  // 📐 CALCULS PAR NIVEAU
  // ============================================================

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

  int _stockInitialNiveau(Medicament med) {
    final div = _unitesParNiveau(med);
    return div > 0 ? med.quantiteInitiale ~/ div : med.quantiteInitiale;
  }

  double _prixAchatNiveau(Medicament med) {
    return switch (_niveau) {
      NiveauControle.comprime  => _bestPA(med),
      NiveauControle.plaquette => med.prixAchatPlaquette ?? _bestPA(med) * (med.unitesParPlaquette ?? 1),
      NiveauControle.boite     => med.prixAchatBoite ?? _bestPA(med) * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1),
      NiveauControle.carton    => med.prixAchatCarton ?? _bestPA(med) * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1),
    };
  }

  double _prixVenteNiveau(Medicament med) {
    return switch (_niveau) {
      NiveauControle.comprime  => _bestPV(med),
      NiveauControle.plaquette => med.prixVentePlaquette ?? _bestPV(med) * (med.unitesParPlaquette ?? 1),
      NiveauControle.boite     => med.prixVenteBoite ?? _bestPV(med) * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1),
      NiveauControle.carton    => med.prixVenteCarton ?? _bestPV(med) * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1),
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

  int _qteVendueNiveau(Medicament med) {
    final div = _unitesParNiveau(med);
    return div > 0 ? med.quantiteVendue ~/ div : med.quantiteVendue;
  }

  int _qteRestanteNiveau(Medicament med) {
    return _stockInitialNiveau(med) - _qteVendueNiveau(med);
  }

  int? _stockReelNiveau(Medicament med) {
    if (med.stockReel == null) return null;
    final div = _unitesParNiveau(med);
    return div > 0 ? med.stockReel! ~/ div : med.stockReel;
  }

  int? _ecartNiveau(Medicament med) {
    final sr = _stockReelNiveau(med);
    if (sr == null) return null;
    return sr - _qteRestanteNiveau(med);
  }

  double _pvTotalNiveau(Medicament med) {
    return _qteVendueNiveau(med) * _prixVenteNiveau(med);
  }

  double _beneficeNiveau(Medicament med) {
    final pv = _prixVenteNiveau(med);
    final pa = _prixAchatNiveau(med);
    return _qteVendueNiveau(med) * (pv - pa);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de contrôle'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Export disponible prochainement'),
                  backgroundColor: kPrimaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Exporter',
          ),
        ],
      ),
      body: Consumer<ControleProvider>(
        builder: (context, provider, _) {
          if (provider.medicaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_chart_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: kPaddingM),
                  Text('Aucune donnée à afficher', style: GoogleFonts.inter(fontSize: kFontSizeL, color: kTextSecondary)),
                ],
              ),
            );
          }

          // Calcul des totaux au niveau choisi
          int totalVendus = 0;
          double totalPV = 0;
          double totalBen = 0;
          for (final m in provider.medicaments) {
            totalVendus += _qteVendueNiveau(m);
            totalPV += _pvTotalNiveau(m);
            totalBen += _beneficeNiveau(m);
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
                    Text('Niveau :', style: GoogleFonts.inter(fontSize: kFontSizeS, color: kPrimaryColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: NiveauControle.values.map((n) {
                        final selected = _niveau == n;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _niveau = n),
                            child: Container(
                              margin: EdgeInsets.only(right: n != NiveauControle.carton ? 6 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? kPrimaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selected ? kPrimaryColor : kBorderColor, width: selected ? 2 : 1),
                              ),
                              child: Column(
                                children: [
                                  Icon(n.icon, size: 16, color: selected ? Colors.white : kTextSecondary),
                                  const SizedBox(height: 2),
                                  Text(n.label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? Colors.white : kTextSecondary)),
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

              // En-tête totaux
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(kPaddingS),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withAlpha(10),
                  border: Border(bottom: BorderSide(color: kBorderColor)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTotalChip('PV Total', formatCurrency(totalPV), kPrimaryColor)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTotalChip('Bénéfice', formatCurrency(totalBen), totalBen >= 0 ? kSuccessColor : kDangerColor)),
                  ],
                ),
              ),

              // Tableau scrollable
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(kPrimaryColor.withAlpha(20)),
                      headingTextStyle: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w700, color: kPrimaryDarkColor),
                      dataTextStyle: GoogleFonts.inter(fontSize: kFontSizeS, color: kTextPrimary),
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: [
                        const DataColumn(label: Text(kLabelNom)),
                        DataColumn(label: Text('Q.I\n(${_niveau.label})'), numeric: true),
                        DataColumn(label: Text('PA\n(${_niveau.label})'), numeric: true),
                        DataColumn(label: Text('PV\n(${_niveau.label})'), numeric: true),
                        const DataColumn(label: Text(kLabelQVendue), numeric: true),
                        const DataColumn(label: Text(kLabelPVTotal), numeric: true),
                        const DataColumn(label: Text(kLabelQRestante), numeric: true),
                        const DataColumn(label: Text(kLabelStockReel), numeric: true),
                        const DataColumn(label: Text(kLabelBenefice), numeric: true),
                      ],
                      rows: [
                        ...() {
                          final rows = <DataRow>[];
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

                          for (final groupKey in groupOrder) {
                            final indices = grouped[groupKey]!;
                            final firstMed = allMeds[indices.first];
                            final hasMultipleLots = indices.length > 1;

                            // Calculer les totaux du groupe
                            int groupQI = 0, groupQV = 0;
                            double groupPVT = 0, groupBen = 0;
                            int? groupSR;
                            for (final idx in indices) {
                              final m = allMeds[idx];
                              groupQI += _stockInitialNiveau(m);
                              groupQV += _qteVendueNiveau(m);
                              groupPVT += _pvTotalNiveau(m);
                              groupBen += _beneficeNiveau(m);
                              if (m.stockReel != null) {
                                groupSR = (groupSR ?? 0) + (_stockReelNiveau(m) ?? 0);
                              }
                            }
                            final groupQR = groupQI - groupQV;

                            if (hasMultipleLots) {
                              // Ligne d'en-tête du groupe (nom + totaux agrégés)
                              rows.add(DataRow(
                                color: WidgetStateProperty.all(kPrimaryColor.withAlpha(15)),
                                cells: [
                                  DataCell(SizedBox(
                                    width: kColNom,
                                    child: Row(children: [
                                      Expanded(child: Text(firstMed.nom, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: kPrimaryDarkColor))),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(color: Colors.deepPurple.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                                        child: Text('${indices.length} lots', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
                                      ),
                                    ]),
                                  )),
                                  DataCell(Text('$groupQI', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: kPrimaryDarkColor))),
                                  const DataCell(Text('')),
                                  const DataCell(Text('')),
                                  DataCell(Text('$groupQV', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                                  DataCell(Text(formatNumber(groupPVT), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.orange.shade800))),
                                  DataCell(Text('$groupQR', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                                  DataCell(Text(groupSR?.toString() ?? '-', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: groupSR == null ? kTextSecondary : kTextPrimary))),
                                  DataCell(Text(formatNumber(groupBen), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: groupBen >= 0 ? kSuccessColor : kDangerColor))),
                                ],
                              ));

                              // Lignes individuelles des lots
                              for (int j = 0; j < indices.length; j++) {
                                final med = allMeds[indices[j]];
                                final qiN = _stockInitialNiveau(med);
                                final paN = _prixAchatNiveau(med);
                                final pvN = _prixVenteNiveau(med);
                                final qvN = _qteVendueNiveau(med);
                                final pvT = _pvTotalNiveau(med);
                                final qrN = _qteRestanteNiveau(med);
                                final srN = _stockReelNiveau(med);
                                final benN = _beneficeNiveau(med);

                                rows.add(DataRow(
                                  color: WidgetStateProperty.all(Colors.deepPurple.withAlpha(6)),
                                  cells: [
                                    DataCell(SizedBox(
                                      width: kColNom,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(children: [
                                            Text('  ↳ ', style: GoogleFonts.inter(fontSize: 10, color: Colors.deepPurple)),
                                            Text('Lot ${j + 1}', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.deepPurple)),
                                          ]),
                                          if (med.dateEntreeStock != null)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 16),
                                              child: Text('${med.dateEntreeStock!.day.toString().padLeft(2, '0')}/${med.dateEntreeStock!.month.toString().padLeft(2, '0')}/${med.dateEntreeStock!.year}', style: GoogleFonts.inter(fontSize: 8, color: kTextSecondary)),
                                            ),
                                        ],
                                      ),
                                    )),
                                    DataCell(Text('$qiN')),
                                    DataCell(Text(formatNumber(paN), style: GoogleFonts.inter(color: Colors.orange.shade700))),
                                    DataCell(Text(formatNumber(pvN), style: GoogleFonts.inter(color: kPrimaryColor))),
                                    DataCell(Text('$qvN')),
                                    DataCell(Text(formatNumber(pvT), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.orange.shade800))),
                                    DataCell(Text('$qrN')),
                                    DataCell(Text(srN?.toString() ?? '-', style: GoogleFonts.inter(color: srN == null ? kTextSecondary : kTextPrimary))),
                                    DataCell(Text(formatNumber(benN), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: benN >= 0 ? kSuccessColor : kDangerColor))),
                                  ],
                                ));
                              }
                            } else {
                              // Un seul lot — affichage normal
                              final med = firstMed;
                              final qiN = _stockInitialNiveau(med);
                              final paN = _prixAchatNiveau(med);
                              final pvN = _prixVenteNiveau(med);
                              final qvN = _qteVendueNiveau(med);
                              final pvT = _pvTotalNiveau(med);
                              final qrN = _qteRestanteNiveau(med);
                              final srN = _stockReelNiveau(med);
                              final benN = _beneficeNiveau(med);

                              rows.add(DataRow(
                                cells: [
                                  DataCell(SizedBox(
                                    width: kColNom,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(med.nom, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                                        if (med.dateEntreeStock != null)
                                          Text('${med.dateEntreeStock!.day.toString().padLeft(2, '0')}/${med.dateEntreeStock!.month.toString().padLeft(2, '0')}/${med.dateEntreeStock!.year}', style: GoogleFonts.inter(fontSize: 8, color: kTextSecondary)),
                                      ],
                                    ),
                                  )),
                                  DataCell(Text('$qiN')),
                                  DataCell(Text(formatNumber(paN), style: GoogleFonts.inter(color: Colors.orange.shade700))),
                                  DataCell(Text(formatNumber(pvN), style: GoogleFonts.inter(color: kPrimaryColor))),
                                  DataCell(Text('$qvN')),
                                  DataCell(Text(formatNumber(pvT), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.orange.shade800))),
                                  DataCell(Text('$qrN')),
                                  DataCell(Text(srN?.toString() ?? '-', style: GoogleFonts.inter(color: srN == null ? kTextSecondary : kTextPrimary))),
                                  DataCell(Text(formatNumber(benN), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: benN >= 0 ? kSuccessColor : kDangerColor))),
                                ],
                              ));
                            }
                          }
                          return rows;
                        }(),
                        // Ligne de totaux
                        DataRow(
                          color: WidgetStateProperty.all(kPrimaryColor.withAlpha(10)),
                          cells: [
                            DataCell(Text('TOTAUX', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: kPrimaryDarkColor))),
                            const DataCell(Text('')),
                            const DataCell(Text('')),
                            const DataCell(Text('')),
                            DataCell(Text('$totalVendus', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                            DataCell(Text(formatNumber(totalPV), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.orange.shade800))),
                            const DataCell(Text('')),
                            const DataCell(Text('')),
                            DataCell(Text(formatNumber(totalBen), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: totalBen >= 0 ? kSuccessColor : kDangerColor))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
