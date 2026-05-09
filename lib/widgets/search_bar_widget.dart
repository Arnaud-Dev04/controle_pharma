/// Widget de barre de recherche pour les médicaments
///
/// Barre de recherche animée avec :
/// - Filtrage en temps réel
/// - Bouton d'effacement
/// - Animation d'ouverture/fermeture
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Rechercher un médicament...',
    required this.onChanged,
    this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: kPaddingM,
        vertical: kPaddingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() => _hasText = value.isNotEmpty);
          widget.onChanged(value);
        },
        style: GoogleFonts.inter(fontSize: kFontSizeM),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.inter(
            color: kTextSecondary,
            fontSize: kFontSizeM,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryColor),
          suffixIcon: _hasText
              ? IconButton(
                  onPressed: () {
                    _controller.clear();
                    setState(() => _hasText = false);
                    widget.onChanged('');
                    widget.onClear?.call();
                  },
                  icon:
                      const Icon(Icons.clear_rounded, color: kTextSecondary),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: kPaddingM,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
