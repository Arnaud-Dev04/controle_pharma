/// Écran de déverrouillage unique
///
/// S'affiche uniquement à la première utilisation de l'application.
/// Une fois le code correct saisi, l'écran disparaît définitivement.
/// Il réapparaîtra seulement après une réinstallation complète.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import 'pharmacie_selection_screen.dart';

/// Clé SharedPreferences indiquant que l'app a été déverrouillée
const String kUnlockKey = 'app_unlocked';

/// Code d'activation (à personnaliser)
const String kUnlockCode = 'NTAKI04PHARMA';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen>
    with TickerProviderStateMixin {
  // Saisie du code par cases individuelles
  static const int _codeLength = 13; // longueur de "PHARMA2026"
  final List<TextEditingController> _controllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  bool _isError = false;
  bool _isSuccess = false;
  bool _isChecking = false;

  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Focus automatique sur la première case
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================
  // 🔑 LOGIQUE DE VÉRIFICATION
  // ============================================================

  String get _saisie => _controllers.map((c) => c.text.toUpperCase()).join();

  Future<void> _verifier() async {
    if (_saisie.length < _codeLength) return;
    if (_isChecking) return;

    setState(() => _isChecking = true);

    // Légère pause pour effet visuel
    await Future.delayed(const Duration(milliseconds: 300));

    if (_saisie == kUnlockCode) {
      // ✅ CODE CORRECT
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kUnlockKey, true);

      setState(() {
        _isSuccess = true;
        _isError = false;
        _isChecking = false;
      });

      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (ctx, animation, secondaryAnimation) =>
              const PharmacieSelectionScreen(),
          transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      // ❌ CODE INCORRECT
      setState(() {
        _isError = true;
        _isSuccess = false;
        _isChecking = false;
      });
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();

      // Vider les cases et redonner le focus
      await Future.delayed(const Duration(milliseconds: 600));
      for (final c in _controllers) {
        c.clear();
      }
      setState(() => _isError = false);
      _focusNodes[0].requestFocus();
    }
  }

  // ============================================================
  // 🎨 BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0D2547), Color(0xFF1A3A6B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: kPaddingL,
              vertical: kPaddingXL,
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ── Icône animée ──────────────────────────────
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(15),
                      border: Border.all(
                        color: Colors.white.withAlpha(60),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryLightColor.withAlpha(80),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isSuccess
                          ? Icons.check_circle_rounded
                          : Icons.lock_rounded,
                      size: 48,
                      color: _isSuccess ? kSuccessColor : Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: kPaddingL),

                // ── Titre ────────────────────────────────────
                Text(
                  _isSuccess ? 'Accès accordé !' : 'Activation requise',
                  style: GoogleFonts.inter(
                    fontSize: kFontSizeXXL,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: kPaddingS),
                Text(
                  _isSuccess
                      ? 'Bienvenue dans Contrôle Pharma'
                      : 'Entrez votre code d\'activation\npour déverrouiller l\'application',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: kFontSizeM,
                    color: Colors.white60,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: kPaddingXL),

                // ── Cases de saisie ──────────────────────────
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final dx = _isError
                        ? (8 * (0.5 - (_shakeAnimation.value - 0.5).abs()))
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: _buildCodeInput(),
                ),

                const SizedBox(height: kPaddingL),

                // ── Message d'erreur ─────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isError
                      ? Container(
                          key: const ValueKey('error'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: kPaddingM,
                            vertical: kPaddingS,
                          ),
                          decoration: BoxDecoration(
                            color: kDangerColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: kDangerColor.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: kDangerColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Code incorrect. Veuillez réessayer.',
                                style: GoogleFonts.inter(
                                  color: kDangerColor,
                                  fontSize: kFontSizeS,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _isSuccess
                      ? Container(
                          key: const ValueKey('success'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: kPaddingM,
                            vertical: kPaddingS,
                          ),
                          decoration: BoxDecoration(
                            color: kSuccessColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: kSuccessColor.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: kSuccessColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Application déverrouillée !',
                                style: GoogleFonts.inter(
                                  color: kSuccessColor,
                                  fontSize: kFontSizeS,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('none')),
                ),

                const SizedBox(height: kPaddingXL),

                // ── Bouton valider ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChecking || _isSuccess ? null : _verifier,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kPrimaryDarkColor,
                      disabledBackgroundColor: Colors.white.withAlpha(40),
                      disabledForegroundColor: Colors.white60,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: kFontSizeL,
                      ),
                      elevation: 0,
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kPrimaryColor,
                            ),
                          )
                        : const Text('Déverrouiller'),
                  ),
                ),

                const SizedBox(height: kPaddingL),

                // ── Footer ───────────────────────────────────
                Text(
                  'Contrôle Pharma — Audit & Contrôle Financier',
                  style: GoogleFonts.inter(
                    fontSize: kFontSizeXS,
                    color: Colors.white30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🧩 WIDGET CASES DE SAISIE
  // ============================================================

  Widget _buildCodeInput() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 8,
      children: List.generate(_codeLength, (index) {
        return _buildCodeBox(index);
      }),
    );
  }

  Widget _buildCodeBox(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;
    final borderColor = _isError
        ? kDangerColor
        : _isSuccess
        ? kSuccessColor
        : isFilled
        ? Colors.white
        : Colors.white30;

    return SizedBox(
      width: 42,
      height: 52,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          UpperCaseTextFormatter(),
        ],
        style: GoogleFonts.inter(
          fontSize: kFontSizeXL,
          fontWeight: FontWeight.w800,
          color: _isSuccess ? kSuccessColor : Colors.white,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white.withAlpha(isFilled ? 25 : 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty) {
            // Passer à la case suivante
            if (index < _codeLength - 1) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Dernière case → valider automatiquement
              _focusNodes[index].unfocus();
              _verifier();
            }
          }
        },
        onTap: () {
          // Sélectionner tout le texte au tap
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        },
      ),
    );
  }
}

// ============================================================
// 🔧 FORMATTER
// ============================================================

/// Convertit automatiquement en majuscules
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
