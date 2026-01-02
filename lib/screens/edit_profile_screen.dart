import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Contrôleurs de texte
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  User? _currentUser;

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
    super.dispose();
  }

  // Charger les données de l'utilisateur
  Future<void> _loadUserData() async {
    try {
      User? user = await _userService.getCurrentUser();

      if (user != null) {
        setState(() {
          _currentUser = user;
          _nomController.text = user.nom;
          _prenomController.text = user.prenom;
          _telephoneController.text = user.telephone ?? '';
          _isLoading = false;
        });
      } else {
        // Créer un nouveau profil si l'utilisateur n'existe pas
        final authUser = _auth.currentUser;
        if (authUser != null) {
          await _userService.createUser(
            userId: authUser.uid,
            email: authUser.email ?? '',
            nom: '',
            prenom: '',
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement du profil: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Enregistrer les modifications
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier si l'utilisateur existe
      bool userExists = await _userService.userExists(userId);

      if (userExists) {
        // Mettre à jour l'utilisateur existant
        await _userService.updateUser(
          userId: userId,
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim().isEmpty
              ? null
              : _telephoneController.text.trim(),
        );
      } else {
        // Créer un nouvel utilisateur
        await _userService.createUser(
          userId: userId,
          email: _auth.currentUser?.email ?? '',
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim().isEmpty
              ? null
              : _telephoneController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Enregistrer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
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
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: _currentUser?.photoUrl != null
                                ? NetworkImage(_currentUser!.photoUrl!)
                                : null,
                            child: _currentUser?.photoUrl == null
                                ? Text(
                                    _getInitials(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
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
                    const SizedBox(height: 32),

                    // Email (non modifiable)
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _auth.currentUser?.email ?? 'Non disponible',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Prénom
                    const Text(
                      'Prénom *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _prenomController,
                      decoration: InputDecoration(
                        hintText: 'Entrez votre prénom',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le prénom est obligatoire';
                        }
                        if (value.trim().length < 2) {
                          return 'Le prénom doit contenir au moins 2 caractères';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),

                    // Nom
                    const Text(
                      'Nom *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomController,
                      decoration: InputDecoration(
                        hintText: 'Entrez votre nom',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est obligatoire';
                        }
                        if (value.trim().length < 2) {
                          return 'Le nom doit contenir au moins 2 caractères';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),

                    // Téléphone
                    const Text(
                      'Téléphone (optionnel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _telephoneController,
                      decoration: InputDecoration(
                        hintText: '+33 6 12 34 56 78',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
                          if (!phoneRegex.hasMatch(value.trim())) {
                            return 'Format de téléphone invalide';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Bouton Enregistrer
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Enregistrer les modifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Les champs marqués d\'un * sont obligatoires',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Obtenir les initiales pour l'avatar
  String _getInitials() {
    final prenom = _prenomController.text.trim();
    final nom = _nomController.text.trim();

    if (prenom.isEmpty && nom.isEmpty) {
      return _auth.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U';
    }

    String initiales = '';
    if (prenom.isNotEmpty) initiales += prenom[0].toUpperCase();
    if (nom.isNotEmpty) initiales += nom[0].toUpperCase();

    return initiales.isEmpty ? 'U' : initiales;
  }
}
