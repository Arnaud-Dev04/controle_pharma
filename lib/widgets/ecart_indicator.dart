/// Widget indicateur d'écart
///
/// Affiche visuellement l'écart entre stock réel et théorique :
/// - Vert (0) : Stock cohérent
/// - Rouge (négatif) : Perte détectée
/// - Jaune (positif) : Surplus
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';
import '../utils/formatters.dart';

class EcartIndicator extends StatelessWidget {
  final int ecart;

  const EcartIndicator({
    super.key,
    required this.ecart,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    if (ecart == 0) {
      color = kSuccessColor;
      icon = Icons.check_circle_rounded;
      label = 'OK';
    } else if (ecart < 0) {
      color = kDangerColor;
      icon = Icons.arrow_downward_rounded;
      label = formatEcart(ecart);
    } else {
      color = kWarningColor;
      icon = Icons.arrow_upward_rounded;
      label = formatEcart(ecart);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(
            'Écart',
            style: GoogleFonts.inter(
              fontSize: kFontSizeXS,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: kFontSizeM,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
