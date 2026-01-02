import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String trajetId;
  final String passagerId;
  final String conducteurId;
  final int nombrePlaces;
  final double montantTotal;
  final String
  statut; // 'en_attente', 'confirmee', 'refusee', 'annulee', 'terminee'
  final DateTime dateReservation;
  final DateTime? dateConfirmation;
  final DateTime? dateAnnulation;
  final String? raisonAnnulation;

  Reservation({
    required this.id,
    required this.trajetId,
    required this.passagerId,
    required this.conducteurId,
    required this.nombrePlaces,
    required this.montantTotal,
    this.statut = 'en_attente',
    required this.dateReservation,
    this.dateConfirmation,
    this.dateAnnulation,
    this.raisonAnnulation,
  });

  // Conversion depuis Firestore
  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Reservation(
      id: doc.id,
      trajetId: data['trajetId'] ?? '',
      passagerId: data['passagerId'] ?? '',
      conducteurId: data['conducteurId'] ?? '',
      nombrePlaces: data['nombrePlaces'] ?? 1,
      montantTotal: (data['montantTotal'] ?? 0.0).toDouble(),
      statut: data['statut'] ?? 'en_attente',
      dateReservation: (data['dateReservation'] as Timestamp).toDate(),
      dateConfirmation: data['dateConfirmation'] != null
          ? (data['dateConfirmation'] as Timestamp).toDate()
          : null,
      dateAnnulation: data['dateAnnulation'] != null
          ? (data['dateAnnulation'] as Timestamp).toDate()
          : null,
      raisonAnnulation: data['raisonAnnulation'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'trajetId': trajetId,
      'passagerId': passagerId,
      'conducteurId': conducteurId,
      'nombrePlaces': nombrePlaces,
      'montantTotal': montantTotal,
      'statut': statut,
      'dateReservation': Timestamp.fromDate(dateReservation),
      if (dateConfirmation != null)
        'dateConfirmation': Timestamp.fromDate(dateConfirmation!),
      if (dateAnnulation != null)
        'dateAnnulation': Timestamp.fromDate(dateAnnulation!),
      if (raisonAnnulation != null) 'raisonAnnulation': raisonAnnulation,
    };
  }

  // Vérifier si la réservation est confirmée
  bool get estConfirmee => statut == 'confirmee';

  // Vérifier si la réservation est en attente
  bool get estEnAttente => statut == 'en_attente';

  // Vérifier si la réservation est annulée
  bool get estAnnulee => statut == 'annulee' || statut == 'refusee';

  // Vérifier si la réservation est terminée
  bool get estTerminee => statut == 'terminee';

  // Copier avec modifications
  Reservation copyWith({
    String? trajetId,
    String? passagerId,
    String? conducteurId,
    int? nombrePlaces,
    double? montantTotal,
    String? statut,
    DateTime? dateReservation,
    DateTime? dateConfirmation,
    DateTime? dateAnnulation,
    String? raisonAnnulation,
  }) {
    return Reservation(
      id: this.id,
      trajetId: trajetId ?? this.trajetId,
      passagerId: passagerId ?? this.passagerId,
      conducteurId: conducteurId ?? this.conducteurId,
      nombrePlaces: nombrePlaces ?? this.nombrePlaces,
      montantTotal: montantTotal ?? this.montantTotal,
      statut: statut ?? this.statut,
      dateReservation: dateReservation ?? this.dateReservation,
      dateConfirmation: dateConfirmation ?? this.dateConfirmation,
      dateAnnulation: dateAnnulation ?? this.dateAnnulation,
      raisonAnnulation: raisonAnnulation ?? this.raisonAnnulation,
    );
  }
}
