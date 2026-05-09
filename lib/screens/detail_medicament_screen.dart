/// Écran de détail d'un médicament
///
/// Affiche toutes les informations d'un médicament avec :
/// - Infos générales + sélecteur de niveau
/// - Historique des lots (même nom, prix différents)
/// - Comparaison des prix entre lots
/// - Résumé financier global tous lots confondus
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/medicament.dart';
import '../providers/controle_provider.dart';
import '../screens/controle_simplifie_screen.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'medicament_form_screen.dart';

class DetailMedicamentScreen extends StatefulWidget {
  final Medicament medicament;
  final int index;

  const DetailMedicamentScreen({
    super.key,
    required this.medicament,
    required this.index,
  });

  @override
  State<DetailMedicamentScreen> createState() => _DetailMedicamentScreenState();
}

class _DetailMedicamentScreenState extends State<DetailMedicamentScreen> {
  NiveauControle _niveau = NiveauControle.comprime;

  Medicament get med => widget.medicament;

  // ── Calculs par niveau pour un médicament donné ──
  double _paNiv(Medicament m) {
    return switch (_niveau) {
      NiveauControle.comprime  => _bestPA(m),
      NiveauControle.plaquette => m.prixAchatPlaquette ?? _bestPA(m) * (m.unitesParPlaquette ?? 1),
      NiveauControle.boite     => m.prixAchatBoite ?? _bestPA(m) * (m.unitesParPlaquette ?? 1) * (m.plaquettesParBoite ?? 1),
      NiveauControle.carton    => m.prixAchatCarton ?? _bestPA(m) * (m.unitesParPlaquette ?? 1) * (m.plaquettesParBoite ?? 1) * (m.boitesParCarton ?? 1),
    };
  }

  double _pvNiv(Medicament m) {
    return switch (_niveau) {
      NiveauControle.comprime  => _bestPV(m),
      NiveauControle.plaquette => m.prixVentePlaquette ?? _bestPV(m) * (m.unitesParPlaquette ?? 1),
      NiveauControle.boite     => m.prixVenteBoite ?? _bestPV(m) * (m.unitesParPlaquette ?? 1) * (m.plaquettesParBoite ?? 1),
      NiveauControle.carton    => m.prixVenteCarton ?? _bestPV(m) * (m.unitesParPlaquette ?? 1) * (m.plaquettesParBoite ?? 1) * (m.boitesParCarton ?? 1),
    };
  }

  int _qteNiv(Medicament m) {
    final div = _unitesParNiv(m);
    return div > 0 ? m.quantiteInitiale ~/ div : 0;
  }

  int _unitesParNiv(Medicament m) {
    final u = m.unitesParPlaquette ?? 1;
    final p = m.plaquettesParBoite ?? 1;
    final b = m.boitesParCarton ?? 1;
    return switch (_niveau) {
      NiveauControle.comprime  => 1,
      NiveauControle.plaquette => u,
      NiveauControle.boite     => u * p,
      NiveauControle.carton    => u * p * b,
    };
  }

  double _bestPA(Medicament m) {
    if (m.prixUnitaire > 0) return m.prixUnitaire;
    if ((m.prixAchatPlaquette ?? 0) > 0) return m.prixAchatPlaquette! / (m.unitesParPlaquette ?? 1);
    if ((m.prixAchatBoite ?? 0) > 0) return m.prixAchatBoite! / ((m.unitesParPlaquette ?? 1) * (m.plaquettesParBoite ?? 1));
    if ((m.prixAchatCarton ?? 0) > 0) return m.prixAchatCarton! / ((m.unitesParPlaquette ?? 1) * (m.plaquettesParBoite ?? 1) * (m.boitesParCarton ?? 1));
    return 0;
  }

  double _bestPV(Medicament m) {
    if (m.prixVente > 0) return m.prixVente;
    if ((m.prixVentePlaquette ?? 0) > 0) return m.prixVentePlaquette! / (m.unitesParPlaquette ?? 1);
    if ((m.prixVenteBoite ?? 0) > 0) return m.prixVenteBoite! / ((m.unitesParPlaquette ?? 1) * (m.plaquettesParBoite ?? 1));
    if ((m.prixVenteCarton ?? 0) > 0) return m.prixVenteCarton! / ((m.unitesParPlaquette ?? 1) * (m.plaquettesParBoite ?? 1) * (m.boitesParCarton ?? 1));
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ControleProvider>(
      builder: (context, provider, _) {
        // Trouver TOUS les lots du même médicament (même nom)
        final tousLots = <_LotInfo>[];
        for (int i = 0; i < provider.medicaments.length; i++) {
          final m = provider.medicaments[i];
          if (m.nom.toLowerCase() == med.nom.toLowerCase()) {
            tousLots.add(_LotInfo(medicament: m, index: i));
          }
        }

        // Trier par date d'entrée
        tousLots.sort((a, b) {
          final da = a.medicament.dateEntreeStock;
          final db = b.medicament.dateEntreeStock;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

        final hasMultipleLots = tousLots.length > 1;

        return Scaffold(
          appBar: AppBar(
            title: Text(med.nom, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicamentFormScreen(medicament: med, editIndex: widget.index))),
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Modifier',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(kPaddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── INFO GÉNÉRALES (lot actuel) ──
                _buildCard(
                  title: 'Informations générales',
                  icon: Icons.info_outline_rounded,
                  color: kPrimaryColor,
                  children: [
                    _infoRow('Nom', med.nom),
                    _infoRow('Forme', '${med.forme.emoji}  ${med.forme.label}'),
                    _infoRow('Date d\'entrée', med.dateEntreeStock != null ? formatDateShort(med.dateEntreeStock!) : 'Non renseignée'),
                    _infoRow('Quantité entrée', '${med.quantiteInitiale} unités'),
                    _infoRow('Quantité vendue', '${med.quantiteVendue} unités'),
                    _infoRow('Quantité restante', '${med.quantiteRestante} unités'),
                    if (med.stockReel != null)
                      _infoRow('Stock réel (compté)', '${med.stockReel} unités'),
                    if (hasMultipleLots)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange.shade200)),
                          child: Row(children: [
                            Icon(Icons.layers_rounded, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text('${tousLots.length} lots avec prix différents', style: GoogleFonts.inter(fontSize: kFontSizeXS, fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
                          ]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: kPaddingM),

                // ── SÉLECTEUR DE NIVEAU ──
                _buildCard(
                  title: 'Niveau d\'affichage',
                  icon: Icons.tune_rounded,
                  color: Colors.teal,
                  children: [
                    Row(
                      children: NiveauControle.values.map((n) {
                        final sel = _niveau == n;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _niveau = n),
                            child: Container(
                              margin: EdgeInsets.only(right: n != NiveauControle.carton ? 6 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? kPrimaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: sel ? kPrimaryColor : kBorderColor, width: sel ? 2 : 1),
                              ),
                              child: Column(children: [
                                Icon(n.icon, size: 16, color: sel ? Colors.white : kTextSecondary),
                                const SizedBox(height: 2),
                                Text(n.label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: sel ? Colors.white : kTextSecondary)),
                              ]),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: kPaddingM),

                // ── HISTORIQUE DES LOTS ──
                _buildCard(
                  title: hasMultipleLots ? 'Historique des lots (${tousLots.length})' : 'Prix & Stock',
                  icon: Icons.history_rounded,
                  color: Colors.deepPurple,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: () {
                        // Pré-calculer les totaux
                        int gQte = 0, gVendu = 0, gRestant = 0;
                        double gPA = 0, gPV = 0, gPVTotal = 0, gBen = 0;

                        final lotRows = tousLots.asMap().entries.map((entry) {
                          final i = entry.key;
                          final lot = entry.value;
                          final m = lot.medicament;
                          final pa = _paNiv(m);
                          final pv = _pvNiv(m);
                          final qte = _qteNiv(m);
                          final div = _unitesParNiv(m);
                          final vendu = div > 0 ? m.quantiteVendue ~/ div : 0;
                          final restant = qte - vendu;
                          final pvTotal = pv * qte;
                          final ben = (pv - pa) * qte;
                          final isCurrent = lot.index == widget.index;

                          gQte += qte; gVendu += vendu; gRestant += restant;
                          gPA += pa * qte; gPV += pv * qte; gPVTotal += pvTotal; gBen += ben;

                          // Variation PA
                          Widget? deltaPA;
                          if (hasMultipleLots && i > 0) {
                            final prevPA = _paNiv(tousLots[i - 1].medicament);
                            final diff = pa - prevPA;
                            if (diff != 0) {
                              final isUp = diff > 0;
                              deltaPA = Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: isUp ? kDangerColor : kSuccessColor),
                                Text(formatNumber(diff.abs()), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: isUp ? kDangerColor : kSuccessColor)),
                              ]);
                            }
                          }

                          return DataRow(
                            color: WidgetStateProperty.all(isCurrent ? kPrimaryColor.withAlpha(10) : Colors.transparent),
                            cells: [
                              if (hasMultipleLots) DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(color: isCurrent ? kPrimaryColor : Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                                child: Text('${i + 1}', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: isCurrent ? Colors.white : kTextPrimary)),
                              )),
                              DataCell(Text(
                                m.dateEntreeStock != null ? '${m.dateEntreeStock!.day.toString().padLeft(2, '0')}/${m.dateEntreeStock!.month.toString().padLeft(2, '0')}/${m.dateEntreeStock!.year}' : '-',
                                style: GoogleFonts.inter(fontSize: 9),
                              )),
                              DataCell(Text('$qte', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                              DataCell(Text(formatNumber(pa), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.orange.shade700))),
                              DataCell(Text(formatNumber(pv), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: kPrimaryColor))),
                              DataCell(Text('$vendu', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: vendu > 0 ? Colors.orange.shade700 : kTextSecondary))),
                              DataCell(Text('$restant', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: restant > 0 ? kSuccessColor : kDangerColor))),
                              DataCell(Text(formatNumber(pvTotal), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.orange.shade800))),
                              DataCell(Text(formatNumber(ben), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ben >= 0 ? kSuccessColor : kDangerColor))),
                              if (hasMultipleLots) DataCell(deltaPA ?? Text(i == 0 ? 'Réf.' : '=', style: GoogleFonts.inter(fontSize: 9, color: kTextSecondary))),
                            ],
                          );
                        }).toList();

                        // Ligne TOTAUX
                        lotRows.add(DataRow(
                          color: WidgetStateProperty.all(Colors.deepPurple.withAlpha(12)),
                          cells: [
                            if (hasMultipleLots) DataCell(Text('', style: GoogleFonts.inter())),
                            DataCell(Text('TOTAUX', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.deepPurple))),
                            DataCell(Text('$gQte', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                            DataCell(Text(formatNumber(gPA), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.orange.shade800))),
                            DataCell(Text(formatNumber(gPV), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: kPrimaryDarkColor))),
                            DataCell(Text('$gVendu', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.orange.shade700))),
                            DataCell(Text('$gRestant', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: kSuccessColor))),
                            DataCell(Text(formatNumber(gPVTotal), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.orange.shade800))),
                            DataCell(Text(formatNumber(gBen), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: gBen >= 0 ? kSuccessColor : kDangerColor))),
                            if (hasMultipleLots) DataCell(Text('', style: GoogleFonts.inter())),
                          ],
                        ));

                        return DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.deepPurple.withAlpha(12)),
                          headingTextStyle: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.deepPurple),
                          dataTextStyle: GoogleFonts.inter(fontSize: 10, color: kTextPrimary),
                          columnSpacing: 8,
                          horizontalMargin: 4,
                          columns: [
                            if (hasMultipleLots) const DataColumn(label: Text('Lot')),
                            const DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Qté\n(${_niveau.label})'), numeric: true),
                            DataColumn(label: Text('PA\n(${_niveau.label})'), numeric: true),
                            DataColumn(label: Text('PV\n(${_niveau.label})'), numeric: true),
                            const DataColumn(label: Text('Vendu'), numeric: true),
                            const DataColumn(label: Text('Restant'), numeric: true),
                            const DataColumn(label: Text('PV Total'), numeric: true),
                            const DataColumn(label: Text('Bénéfice'), numeric: true),
                            if (hasMultipleLots) const DataColumn(label: Text('Δ PA')),
                          ],
                          rows: lotRows,
                        );
                      }(),
                    ),

                    // Légende
                    if (hasMultipleLots) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.deepPurple.withAlpha(8), borderRadius: BorderRadius.circular(8)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(Icons.arrow_upward_rounded, size: 12, color: kDangerColor),
                            Text(' PA augmenté  ', style: GoogleFonts.inter(fontSize: 9, color: kTextSecondary)),
                            Icon(Icons.arrow_downward_rounded, size: 12, color: kSuccessColor),
                            Text(' PA diminué', style: GoogleFonts.inter(fontSize: 9, color: kTextSecondary)),
                          ]),
                        ]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: kPaddingM),

                // ── RÉSUMÉ FINANCIER GLOBAL (tous lots) ──
                _buildCard(
                  title: hasMultipleLots ? 'Résumé financier (tous lots)' : 'Résumé financier',
                  icon: Icons.account_balance_wallet_rounded,
                  color: kSuccessColor,
                  children: [
                    ...() {
                      double totalPA = 0, totalPV = 0, totalBen = 0;
                      int totalQte = 0;
                      for (final lot in tousLots) {
                        final m = lot.medicament;
                        final pa = _paNiv(m);
                        final pv = _pvNiv(m);
                        final qte = _qteNiv(m);
                        totalPA += pa * qte;
                        totalPV += pv * qte;
                        totalBen += (pv - pa) * qte;
                        totalQte += qte;
                      }
                      return [
                        _finRow('Quantité totale', '$totalQte ${_niveau.label}s', kPrimaryColor),
                        _finRow('PA Total (stock)', formatCurrency(totalPA), Colors.orange.shade700),
                        _finRow('PV Total (stock)', formatCurrency(totalPV), kPrimaryColor),
                        _finRow('Bénéfice Total', formatCurrency(totalBen), totalBen >= 0 ? kSuccessColor : kDangerColor, bold: true),
                        if (hasMultipleLots) ...[
                          const Divider(height: 20),
                          _finRow('PA moyen / ${_niveau.label}', formatCurrency(totalQte > 0 ? totalPA / totalQte : 0), Colors.orange.shade700),
                          _finRow('PV moyen / ${_niveau.label}', formatCurrency(totalQte > 0 ? totalPV / totalQte : 0), kPrimaryColor),
                        ],
                      ];
                    }(),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Widgets helpers ──

  Widget _buildCard({required String title, required IconData icon, required Color color, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kPaddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(30)),
        boxShadow: [BoxShadow(color: color.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: kFontSizeM, fontWeight: FontWeight.w700, color: color))),
          ]),
          const SizedBox(height: kPaddingM),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: GoogleFonts.inter(fontSize: kFontSizeS, color: kTextSecondary, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w600, color: kTextPrimary))),
        ],
      ),
    );
  }

  Widget _finRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: kFontSizeS, color: kTextSecondary, fontWeight: FontWeight.w500))),
          Text(value, style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Info sur un lot pour le regroupement
class _LotInfo {
  final Medicament medicament;
  final int index;
  const _LotInfo({required this.medicament, required this.index});
}
