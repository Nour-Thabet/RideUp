import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/avatar_widget.dart';
import 'avatar_selector_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();

  // ✅ NOUVEAUX CONTRÔLEURS POUR LE VÉHICULE
  final TextEditingController _permisController = TextEditingController();
  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _modeleController = TextEditingController();
  final TextEditingController _immatriculationController =
      TextEditingController();
  final TextEditingController _anneeController = TextEditingController();
  final TextEditingController _couleurController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _showVehicleSection = false; // ✅ Afficher la section véhicule

  User? _currentUser;
  String? _selectedAvatarPath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _permisController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _immatriculationController.dispose();
    _anneeController.dispose();
    _couleurController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUser();

      if (user != null) {
        setState(() {
          _currentUser = user;
          _nomController.text = user.nom;
          _prenomController.text = user.prenom;
          _telephoneController.text = user.telephone ?? '';
          _selectedAvatarPath = user.photoUrl;

          // ✅ CHARGER LES INFOS DU VÉHICULE
          _permisController.text = user.permisConduire ?? '';
          _marqueController.text = user.marqueVehicule ?? '';
          _modeleController.text = user.modeleVehicule ?? '';
          _immatriculationController.text = user.immatriculation ?? '';
          _anneeController.text = user.anneeFabrication?.toString() ?? '';
          _couleurController.text = user.couleurVehicule ?? '';

          _showVehicleSection = user.estConducteur ||
              (user.immatriculation != null &&
                  user.immatriculation!.isNotEmpty);

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectAvatar() async {
    final avatar = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const AvatarSelectorScreen()),
    );

    if (avatar != null && mounted) {
      setState(() => _selectedAvatarPath = avatar);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // ✅ SAUVEGARDER LES INFOS DE BASE
      await _userService.updateUser(
        userId: userId,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        photoUrl: _selectedAvatarPath,
      );

      // ✅ SAUVEGARDER LES INFOS DU VÉHICULE SI RENSEIGNÉES
      if (_showVehicleSection &&
          _immatriculationController.text.trim().isNotEmpty) {
        await _userService.activerModeConducteur(
          userId: userId,
          permisConduire: _permisController.text.trim(),
          marqueVehicule: _marqueController.text.trim(),
          modeleVehicule: _modeleController.text.trim(),
          immatriculation: _immatriculationController.text.trim(),
          anneeFabrication: int.tryParse(_anneeController.text.trim()),
          couleurVehicule: _couleurController.text.trim().isEmpty
              ? null
              : _couleurController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
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

  String _getInitials() {
    final p = _prenomController.text.trim();
    final n = _nomController.text.trim();

    if (p.isEmpty && n.isEmpty) {
      return _auth.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U';
    }

    return '${p.isNotEmpty ? p[0] : ''}${n.isNotEmpty ? n[0] : ''}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(color: Colors.white),
                  ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: _selectAvatar,
                        child: Stack(
                          children: [
                            AvatarWidget(
                              photoUrl: _selectedAvatarPath,
                              initiales: _getInitials(),
                              radius: 60,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ==================== INFORMATIONS PERSONNELLES ====================
                    const Text(
                      'Informations personnelles',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    // ==================== INFORMATIONS DU VÉHICULE ====================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Informations du véhicule',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _showVehicleSection,
                          onChanged: (value) {
                            setState(() => _showVehicleSection = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Renseignez ces informations pour proposer des trajets',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),

                    if (_showVehicleSection) ...[
                      TextFormField(
                        controller: _permisController,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de permis *',
                          prefixIcon: Icon(Icons.card_membership),
                          border: OutlineInputBorder(),
                        ),
                        validator: _showVehicleSection
                            ? (v) => v!.isEmpty ? 'Obligatoire' : null
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _marqueController,
                        decoration: const InputDecoration(
                          labelText: 'Marque *',
                          prefixIcon: Icon(Icons.directions_car),
                          border: OutlineInputBorder(),
                        ),
                        validator: _showVehicleSection
                            ? (v) => v!.isEmpty ? 'Obligatoire' : null
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _modeleController,
                        decoration: const InputDecoration(
                          labelText: 'Modèle *',
                          prefixIcon: Icon(Icons.car_repair),
                          border: OutlineInputBorder(),
                        ),
                        validator: _showVehicleSection
                            ? (v) => v!.isEmpty ? 'Obligatoire' : null
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _immatriculationController,
                        decoration: const InputDecoration(
                          labelText: 'Immatriculation *',
                          prefixIcon: Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(),
                          hintText: '123 TU 4567',
                        ),
                        validator: _showVehicleSection
                            ? (v) => v!.isEmpty ? 'Obligatoire' : null
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _anneeController,
                        decoration: const InputDecoration(
                          labelText: 'Année de fabrication',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _couleurController,
                        decoration: const InputDecoration(
                          labelText: 'Couleur',
                          prefixIcon: Icon(Icons.palette),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Enregistrer les modifications'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
