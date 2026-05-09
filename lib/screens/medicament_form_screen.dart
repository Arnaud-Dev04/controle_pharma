/// Formulaire d'ajout/modification d'un médicament
///
/// Sections :
/// - Identification (nom + forme galénique)
/// - Conditionnement (toggle simplifié/détaillé)
/// - Prix (PU + PV côte à côte)
/// - Aperçu financier temps réel
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/medicament.dart';
import '../providers/controle_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class MedicamentFormScreen extends StatefulWidget {
  final Medicament? medicament;
  final int? editIndex;

  const MedicamentFormScreen({super.key, this.medicament, this.editIndex});

  @override
  State<MedicamentFormScreen> createState() => _MedicamentFormScreenState();
}

class _MedicamentFormScreenState extends State<MedicamentFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomCtrl;
  late final TextEditingController _puCtrl;
  late final TextEditingController _pvCtrl;
  late final TextEditingController _qteDirecteCtrl;
  late final TextEditingController _cartonsCtrl;
  late final TextEditingController _boitesCtrl;
  late final TextEditingController _plaquettesCtrl;
  late final TextEditingController _unitesCtrl;

  // Prix par niveau
  late final TextEditingController _paCartonCtrl;
  late final TextEditingController _paBoiteCtrl;
  late final TextEditingController _paPlaquetteCtrl;
  late final TextEditingController _pvCartonCtrl;
  late final TextEditingController _pvBoiteCtrl;
  late final TextEditingController _pvPlaquetteCtrl;

  DateTime? _dateEntreeStock;

  late final FocusNode _nomFocus;
  late final FocusNode _qteFocus;
  late final FocusNode _puFocus;
  late final FocusNode _pvFocus;

  late AnimationController _animCtrl;

  FormeGalenique _forme = FormeGalenique.comprime;
  bool _modeDetaille = true;
  bool _isSaving = false;

  // Niveaux de prix sélectionnés
  bool _showPrixComprime = false;
  bool _showPrixPlaquette = false;
  bool _showPrixBoite = false;
  bool _showPrixCarton = false;
  bool get _isEditing => widget.medicament != null;

  /// Médicaments de l'historique pour l'auto-complétion
  List<Medicament> _medsHistorique = [];

  @override
  void initState() {
    super.initState();
    final m = widget.medicament;

    _nomCtrl = TextEditingController(text: m?.nom ?? '');
    _puCtrl = TextEditingController(
      text: m != null ? m.prixUnitaire.toString() : '',
    );
    _pvCtrl = TextEditingController(
      text: m != null ? m.prixVente.toString() : '',
    );
    _qteDirecteCtrl = TextEditingController(
      text: m != null ? m.quantiteInitiale.toString() : '',
    );
    _cartonsCtrl = TextEditingController(text: m?.nbCartons?.toString() ?? '');
    _boitesCtrl = TextEditingController(
      text: m?.boitesParCarton?.toString() ?? '',
    );
    _plaquettesCtrl = TextEditingController(
      text: m?.plaquettesParBoite?.toString() ?? '',
    );
    _unitesCtrl = TextEditingController(
      text: m?.unitesParPlaquette?.toString() ?? '',
    );

    // Prix par niveau
    _paCartonCtrl = TextEditingController(
      text: m?.prixAchatCarton?.toString() ?? '',
    );
    _paBoiteCtrl = TextEditingController(
      text: m?.prixAchatBoite?.toString() ?? '',
    );
    _paPlaquetteCtrl = TextEditingController(
      text: m?.prixAchatPlaquette?.toString() ?? '',
    );
    _pvCartonCtrl = TextEditingController(
      text: m?.prixVenteCarton?.toString() ?? '',
    );
    _pvBoiteCtrl = TextEditingController(
      text: m?.prixVenteBoite?.toString() ?? '',
    );
    _pvPlaquetteCtrl = TextEditingController(
      text: m?.prixVentePlaquette?.toString() ?? '',
    );

    _dateEntreeStock = m?.dateEntreeStock;

    if (m != null) {
      _forme = m.forme;
      _modeDetaille = m.hasConditionnement;
    }

    _nomFocus = FocusNode();
    _qteFocus = FocusNode();
    _puFocus = FocusNode();
    _pvFocus = FocusNode();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    // Listeners pour mise à jour temps réel
    for (final c in [
      _puCtrl,
      _pvCtrl,
      _qteDirecteCtrl,
      _cartonsCtrl,
      _boitesCtrl,
      _plaquettesCtrl,
      _unitesCtrl,
      _paCartonCtrl,
      _paBoiteCtrl,
      _paPlaquetteCtrl,
      _pvCartonCtrl,
      _pvBoiteCtrl,
      _pvPlaquetteCtrl,
    ]) {
      c.addListener(_onFieldChanged);
    }

    // Charger les médicaments historiques pour l'auto-complétion
    if (!_isEditing) {
      _loadHistorique();
    }
  }

  Future<void> _loadHistorique() async {
    final provider = context.read<ControleProvider>();
    final meds = await provider.getMedicamentsHistorique();
    if (mounted) setState(() => _medsHistorique = meds);
  }

  /// Pré-remplit tous les champs depuis un médicament de l'historique
  void _preFillFromMed(Medicament m) {
    _nomCtrl.text = m.nom;
    _forme = m.forme;
    _puCtrl.text = m.prixUnitaire > 0 ? m.prixUnitaire.toString() : '';
    _pvCtrl.text = m.prixVente > 0 ? m.prixVente.toString() : '';

    if (m.hasConditionnement) {
      _modeDetaille = true;
      _cartonsCtrl.text = m.nbCartons?.toString() ?? '';
      _boitesCtrl.text = m.boitesParCarton?.toString() ?? '';
      _plaquettesCtrl.text = m.plaquettesParBoite?.toString() ?? '';
      _unitesCtrl.text = m.unitesParPlaquette?.toString() ?? '';
    }

    if (m.prixAchatCarton != null) {
      _showPrixCarton = true;
      _paCartonCtrl.text = m.prixAchatCarton.toString();
      _pvCartonCtrl.text = m.prixVenteCarton?.toString() ?? '';
    }
    if (m.prixAchatBoite != null) {
      _showPrixBoite = true;
      _paBoiteCtrl.text = m.prixAchatBoite.toString();
      _pvBoiteCtrl.text = m.prixVenteBoite?.toString() ?? '';
    }
    if (m.prixAchatPlaquette != null) {
      _showPrixPlaquette = true;
      _paPlaquetteCtrl.text = m.prixAchatPlaquette.toString();
      _pvPlaquetteCtrl.text = m.prixVentePlaquette?.toString() ?? '';
    }
    if (m.prixUnitaire > 0 || m.prixVente > 0) {
      _showPrixComprime = true;
    }

    setState(() {});
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [
      _nomCtrl,
      _puCtrl,
      _pvCtrl,
      _qteDirecteCtrl,
      _cartonsCtrl,
      _boitesCtrl,
      _plaquettesCtrl,
      _unitesCtrl,
      _paCartonCtrl,
      _paBoiteCtrl,
      _paPlaquetteCtrl,
      _pvCartonCtrl,
      _pvBoiteCtrl,
      _pvPlaquetteCtrl,
    ]) {
      c.dispose();
    }
    _nomFocus.dispose();
    _qteFocus.dispose();
    _puFocus.dispose();
    _pvFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  int get _quantiteTotale {
    if (_modeDetaille) {
      final c = int.tryParse(_cartonsCtrl.text) ?? 1;
      final b = int.tryParse(_boitesCtrl.text) ?? 1;
      final p = int.tryParse(_plaquettesCtrl.text) ?? 1;
      final u = int.tryParse(_unitesCtrl.text) ?? 0;
      return c * b * p * u;
    }
    return int.tryParse(_qteDirecteCtrl.text) ?? 0;
  }

  double get _marge {
    final pu = double.tryParse(_puCtrl.text) ?? 0;
    final pv = double.tryParse(_pvCtrl.text) ?? 0;
    return pv - pu;
  }

  double get _margePercent {
    final pu = double.tryParse(_puCtrl.text) ?? 0;
    return pu > 0 ? (_marge / pu) * 100 : 0;
  }

  double get _beneficeEstime => _marge * _quantiteTotale;

  double _margeNiveau(
    TextEditingController paCtrl,
    TextEditingController pvCtrl,
  ) {
    final pa = double.tryParse(paCtrl.text) ?? 0;
    final pv = double.tryParse(pvCtrl.text) ?? 0;
    return pv - pa;
  }

  double _margePctNiveau(
    TextEditingController paCtrl,
    TextEditingController pvCtrl,
  ) {
    final pa = double.tryParse(paCtrl.text) ?? 0;
    final m = _margeNiveau(paCtrl, pvCtrl);
    return pa > 0 ? (m / pa) * 100 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier médicament' : 'Ajouter un médicament',
        ),
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPaddingM),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: kPaddingL),
                _buildIdentificationSection(),
                const SizedBox(height: kPaddingL),
                _buildConditionnementSection(),
                const SizedBox(height: kPaddingL),
                _buildPrixSection(),
                const SizedBox(height: kPaddingL),
                _buildFinancialPreview(),
                const SizedBox(height: kPaddingXL),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 📝 EN-TÊTE
  // ============================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(kPaddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor.withAlpha(20), kPrimaryColor.withAlpha(8)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: kPrimaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Modification' : 'Nouveau médicament',
                  style: GoogleFonts.inter(
                    fontSize: kFontSizeL,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
                Text(
                  'Remplissez les informations du médicament',
                  style: GoogleFonts.inter(
                    fontSize: kFontSizeS,
                    color: kPrimaryColor.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🏷️ SECTION IDENTIFICATION
  // ============================================================
  Widget _buildIdentificationSection() {
    return _buildSection(
      title: 'Identification',
      icon: Icons.badge_rounded,
      children: [
        // Champ nom avec auto-complétion
        if (!_isEditing && _medsHistorique.isNotEmpty)
          Autocomplete<Medicament>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) return const Iterable.empty();
              final query = textEditingValue.text.toLowerCase();
              return _medsHistorique.where((m) => m.nom.toLowerCase().contains(query));
            },
            displayStringForOption: (m) => m.nom,
            onSelected: (m) => _preFillFromMed(m),
            fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
              // Sync with our own controller
              controller.text = _nomCtrl.text;
              controller.addListener(() {
                if (_nomCtrl.text != controller.text) {
                  _nomCtrl.text = controller.text;
                }
              });
              _nomCtrl.addListener(() {
                if (controller.text != _nomCtrl.text) {
                  controller.text = _nomCtrl.text;
                }
              });
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  onSubmitted();
                  _qteFocus.requestFocus();
                },
                decoration: const InputDecoration(
                  labelText: 'Nom du médicament',
                  hintText: 'Ex: Paracétamol 500mg',
                  prefixIcon: Icon(Icons.medication_outlined),
                  suffixIcon: Icon(Icons.search_rounded, size: 18),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
              );
            },
            optionsViewBuilder: (ctx, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 340),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (ctx, i) {
                        final m = options.elementAt(i);
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.medication_rounded, size: 18, color: kPrimaryColor),
                          title: Text(m.nom, style: GoogleFonts.inter(fontSize: kFontSizeS, fontWeight: FontWeight.w500)),
                          subtitle: Text('PA: ${formatNumber(m.prixUnitaire)} → PV: ${formatNumber(m.prixVente)}', style: GoogleFonts.inter(fontSize: kFontSizeXS, color: kTextSecondary)),
                          onTap: () => onSelected(m),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          )
        else
          TextFormField(
            controller: _nomCtrl,
            focusNode: _nomFocus,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _qteFocus.requestFocus(),
            decoration: const InputDecoration(
              labelText: 'Nom du médicament',
              hintText: 'Ex: Paracétamol 500mg',
              prefixIcon: Icon(Icons.medication_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
          ),
        const SizedBox(height: kPaddingM),
        DropdownButtonFormField<FormeGalenique>(
          initialValue: _forme,
          decoration: const InputDecoration(
            labelText: 'Forme galénique',
            prefixIcon: Icon(Icons.category_rounded),
          ),
          items: FormeGalenique.values.map((f) {
            return DropdownMenuItem(
              value: f,
              child: Text(
                '${f.emoji}  ${f.label}',
                style: GoogleFonts.inter(fontSize: kFontSizeM),
              ),
            );
          }).toList(),
          onChanged: (v) =>
              setState(() => _forme = v ?? FormeGalenique.comprime),
        ),
        const SizedBox(height: kPaddingM),
        // Date d'entrée en stock
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dateEntreeStock ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _dateEntreeStock = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date d\'entrée en stock',
              prefixIcon: Icon(Icons.calendar_today_rounded),
            ),
            child: Text(
              _dateEntreeStock != null
                  ? '${_dateEntreeStock!.day.toString().padLeft(2, '0')}/${_dateEntreeStock!.month.toString().padLeft(2, '0')}/${_dateEntreeStock!.year}'
                  : 'Sélectionner une date',
              style: GoogleFonts.inter(
                fontSize: kFontSizeM,
                color: _dateEntreeStock != null ? kTextPrimary : kTextSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 📦 SECTION CONDITIONNEMENT
  // ============================================================
  Widget _buildConditionnementSection() {
    return _buildSection(
      title: 'Conditionnement',
      icon: Icons.inventory_2_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _modeDetaille ? 'Détaillé' : 'Simple',
            style: GoogleFonts.inter(
              fontSize: kFontSizeS,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Switch(
            value: _modeDetaille,
            onChanged: (v) => setState(() => _modeDetaille = v),
            activeThumbColor: kPrimaryColor,
          ),
        ],
      ),
      children: [
        if (!_modeDetaille) ...[
          TextFormField(
            controller: _qteDirecteCtrl,
            focusNode: _qteFocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _puFocus.requestFocus(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Quantité totale',
              hintText: 'Ex: 100',
              prefixIcon: Icon(Icons.numbers_rounded),
              suffixText: 'unités',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Obligatoire';
              final qty = int.tryParse(v);
              if (qty == null || qty <= 0) return 'Quantité invalide';
              return null;
            },
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: _buildPackagingField(
                  controller: _cartonsCtrl,
                  label: 'Cartons',
                  icon: Icons.archive_rounded,
                ),
              ),
              const SizedBox(width: kPaddingS),
              Expanded(
                child: _buildPackagingField(
                  controller: _boitesCtrl,
                  label: 'Boîtes/Crt',
                  icon: Icons.inbox_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: kPaddingS),
          Row(
            children: [
              Expanded(
                child: _buildPackagingField(
                  controller: _plaquettesCtrl,
                  label: 'Plaq./Boîte',
                  icon: Icons.view_column_rounded,
                ),
              ),
              const SizedBox(width: kPaddingS),
              Expanded(
                child: _buildPackagingField(
                  controller: _unitesCtrl,
                  label: 'Unités/Plaq.',
                  icon: Icons.circle_outlined,
                  isLast: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: kPaddingM),
          // Résultat du calcul
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _quantiteTotale > 0
                  ? kPrimaryColor.withAlpha(15)
                  : Colors.grey.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _quantiteTotale > 0
                    ? kPrimaryColor.withAlpha(50)
                    : Colors.grey.withAlpha(30),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calculate_rounded,
                  color: _quantiteTotale > 0 ? kPrimaryColor : kTextSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quantité totale : ',
                  style: GoogleFonts.inter(
                    fontSize: kFontSizeM,
                    color: kTextSecondary,
                  ),
                ),
                Text(
                  '$_quantiteTotale unités',
                  style: GoogleFonts.inter(
                    fontSize: kFontSizeL,
                    fontWeight: FontWeight.w700,
                    color: _quantiteTotale > 0 ? kPrimaryColor : kDangerColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPackagingField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isLast = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: isLast ? TextInputAction.next : TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
      ),
      onFieldSubmitted: isLast ? (_) => _puFocus.requestFocus() : null,
    );
  }

  // ============================================================
  // 💰 SECTION PRIX
  // ============================================================
  Widget _buildPrixSection() {
    final margeNegative =
        _marge < 0 && _puCtrl.text.isNotEmpty && _pvCtrl.text.isNotEmpty;

    return _buildSection(
      title: 'Prix',
      icon: Icons.payments_rounded,
      children: [
        // Sélection des niveaux en premier
        Text(
          'Choisir les niveaux de prix :',
          style: GoogleFonts.inter(
            fontSize: kFontSizeS,
            color: kTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: kPaddingXS),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildNiveauChip(
              'Comprimé',
              _showPrixComprime,
              (v) => setState(() => _showPrixComprime = v),
            ),
            if (_modeDetaille) ...[
              _buildNiveauChip(
                'Plaquette',
                _showPrixPlaquette,
                (v) => setState(() => _showPrixPlaquette = v),
              ),
              _buildNiveauChip(
                'Boîte',
                _showPrixBoite,
                (v) => setState(() => _showPrixBoite = v),
              ),
              _buildNiveauChip(
                'Carton',
                _showPrixCarton,
                (v) => setState(() => _showPrixCarton = v),
              ),
            ],
          ],
        ),
        // Champs prix pour niveaux sélectionnés
        if (_showPrixComprime) ...[          
          const SizedBox(height: kPaddingS),
          Row(children: [
            Expanded(
              child: _buildPriceField(_puCtrl, 'PA Comprimé', _puFocus),
            ),
            const SizedBox(width: kPaddingS),
            Expanded(
              child: _buildPriceField(_pvCtrl, 'PV Comprimé', _pvFocus),
            ),
          ]),
        ],
        if (_showPrixPlaquette) ...[          
          const SizedBox(height: kPaddingS),
          Row(children: [
            Expanded(
              child: _buildPriceField(_paPlaquetteCtrl, 'PA Plaquette'),
            ),
            const SizedBox(width: kPaddingS),
            Expanded(
              child: _buildPriceField(_pvPlaquetteCtrl, 'PV Plaquette'),
            ),
          ]),
        ],
        if (_showPrixBoite) ...[          
          const SizedBox(height: kPaddingS),
          Row(children: [
            Expanded(child: _buildPriceField(_paBoiteCtrl, 'PA Boîte')),
            const SizedBox(width: kPaddingS),
            Expanded(child: _buildPriceField(_pvBoiteCtrl, 'PV Boîte')),
          ]),
        ],
        if (_showPrixCarton) ...[          
          const SizedBox(height: kPaddingS),
          Row(children: [
            Expanded(child: _buildPriceField(_paCartonCtrl, 'PA Carton')),
            const SizedBox(width: kPaddingS),
            Expanded(child: _buildPriceField(_pvCartonCtrl, 'PV Carton')),
          ]),
        ],
        if (_showPrixComprime &&
            (_showPrixCarton || _showPrixBoite || _showPrixPlaquette)) ...[          
          const SizedBox(height: kPaddingS),
          OutlinedButton.icon(
            onPressed: _autoCalculerPrix,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
            label: const Text('Auto-calculer les prix'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(color: kPrimaryColor.withAlpha(80)),
            ),
          ),
        ],
        if (margeNegative) ...[          
          const SizedBox(height: kPaddingS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kWarningColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kWarningColor.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: kWarningColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Attention : le prix de vente est inférieur au prix d\'achat',
                    style: GoogleFonts.inter(
                      fontSize: kFontSizeS,
                      color: kWarningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNiveauChip(
    String label,
    bool selected,
    ValueChanged<bool> onChanged,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: kFontSizeS,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: onChanged,
      selectedColor: kPrimaryColor.withAlpha(30),
      checkmarkColor: kPrimaryColor,
      side: BorderSide(color: selected ? kPrimaryColor : kBorderColor),
    );
  }



  Widget _buildPriceField(
    TextEditingController ctrl,
    String label, [
    FocusNode? focus,
  ]) {
    return TextFormField(
      controller: ctrl,
      focusNode: focus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'FBu',
        isDense: true,
      ),
    );
  }

  /// Auto-calcule les prix par niveau depuis le conditionnement
  void _autoCalculerPrix() {
    final pu = double.tryParse(_puCtrl.text) ?? 0;
    final pv = double.tryParse(_pvCtrl.text) ?? 0;
    final uPlq = int.tryParse(_unitesCtrl.text) ?? 1;
    final plqBte = int.tryParse(_plaquettesCtrl.text) ?? 1;
    final bteCrt = int.tryParse(_boitesCtrl.text) ?? 1;

    if (pu > 0) {
      _paPlaquetteCtrl.text = (pu * uPlq).toStringAsFixed(0);
      _paBoiteCtrl.text = (pu * uPlq * plqBte).toStringAsFixed(0);
      _paCartonCtrl.text = (pu * uPlq * plqBte * bteCrt).toStringAsFixed(0);
    }
    if (pv > 0) {
      _pvPlaquetteCtrl.text = (pv * uPlq).toStringAsFixed(0);
      _pvBoiteCtrl.text = (pv * uPlq * plqBte).toStringAsFixed(0);
      _pvCartonCtrl.text = (pv * uPlq * plqBte * bteCrt).toStringAsFixed(0);
    }
    setState(() {});
  }

  // ============================================================
  // 📊 APERÇU FINANCIER
  // ============================================================
  Widget _buildFinancialPreview() {
    final isPositive = _marge >= 0;
    final color = isPositive ? kSuccessColor : kDangerColor;

    return Container(
      padding: const EdgeInsets.all(kPaddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(15), color.withAlpha(5)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                'Aperçu financier',
                style: GoogleFonts.inter(
                  fontSize: kFontSizeM,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_showPrixComprime)
            _buildMargeRow('Comprimé', _marge, _margePercent, color),
          if (_showPrixPlaquette)
            _buildMargeRow(
              'Plaquette',
              _margeNiveau(_paPlaquetteCtrl, _pvPlaquetteCtrl),
              _margePctNiveau(_paPlaquetteCtrl, _pvPlaquetteCtrl),
              color,
            ),
          if (_showPrixBoite)
            _buildMargeRow(
              'Boîte',
              _margeNiveau(_paBoiteCtrl, _pvBoiteCtrl),
              _margePctNiveau(_paBoiteCtrl, _pvBoiteCtrl),
              color,
            ),
          if (_showPrixCarton)
            _buildMargeRow(
              'Carton',
              _margeNiveau(_paCartonCtrl, _pvCartonCtrl),
              _margePctNiveau(_paCartonCtrl, _pvCartonCtrl),
              color,
            ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bénéfice total',
                style: GoogleFonts.inter(
                  fontSize: kFontSizeM,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                '${_beneficeEstime.toStringAsFixed(0)} FBu',
                style: GoogleFonts.inter(
                  fontSize: kFontSizeL,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMargeRow(String level, double marge, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              level,
              style: GoogleFonts.inter(
                fontSize: kFontSizeS,
                color: kTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${marge.toStringAsFixed(0)} FBu',
              style: GoogleFonts.inter(
                fontSize: kFontSizeS,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: kFontSizeS,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🧩 SECTION WRAPPER
  // ============================================================
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: kPrimaryColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: kFontSizeM,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
        const SizedBox(height: kPaddingS),
        ...children,
      ],
    );
  }

  // ============================================================
  // ✅ BOUTONS D'ACTION
  // ============================================================
  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveMedicament,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
          label: Text(_isEditing ? 'Modifier' : 'Ajouter'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        if (!_isEditing) ...[
          const SizedBox(height: kPaddingS),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _saveAndContinue,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Ajouter et continuer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: kPrimaryColor),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // 💾 SAUVEGARDE
  // ============================================================
  Medicament? _buildMedicament() {
    if (!_formKey.currentState!.validate()) return null;
    if (_modeDetaille && _quantiteTotale <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Le conditionnement doit donner une quantité > 0',
          ),
          backgroundColor: kDangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return null;
    }

    // Vérifier qu'au moins un prix est saisi
    final pu = double.tryParse(_puCtrl.text) ?? 0;
    final pv = double.tryParse(_pvCtrl.text) ?? 0;
    final paPlq = double.tryParse(_paPlaquetteCtrl.text) ?? 0;
    final pvPlq = double.tryParse(_pvPlaquetteCtrl.text) ?? 0;
    final paBte = double.tryParse(_paBoiteCtrl.text) ?? 0;
    final pvBte = double.tryParse(_pvBoiteCtrl.text) ?? 0;
    final paCrt = double.tryParse(_paCartonCtrl.text) ?? 0;
    final pvCrt = double.tryParse(_pvCartonCtrl.text) ?? 0;

    final hasAnyPrice = pu > 0 || pv > 0 || paPlq > 0 || pvPlq > 0 ||
        paBte > 0 || pvBte > 0 || paCrt > 0 || pvCrt > 0;

    if (!hasAnyPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Sélectionnez un niveau et saisissez au moins un prix',
          ),
          backgroundColor: kDangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return null;
    }

    return Medicament(
      nom: _nomCtrl.text.trim(),
      forme: _forme,
      quantiteInitiale: _quantiteTotale,
      prixUnitaire: pu,
      prixVente: pv,
      dateEntreeStock: _dateEntreeStock,
      nbCartons: _modeDetaille ? int.tryParse(_cartonsCtrl.text) : null,
      boitesParCarton: _modeDetaille ? int.tryParse(_boitesCtrl.text) : null,
      plaquettesParBoite: _modeDetaille
          ? int.tryParse(_plaquettesCtrl.text)
          : null,
      unitesParPlaquette: _modeDetaille
          ? int.tryParse(_unitesCtrl.text)
          : null,
      prixAchatCarton: _showPrixCarton ? double.tryParse(_paCartonCtrl.text) : null,
      prixAchatBoite: _showPrixBoite ? double.tryParse(_paBoiteCtrl.text) : null,
      prixAchatPlaquette: _showPrixPlaquette ? double.tryParse(_paPlaquetteCtrl.text) : null,
      prixVenteCarton: _showPrixCarton ? double.tryParse(_pvCartonCtrl.text) : null,
      prixVenteBoite: _showPrixBoite ? double.tryParse(_pvBoiteCtrl.text) : null,
      prixVentePlaquette: _showPrixPlaquette ? double.tryParse(_pvPlaquetteCtrl.text) : null,
    );
  }

  Future<void> _saveMedicament() async {
    final med = _buildMedicament();
    if (med == null) return;

    setState(() => _isSaving = true);
    final provider = context.read<ControleProvider>();

    if (_isEditing && widget.editIndex != null) {
      await provider.mettreAJourMedicament(widget.editIndex!, med);
    } else {
      await provider.ajouterMedicament(med);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? '${med.nom} modifié ✓' : '${med.nom} ajouté ✓',
        ),
        backgroundColor: kSuccessColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _saveAndContinue() async {
    final med = _buildMedicament();
    if (med == null) return;

    setState(() => _isSaving = true);
    await context.read<ControleProvider>().ajouterMedicament(med);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${med.nom} ajouté ✓'),
        backgroundColor: kSuccessColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    _nomCtrl.clear();
    _qteDirecteCtrl.clear();
    _cartonsCtrl.clear();
    _boitesCtrl.clear();
    _plaquettesCtrl.clear();
    _unitesCtrl.clear();
    _paCartonCtrl.clear();
    _paBoiteCtrl.clear();
    _paPlaquetteCtrl.clear();
    _pvCartonCtrl.clear();
    _pvBoiteCtrl.clear();
    _pvPlaquetteCtrl.clear();
    _dateEntreeStock = null;
    _nomFocus.requestFocus();
    setState(() {});
  }
}
