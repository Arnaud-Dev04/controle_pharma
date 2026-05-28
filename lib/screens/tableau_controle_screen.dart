/// Tableau de contrôle récapitulatif (type Excel)
///
/// Affiche TOUS les contrôles empilés chronologiquement avec :
/// - Sélecteur de niveau (Comprimé/Plaquette/Boîte/Carton)
/// - En-tête de section pour chaque contrôle
/// - Colonnes : Nom, Q.I, P.A, P.V, Q.Vendue, PV Total, Q.Rest, Stock Réel, Bénéfice
/// - Sous-totaux par contrôle + Grand total
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
  final Map<int, NiveauControle> _niveaux = {};

  NiveauControle _getNiveau(int globalIndex) {
    _niveaux[globalIndex] ??= NiveauControle.comprime;
    return _niveaux[globalIndex]!;
  }

  // ============================================================
  // 📐 CALCULS PAR NIVEAU
  // ============================================================

  int _unitesParNiveau(Medicament med, NiveauControle niveau) {
    final uPlq = med.unitesParPlaquette ?? 1;
    final plqBte = med.plaquettesParBoite ?? 1;
    final bteCrt = med.boitesParCarton ?? 1;
    return switch (niveau) {
      NiveauControle.comprime  => 1,
      NiveauControle.plaquette => uPlq,
      NiveauControle.boite     => uPlq * plqBte,
      NiveauControle.carton    => uPlq * plqBte * bteCrt,
    };
  }

  int _stockInitialNiveau(Medicament med, NiveauControle niveau) {
    final div = _unitesParNiveau(med, niveau);
    return div > 0 ? med.quantiteInitiale ~/ div : med.quantiteInitiale;
  }

  double _prixAchatNiveau(Medicament med, NiveauControle niveau) {
    return switch (niveau) {
      NiveauControle.comprime  => _bestPA(med),
      NiveauControle.plaquette => med.prixAchatPlaquette ?? _bestPA(med) * (med.unitesParPlaquette ?? 1),
      NiveauControle.boite     => med.prixAchatBoite ?? _bestPA(med) * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1),
      NiveauControle.carton    => med.prixAchatCarton ?? _bestPA(med) * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1),
    };
  }

  double _prixVenteNiveau(Medicament med, NiveauControle niveau) {
    return switch (niveau) {
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

  int _qteVendueNiveau(Medicament med, NiveauControle niveau) {
    final div = _unitesParNiveau(med, niveau);
    return div > 0 ? med.quantiteVendue ~/ div : med.quantiteVendue;
  }

  int _qteRestanteNiveau(Medicament med, NiveauControle niveau) {
    return _stockInitialNiveau(med, niveau) - _qteVendueNiveau(med, niveau);
  }

  int? _stockReelNiveau(Medicament med, NiveauControle niveau) {
    if (med.stockReel == null) return null;
    final div = _unitesParNiveau(med, niveau);
    return div > 0 ? med.stockReel! ~/ div : med.stockReel;
  }

  double _pvTotalNiveau(Medicament med, NiveauControle niveau) {
    return _qteVendueNiveau(med, niveau) * _prixVenteNiveau(med, niveau);
  }

  double _beneficeNiveau(Medicament med, NiveauControle niveau) {
    final pv = _prixVenteNiveau(med, niveau);
    final pa = _prixAchatNiveau(med, niveau);
    return _qteVendueNiveau(med, niveau) * (pv - pa);
  }

  // ============================================================
  // 🧱 LIGNES DE MÉDICAMENTS (avec groupement par nom)
  // ============================================================

  List<DataRow> _buildMedRows(List<Medicament> allMeds, {int globalOffset = 0}) {
    final rows = <DataRow>[];
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

      if (indices.length > 1) {
        int groupQI = 0, groupQV = 0;
        double groupPVT = 0, groupBen = 0;
        int? groupSR;
        for (final idx in indices) {
          final m = allMeds[idx];
          final niv = _getNiveau(globalOffset + idx);
          groupQI += _stockInitialNiveau(m, niv);
          groupQV += _qteVendueNiveau(m, niv);
          groupPVT += _pvTotalNiveau(m, niv);
          groupBen += _beneficeNiveau(m, niv);
          if (m.stockReel != null) groupSR = (groupSR ?? 0) + (_stockReelNiveau(m, niv) ?? 0);
        }

        rows.add(DataRow(
          color: WidgetStateProperty.all(kPrimaryColor.withAlpha(15)),
          cells: [
            DataCell(SizedBox(width: kColNom, child: Row(children: [
              Expanded(child: Text(firstMed.nom, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: kPrimaryDarkColor))),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: Colors.deepPurple.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                child: Text('${indices.length} lots', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
              ),
            ]))),
            const DataCell(Text('')), // Date vide pour groupe
            DataCell(Text('$groupQI', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
            const DataCell(Text('')), const DataCell(Text('')),
            DataCell(Text('$groupQV', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
            DataCell(Text(formatNumber(groupPVT), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.orange.shade800))),
            DataCell(Text('${groupQI - groupQV}', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
            DataCell(Text(groupSR?.toString() ?? '-', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
            DataCell(Text(formatNumber(groupBen), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: groupBen >= 0 ? kSuccessColor : kDangerColor))),
          ],
        ));

        for (int j = 0; j < indices.length; j++) {
          rows.add(_singleRow(allMeds[indices[j]], globalIndex: globalOffset + indices[j], lotLabel: 'Lot ${j + 1}', isLot: true));
        }
      } else {
        rows.add(_singleRow(firstMed, globalIndex: globalOffset + indices.first));
      }
    }
    return rows;
  }

  DataRow _singleRow(Medicament med, {required int globalIndex, String? lotLabel, bool isLot = false}) {
    final niveau = _getNiveau(globalIndex);
    final qiN = _stockInitialNiveau(med, niveau);
    final paN = _prixAchatNiveau(med, niveau);
    final pvN = _prixVenteNiveau(med, niveau);
    final qvN = _qteVendueNiveau(med, niveau);
    final pvT = _pvTotalNiveau(med, niveau);
    final qrN = _qteRestanteNiveau(med, niveau);
    final srN = _stockReelNiveau(med, niveau);
    final benN = _beneficeNiveau(med, niveau);
    final niveauxDispo = NiveauControle.values.where((n) => n.estApplicable(med.forme)).toList();

    return DataRow(
      color: isLot ? WidgetStateProperty.all(Colors.deepPurple.withAlpha(6)) : null,
      cells: [
        DataCell(SizedBox(width: kColNom, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLot)
              Row(children: [
                Text('  ↳ ', style: GoogleFonts.inter(fontSize: 10, color: Colors.deepPurple)),
                Text(lotLabel ?? '', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.deepPurple)),
              ])
            else
              Text(med.nom, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Wrap(spacing: 3, runSpacing: 2, children: niveauxDispo.map((n) {
              final sel = niveau == n;
              return GestureDetector(
                onTap: () => setState(() => _niveaux[globalIndex] = n),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: sel ? kPrimaryColor : Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sel ? kPrimaryColor : kBorderColor, width: 0.5),
                  ),
                  child: Text(
                    n.labelPour(med.forme),
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: sel ? Colors.white : kTextSecondary),
                  ),
                ),
              );
            }).toList()),
          ],
        ))),
        DataCell(Text(
          med.dateEntreeStock != null
            ? '${med.dateEntreeStock!.day.toString().padLeft(2, '0')}/${med.dateEntreeStock!.month.toString().padLeft(2, '0')}/${med.dateEntreeStock!.year.toString().substring(2)}'
            : '-',
          style: GoogleFonts.inter(fontSize: 9, color: kTextSecondary),
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
    );
  }

  // ============================================================
  // 🏗️ BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de contrôle'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Export disponible prochainement'),
                backgroundColor: kPrimaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ));
            },
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Exporter',
          ),
        ],
      ),
      body: Consumer<ControleProvider>(
        builder: (context, provider, _) {
          // Ordre chronologique (ancien → récent)
          final allControles = provider.controles.reversed.toList();

          if (allControles.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_chart_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: kPaddingM),
                Text('Aucune donnée à afficher', style: GoogleFonts.inter(fontSize: kFontSizeL, color: kTextSecondary)),
              ],
            ));
          }

          // Grand totaux (au niveau comprimé/unité par défaut)
          int grandVendus = 0;
          double grandPV = 0, grandBen = 0;
          int globalIdx = 0;
          for (final c in allControles) {
            final meds = c.id == provider.controleActuel?.id ? provider.medicaments : c.medicaments;
            for (final m in meds) {
              final niv = _getNiveau(globalIdx);
              grandVendus += _qteVendueNiveau(m, niv);
              grandPV += _pvTotalNiveau(m, niv);
              grandBen += _beneficeNiveau(m, niv);
              globalIdx++;
            }
          }

          return SafeArea(
            top: false,
            child: Column(children: [
            // En-tête grand totaux
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kPaddingS),
              decoration: BoxDecoration(color: kPrimaryColor.withAlpha(10), border: Border(bottom: BorderSide(color: kBorderColor))),
              child: Row(children: [
                Expanded(child: _chip('${allControles.length} contrôle(s)', kPrimaryColor)),
                const SizedBox(width: 6),
                Expanded(child: _chip('PV: ${formatCurrency(grandPV)}', Colors.orange.shade700)),
                const SizedBox(width: 6),
                Expanded(child: _chip('Bén: ${formatCurrency(grandBen)}', grandBen >= 0 ? kSuccessColor : kDangerColor)),
              ]),
            ),

            // Tableau scrollable
            Expanded(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(child: DataTable(
                headingRowColor: WidgetStateProperty.all(kPrimaryColor.withAlpha(20)),
                headingTextStyle: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w700, color: kPrimaryDarkColor),
                dataTextStyle: GoogleFonts.inter(fontSize: kFontSizeS, color: kTextPrimary),
                columnSpacing: 16, horizontalMargin: 12,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 100,
                columns: [
                  const DataColumn(label: Text(kLabelNom)),
                  const DataColumn(label: Text('Date')),
                  const DataColumn(label: Text('Q.I'), numeric: true),
                  const DataColumn(label: Text('PA'), numeric: true),
                  const DataColumn(label: Text('PV'), numeric: true),
                  const DataColumn(label: Text(kLabelQVendue), numeric: true),
                  const DataColumn(label: Text(kLabelPVTotal), numeric: true),
                  const DataColumn(label: Text(kLabelQRestante), numeric: true),
                  const DataColumn(label: Text(kLabelStockReel), numeric: true),
                  const DataColumn(label: Text(kLabelBenefice), numeric: true),
                ],
                rows: [
                  ...() {
                    final allRows = <DataRow>[];
                    int medOffset = 0;
                    for (int ci = 0; ci < allControles.length; ci++) {
                      final controle = allControles[ci];
                      final isActuel = controle.id == provider.controleActuel?.id;
                      final meds = isActuel ? provider.medicaments : controle.medicaments;

                      int subV = 0; double subPV = 0, subB = 0;
                      for (int mi = 0; mi < meds.length; mi++) {
                        final m = meds[mi];
                        final niv = _getNiveau(medOffset + mi);
                        subV += _qteVendueNiveau(m, niv);
                        subPV += _pvTotalNiveau(m, niv);
                        subB += _beneficeNiveau(m, niv);
                      }

                      final dateStr = '${controle.dateCreation.day.toString().padLeft(2, '0')}/${controle.dateCreation.month.toString().padLeft(2, '0')}/${controle.dateCreation.year}';
                      final isTermine = controle.statut == 'termine';

                      // ── EN-TÊTE SECTION ──
                      allRows.add(DataRow(
                        color: WidgetStateProperty.all(isActuel ? kPrimaryColor.withAlpha(30) : Colors.blueGrey.withAlpha(20)),
                        cells: [
                          DataCell(SizedBox(width: kColNom, child: Row(children: [
                            Icon(isTermine ? Icons.check_circle_rounded : Icons.pending_rounded, size: 14, color: isTermine ? kSuccessColor : Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Expanded(child: Text(
                              '${controle.titre} — $dateStr',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: isActuel ? kPrimaryColor : kPrimaryDarkColor),
                              overflow: TextOverflow.ellipsis,
                            )),
                          ]))),
                          DataCell(Text('${meds.length} méd.', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: kTextSecondary))),
                          const DataCell(Text('')), const DataCell(Text('')),
                          const DataCell(Text('')), const DataCell(Text('')),
                          const DataCell(Text('')), const DataCell(Text('')),
                          DataCell(Text(isTermine ? '✓ Terminé' : '⏳ En cours', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: isTermine ? kSuccessColor : Colors.orange.shade700))),
                          const DataCell(Text('')),
                        ],
                      ));

                      // ── LIGNES MÉDICAMENTS ──
                      if (meds.isNotEmpty) {
                        allRows.addAll(_buildMedRows(meds, globalOffset: medOffset));

                        // ── SOUS-TOTAL ──
                        allRows.add(DataRow(
                          color: WidgetStateProperty.all(isActuel ? kPrimaryColor.withAlpha(15) : Colors.blueGrey.withAlpha(10)),
                          cells: [
                            DataCell(Text('  ∑ Sous-total', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kPrimaryDarkColor, fontStyle: FontStyle.italic))),
                            const DataCell(Text('')), const DataCell(Text('')), const DataCell(Text('')), const DataCell(Text('')),
                            DataCell(Text('$subV', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                            DataCell(Text(formatNumber(subPV), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.orange.shade800))),
                            const DataCell(Text('')), const DataCell(Text('')),
                            DataCell(Text(formatNumber(subB), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: subB >= 0 ? kSuccessColor : kDangerColor))),
                          ],
                        ));
                      }
                      medOffset += meds.length;

                      // Séparateur entre contrôles
                      if (ci < allControles.length - 1) {
                        allRows.add(DataRow(
                          color: WidgetStateProperty.all(Colors.transparent),
                          cells: List.generate(10, (_) => const DataCell(SizedBox(height: 6))),
                        ));
                      }
                    }
                    return allRows;
                  }(),

                  // ── GRAND TOTAL ──
                  DataRow(
                    color: WidgetStateProperty.all(kPrimaryColor.withAlpha(25)),
                    cells: [
                      DataCell(Text('GRAND TOTAL', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: kPrimaryDarkColor))),
                      const DataCell(Text('')), const DataCell(Text('')), const DataCell(Text('')), const DataCell(Text('')),
                      DataCell(Text('$grandVendus', style: GoogleFonts.inter(fontWeight: FontWeight.w800))),
                      DataCell(Text(formatNumber(grandPV), style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.orange.shade800))),
                      const DataCell(Text('')), const DataCell(Text('')),
                      DataCell(Text(formatNumber(grandBen), style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: grandBen >= 0 ? kSuccessColor : kDangerColor))),
                    ],
                  ),
                ],
              )),
            )),
          ]),
          );
        },
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(40))),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
