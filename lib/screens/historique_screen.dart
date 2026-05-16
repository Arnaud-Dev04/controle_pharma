/// Écran d'historique des contrôles
///
/// Affiche la liste de tous les contrôles passés avec :
/// - Titre et date
/// - Nombre de médicaments
/// - Total bénéfice et nombre d'écarts
/// - Actions : ouvrir détails, charger, supprimer
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/controle.dart';
import '../models/medicament.dart';
import '../providers/controle_provider.dart';
import '../providers/pharmacie_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'controle_simplifie_screen.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  @override
  void initState() {
    super.initState();
    // Recharger l'historique à chaque ouverture pour avoir les données à jour
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ControleProvider>().chargerHistorique();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pharmacieNom = context
        .watch<PharmacieProvider>()
        .pharmacieSelectionnee
        ?.nom ?? 'Pharmacie';

    return Scaffold(
      appBar: AppBar(
        title: Text('Historique — $pharmacieNom'),
      ),
      body: Consumer<ControleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.controles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: kPaddingM),
                  Text(
                    'Aucun historique',
                    style: GoogleFonts.inter(
                      fontSize: kFontSizeXL,
                      fontWeight: FontWeight.w600,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: kPaddingS),
                  Text(
                    'Les contrôles terminés apparaîtront ici',
                    style: GoogleFonts.inter(
                      fontSize: kFontSizeM,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(kPaddingM),
            itemCount: provider.controles.length,
            itemBuilder: (context, index) {
              final controle = provider.controles[index];
              final isActuel = provider.controleActuel?.id == controle.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: kPaddingS),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isActuel
                        ? const BorderSide(color: kPrimaryColor, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showControleDetails(context, controle, provider),
                    child: Padding(
                      padding: const EdgeInsets.all(kPaddingS),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ligne 1 : Titre + Statut
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: controle.statut == 'termine'
                                      ? kSuccessColor.withAlpha(20)
                                      : kPrimaryColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  controle.statut == 'termine'
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_rounded,
                                  color: controle.statut == 'termine'
                                      ? kSuccessColor
                                      : kPrimaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controle.titre,
                                      style: GoogleFonts.inter(
                                        fontSize: kFontSizeL,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      formatDateTime(controle.dateCreation),
                                      style: GoogleFonts.inter(
                                        fontSize: kFontSizeS,
                                        color: kTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Badge actuel
                              if (isActuel)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'ACTUEL',
                                    style: GoogleFonts.inter(
                                      fontSize: kFontSizeXS,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              // Bouton supprimer
                              if (!isActuel)
                                IconButton(
                                  onPressed: () => _confirmDelete(
                                      context, provider, controle.id!),
                                  icon: const Icon(
                                      Icons.delete_outline_rounded),
                                  color: kDangerColor,
                                  iconSize: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Ligne 2 : Métriques
                          Row(
                            children: [
                              _buildMetric(
                                Icons.medication_rounded,
                                '${controle.nombreMedicaments}',
                                'Méd.',
                                kPrimaryColor,
                              ),
                              _buildMetric(
                                Icons.trending_up_rounded,
                                formatCurrency(controle.totalBenefice),
                                'Bénéfice',
                                controle.totalBenefice >= 0
                                    ? kSuccessColor
                                    : kDangerColor,
                              ),
                              _buildMetric(
                                Icons.warning_amber_rounded,
                                '${controle.nombreEcarts}',
                                'Écarts',
                                controle.nombreEcarts > 0
                                    ? kDangerColor
                                    : kSuccessColor,
                              ),
                              _buildMetric(
                                Icons.pie_chart_rounded,
                                '${(controle.progressionControle * 100).toInt()}%',
                                'Ctrl',
                                kPrimaryColor,
                              ),
                            ],
                          ),
                          // Bouton Quitter l'inventaire
                          if (isActuel) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Quitter l\'inventaire'),
                                      content: const Text('Voulez-vous terminer cet inventaire ? Il sera sauvegardé dans l\'historique.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Annuler'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await provider.terminerControle();
                                            if (ctx.mounted) Navigator.pop(ctx);
                                            if (context.mounted) setState(() {});
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: kDangerColor),
                                          child: const Text('Terminer', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.exit_to_app_rounded, size: 16),
                                label: Text('Quitter l\'inventaire', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kDangerColor,
                                  side: const BorderSide(color: kDangerColor),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetric(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: kFontSizeS,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: kFontSizeXS,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📐 CALCULS PAR NIVEAU DE CONDITIONNEMENT
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

  int _qteVendueNiveau(Medicament med, NiveauControle niveau) {
    final div = _unitesParNiveau(med, niveau);
    return div > 0 ? med.quantiteVendue ~/ div : med.quantiteVendue;
  }

  int _qteRestanteNiveau(Medicament med, NiveauControle niveau) {
    if (med.stockReel != null) {
      final div = _unitesParNiveau(med, niveau);
      return div > 0 ? med.stockReel! ~/ div : med.stockReel!;
    }
    return _stockInitialNiveau(med, niveau) - _qteVendueNiveau(med, niveau);
  }

  double _prixVenteNiveau(Medicament med, NiveauControle niveau) {
    return switch (niveau) {
      NiveauControle.comprime  => med.bestPrixVente,
      NiveauControle.plaquette => med.prixVentePlaquette ?? med.bestPrixVente * (med.unitesParPlaquette ?? 1),
      NiveauControle.boite     => med.prixVenteBoite ?? med.bestPrixVente * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1),
      NiveauControle.carton    => med.prixVenteCarton ?? med.bestPrixVente * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1),
    };
  }

  double _prixAchatNiveau(Medicament med, NiveauControle niveau) {
    return switch (niveau) {
      NiveauControle.comprime  => med.bestPrixAchat,
      NiveauControle.plaquette => med.prixAchatPlaquette ?? med.bestPrixAchat * (med.unitesParPlaquette ?? 1),
      NiveauControle.boite     => med.prixAchatBoite ?? med.bestPrixAchat * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1),
      NiveauControle.carton    => med.prixAchatCarton ?? med.bestPrixAchat * (med.unitesParPlaquette ?? 1) * (med.plaquettesParBoite ?? 1) * (med.boitesParCarton ?? 1),
    };
  }

  // ============================================================
  // 📋 DÉTAILS DU CONTRÔLE — Dialog
  // ============================================================

  void _showControleDetails(
      BuildContext context, Controle controle, ControleProvider provider) {
    final meds = controle.medicaments;
    NiveauControle niveau = NiveauControle.comprime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            // Calculs totaux au niveau choisi
            double totalPA = 0;
            double totalPV = 0;
            double totalBenefice = 0;
            int totalVendus = 0;
            int totalRestants = 0;

            for (final m in meds) {
              final vendus = _qteVendueNiveau(m, niveau);
              final restant = _qteRestanteNiveau(m, niveau);
              final pa = _prixAchatNiveau(m, niveau);
              final pv = _prixVenteNiveau(m, niveau);

              totalVendus += vendus;
              totalRestants += restant;
              totalPA += pa * vendus;
              totalPV += pv * vendus;
              totalBenefice += (pv - pa) * vendus;
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kPaddingS, kPaddingS, kPaddingS, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [kPrimaryColor, kPrimaryLightColor],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.fact_check_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controle.titre,
                                    style: GoogleFonts.inter(
                                      fontSize: kFontSizeL,
                                      fontWeight: FontWeight.w700,
                                      color: kPrimaryDarkColor,
                                    ),
                                  ),
                                  Text(
                                    formatDateTime(controle.dateCreation),
                                    style: GoogleFonts.inter(
                                      fontSize: kFontSizeXS,
                                      color: kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Bouton charger
                            TextButton.icon(
                              onPressed: () {
                                provider.chargerControle(controle);
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: Text('Charger',
                                  style: GoogleFonts.inter(
                                      fontSize: kFontSizeXS,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Sélecteur de niveau
                        Row(
                          children: NiveauControle.values.map((n) {
                            final selected = niveau == n;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(() => niveau = n),
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: n != NiveauControle.carton ? 4 : 0),
                                  padding: const EdgeInsets.symmetric(vertical: 5),
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
                                      Icon(n.icon,
                                          size: 14,
                                          color: selected
                                              ? Colors.white
                                              : kTextSecondary),
                                      const SizedBox(height: 2),
                                      Text(
                                        n.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 6),

                        // Résumé cartes
                        Row(
                          children: [
                            _buildSummaryChip(
                                Icons.shopping_cart_rounded,
                                '$totalVendus',
                                'Vendus',
                                Colors.orange.shade700),
                            const SizedBox(width: 6),
                            _buildSummaryChip(
                                Icons.inventory_rounded,
                                '$totalRestants',
                                'Restants',
                                kPrimaryColor),
                            const SizedBox(width: 6),
                            _buildSummaryChip(
                                Icons.trending_up_rounded,
                                formatCurrency(totalBenefice),
                                'Bénéfice',
                                totalBenefice >= 0
                                    ? kSuccessColor
                                    : kDangerColor),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),
                  const Divider(height: 1),

                  // Table header
                  Container(
                    color: kPrimaryColor.withAlpha(15),
                    padding: const EdgeInsets.symmetric(
                        horizontal: kPaddingS, vertical: 8),
                    child: Row(
                      children: [
                        _headerCell('Médicament', flex: 3),
                        _headerCell('Date', flex: 2),
                        _headerCell('Vendus', flex: 1),
                        _headerCell('Restant', flex: 1),
                        _headerCell('P.A\n(${niveau.label})', flex: 2),
                        _headerCell('P.V\n(${niveau.label})', flex: 2),
                        _headerCell('Bénéfice', flex: 2),
                      ],
                    ),
                  ),

                  // Liste des médicaments
                  Expanded(
                    child: meds.isEmpty
                        ? Center(
                            child: Text('Aucun médicament',
                                style: GoogleFonts.inter(color: kTextSecondary)),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: kPaddingXS),
                            itemCount: meds.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: kBorderColor),
                            itemBuilder: (context, i) {
                              final m = meds[i];
                              return _buildMedRowNiveau(m, niveau);
                            },
                          ),
                  ),

                  // Footer totaux
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: kPaddingS, vertical: kPaddingXS),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withAlpha(10),
                      border: Border(
                          top: BorderSide(
                              color: kPrimaryColor.withAlpha(50), width: 2)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          _buildTotalCard('Total PA',
                              formatCurrency(totalPA), Colors.orange.shade700),
                          const SizedBox(width: 6),
                          _buildTotalCard('Total PV',
                              formatCurrency(totalPV), kPrimaryColor),
                          const SizedBox(width: 6),
                          _buildTotalCard(
                              'Bénéfice',
                              formatCurrency(totalBenefice),
                              totalBenefice >= 0
                                  ? kSuccessColor
                                  : kDangerColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Ligne d'un médicament dans le détail (au niveau choisi)
  Widget _buildMedRowNiveau(Medicament m, NiveauControle niveau) {
    final vendus = _qteVendueNiveau(m, niveau);
    final restant = _qteRestanteNiveau(m, niveau);
    final pa = _prixAchatNiveau(m, niveau);
    final pv = _prixVenteNiveau(m, niveau);
    final benefice = (pv - pa) * vendus;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Nom
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.nom,
                  style: GoogleFonts.inter(
                    fontSize: kFontSizeS,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  m.forme.label,
                  style: GoogleFonts.inter(
                      fontSize: 9, color: kTextSecondary),
                ),
              ],
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                m.dateEntreeStock != null
                    ? '${m.dateEntreeStock!.day.toString().padLeft(2, '0')}/${m.dateEntreeStock!.month.toString().padLeft(2, '0')}/${m.dateEntreeStock!.year.toString().substring(2)}'
                    : '-',
                style: GoogleFonts.inter(fontSize: 9, color: kTextSecondary),
              ),
            ),
          ),
          // Vendus
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '$vendus',
                style: GoogleFonts.inter(
                  fontSize: kFontSizeS,
                  fontWeight: FontWeight.w600,
                  color: vendus > 0
                      ? Colors.orange.shade700
                      : kTextSecondary,
                ),
              ),
            ),
          ),
          // Restant
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '$restant',
                style: GoogleFonts.inter(
                  fontSize: kFontSizeS,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryColor,
                ),
              ),
            ),
          ),
          // PA
          Expanded(
            flex: 2,
            child: Text(
              formatNumber(pa),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          // PV
          Expanded(
            flex: 2,
            child: Text(
              formatNumber(pv),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kPrimaryColor,
              ),
            ),
          ),
          // Bénéfice
          Expanded(
            flex: 2,
            child: Text(
              formatNumber(benefice),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: benefice >= 0 ? kSuccessColor : kDangerColor,
              ),
            ),
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
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: kPrimaryDarkColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSummaryChip(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: kFontSizeS,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: color.withAlpha(180),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: kFontSizeS,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, ControleProvider provider, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: kDangerColor),
            const SizedBox(width: 8),
            Text('Supprimer',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer ce contrôle ?\nCette action est irréversible.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.supprimerControle(id);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: kDangerColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
