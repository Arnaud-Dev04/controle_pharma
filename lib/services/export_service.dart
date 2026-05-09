/// Service d'export PDF pour les rapports de contrôle
///
/// Génère un rapport PDF professionnel contenant :
/// - En-tête avec titre et date
/// - Tableau complet des médicaments
/// - Totaux (PV total, bénéfice, écarts)
/// - Code couleur pour les écarts
library;

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/controle.dart';
import '../models/medicament.dart';

class ExportService {
  // ============================================================
  // 📄 GÉNÉRATION PDF
  // ============================================================

  /// Génère un rapport PDF complet pour un contrôle
  static Future<Uint8List> genererRapportPDF(Controle controle) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final numberFormat = NumberFormat('#,##0', 'fr_FR');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(controle, dateFormat),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Résumé
          _buildResume(controle, numberFormat),
          pw.SizedBox(height: 20),

          // Tableau des médicaments
          _buildTableau(controle.medicaments, numberFormat),
          pw.SizedBox(height: 20),

          // Totaux
          _buildTotaux(controle, numberFormat),

          // Médicaments avec écart
          if (controle.nombreEcarts > 0) ...[
            pw.SizedBox(height: 20),
            _buildAlertesEcarts(controle.medicaments, numberFormat),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Affiche le dialogue d'impression/partage
  static Future<void> imprimerRapport(Controle controle) async {
    final pdfData = await genererRapportPDF(controle);
    await Printing.layoutPdf(
      onLayout: (_) => pdfData,
      name: 'Rapport_${controle.titre.replaceAll(' ', '_')}',
    );
  }

  /// Partage le PDF
  static Future<void> partagerRapport(Controle controle) async {
    final pdfData = await genererRapportPDF(controle);
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Rapport_${controle.titre.replaceAll(' ', '_')}.pdf',
    );
  }

  // ============================================================
  // 🏗️ COMPOSANTS DU PDF
  // ============================================================

  /// En-tête du rapport
  static pw.Widget _buildHeader(
      Controle controle, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CONTRÔLE PHARMA',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'Rapport d\'audit pharmaceutique',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                controle.titre,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Créé le: ${dateFormat.format(controle.dateCreation)}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Statut: ${controle.statut == 'termine' ? 'Terminé ✓' : 'En cours'}',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: controle.statut == 'termine'
                      ? PdfColors.green700
                      : PdfColors.orange700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pied de page
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Contrôle Pharma - Rapport généré automatiquement',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Section résumé
  static pw.Widget _buildResume(
      Controle controle, NumberFormat numberFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildResumeItem(
            'Médicaments',
            '${controle.nombreMedicaments}',
            PdfColors.blue800,
          ),
          _buildResumeItem(
            'Contrôlés',
            '${controle.nombreControles}/${controle.nombreMedicaments}',
            PdfColors.blue800,
          ),
          _buildResumeItem(
            'Écarts',
            '${controle.nombreEcarts}',
            controle.nombreEcarts > 0
                ? PdfColors.red700
                : PdfColors.green700,
          ),
          _buildResumeItem(
            'Progression',
            '${(controle.progressionControle * 100).toInt()}%',
            PdfColors.blue800,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildResumeItem(
      String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Tableau des médicaments
  static pw.Widget _buildTableau(
      List<Medicament> medicaments, NumberFormat numberFormat) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellHeight: 24,
      headerHeight: 28,
      headers: [
        'Nom',
        'Q.I',
        'P.U',
        'P.V',
        'Q.Vendue',
        'PV Total',
        'Q.Rest',
        'Stock R.',
        'Écart',
        'Bénéfice',
      ],
      data: medicaments.map((m) {
        return [
          m.nom,
          '${m.quantiteInitiale}',
          numberFormat.format(m.prixUnitaire),
          numberFormat.format(m.prixVente),
          '${m.quantiteVendue}',
          numberFormat.format(m.pvTotal),
          '${m.quantiteRestante}',
          m.stockReel?.toString() ?? '-',
          m.ecart != null
              ? (m.ecart! > 0 ? '+${m.ecart}' : '${m.ecart}')
              : '-',
          numberFormat.format(m.benefice),
        ];
      }).toList(),
    );
  }

  /// Ligne de totaux
  static pw.Widget _buildTotaux(
      Controle controle, NumberFormat numberFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildTotalItem(
            'Total PV',
            '${numberFormat.format(controle.totalPVTotal)} FBu',
            PdfColors.blue800,
          ),
          _buildTotalItem(
            'Total Bénéfice',
            '${numberFormat.format(controle.totalBenefice)} FBu',
            controle.totalBenefice >= 0
                ? PdfColors.green700
                : PdfColors.red700,
          ),
          _buildTotalItem(
            'Valeur Écarts',
            '${numberFormat.format(controle.totalValeurEcarts.abs())} FBu',
            controle.totalValeurEcarts < 0
                ? PdfColors.red700
                : PdfColors.green700,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalItem(
      String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Section alertes écarts
  static pw.Widget _buildAlertesEcarts(
      List<Medicament> medicaments, NumberFormat numberFormat) {
    final medsAvecEcart =
        medicaments.where((m) => m.ecart != null && m.ecart != 0).toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.red200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '⚠ ALERTES - Écarts détectés (${medsAvecEcart.length})',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red700,
            ),
          ),
          pw.SizedBox(height: 8),
          ...medsAvecEcart.map((m) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  children: [
                    pw.Text(
                      '• ${m.nom}: ',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'écart de ${m.ecart} unités ',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.Text(
                      '(valeur: ${numberFormat.format(m.valeurEcart!.abs())} FBu)',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
