/// Écran de contrôle - Saisie du stock réel
///
/// Permet de :
/// - Saisir le stock réel physique pour chaque médicament
/// - Afficher automatiquement l'écart (stock réel - quantité restante)
/// - Visualiser par couleur : vert = cohérent, rouge = perte
/// - Voir le bénéfice et le PV total par médicament
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/controle_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/ecart_indicator.dart';

class ControleScreen extends StatefulWidget {
  const ControleScreen({super.key});

  @override
  State<ControleScreen> createState() => _ControleScreenState();
}

class _ControleScreenState extends State<ControleScreen> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(int index, int? currentValue) {
    if (!_controllers.containsKey(index)) {
      _controllers[index] = TextEditingController(
        text: currentValue?.toString() ?? '',
      );
    }
    return _controllers[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrôle du stock'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Terminé',
          ),
        ],
      ),
      body: Consumer<ControleProvider>(
        builder: (context, provider, _) {
          if (provider.medicaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fact_check_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: kPaddingM),
                  Text(
                    'Aucun médicament à contrôler',
                    style: GoogleFonts.inter(
                      fontSize: kFontSizeL,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Progression du contrôle
          final progression = provider.controleActuel?.progressionControle ?? 0;

          return Column(
            children: [
              // Barre de progression
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(kPaddingM),
                color: kSuccessColor.withAlpha(15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fact_check_rounded,
                            color: kSuccessColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Saisissez le stock réel compté physiquement',
                            style: GoogleFonts.inter(
                              fontSize: kFontSizeS,
                              color: kSuccessColor,
                            ),
                          ),
                        ),
                        Text(
                          '${(progression * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: kFontSizeM,
                            fontWeight: FontWeight.w700,
                            color: kSuccessColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progression,
                        backgroundColor: kSuccessColor.withAlpha(30),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            kSuccessColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des médicaments
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(kPaddingM),
                  itemCount: provider.medicaments.length,
                  itemBuilder: (context, index) {
                    final med = provider.medicaments[index];
                    final controller =
                        _getController(index, med.stockReel);

                    return Card(
                      margin: const EdgeInsets.only(bottom: kPaddingS),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: med.ecart != null
                              ? (med.ecart == 0
                                  ? kSuccessColor.withAlpha(80)
                                  : kDangerColor.withAlpha(80))
                              : kBorderColor,
                          width: med.ecart != null ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(kPaddingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ligne 1 : Nom et quantités
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: med.ecart != null
                                        ? (med.ecart == 0
                                            ? kSuccessColor.withAlpha(25)
                                            : kDangerColor.withAlpha(25))
                                        : kPrimaryColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: med.ecart != null
                                        ? Icon(
                                            med.ecart == 0
                                                ? Icons.check_rounded
                                                : Icons.warning_rounded,
                                            size: 18,
                                            color: med.ecart == 0
                                                ? kSuccessColor
                                                : kDangerColor,
                                          )
                                        : Text(
                                            '${index + 1}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              color: kPrimaryColor,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.nom,
                                        style: GoogleFonts.inter(
                                          fontSize: kFontSizeL,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Théorique: ${med.quantiteRestante} (${med.quantiteInitiale} - ${med.quantiteVendue})',
                                        style: GoogleFonts.inter(
                                          fontSize: kFontSizeS,
                                          color: kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Champ stock réel
                            TextFormField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Stock réel (compté)',
                                hintText: '${med.quantiteRestante}',
                                prefixIcon:
                                    const Icon(Icons.inventory_rounded),
                                suffixText: 'unités',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (value) {
                                final stock = int.tryParse(value);
                                if (stock != null) {
                                  provider.mettreAJourStockReel(
                                      index, stock);
                                  setState(() {});
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Résultats
                            if (med.ecart != null) ...[
                              Row(
                                children: [
                                  // Indicateur d'écart
                                  Expanded(
                                    child: EcartIndicator(ecart: med.ecart!),
                                  ),
                                  const SizedBox(width: 8),
                                  // PV Total
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withAlpha(15),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'PV Total',
                                            style: GoogleFonts.inter(
                                              fontSize: kFontSizeXS,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                          Text(
                                            formatCurrency(med.pvTotal),
                                            style: GoogleFonts.inter(
                                              fontSize: kFontSizeS,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.orange.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Bénéfice
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: med.benefice >= 0
                                            ? kSuccessColor.withAlpha(15)
                                            : kDangerColor.withAlpha(15),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Bénéfice',
                                            style: GoogleFonts.inter(
                                              fontSize: kFontSizeXS,
                                              color: med.benefice >= 0
                                                  ? kSuccessColor
                                                  : kDangerColor,
                                            ),
                                          ),
                                          Text(
                                            formatCurrency(med.benefice),
                                            style: GoogleFonts.inter(
                                              fontSize: kFontSizeS,
                                              fontWeight: FontWeight.w700,
                                              color: med.benefice >= 0
                                                  ? kSuccessColor
                                                  : kDangerColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Alerte d'écart
                              if (med.ecart != 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: kDangerColor.withAlpha(15),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color:
                                              kDangerColor.withAlpha(40)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.notification_important_rounded,
                                          color: kDangerColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            med.ecart! < 0
                                                ? 'Perte de ${med.ecart!.abs()} unités (${formatCurrency(med.valeurEcart!.abs())})'
                                                : 'Surplus de ${med.ecart} unités',
                                            style: GoogleFonts.inter(
                                              fontSize: kFontSizeXS,
                                              color: kDangerColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
