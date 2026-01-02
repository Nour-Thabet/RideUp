import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? photoUrl;
  final double noteMoyenne;
  final int nombreAvis;
  final DateTime dateInscription;
  final bool estConducteur;
  final bool estPassager;

  // Champs conducteur (si estConducteur = true)
  final String? permisConduire;
  final String? marqueVehicule;
  final String? modeleVehicule;
  final String? immatriculation;
  final int? anneeFabrication;
  final String? couleurVehicule;

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.photoUrl,
    this.noteMoyenne = 0.0,
    this.nombreAvis = 0,
    required this.dateInscription,
    this.estConducteur = false,
    this.estPassager = true,
    // Champs conducteur
    this.permisConduire,
    this.marqueVehicule,
    this.modeleVehicule,
    this.immatriculation,
    this.anneeFabrication,
    this.couleurVehicule,
  });

  // Conversion depuis Firestore
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'],
      photoUrl: data['photoUrl'],
      noteMoyenne: (data['noteMoyenne'] ?? 0.0).toDouble(),
      nombreAvis: data['nombreAvis'] ?? 0,
      dateInscription: (data['dateInscription'] as Timestamp).toDate(),
      estConducteur: data['estConducteur'] ?? false,
      estPassager: data['estPassager'] ?? true,
      // Champs conducteur
      permisConduire: data['permisConduire'],
      marqueVehicule: data['marqueVehicule'],
      modeleVehicule: data['modeleVehicule'],
      immatriculation: data['immatriculation'],
      anneeFabrication: data['anneeFabrication'],
      couleurVehicule: data['couleurVehicule'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'photoUrl': photoUrl,
      'noteMoyenne': noteMoyenne,
      'nombreAvis': nombreAvis,
      'dateInscription': Timestamp.fromDate(dateInscription),
      'estConducteur': estConducteur,
      'estPassager': estPassager,
      // Champs conducteur
      if (permisConduire != null) 'permisConduire': permisConduire,
      if (marqueVehicule != null) 'marqueVehicule': marqueVehicule,
      if (modeleVehicule != null) 'modeleVehicule': modeleVehicule,
      if (immatriculation != null) 'immatriculation': immatriculation,
      if (anneeFabrication != null) 'anneeFabrication': anneeFabrication,
      if (couleurVehicule != null) 'couleurVehicule': couleurVehicule,
    };
  }

  // Obtenir le nom complet
  String get nomComplet => '$prenom $nom';

  // Obtenir les initiales
  String get initiales {
    String firstInitial = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    String lastInitial = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  // Copier avec modifications
  User copyWith({
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? photoUrl,
    double? noteMoyenne,
    int? nombreAvis,
    DateTime? dateInscription,
    bool? estConducteur,
    bool? estPassager,
    String? permisConduire,
    String? marqueVehicule,
    String? modeleVehicule,
    String? immatriculation,
    int? anneeFabrication,
    String? couleurVehicule,
  }) {
    return User(
      id: this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      photoUrl: photoUrl ?? this.photoUrl,
      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      nombreAvis: nombreAvis ?? this.nombreAvis,
      dateInscription: dateInscription ?? this.dateInscription,
      estConducteur: estConducteur ?? this.estConducteur,
      estPassager: estPassager ?? this.estPassager,
      permisConduire: permisConduire ?? this.permisConduire,
      marqueVehicule: marqueVehicule ?? this.marqueVehicule,
      modeleVehicule: modeleVehicule ?? this.modeleVehicule,
      immatriculation: immatriculation ?? this.immatriculation,
      anneeFabrication: anneeFabrication ?? this.anneeFabrication,
      couleurVehicule: couleurVehicule ?? this.couleurVehicule,
    );
  }
}
