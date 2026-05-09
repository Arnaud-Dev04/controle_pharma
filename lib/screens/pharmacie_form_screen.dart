/// Formulaire de création / édition d'une pharmacie
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pharmacie.dart';
import '../providers/pharmacie_provider.dart';
import '../utils/constants.dart';

class PharmacieFormScreen extends StatefulWidget {
  /// Null = mode création, non-null = mode édition
  final Pharmacie? pharmacie;

  const PharmacieFormScreen({super.key, this.pharmacie});

  @override
  State<PharmacieFormScreen> createState() => _PharmacieFormScreenState();
}

class _PharmacieFormScreenState extends State<PharmacieFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _adresseCtrl;
  late TextEditingController _telCtrl;
  bool _isSaving = false;

  bool get _isEditMode => widget.pharmacie != null;

  @override
  void initState() {
    super.initState();
    _nomCtrl =
        TextEditingController(text: widget.pharmacie?.nom ?? '');
    _adresseCtrl =
        TextEditingController(text: widget.pharmacie?.adresse ?? '');
    _telCtrl =
        TextEditingController(text: widget.pharmacie?.telephone ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _adresseCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Modifier la pharmacie' : 'Nouvelle pharmacie',
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône décorative
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kPrimaryDarkColor, kPrimaryColor],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withAlpha(80),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: kPaddingXL),

              // Nom (obligatoire)
              _buildSectionLabel('Nom de la pharmacie *'),
              const SizedBox(height: kPaddingS),
              TextFormField(
                controller: _nomCtrl,
                autofocus: !_isEditMode,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Ex: Pharmacie Centrale',
                  prefixIcon: Icon(Icons.store_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: kPaddingM),

              // Adresse (optionnel)
              _buildSectionLabel('Adresse (optionnel)'),
              const SizedBox(height: kPaddingS),
              TextFormField(
                controller: _adresseCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  hintText: 'Ex: Avenue de la République, Bujumbura',
                  prefixIcon: Icon(Icons.location_on_rounded),
                ),
              ),
              const SizedBox(height: kPaddingM),

              // Téléphone (optionnel)
              _buildSectionLabel('Téléphone (optionnel)'),
              const SizedBox(height: kPaddingS),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: 'Ex: +257 79 000 000',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
              const SizedBox(height: kPaddingXL),

              // Bouton sauvegarder
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _sauvegarder,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isEditMode
                              ? Icons.save_rounded
                              : Icons.add_business_rounded,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Enregistrement...'
                        : _isEditMode
                            ? 'Enregistrer les modifications'
                            : 'Créer la pharmacie',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: kFontSizeS,
        fontWeight: FontWeight.w600,
        color: kTextSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<PharmacieProvider>();
    bool success;

    if (_isEditMode) {
      final updated = widget.pharmacie!.copyWith(
        nom: _nomCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
      );
      success = await provider.mettreAJourPharmacie(updated);
    } else {
      final result = await provider.creerPharmacie(
        nom: _nomCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
      );
      success = result != null;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Pharmacie mise à jour ✓'
                : 'Pharmacie créée ✓',
          ),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue'),
          backgroundColor: kDangerColor,
        ),
      );
    }
  }
}
