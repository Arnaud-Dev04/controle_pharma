/// Écran Liste des Médicaments
///
/// Affiche la liste complète avec sélecteur de niveau.
/// Indique la source des prix (direct ou calculé).
/// Inclut PV Total.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/medicament.dart';
import '../providers/controle_provider.dart';
import '../screens/controle_simplifie_screen.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'detail_medicament_screen.dart';
import 'medicament_form_screen.dart';

class ListeMedicamentsScreen extends StatefulWidget {
  const ListeMedicamentsScreen({super.key});

  @override
  State<ListeMedicamentsScreen> createState() => _ListeMedicamentsScreenState();
}

class _ListeMedicamentsScreenState extends State<ListeMedicamentsScreen> {
  String _searchQuery = '';
  final Map<int, NiveauControle> _niveaux = {};

  NiveauControle _getNiveau(int realIndex, Medicament med) {
    _niveaux[realIndex] ??= NiveauControle.comprime;
    return _niveaux[realIndex]!;
  }

  // ── Prix avec source ──
  /// Retourne (prix, estDirect) pour PA au niveau sélectionné
  (double, bool) _paNiveauSrc(Medicament med, NiveauControle niveau) {
    final u = med.unitesParPlaquette ?? 1;
    final p = med.plaquettesParBoite ?? 1;
    final b = med.boitesParCarton ?? 1;
    return switch (niveau) {
      NiveauControle.comprime  => (med.prixUnitaire > 0 ? med.prixUnitaire : _bestPA(med), med.prixUnitaire > 0),
      NiveauControle.plaquette => (med.prixAchatPlaquette ?? _bestPA(med) * u, med.prixAchatPlaquette != null),
      NiveauControle.boite     => (med.prixAchatBoite ?? _bestPA(med) * u * p, med.prixAchatBoite != null),
      NiveauControle.carton    => (med.prixAchatCarton ?? _bestPA(med) * u * p * b, med.prixAchatCarton != null),
    };
  }

  (double, bool) _pvNiveauSrc(Medicament med, NiveauControle niveau) {
    final u = med.unitesParPlaquette ?? 1;
    final p = med.plaquettesParBoite ?? 1;
    final b = med.boitesParCarton ?? 1;
    return switch (niveau) {
      NiveauControle.comprime  => (med.prixVente > 0 ? med.prixVente : _bestPV(med), med.prixVente > 0),
      NiveauControle.plaquette => (med.prixVentePlaquette ?? _bestPV(med) * u, med.prixVentePlaquette != null),
      NiveauControle.boite     => (med.prixVenteBoite ?? _bestPV(med) * u * p, med.prixVenteBoite != null),
      NiveauControle.carton    => (med.prixVenteCarton ?? _bestPV(med) * u * p * b, med.prixVenteCarton != null),
    };
  }

  /// Quantité au niveau choisi — utilise stockReel si disponible
  /// (= stock mis à jour après contrôle), sinon quantiteInitiale
  int _qteNiveau(Medicament med, NiveauControle niveau) {
    final u = med.unitesParPlaquette ?? 1;
    final p = med.plaquettesParBoite ?? 1;
    final b = med.boitesParCarton ?? 1;
    final div = switch (niveau) {
      NiveauControle.comprime  => 1,
      NiveauControle.plaquette => u,
      NiveauControle.boite     => u * p,
      NiveauControle.carton    => u * p * b,
    };
    final stock = med.stockReel ?? med.quantiteInitiale;
    return div > 0 ? stock ~/ div : 0;
  }


  double _bestPA(Medicament med) {
    if (med.prixUnitaire > 0) return med.prixUnitaire;
    if ((med.prixAchatPlaquette ?? 0) > 0) return med.prixAchatPlaquette! / (med.unitesParPlaquette ?? 1);
    if ((med.prixAchatBoite ?? 0) > 0) return med.prixAchatBoite! / ((med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1));
    if ((med.prixAchatCarton ?? 0) > 0) return med.prixAchatCarton! / ((med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1));
    return 0;
  }

  double _bestPV(Medicament med) {
    if (med.prixVente > 0) return med.prixVente;
    if ((med.prixVentePlaquette ?? 0) > 0) return med.prixVentePlaquette! / (med.unitesParPlaquette ?? 1);
    if ((med.prixVenteBoite ?? 0) > 0) return med.prixVenteBoite! / ((med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1));
    if ((med.prixVenteCarton ?? 0) > 0) return med.prixVenteCarton! / ((med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1));
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des médicaments'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicamentFormScreen())),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Ajouter',
          ),
        ],
      ),
      body: Consumer<ControleProvider>(
        builder: (context, provider, _) {
          final meds = _searchQuery.isEmpty
              ? provider.medicaments
              : provider.medicaments.where((m) => m.nom.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          if (provider.medicaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_liquid_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: kPaddingM),
                  Text('Aucun médicament', style: GoogleFonts.inter(fontSize: kFontSizeL, color: kTextSecondary)),
                  const SizedBox(height: kPaddingS),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicamentFormScreen())),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter un médicament'),
                  ),
                ],
              ),
            );
          }

          // Totaux
          double totalPA = 0, totalPV = 0, totalPVTotal = 0, totalBen = 0;
          for (int i = 0; i < meds.length; i++) {
            final m = meds[i];
            final realIdx = provider.medicaments.indexOf(m);
            final niv = _getNiveau(realIdx, m);
            final (pa, _) = _paNiveauSrc(m, niv);
            final (pv, _) = _pvNiveauSrc(m, niv);
            final qte = _qteNiveau(m, niv);
            totalPA += pa * qte;
            totalPV += pv * qte;
            totalPVTotal += pv * qte;
            totalBen += (pv - pa) * qte;
          }

          return Column(
            children: [
              // Recherche
              if (provider.medicaments.length > 3)
                Padding(
                  padding: const EdgeInsets.all(kPaddingS),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true, fillColor: kPrimaryColor.withAlpha(8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorderColor)),
                    ),
                    style: GoogleFonts.inter(fontSize: kFontSizeS),
                  ),
                ),

              // Légende source prix
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: kPaddingS, vertical: 4),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 12, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text('Prix direct', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: kTextPrimary)),
                    const SizedBox(width: 4),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('Prix calculé', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: kTextPrimary)),
                    const SizedBox(width: 4),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.orange.shade600, shape: BoxShape.circle)),
                  ],
                ),
              ),

              // Chips totaux
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: kPaddingS, vertical: 6),
                decoration: BoxDecoration(color: kPrimaryColor.withAlpha(8), border: Border(bottom: BorderSide(color: kBorderColor))),
                child: Row(
                  children: [
                    _chip('${meds.length}', kPrimaryColor),
                    const SizedBox(width: 4),
                    _chip('PA: ${formatCurrency(totalPA)}', Colors.orange.shade700),
                    const SizedBox(width: 4),
                    _chip('PV.T: ${formatCurrency(totalPVTotal)}', kPrimaryColor),
                    const SizedBox(width: 4),
                    Expanded(child: _chip('B: ${formatCurrency(totalBen)}', totalBen >= 0 ? kSuccessColor : kDangerColor)),
                  ],
                ),
              ),

              // Tableau
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 32,
                    ),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(kPrimaryColor.withAlpha(20)),
                      headingTextStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kPrimaryDarkColor),
                      dataTextStyle: GoogleFonts.inter(fontSize: 10, color: kTextPrimary),
                      columnSpacing: 12,
                      horizontalMargin: 8,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 72,
                      columns: const [
                        DataColumn(label: Text('N°')),
                        DataColumn(label: Text('Nom')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Stock'), numeric: true),
                        DataColumn(label: Text('P.A'), numeric: true),
                        DataColumn(label: Text('P.V'), numeric: true),
                        DataColumn(label: Text('PV Total'), numeric: true),
                        DataColumn(label: Text('Bénéfice'), numeric: true),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        ...() {
                          final rows = <DataRow>[];

                          // Grouper les médicaments par nom
                          final grouped = <String, List<int>>{};
                          final groupOrder = <String>[];
                          for (int i = 0; i < meds.length; i++) {
                            final key = meds[i].nom.toLowerCase();
                            if (!grouped.containsKey(key)) {
                              grouped[key] = [];
                              groupOrder.add(key);
                            }
                            grouped[key]!.add(i);
                          }

                          int num = 0;
                          for (final groupKey in groupOrder) {
                            final indices = grouped[groupKey]!;
                            final firstMed = meds[indices.first];
                            final hasMultipleLots = indices.length > 1;
                            num++;

                            // Calculer les totaux du groupe
                            double groupPVT = 0, groupBen = 0;
                            int groupQte = 0;
                            for (final idx in indices) {
                              final m = meds[idx];
                              final ri = provider.medicaments.indexOf(m);
                              final niv = _getNiveau(ri, m);
                              final (pa, _) = _paNiveauSrc(m, niv);
                              final (pv, _) = _pvNiveauSrc(m, niv);
                              final qte = _qteNiveau(m, niv);
                              groupQte += qte;

                              groupPVT += pv * qte;
                              groupBen += (pv - pa) * qte;
                            }

                            if (hasMultipleLots) {
                              // Ligne d'en-tête du groupe
                              final realIndex = provider.medicaments.indexOf(firstMed);
                              rows.add(DataRow(
                                color: WidgetStateProperty.all(kPrimaryColor.withAlpha(15)),
                                cells: [
                                  DataCell(Text('$num', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: kPrimaryColor))),
                                  DataCell(
                                    SizedBox(width: 110, child: Row(children: [
                                      Expanded(child: Text(firstMed.nom, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: kPrimaryDarkColor))),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(color: Colors.deepPurple.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                                        child: Text('${indices.length} lots', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
                                      ),
                                    ])),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailMedicamentScreen(medicament: firstMed, index: realIndex))),
                                  ),
                                  const DataCell(Text('')),
                                  DataCell(Text('$groupQte', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                                  const DataCell(Text('')),
                                  const DataCell(Text('')),
                                  DataCell(Text(formatNumber(groupPVT), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.orange.shade800))),
                                  DataCell(Text(formatNumber(groupBen), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: groupBen >= 0 ? kSuccessColor : kDangerColor))),
                                  const DataCell(Text('')),
                                ],
                              ));

                              // Lignes individuelles des lots
                              for (int j = 0; j < indices.length; j++) {
                                final med = meds[indices[j]];
                                final realIndex = provider.medicaments.indexOf(med);
                                final niv = _getNiveau(realIndex, med);
                                final (pa, paDirect) = _paNiveauSrc(med, niv);
                                final (pv, pvDirect) = _pvNiveauSrc(med, niv);
                                final qte = _qteNiveau(med, niv);
                                final pvTotal = pv * qte;
                                final ben = (pv - pa) * qte;

                                rows.add(DataRow(
                                  color: WidgetStateProperty.all(Colors.deepPurple.withAlpha(6)),
                                  cells: [
                                    const DataCell(Text('')),
                                    DataCell(
                                      SizedBox(width: 110, child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(children: [
                                            Text('  ↳ ', style: GoogleFonts.inter(fontSize: 10, color: Colors.deepPurple)),
                                            Expanded(child: Text('Lot ${j + 1}', overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.deepPurple))),
                                          ]),
                                          Wrap(spacing: 2, children: NiveauControle.values.where((n) => n.estApplicable(med.forme)).map((n) {
                                            final sel = niv == n;
                                            return GestureDetector(
                                              onTap: () => setState(() => _niveaux[realIndex] = n),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                                                decoration: BoxDecoration(
                                                  color: sel ? kPrimaryColor : Colors.grey.withAlpha(20),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: Text(n.labelPour(med.forme), style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w600, color: sel ? Colors.white : kTextSecondary)),
                                              ),
                                            );
                                          }).toList()),
                                        ],
                                      )),
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailMedicamentScreen(medicament: med, index: realIndex))),
                                    ),
                                    DataCell(Text(
                                      med.dateEntreeStock != null ? '${med.dateEntreeStock!.day.toString().padLeft(2, '0')}/${med.dateEntreeStock!.month.toString().padLeft(2, '0')}' : '-',
                                      style: GoogleFonts.inter(fontSize: 9, color: kTextSecondary),
                                    )),
                                    DataCell(Text('$qte')),
                                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                      Text(formatNumber(pa), style: GoogleFonts.inter(fontSize: 10)),
                                      const SizedBox(width: 3),
                                      Container(width: 6, height: 6, decoration: BoxDecoration(color: paDirect ? kPrimaryColor : Colors.orange.shade600, shape: BoxShape.circle)),
                                    ])),
                                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                      Text(formatNumber(pv), style: GoogleFonts.inter(fontSize: 10)),
                                      const SizedBox(width: 3),
                                      Container(width: 6, height: 6, decoration: BoxDecoration(color: pvDirect ? kPrimaryColor : Colors.orange.shade600, shape: BoxShape.circle)),
                                    ])),
                                    DataCell(Text(formatNumber(pvTotal), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.orange.shade800))),
                                    DataCell(Text(formatNumber(ben), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ben >= 0 ? kSuccessColor : kDangerColor))),
                                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                      InkWell(onTap: () => _showReapproDialog(context, provider, med, realIndex), child: const Icon(Icons.add_box_rounded, size: 16, color: kPrimaryColor)),
                                      const SizedBox(width: 4),
                                      InkWell(onTap: () => _confirmDelete(context, provider, med, realIndex), child: const Icon(Icons.delete_outline_rounded, size: 16, color: kDangerColor)),
                                    ])),
                                  ],
                                ));
                              }
                            } else {
                              // Un seul lot — affichage normal
                              final med = firstMed;
                              final realIndex = provider.medicaments.indexOf(med);
                              final niv = _getNiveau(realIndex, med);
                              final (pa, paDirect) = _paNiveauSrc(med, niv);
                              final (pv, pvDirect) = _pvNiveauSrc(med, niv);
                              final qte = _qteNiveau(med, niv);
                              final pvTotal = pv * qte;
                              final ben = (pv - pa) * qte;

                              rows.add(DataRow(
                                cells: [
                                  DataCell(Text('$num', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: kPrimaryColor))),
                                  DataCell(
                                    SizedBox(width: 110, child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(med.nom, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: kPrimaryColor, decoration: TextDecoration.underline)),
                                        Wrap(spacing: 2, children: NiveauControle.values.where((n) => n.estApplicable(med.forme)).map((n) {
                                          final sel = niv == n;
                                          return GestureDetector(
                                            onTap: () => setState(() => _niveaux[realIndex] = n),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: sel ? kPrimaryColor : Colors.grey.withAlpha(20),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(n.labelPour(med.forme), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: sel ? Colors.white : kTextSecondary)),
                                            ),
                                          );
                                        }).toList()),
                                      ],
                                    )),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailMedicamentScreen(medicament: med, index: realIndex))),
                                  ),
                                  DataCell(Text(
                                    med.dateEntreeStock != null ? '${med.dateEntreeStock!.day.toString().padLeft(2, '0')}/${med.dateEntreeStock!.month.toString().padLeft(2, '0')}' : '-',
                                    style: GoogleFonts.inter(fontSize: 9, color: kTextSecondary),
                                  )),
                                  DataCell(Text('$qte')),
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text(formatNumber(pa), style: GoogleFonts.inter(fontSize: 10)),
                                    const SizedBox(width: 3),
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: paDirect ? kPrimaryColor : Colors.orange.shade600, shape: BoxShape.circle)),
                                  ])),
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text(formatNumber(pv), style: GoogleFonts.inter(fontSize: 10)),
                                    const SizedBox(width: 3),
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: pvDirect ? kPrimaryColor : Colors.orange.shade600, shape: BoxShape.circle)),
                                  ])),
                                  DataCell(Text(formatNumber(pvTotal), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.orange.shade800))),
                                  DataCell(Text(formatNumber(ben), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ben >= 0 ? kSuccessColor : kDangerColor))),
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    InkWell(onTap: () => _showReapproDialog(context, provider, med, realIndex), child: const Icon(Icons.add_box_rounded, size: 16, color: kPrimaryColor)),
                                    const SizedBox(width: 4),
                                    InkWell(onTap: () => _confirmDelete(context, provider, med, realIndex), child: const Icon(Icons.delete_outline_rounded, size: 16, color: kDangerColor)),
                                  ])),
                                ],
                              ));
                            }
                          }
                          return rows;
                        }(),
                        // Totaux
                        DataRow(
                          color: WidgetStateProperty.all(kPrimaryColor.withAlpha(12)),
                          cells: [
                            DataCell(Text('', style: GoogleFonts.inter())),
                            DataCell(Text('TOTAUX', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: kPrimaryDarkColor))),
                            const DataCell(Text('')),
                            const DataCell(Text('')),
                            DataCell(Text(formatNumber(totalPA), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.orange.shade800))),
                            DataCell(Text(formatNumber(totalPV), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: kPrimaryDarkColor))),
                            DataCell(Text(formatNumber(totalPVTotal), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.orange.shade800))),
                            DataCell(Text(formatNumber(totalBen), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: totalBen >= 0 ? kSuccessColor : kDangerColor))),
                            const DataCell(Text('')),
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


  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withAlpha(40))),
      child: Text(text, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  void _showReapproDialog(BuildContext context, ControleProvider provider, Medicament med, int index) {
    final qteCtrl = TextEditingController();
    final paCtrl = TextEditingController(text: _bestPA(med).toStringAsFixed(0));
    final pvCtrl = TextEditingController(text: _bestPV(med).toStringAsFixed(0));
    bool updatePrix = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [const Icon(Icons.add_box_rounded, color: kPrimaryColor), const SizedBox(width: 8), Expanded(child: Text('Réapprovisionner', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: kFontSizeL)))]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(med.nom, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: kPrimaryColor)),
            const SizedBox(height: 4),
            Text('Stock actuel : ${med.quantiteInitiale} unités', style: GoogleFonts.inter(fontSize: kFontSizeS, color: kTextSecondary)),
            const SizedBox(height: kPaddingM),
            TextFormField(controller: qteCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Quantité à ajouter', suffixText: 'unités', prefixIcon: Icon(Icons.add_rounded)), autofocus: true),
            const SizedBox(height: kPaddingS),
            CheckboxListTile(value: updatePrix, onChanged: (v) => setDialogState(() => updatePrix = v ?? false), title: Text('Mettre à jour les prix', style: GoogleFonts.inter(fontSize: kFontSizeS)), dense: true, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
            if (updatePrix) Row(children: [
              Expanded(child: TextFormField(controller: paCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'PA', suffixText: 'FBu', isDense: true))),
              const SizedBox(width: kPaddingS),
              Expanded(child: TextFormField(controller: pvCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'PV', suffixText: 'FBu', isDense: true))),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: GoogleFonts.inter(color: kTextSecondary))),
            ElevatedButton(onPressed: () {
              final qte = int.tryParse(qteCtrl.text);
              if (qte == null || qte <= 0) return;
              provider.reapprovisionner(index, quantiteAjoutee: qte, nouveauPA: updatePrix ? double.tryParse(paCtrl.text) : null, nouveauPV: updatePrix ? double.tryParse(pvCtrl.text) : null);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+$qte ajoutées à ${med.nom} ✓'), backgroundColor: kSuccessColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
            }, child: const Text('Confirmer')),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ControleProvider provider, Medicament med, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [const Icon(Icons.warning_rounded, color: kDangerColor), const SizedBox(width: 8), Text('Supprimer', style: GoogleFonts.inter(fontWeight: FontWeight.w600))]),
        content: Text('Supprimer "${med.nom}" ?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: GoogleFonts.inter(color: kTextSecondary))),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); provider.supprimerMedicament(index); }, style: ElevatedButton.styleFrom(backgroundColor: kDangerColor), child: const Text('Supprimer')),
        ],
      ),
    );
  }
}
