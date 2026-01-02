import 'package:cloud_firestore/cloud_firestore.dart';
import 'geo_point.dart';

class Trip {
  final String id;
  final String conducteurId;
  final AppGeoPoint pointDepart;
  final AppGeoPoint pointArrivee;
  final DateTime dateHeureDepart;
  final int placesDisponibles;
  final int placesTotal;
  final double prix;
  final String? commentaire;
  final String statut; // 'actif', 'complet', 'termine', 'annule'
  final DateTime dateCreation;

  // Informations calculées
  final double? distance; // en km
  final String? duree; // format: "2h 30min"

  // Préférences du conducteur
  final bool fumeursAcceptes;
  final bool animauxAcceptes;
  final bool musiqueOk;
  final bool discussionOk;

  Trip({
    required this.id,
    required this.conducteurId,
    required this.pointDepart,
    required this.pointArrivee,
    required this.dateHeureDepart,
    required this.placesDisponibles,
    required this.placesTotal,
    required this.prix,
    this.commentaire,
    this.statut = 'actif',
    required this.dateCreation,
    this.distance,
    this.duree,
    this.fumeursAcceptes = false,
    this.animauxAcceptes = false,
    this.musiqueOk = true,
    this.discussionOk = true,
  });

  // Conversion depuis Firestore
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Trip(
      id: doc.id,
      conducteurId: data['conducteurId'] ?? '',
      pointDepart: AppGeoPoint.fromJson(data['pointDepart'] ?? {}),
      pointArrivee: AppGeoPoint.fromJson(data['pointArrivee'] ?? {}),
      dateHeureDepart: (data['dateHeureDepart'] as Timestamp).toDate(),
      placesDisponibles: data['placesDisponibles'] ?? 0,
      placesTotal: data['placesTotal'] ?? 0,
      prix: (data['prix'] ?? 0.0).toDouble(),
      commentaire: data['commentaire'],
      statut: data['statut'] ?? 'actif',
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      distance: data['distance']?.toDouble(),
      duree: data['duree'],
      fumeursAcceptes: data['fumeursAcceptes'] ?? false,
      animauxAcceptes: data['animauxAcceptes'] ?? false,
      musiqueOk: data['musiqueOk'] ?? true,
      discussionOk: data['discussionOk'] ?? true,
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'conducteurId': conducteurId,
      'pointDepart': pointDepart.toJson(),
      'pointArrivee': pointArrivee.toJson(),
      'dateHeureDepart': Timestamp.fromDate(dateHeureDepart),
      'placesDisponibles': placesDisponibles,
      'placesTotal': placesTotal,
      'prix': prix,
      'commentaire': commentaire,
      'statut': statut,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'distance': distance,
      'duree': duree,
      'fumeursAcceptes': fumeursAcceptes,
      'animauxAcceptes': animauxAcceptes,
      'musiqueOk': musiqueOk,
      'discussionOk': discussionOk,
    };
  }

  // Vérifier si le trajet est complet
  bool get estComplet => placesDisponibles == 0 || statut == 'complet';

  // Vérifier si le trajet est dans le futur
  bool get estDansLeFutur => dateHeureDepart.isAfter(DateTime.now());

  // Vérifier si le trajet est actif
  bool get estActif => statut == 'actif' && estDansLeFutur && !estComplet;

  // Obtenir le nombre de places réservées
  int get placesReservees => placesTotal - placesDisponibles;

  // Copier avec modifications
  Trip copyWith({
    String? conducteurId,
    AppGeoPoint? pointDepart,
    AppGeoPoint? pointArrivee,
    DateTime? dateHeureDepart,
    int? placesDisponibles,
    int? placesTotal,
    double? prix,
    String? commentaire,
    String? statut,
    DateTime? dateCreation,
    double? distance,
    String? duree,
    bool? fumeursAcceptes,
    bool? animauxAcceptes,
    bool? musiqueOk,
    bool? discussionOk,
  }) {
    return Trip(
      id: this.id,
      conducteurId: conducteurId ?? this.conducteurId,
      pointDepart: pointDepart ?? this.pointDepart,
      pointArrivee: pointArrivee ?? this.pointArrivee,
      dateHeureDepart: dateHeureDepart ?? this.dateHeureDepart,
      placesDisponibles: placesDisponibles ?? this.placesDisponibles,
      placesTotal: placesTotal ?? this.placesTotal,
      prix: prix ?? this.prix,
      commentaire: commentaire ?? this.commentaire,
      statut: statut ?? this.statut,
      dateCreation: dateCreation ?? this.dateCreation,
      distance: distance ?? this.distance,
      duree: duree ?? this.duree,
      fumeursAcceptes: fumeursAcceptes ?? this.fumeursAcceptes,
      animauxAcceptes: animauxAcceptes ?? this.animauxAcceptes,
      musiqueOk: musiqueOk ?? this.musiqueOk,
      discussionOk: discussionOk ?? this.discussionOk,
    );
  }
}
