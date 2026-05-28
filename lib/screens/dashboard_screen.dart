/// Écran principal - Dashboard
///
/// Intègre : recherche, export PDF, statistiques, mode sombre, historique
/// Désormais scopé à une pharmacie spécifique.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pharmacie.dart';
import '../providers/controle_provider.dart';
import '../providers/theme_provider.dart';
import '../services/export_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'medicament_form_screen.dart';
import 'vente_screen.dart';
import 'tableau_controle_screen.dart';
import 'historique_screen.dart';
import 'pharmacie_form_screen.dart';
import 'controle_simplifie_screen.dart';
import 'liste_medicaments_screen.dart';

class DashboardScreen extends StatefulWidget {
  /// Pharmacie à laquelle ce dashboard est scopé
  final Pharmacie pharmacie;

  const DashboardScreen({super.key, required this.pharmacie});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;


  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<ControleProvider>(
        builder: (context, provider, _) {


          return FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // ============================================================
                // 🔝 APP BAR
                // ============================================================
                SliverAppBar(
                  expandedHeight: 190,
                  floating: false,
                  pinned: true,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    tooltip: 'Changer de pharmacie',
                  ),
                  actions: [
                    // Bouton éditer la pharmacie
                    IconButton(
                      onPressed: () => _editerPharmacie(context),
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: 'Modifier la pharmacie',
                    ),
                    // Bouton mode sombre
                    IconButton(
                      onPressed: () =>
                          context.read<ThemeProvider>().toggleTheme(),
                      icon: Icon(isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded),
                      tooltip: isDark ? 'Mode clair' : 'Mode sombre',
                    ),
                    // Bouton historique
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoriqueScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.history_rounded),
                      tooltip: 'Historique',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.pharmacie.nom,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          kAppSubtitle,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w400,
                            fontSize: 9,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF0D253F),
                                  const Color(0xFF1A3A5C),
                                  const Color(0xFF264D73),
                                ]
                              : [
                                  kPrimaryDarkColor,
                                  kPrimaryColor,
                                  kPrimaryLightColor,
                                ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.local_pharmacy_rounded,
                              size: 44,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 6),
                            if (widget.pharmacie.adresse != null &&
                                widget.pharmacie.adresse!.isNotEmpty)
                              Text(
                                widget.pharmacie.adresse!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ============================================================
                // 📊 CONTENU PRINCIPAL
                // ============================================================
                if (provider.hasControleActuel) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(kPaddingM),
                      child: Column(
                        children: [
                          // Titre du contrôle
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_rounded,
                                  color: kPrimaryColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Inventaire',
                                  style: GoogleFonts.inter(
                                    fontSize: kFontSizeL,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${provider.medicaments.length} méd.',
                                  style: GoogleFonts.inter(
                                    fontSize: kFontSizeS,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'export':
                                      _exportPDF(context, provider);
                                      break;
                                    case 'partager':
                                      _partagerPDF(context, provider);
                                      break;
                                    case 'historique':
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoriqueScreen()));
                                      break;
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'export',
                                    child: Row(
                                      children: [
                                        Icon(Icons.picture_as_pdf_rounded, color: kDangerColor, size: 20),
                                        SizedBox(width: 8),
                                        Text('Exporter PDF'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'partager',
                                    child: Row(
                                      children: [
                                        Icon(Icons.share_rounded, color: kPrimaryColor, size: 20),
                                        SizedBox(width: 8),
                                        Text('Partager PDF'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'historique',
                                    child: Row(
                                      children: [
                                        Icon(Icons.history_rounded, color: kPrimaryColor, size: 20),
                                        SizedBox(width: 8),
                                        Text('Historique'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: kPaddingM),

                          // Cartes de résumé
                          Row(
                            children: [
                              _buildSummaryCard(
                                icon: Icons.monetization_on_rounded,
                                label: 'PV Total',
                                value:
                                    formatCurrency(provider.totalPVTotal),
                                color: kPrimaryColor,
                              ),
                              const SizedBox(width: kPaddingS),
                              _buildSummaryCard(
                                icon: Icons.trending_up_rounded,
                                label: 'Bénéfice',
                                value: formatCurrency(
                                    provider.totalBenefice),
                                color: kSuccessColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: kPaddingM),

                          // Boutons d'action — Ligne 1
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.edit_note_rounded,
                                  label: 'Ventes',
                                  color: Colors.orange.shade700,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const VenteScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: kPaddingS),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.fact_check_rounded,
                                  label: 'Contrôle',
                                  color: kSuccessColor,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ControleSimplifieScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: kPaddingS),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.table_chart_rounded,
                                  label: 'Tableau',
                                  color: kPrimaryDarkColor,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const TableauControleScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: kPaddingS),
                          // Boutons d'action — Ligne 2
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.list_alt_rounded,
                                  label: 'Liste',
                                  color: Colors.teal.shade600,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ListeMedicamentsScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: kPaddingS),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.history_rounded,
                                  label: 'Historique',
                                  color: Colors.deepPurple,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const HistoriqueScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: kPaddingM),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 80 + MediaQuery.of(context).viewPadding.bottom)),
                ] else ...[
                  // Chargement — le contrôle est auto-créé
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: kPaddingM),
                          Text(
                            'Chargement de l\'inventaire...',
                            style: GoogleFonts.inter(
                              fontSize: kFontSizeM,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<ControleProvider>(
        builder: (context, provider, _) {
          if (!provider.hasControleActuel) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MedicamentFormScreen()),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Médicament'),
          );
        },
      ),
    );
  }

  // ============================================================
  // 🧩 WIDGETS
  // ============================================================

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(kPaddingM),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: kFontSizeXS,
                color: color.withAlpha(180),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: kFontSizeM,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _exportPDF(
      BuildContext context, ControleProvider provider) async {
    if (provider.controleActuel == null) return;
    try {
      await ExportService.imprimerRapport(provider.controleActuel!);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur export: $e'),
            backgroundColor: kDangerColor,
          ),
        );
      }
    }
  }

  void _partagerPDF(
      BuildContext context, ControleProvider provider) async {
    if (provider.controleActuel == null) return;
    try {
      await ExportService.partagerRapport(provider.controleActuel!);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur partage: $e'),
            backgroundColor: kDangerColor,
          ),
        );
      }
    }
  }

  void _editerPharmacie(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PharmacieFormScreen(pharmacie: widget.pharmacie),
      ),
    );
  }


  // ============================================================
  // 📦 RÉAPPROVISIONNEMENT
  // ============================================================



}
