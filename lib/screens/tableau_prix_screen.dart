/// Tableau récapitulatif des prix par niveau de conditionnement
///
/// Affiche pour chaque médicament :
/// Prix Achat / Prix Vente / Bénéfice par Carton, Boîte, Plaquette/Flacon, Unité
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';


import '../providers/controle_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class TableauPrixScreen extends StatelessWidget {
  const TableauPrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau des prix')),
      body: Consumer<ControleProvider>(
        builder: (context, provider, _) {
          if (provider.medicaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_chart_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: kPaddingM),
                  Text('Aucune donnée', style: GoogleFonts.inter(fontSize: kFontSizeL, color: kTextSecondary)),
                ],
              ),
            );
          }

          // Déterminer si au moins un médicament a un niveau intermédiaire
          final hasAnyPlaquette = provider.medicaments.any((m) => m.forme.hasNiveauIntermediaire);

          return Column(
            children: [
              // En-tête totaux
              Container(
                padding: const EdgeInsets.all(kPaddingS),
                color: kPrimaryColor.withAlpha(10),
                child: Row(
                  children: [
                    Expanded(child: _chip('Médicaments', '${provider.medicaments.length}', kPrimaryColor)),
                    const SizedBox(width: 6),
                    Expanded(child: _chip('Bénéfice total', formatCurrency(provider.totalBenefice), kSuccessColor)),
                  ],
                ),
              ),
              // Tableau
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(kPrimaryColor.withAlpha(20)),
                      headingTextStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kPrimaryDarkColor),
                      dataTextStyle: GoogleFonts.inter(fontSize: 10, color: kTextPrimary),
                      columnSpacing: 12,
                      horizontalMargin: 8,
                      dataRowMinHeight: 40,
                      dataRowMaxHeight: 60,
                      columns: [
                        const DataColumn(label: Text('Nom')),
                        const DataColumn(label: Text(kLabelPACarton), numeric: true),
                        const DataColumn(label: Text(kLabelPABoite), numeric: true),
                        if (hasAnyPlaquette) const DataColumn(label: Text('PA Plq'), numeric: true),
                        const DataColumn(label: Text('PA Unit'), numeric: true),
                        const DataColumn(label: Text(kLabelPVCarton), numeric: true),
                        const DataColumn(label: Text(kLabelPVBoite), numeric: true),
                        if (hasAnyPlaquette) const DataColumn(label: Text('PV Plq'), numeric: true),
                        const DataColumn(label: Text('PV Unit'), numeric: true),
                        const DataColumn(label: Text(kLabelBenCarton), numeric: true),
                        const DataColumn(label: Text(kLabelBenBoite), numeric: true),
                        if (hasAnyPlaquette) const DataColumn(label: Text('Bén Plq'), numeric: true),
                        const DataColumn(label: Text('Bén Unit'), numeric: true),
                      ],
                      rows: provider.medicaments.map((m) {
                        final unitLabel = m.forme.uniteLabel;
                        return DataRow(cells: [
                          DataCell(SizedBox(width: 100, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(m.nom, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                              Text('${m.forme.emoji} $unitLabel', style: GoogleFonts.inter(fontSize: 8, color: kTextSecondary)),
                            ],
                          ))),
                          _numCell(m.prixAchatCarton),
                          _numCell(m.prixAchatBoite),
                          if (hasAnyPlaquette) _numCell(m.forme.hasNiveauIntermediaire ? m.prixAchatPlaquette : null),
                          _numCell(m.prixUnitaire),
                          _numCell(m.prixVenteCarton),
                          _numCell(m.prixVenteBoite),
                          if (hasAnyPlaquette) _numCell(m.forme.hasNiveauIntermediaire ? m.prixVentePlaquette : null),
                          _numCell(m.prixVente),
                          _benCell(m.beneficeParCarton),
                          _benCell(m.beneficeParBoite),
                          if (hasAnyPlaquette) _benCell(m.forme.hasNiveauIntermediaire ? m.beneficeParPlaquette : 0),
                          _benCell(m.beneficeParComprime),
                        ]);
                      }).toList(),
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

  DataCell _numCell(double? v) {
    return DataCell(Text(
      v != null ? formatNumber(v) : '-',
      style: GoogleFonts.inter(color: v == null ? kTextSecondary : kTextPrimary),
    ));
  }

  DataCell _benCell(double v) {
    final color = v >= 0 ? kSuccessColor : kDangerColor;
    return DataCell(Text(
      formatNumber(v),
      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: color),
    ));
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: color)),
          Text(value, style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
