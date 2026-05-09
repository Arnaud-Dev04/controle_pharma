/// Widget ligne de résumé
///
/// Utilisé en bas du tableau pour afficher les totaux
/// avec un style mis en évidence.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kPaddingM,
        vertical: kPaddingS,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: kFontSizeM,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: kFontSizeL,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
