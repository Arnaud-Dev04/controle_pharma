/// Écran de statistiques et graphiques
///
/// Affiche des graphiques visuels pour analyser le contrôle :
/// - Camembert des écarts (OK vs problème)
/// - Barres des bénéfices par médicament (top 10)
/// - Barres des PV total par médicament
/// - Statistiques globales
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/controle_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class StatistiquesScreen extends StatelessWidget {
  const StatistiquesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
      ),
      body: Consumer<ControleProvider>(
        builder: (context, provider, _) {
          if (provider.medicaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: kPaddingM),
                  Text(
                    'Aucune donnée à analyser',
                    style: GoogleFonts.inter(
                      fontSize: kFontSizeL,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final meds = provider.medicaments;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(kPaddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================
                // 📊 RÉSUMÉ GLOBAL
                // ============================================
                _buildSectionTitle('Résumé global', Icons.analytics_rounded),
                const SizedBox(height: kPaddingS),
                _buildGlobalStats(provider),
                const SizedBox(height: kPaddingL),

                // ============================================
                // 🥧 CAMEMBERT - ÉTAT DU STOCK
                // ============================================
                _buildSectionTitle(
                    'État du stock', Icons.pie_chart_rounded),
                const SizedBox(height: kPaddingS),
                _buildStockPieChart(meds),
                const SizedBox(height: kPaddingL),

                // ============================================
                // 📊 BARRES - TOP BÉNÉFICES
                // ============================================
                _buildSectionTitle(
                    'Top bénéfices', Icons.trending_up_rounded),
                const SizedBox(height: kPaddingS),
                _buildBeneficeBarChart(meds),
                const SizedBox(height: kPaddingL),

                // ============================================
                // 📊 BARRES - TOP VENTES (PV Total)
                // ============================================
                _buildSectionTitle(
                    'Top ventes (PV Total)', Icons.monetization_on_rounded),
                const SizedBox(height: kPaddingS),
                _buildPvTotalBarChart(meds),
                const SizedBox(height: kPaddingL),

                // ============================================
                // 📉 ÉCARTS DÉTAILLÉS
                // ============================================
                if (provider.nombreEcarts > 0) ...[
                  _buildSectionTitle(
                      'Détail des écarts', Icons.warning_amber_rounded),
                  const SizedBox(height: kPaddingS),
                  _buildEcartsChart(meds),
                  const SizedBox(height: kPaddingL),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // 🧩 COMPOSANTS
  // ============================================================

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: kFontSizeL,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }

  /// Stats globales en grille
  Widget _buildGlobalStats(ControleProvider provider) {
    final meds = provider.medicaments;
    final totalQteVendue =
        meds.fold(0, (sum, m) => sum + m.quantiteVendue);
    final margeGlobale = provider.totalPVTotal > 0
        ? (provider.totalBenefice / provider.totalPVTotal * 100)
        : 0.0;
    final tauxDemarque = meds.where((m) => m.ecart != null).isEmpty
        ? 0.0
        : meds
                .where((m) => m.ecart != null && m.ecart! < 0)
                .fold(0, (sum, m) => sum + m.ecart!.abs()) /
            meds.fold(0, (sum, m) => sum + m.quantiteInitiale) *
            100;

    return Wrap(
      spacing: kPaddingS,
      runSpacing: kPaddingS,
      children: [
        _buildStatCard('Médicaments', '${meds.length}',
            Icons.medication_rounded, kPrimaryColor),
        _buildStatCard('Qté vendue', '$totalQteVendue',
            Icons.shopping_bag_rounded, Colors.orange.shade700),
        _buildStatCard('Chiffre d\'affaires',
            formatCurrency(provider.totalPVTotal),
            Icons.monetization_on_rounded, kPrimaryDarkColor),
        _buildStatCard('Bénéfice total',
            formatCurrency(provider.totalBenefice),
            Icons.trending_up_rounded, kSuccessColor),
        _buildStatCard('Marge globale',
            '${margeGlobale.toStringAsFixed(1)}%',
            Icons.percent_rounded, kPrimaryColor),
        _buildStatCard('Taux démarque',
            '${tauxDemarque.toStringAsFixed(2)}%',
            Icons.trending_down_rounded, kDangerColor),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: kFontSizeL,
              fontWeight: FontWeight.w800,
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

  /// Camembert état du stock
  Widget _buildStockPieChart(List<dynamic> meds) {
    final nonControles =
        meds.where((m) => m.stockReel == null).length;
    final ok = meds
        .where((m) => m.ecart != null && m.ecart == 0)
        .length;
    final ecarts = meds
        .where((m) => m.ecart != null && m.ecart != 0)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPaddingM),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: [
                    if (ok > 0)
                      PieChartSectionData(
                        value: ok.toDouble(),
                        title: '$ok',
                        color: kSuccessColor,
                        radius: 60,
                        titleStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    if (ecarts > 0)
                      PieChartSectionData(
                        value: ecarts.toDouble(),
                        title: '$ecarts',
                        color: kDangerColor,
                        radius: 60,
                        titleStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    if (nonControles > 0)
                      PieChartSectionData(
                        value: nonControles.toDouble(),
                        title: '$nonControles',
                        color: Colors.grey.shade400,
                        radius: 60,
                        titleStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kPaddingM),
            // Légende
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend('OK ($ok)', kSuccessColor),
                const SizedBox(width: 16),
                _buildLegend('Écart ($ecarts)', kDangerColor),
                const SizedBox(width: 16),
                _buildLegend(
                    'Non contrôlé ($nonControles)', Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: kFontSizeXS, color: kTextSecondary),
        ),
      ],
    );
  }

  /// Barres bénéfice
  Widget _buildBeneficeBarChart(List<dynamic> meds) {
    final sorted = List.of(meds)
      ..sort((a, b) => b.benefice.compareTo(a.benefice));
    final top = sorted.take(8).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPaddingM),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: top.isNotEmpty
                  ? top.first.benefice * 1.2
                  : 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${top[group.x.toInt()].nom}\n${formatCurrency(rod.toY)}',
                      GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= top.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          top[idx].nom.length > 6
                              ? '${top[idx].nom.substring(0, 6)}.'
                              : top[idx].nom,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: kTextSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        formatNumber(value),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: kTextSecondary,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: top.isNotEmpty
                    ? top.first.benefice / 4
                    : 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: kBorderColor,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: top.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: m.benefice,
                      color: m.benefice >= 0 ? kSuccessColor : kDangerColor,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Barres PV Total
  Widget _buildPvTotalBarChart(List<dynamic> meds) {
    final sorted = List.of(meds)
      ..sort((a, b) => b.pvTotal.compareTo(a.pvTotal));
    final top = sorted.take(8).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPaddingM),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: top.isNotEmpty ? top.first.pvTotal * 1.2 : 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${top[group.x.toInt()].nom}\n${formatCurrency(rod.toY)}',
                      GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= top.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          top[idx].nom.length > 6
                              ? '${top[idx].nom.substring(0, 6)}.'
                              : top[idx].nom,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: kTextSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        formatNumber(value),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: kTextSecondary,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: kBorderColor,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: top.asMap().entries.map((entry) {
                final i = entry.key;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.pvTotal,
                      color: kPrimaryColor,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Graphique des écarts
  Widget _buildEcartsChart(List<dynamic> meds) {
    final medsAvecEcart =
        meds.where((m) => m.ecart != null && m.ecart != 0).toList();
    if (medsAvecEcart.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPaddingM),
        child: Column(
          children: medsAvecEcart.map((m) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      m.nom,
                      style: GoogleFonts.inter(
                        fontSize: kFontSizeS,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (m.ecart!.abs() /
                                (m.quantiteInitiale > 0
                                    ? m.quantiteInitiale
                                    : 1))
                            .clamp(0.0, 1.0),
                        backgroundColor: kBorderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          m.ecart! < 0 ? kDangerColor : kWarningColor,
                        ),
                        minHeight: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: m.ecart! < 0
                          ? kDangerColor.withAlpha(20)
                          : kWarningColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      formatEcart(m.ecart!),
                      style: GoogleFonts.inter(
                        fontSize: kFontSizeS,
                        fontWeight: FontWeight.w700,
                        color: m.ecart! < 0 ? kDangerColor : kWarningColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
