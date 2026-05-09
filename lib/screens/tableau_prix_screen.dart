/// Tableau récapitulatif des prix par niveau de conditionnement
///
/// Affiche pour chaque médicament :
/// Prix Achat / Prix Vente / Bénéfice par Carton, Boîte, Plaquette, Unité
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
                      columns: const [
                        DataColumn(label: Text('Nom')),
                        DataColumn(label: Text(kLabelPACarton), numeric: true),
                        DataColumn(label: Text(kLabelPABoite), numeric: true),
                        DataColumn(label: Text(kLabelPAPlaquette), numeric: true),
                        DataColumn(label: Text(kLabelPAUnite), numeric: true),
                        DataColumn(label: Text(kLabelPVCarton), numeric: true),
                        DataColumn(label: Text(kLabelPVBoite), numeric: true),
                        DataColumn(label: Text(kLabelPVPlaquette), numeric: true),
                        DataColumn(label: Text(kLabelPVUnite), numeric: true),
                        DataColumn(label: Text(kLabelBenCarton), numeric: true),
                        DataColumn(label: Text(kLabelBenBoite), numeric: true),
                        DataColumn(label: Text(kLabelBenPlaquette), numeric: true),
                        DataColumn(label: Text(kLabelBenUnite), numeric: true),
                      ],
                      rows: provider.medicaments.map((m) {
                        return DataRow(cells: [
                          DataCell(SizedBox(width: 100, child: Text(m.nom, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w500)))),
                          _numCell(m.prixAchatCarton),
                          _numCell(m.prixAchatBoite),
                          _numCell(m.prixAchatPlaquette),
                          _numCell(m.prixUnitaire),
                          _numCell(m.prixVenteCarton),
                          _numCell(m.prixVenteBoite),
                          _numCell(m.prixVentePlaquette),
                          _numCell(m.prixVente),
                          _benCell(m.beneficeParCarton),
                          _benCell(m.beneficeParBoite),
                          _benCell(m.beneficeParPlaquette),
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
