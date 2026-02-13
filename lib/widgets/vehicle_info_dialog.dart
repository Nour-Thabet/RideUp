import 'package:flutter/material.dart';
import '../services/user_service.dart';

class VehicleInfoDialog extends StatefulWidget {
  final String userId;

  const VehicleInfoDialog({Key? key, required this.userId}) : super(key: key);

  @override
  State<VehicleInfoDialog> createState() => _VehicleInfoDialogState();
}

class _VehicleInfoDialogState extends State<VehicleInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  final TextEditingController _permisController = TextEditingController();
  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _modeleController = TextEditingController();
  final TextEditingController _immatriculationController =
      TextEditingController();
  final TextEditingController _anneeController = TextEditingController();
  final TextEditingController _couleurController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _permisController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _immatriculationController.dispose();
    _anneeController.dispose();
    _couleurController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _userService.activerModeConducteur(
        userId: widget.userId,
        permisConduire: _permisController.text.trim(),
        marqueVehicule: _marqueController.text.trim(),
        modeleVehicule: _modeleController.text.trim(),
        immatriculation: _immatriculationController.text.trim(),
        anneeFabrication: int.tryParse(_anneeController.text.trim()),
        couleurVehicule: _couleurController.text.trim().isEmpty
            ? null
            : _couleurController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Informations du véhicule'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pour proposer un trajet, vous devez renseigner les informations de votre véhicule.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Numéro de permis
              TextFormField(
                controller: _permisController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de permis *',
                  prefixIcon: Icon(Icons.card_membership),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),

              // Marque
              TextFormField(
                controller: _marqueController,
                decoration: const InputDecoration(
                  labelText: 'Marque *',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),

              // Modèle
              TextFormField(
                controller: _modeleController,
                decoration: const InputDecoration(
                  labelText: 'Modèle *',
                  prefixIcon: Icon(Icons.car_repair),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),

              // Immatriculation
              TextFormField(
                controller: _immatriculationController,
                decoration: const InputDecoration(
                  labelText: 'Immatriculation *',
                  prefixIcon: Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(),
                  hintText: '123 TU 4567',
                ),
                validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),

              // Année
              TextFormField(
                controller: _anneeController,
                decoration: const InputDecoration(
                  labelText: 'Année de fabrication',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final year = int.tryParse(v);
                    if (year == null ||
                        year < 1900 ||
                        year > DateTime.now().year) {
                      return 'Année invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Couleur
              TextFormField(
                controller: _couleurController,
                decoration: const InputDecoration(
                  labelText: 'Couleur (optionnel)',
                  prefixIcon: Icon(Icons.palette),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
