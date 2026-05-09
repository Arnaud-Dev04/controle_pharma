/// Écran de sélection de pharmacie
///
/// Point d'entrée de l'application.
/// Affiche la liste des pharmacies enregistrées et permet d'en sélectionner
/// une pour accéder à son dashboard de contrôle dédié.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pharmacie.dart';
import '../providers/pharmacie_provider.dart';
import '../providers/controle_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import 'dashboard_screen.dart';
import 'pharmacie_form_screen.dart';

class PharmacieSelectionScreen extends StatefulWidget {
  const PharmacieSelectionScreen({super.key});

  @override
  State<PharmacieSelectionScreen> createState() =>
      _PharmacieSelectionScreenState();
}

class _PharmacieSelectionScreenState extends State<PharmacieSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Couleurs attribuées cycliquement aux pharmacies
  static const List<Color> _pharmColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00838F),
    Color(0xFFC62828),
    Color(0xFF4527A0),
    Color(0xFF558B2F),
  ];

  Color _colorForIndex(int index) => _pharmColors[index % _pharmColors.length];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacieProvider>().chargerPharmacies();
    });
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // ============================================================
            // 🔝 APP BAR
            // ============================================================
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              actions: [
                IconButton(
                  onPressed: () =>
                      context.read<ThemeProvider>().toggleTheme(),
                  icon: Icon(isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded),
                  tooltip: isDark ? 'Mode clair' : 'Mode sombre',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  kAppName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
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
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sélectionnez votre pharmacie',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ============================================================
            // 📋 LISTE DES PHARMACIES
            // ============================================================
            Consumer<PharmacieProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (provider.pharmacies.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(kPaddingM),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pharmacie = provider.pharmacies[index];
                        final color = _colorForIndex(index);
                        return _buildPharmacieCard(
                          context,
                          pharmacie,
                          color,
                          index,
                        );
                      },
                      childCount: provider.pharmacies.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // ============================================================
      // ➕ FAB — Ajouter une pharmacie
      // ============================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ajouterPharmacie(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle pharmacie'),
      ),
    );
  }

  // ============================================================
  // 🧩 WIDGETS
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kPaddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  size: 64,
                  color: kPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: kPaddingL),
            Text(
              'Aucune pharmacie',
              style: GoogleFonts.inter(
                fontSize: kFontSizeXL,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: kPaddingS),
            Text(
              'Ajoutez votre première pharmacie\npour commencer les contrôles',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: kFontSizeM,
                color: kTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: kPaddingXL),
            ElevatedButton.icon(
              onPressed: () => _ajouterPharmacie(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter une pharmacie'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacieCard(
    BuildContext context,
    Pharmacie pharmacie,
    Color color,
    int index,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: kPaddingM),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + index * 80),
        curve: Curves.easeOut,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        ),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withAlpha(40), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _ouvrirPharmacie(context, pharmacie),
            child: Padding(
              padding: const EdgeInsets.all(kPaddingM),
              child: Row(
                children: [
                  // Icône colorée
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          color.withAlpha(180),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: kPaddingM),

                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pharmacie.nom,
                          style: GoogleFonts.inter(
                            fontSize: kFontSizeL,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : kTextPrimary,
                          ),
                        ),
                        if (pharmacie.adresse != null &&
                            pharmacie.adresse!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 12, color: color.withAlpha(180)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  pharmacie.adresse!,
                                  style: GoogleFonts.inter(
                                    fontSize: kFontSizeS,
                                    color: kTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (pharmacie.telephone != null &&
                            pharmacie.telephone!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.phone_rounded,
                                  size: 12, color: color.withAlpha(180)),
                              const SizedBox(width: 4),
                              Text(
                                pharmacie.telephone!,
                                style: GoogleFonts.inter(
                                  fontSize: kFontSizeS,
                                  color: kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: kTextSecondary),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editerPharmacie(context, pharmacie);
                          break;
                        case 'delete':
                          _confirmerSuppression(context, pharmacie);
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                color: kPrimaryColor, size: 18),
                            const SizedBox(width: 8),
                            Text('Modifier',
                                style: GoogleFonts.inter()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: kDangerColor, size: 18),
                            const SizedBox(width: 8),
                            Text('Supprimer',
                                style: GoogleFonts.inter(
                                    color: kDangerColor)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🎬 ACTIONS
  // ============================================================

  void _ouvrirPharmacie(BuildContext context, Pharmacie pharmacie) async {
    context.read<PharmacieProvider>().selectionnerPharmacie(pharmacie);

    // Initialiser le ControleProvider pour cette pharmacie
    await context
        .read<ControleProvider>()
        .initialiserPourPharmacie(pharmacie.id!);

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(pharmacie: pharmacie),
      ),
    ).then((_) {
      // Quand on revient, on désélectionne et on recharge la liste
      if (context.mounted) {
        context.read<PharmacieProvider>().deselectionnnerPharmacie();
        context.read<ControleProvider>().reinitialiser();
        context.read<PharmacieProvider>().chargerPharmacies();
      }
    });
  }

  void _ajouterPharmacie(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PharmacieFormScreen(),
      ),
    );
    if (result == true && context.mounted) {
      context.read<PharmacieProvider>().chargerPharmacies();
    }
  }

  void _editerPharmacie(BuildContext context, Pharmacie pharmacie) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PharmacieFormScreen(pharmacie: pharmacie),
      ),
    );
    if (result == true && context.mounted) {
      context.read<PharmacieProvider>().chargerPharmacies();
    }
  }

  void _confirmerSuppression(BuildContext context, Pharmacie pharmacie) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: kDangerColor),
            const SizedBox(width: 8),
            Text('Supprimer la pharmacie',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir supprimer :',
              style: GoogleFonts.inter(fontSize: kFontSizeM),
            ),
            const SizedBox(height: 8),
            Text(
              '"${pharmacie.nom}"',
              style: GoogleFonts.inter(
                fontSize: kFontSizeM,
                fontWeight: FontWeight.w700,
                color: kDangerColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kDangerColor.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kDangerColor.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: kDangerColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tous les contrôles associés seront également supprimés.',
                      style: GoogleFonts.inter(
                        fontSize: kFontSizeS,
                        color: kDangerColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<PharmacieProvider>()
                  .supprimerPharmacie(pharmacie.id!);
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
