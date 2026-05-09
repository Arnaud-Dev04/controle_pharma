/// Widget carte d'un médicament
///
/// Affiche un résumé compact d'un médicament avec :
/// - Nom
/// - Quantités (initiale, vendue, restante)
/// - Prix (PU, PV)
/// - Bénéfice
/// - Écart (si stock réel saisi)
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/medicament.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../screens/medicament_form_screen.dart';

class MedicamentCard extends StatelessWidget {
  final Medicament medicament;
  final int index;
  final VoidCallback? onDelete;
  final VoidCallback? onRenouveler;

  const MedicamentCard({
    super.key,
    required this.medicament,
    required this.index,
    this.onDelete,
    this.onRenouveler,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Ouvrir en mode édition
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicamentFormScreen(
                medicament: medicament,
                editIndex: index,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(kPaddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================
              // Ligne 1 : Nom + Actions
              // ============================================
              Row(
                children: [
                  // Numéro
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimaryColor, kPrimaryLightColor],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: kFontSizeS,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nom
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicament.nom,
                          style: GoogleFonts.inter(
                            fontSize: kFontSizeL,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary,
                          ),
                        ),
                        Text(
                          '${medicament.forme.emoji} ${medicament.forme.label}  •  ${medicament.resumeConditionnement}',
                          style: GoogleFonts.inter(
                            fontSize: kFontSizeXS,
                            color: kTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'PU: ${formatCurrency(medicament.prixUnitaire)} → PV: ${formatCurrency(medicament.prixVente)}'
                          '${medicament.dateEntreeStock != null ? '  •  ${medicament.dateEntreeStock!.day.toString().padLeft(2, '0')}/${medicament.dateEntreeStock!.month.toString().padLeft(2, '0')}/${medicament.dateEntreeStock!.year}' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: kFontSizeXS,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bouton renouveler
                  if (onRenouveler != null)
                    IconButton(
                      onPressed: onRenouveler,
                      icon: const Icon(Icons.replay_rounded),
                      color: kPrimaryColor,
                      iconSize: 20,
                      tooltip: 'Renouveler',
                    ),
                  // Bouton supprimer
                  if (onDelete != null)
                    IconButton(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: kDangerColor,
                      iconSize: 20,
                      tooltip: 'Supprimer',
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ============================================
              // Ligne 2 : Métriques
              // ============================================
              Row(
                children: [
                  _buildMetric(
                    'Q.Init',
                    '${medicament.quantiteInitiale}',
                    kPrimaryColor,
                  ),
                  _buildMetric(
                    'Vendue',
                    '${medicament.quantiteVendue}',
                    Colors.orange.shade700,
                  ),
                  _buildMetric(
                    'Restant',
                    '${medicament.quantiteRestante}',
                    kPrimaryDarkColor,
                  ),
                  _buildMetric(
                    'Bénéfice',
                    formatNumber(medicament.benefice),
                    medicament.benefice >= 0 ? kSuccessColor : kDangerColor,
                  ),
                ],
              ),

              // ============================================
              // Ligne 3 : Écart (si disponible)
              // ============================================
              if (medicament.ecart != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: medicament.ecart == 0
                        ? kSuccessColor.withAlpha(15)
                        : kDangerColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: medicament.ecart == 0
                          ? kSuccessColor.withAlpha(50)
                          : kDangerColor.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        medicament.ecart == 0
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        size: 16,
                        color: medicament.ecart == 0
                            ? kSuccessColor
                            : kDangerColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        medicament.ecart == 0
                            ? 'Stock cohérent ✓'
                            : 'Écart: ${formatEcart(medicament.ecart!)} unités',
                        style: GoogleFonts.inter(
                          fontSize: kFontSizeS,
                          fontWeight: FontWeight.w600,
                          color: medicament.ecart == 0
                              ? kSuccessColor
                              : kDangerColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Réel: ${medicament.stockReel}',
                        style: GoogleFonts.inter(
                          fontSize: kFontSizeXS,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: kFontSizeM,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: kDangerColor),
            const SizedBox(width: 8),
            Text(
              'Supprimer',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "${medicament.nom}" ?',
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
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDangerColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
