/// Écran de saisie des ventes
///
/// Permet de saisir la quantité vendue pour chaque médicament.
/// Affiche en temps réel :
/// - La quantité restante théorique
/// - Le PV total
/// - Le bénéfice unitaire
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/controle_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class VenteScreen extends StatefulWidget {
  const VenteScreen({super.key});

  @override
  State<VenteScreen> createState() => _VenteScreenState();
}

class _VenteScreenState extends State<VenteScreen> {
  /// Controllers pour chaque médicament (indexé par position)
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(int index, int currentValue) {
    if (!_controllers.containsKey(index)) {
      _controllers[index] = TextEditingController(
        text: currentValue > 0 ? currentValue.toString() : '',
      );
    }
    return _controllers[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saisie des ventes'),
        actions: [
          // Bouton tout valider
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
                  Icon(Icons.medication_liquid_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: kPaddingM),
                  Text(
                    'Aucun médicament à traiter',
                    style: GoogleFonts.inter(
                      fontSize: kFontSizeL,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // En-tête informatif
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(kPaddingM),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saisissez la quantité vendue pour chaque médicament',
                        style: GoogleFonts.inter(
                          fontSize: kFontSizeS,
                          color: Colors.orange.shade900,
                        ),
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
                        _getController(index, med.quantiteVendue);

                    return Card(
                      margin: const EdgeInsets.only(bottom: kPaddingS),
                      child: Padding(
                        padding: const EdgeInsets.all(kPaddingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom et infos du médicament
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
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
                                        'Stock: ${med.quantiteInitiale} | PV: ${formatCurrency(med.prixVente)}',
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

                            // Champ de saisie quantité vendue
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Quantité vendue',
                                      hintText: '0',
                                      prefixIcon: const Icon(
                                          Icons.shopping_bag_rounded),
                                      suffixText:
                                          '/ ${med.quantiteInitiale}',
                                    ),
                                    onChanged: (value) {
                                      final qty = int.tryParse(value) ?? 0;
                                      provider.mettreAJourQuantiteVendue(
                                          index, qty);
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Résultats en temps réel
                            Row(
                              children: [
                                _buildChip(
                                  'Restant: ${med.quantiteRestante}',
                                  Icons.inventory_rounded,
                                  kPrimaryColor,
                                ),
                                const SizedBox(width: 8),
                                _buildChip(
                                  'PV: ${formatCurrency(med.pvTotal)}',
                                  Icons.monetization_on_rounded,
                                  Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                _buildChip(
                                  'Bén: ${formatCurrency(med.benefice)}',
                                  Icons.trending_up_rounded,
                                  med.benefice >= 0
                                      ? kSuccessColor
                                      : kDangerColor,
                                ),
                              ],
                            ),

                            // Alerte si quantité vendue > stock initial
                            if (med.quantiteVendue > med.quantiteInitiale)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kDangerColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: kDangerColor.withAlpha(60)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_rounded,
                                          color: kDangerColor, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Quantité vendue supérieure au stock !',
                                        style: GoogleFonts.inter(
                                          fontSize: kFontSizeXS,
                                          color: kDangerColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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

  Widget _buildChip(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
