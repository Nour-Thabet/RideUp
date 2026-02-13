import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/reservation.dart';
import 'trip_service.dart';
import 'notification_service.dart';
import 'user_service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final TripService _tripService = TripService();
  //************************ */
  final NotificationService _notificationService = NotificationService();

  // Collection des réservations
  CollectionReference get _reservationsCollection =>
      _firestore.collection('reservations');

  // ==================== CRÉER UNE RÉSERVATION ====================
  Future<String?> createReservation({
    required String trajetId,
    required String conducteurId,
    required int nombrePlaces,
    required double montantTotal,
  }) async {
    try {
      String? passagerId = _auth.currentUser?.uid;
      if (passagerId == null) {
        throw Exception('Utilisateur non connecté');
      }

      Reservation newReservation = Reservation(
        id: '',
        trajetId: trajetId,
        passagerId: passagerId,
        conducteurId: conducteurId,
        nombrePlaces: nombrePlaces,
        montantTotal: montantTotal,
        statut: 'en_attente',
        dateReservation: DateTime.now(),
      );

      DocumentReference docRef = await _reservationsCollection.add(
        newReservation.toFirestore(),
      );
      //********************************
      // */
      await _notificationService.notifyNewReservation(
        conducteurId: conducteurId,
        passagerNom: 'Un passager', // (optionnel : vrai nom plus tard)
        trajetId: trajetId,
        reservationId: docRef.id,
      );

      // Réduire les places disponibles dans le trajet
      await _tripService.reducePlacesDisponibles(trajetId, nombrePlaces);

      print('✅ Réservation créée: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur lors de la création de la réservation: $e');
      rethrow;
    }
  }

  // ==================== OBTENIR UNE RÉSERVATION PAR ID ====================
  Future<Reservation?> getReservationById(String reservationId) async {
    try {
      DocumentSnapshot doc =
          await _reservationsCollection.doc(reservationId).get();

      if (doc.exists) {
        return Reservation.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la réservation: $e');
      return null;
    }
  }

  // ==================== OBTENIR LES RÉSERVATIONS D'UN PASSAGER ====================
  Stream<List<Reservation>> getReservationsByPassager(String passagerId) {
    return _reservationsCollection
        .where('passagerId', isEqualTo: passagerId)
        .orderBy('dateReservation', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromFirestore(doc))
              .toList(),
        );
  }

  // ==================== OBTENIR MES RÉSERVATIONS (PASSAGER) ====================
  Stream<List<Reservation>> getMyReservations() {
    String? passagerId = _auth.currentUser?.uid;
    if (passagerId == null) return Stream.value([]);

    return getReservationsByPassager(passagerId);
  }

  // ==================== OBTENIR LES RÉSERVATIONS D'UN TRAJET ====================
  Stream<List<Reservation>> getReservationsByTrip(String trajetId) {
    return _reservationsCollection
        .where('trajetId', isEqualTo: trajetId)
        .orderBy('dateReservation', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromFirestore(doc))
              .toList(),
        );
  }

  // ==================== OBTENIR LES RÉSERVATIONS POUR UN TRAJET (ALIAS) ====================
  Stream<List<Reservation>> getReservationsForTrip(String tripId) {
    return getReservationsByTrip(tripId);
  }

  // ==================== OBTENIR LES RÉSERVATIONS POUR MES TRAJETS (CONDUCTEUR) ====================
  Stream<List<Reservation>> getReservationsForMyTrips() {
    String? conducteurId = _auth.currentUser?.uid;
    if (conducteurId == null) return Stream.value([]);

    return _reservationsCollection
        .where('conducteurId', isEqualTo: conducteurId)
        .orderBy('dateReservation', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromFirestore(doc))
              .toList(),
        );
  }

  // ==================== CONFIRMER UNE RÉSERVATION (CONDUCTEUR) ====================
  Future<void> confirmerReservation(String reservationId, String tripId) async {
    try {
      await _reservationsCollection.doc(reservationId).update({
        'statut': 'confirmee',
        'dateConfirmation': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Réservation $reservationId confirmée');
    } catch (e) {
      print('❌ Erreur lors de la confirmation de la réservation: $e');
      rethrow;
    }
  }

  // ==================== REFUSER UNE RÉSERVATION (CONDUCTEUR) ====================
  Future<void> refuserReservation(String reservationId, String tripId) async {
    try {
      // Récupérer la réservation pour connaître le nombre de places
      DocumentSnapshot reservationDoc =
          await _reservationsCollection.doc(reservationId).get();

      if (!reservationDoc.exists) {
        throw Exception('Réservation introuvable');
      }

      Reservation reservation = Reservation.fromFirestore(reservationDoc);

      // Mettre à jour le statut
      await _reservationsCollection.doc(reservationId).update({
        'statut': 'refusee',
        'dateAnnulation': Timestamp.fromDate(DateTime.now()),
      });

      // Remettre les places disponibles dans le trajet
      await _tripService.increasePlacesDisponibles(
        tripId,
        reservation.nombrePlaces,
      );

      print('✅ Réservation $reservationId refusée');
    } catch (e) {
      print('❌ Erreur lors du refus de la réservation: $e');
      rethrow;
    }
  }

  // ==================== ANNULER UNE RÉSERVATION PAR LE PASSAGER ====================
  /// Annuler une réservation (par le passager uniquement si en attente)
  Future<void> annulerReservation(String reservationId) async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer la réservation
      DocumentSnapshot reservationDoc =
          await _reservationsCollection.doc(reservationId).get();

      if (!reservationDoc.exists) {
        throw Exception('Réservation introuvable');
      }

      Reservation reservation = Reservation.fromFirestore(reservationDoc);

      // Vérifier que c'est bien le passager qui annule
      if (reservation.passagerId != currentUserId) {
        throw Exception(
          'Vous n\'êtes pas autorisé à annuler cette réservation',
        );
      }

      // Vérifier que la réservation est en attente
      if (reservation.statut != 'en_attente') {
        throw Exception(
          'Seules les réservations en attente peuvent être annulées',
        );
      }

      // Mettre à jour le statut à 'annulee'
      await _reservationsCollection.doc(reservationId).update({
        'statut': 'annulee',
        'dateAnnulation': FieldValue.serverTimestamp(),
      });

      print('✅ Réservation $reservationId annulée avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'annulation de la réservation: $e');
      rethrow;
    }
  }

  // ==================== ANNULER UNE RÉSERVATION AVEC RAISON ====================
  Future<void> annulerReservationAvecRaison(
    String reservationId,
    String trajetId,
    int nombrePlaces,
    String raison,
  ) async {
    try {
      await _reservationsCollection.doc(reservationId).update({
        'statut': 'annulee',
        'dateAnnulation': Timestamp.fromDate(DateTime.now()),
        'raisonAnnulation': raison,
      });

      // Remettre les places disponibles dans le trajet
      await _tripService.increasePlacesDisponibles(trajetId, nombrePlaces);

      print('✅ Réservation $reservationId annulée');
    } catch (e) {
      print('❌ Erreur lors de l\'annulation de la réservation: $e');
      rethrow;
    }
  }

  // ==================== ANNULER UNE RÉSERVATION (VERSION SIMPLIFIÉE) ====================
  Future<void> annulerReservationSimple(
    String reservationId,
    String tripId,
  ) async {
    try {
      // Récupérer la réservation
      DocumentSnapshot reservationDoc =
          await _reservationsCollection.doc(reservationId).get();

      if (!reservationDoc.exists) {
        throw Exception('Réservation introuvable');
      }

      Reservation reservation = Reservation.fromFirestore(reservationDoc);

      // Mettre à jour le statut
      await _reservationsCollection.doc(reservationId).update({
        'statut': 'annulee',
        'dateAnnulation': Timestamp.fromDate(DateTime.now()),
      });

      // Remettre les places disponibles
      await _tripService.increasePlacesDisponibles(
        tripId,
        reservation.nombrePlaces,
      );

      print('✅ Réservation $reservationId annulée');
    } catch (e) {
      print('❌ Erreur lors de l\'annulation: $e');
      rethrow;
    }
  }

  // ==================== MARQUER UNE RÉSERVATION COMME TERMINÉE ====================
  Future<void> terminerReservation(String reservationId) async {
    try {
      await _reservationsCollection.doc(reservationId).update({
        'statut': 'terminee',
      });

      print('✅ Réservation $reservationId terminée');
    } catch (e) {
      print('❌ Erreur lors de la finalisation de la réservation: $e');
      rethrow;
    }
  }

  // ==================== COMPTER LES RÉSERVATIONS EN ATTENTE ====================
  Future<int> countPendingReservations(String conducteurId) async {
    try {
      QuerySnapshot snapshot = await _reservationsCollection
          .where('conducteurId', isEqualTo: conducteurId)
          .where('statut', isEqualTo: 'en_attente')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Erreur lors du comptage des réservations: $e');
      return 0;
    }
  }

  // ==================== VÉRIFIER SI UN PASSAGER A DÉJÀ RÉSERVÉ ====================
  Future<bool> hasReservation(String passagerId, String trajetId) async {
    try {
      QuerySnapshot snapshot = await _reservationsCollection
          .where('passagerId', isEqualTo: passagerId)
          .where('trajetId', isEqualTo: trajetId)
          .where('statut', whereIn: ['en_attente', 'confirmee']).get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erreur lors de la vérification de la réservation: $e');
      return false;
    }
  }

  // ==================== VÉRIFIER SI J'AI UNE RÉSERVATION POUR CE TRAJET ====================
  Future<bool> hasReservationForTrip(String tripId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      return await hasReservation(userId, tripId);
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');
      return false;
    }
  }

  // ==================== OBTENIR MA RÉSERVATION POUR UN TRAJET ====================
  Future<Reservation?> getMyReservationForTrip(String tripId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      QuerySnapshot snapshot = await _reservationsCollection
          .where('passagerId', isEqualTo: userId)
          .where('trajetId', isEqualTo: tripId)
          .where('statut', whereIn: ['en_attente', 'confirmee'])
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Reservation.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('❌ Erreur lors de la récupération: $e');
      return null;
    }
  }

  // ==================== SUPPRIMER UNE RÉSERVATION ====================
  Future<void> deleteReservation(String reservationId) async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer la réservation
      DocumentSnapshot reservationDoc =
          await _reservationsCollection.doc(reservationId).get();

      if (!reservationDoc.exists) {
        throw Exception('Réservation introuvable');
      }

      Reservation reservation = Reservation.fromFirestore(reservationDoc);

      // Vérifier que c'est bien le passager
      if (reservation.passagerId != currentUserId) {
        throw Exception(
          'Vous n\'êtes pas autorisé à supprimer cette réservation',
        );
      }

      // Supprimer la réservation
      await _reservationsCollection.doc(reservationId).delete();

      print('✅ Réservation $reservationId supprimée avec succès');
    } catch (e) {
      print('❌ Erreur lors de la suppression de la réservation: $e');
      rethrow;
    }
  }

  // ==================== OBTENIR LES STATISTIQUES D'UN PASSAGER ====================
  Future<Map<String, int>> getPassagerStats(String passagerId) async {
    try {
      QuerySnapshot snapshot = await _reservationsCollection
          .where('passagerId', isEqualTo: passagerId)
          .get();

      int total = snapshot.docs.length;
      int enAttente = 0;
      int confirmees = 0;
      int refusees = 0;
      int annulees = 0;
      int terminees = 0;

      for (var doc in snapshot.docs) {
        Reservation reservation = Reservation.fromFirestore(doc);
        switch (reservation.statut) {
          case 'en_attente':
            enAttente++;
            break;
          case 'confirmee':
            confirmees++;
            break;
          case 'refusee':
            refusees++;
            break;
          case 'annulee':
            annulees++;
            break;
          case 'terminee':
            terminees++;
            break;
        }
      }

      return {
        'total': total,
        'en_attente': enAttente,
        'confirmee': confirmees,
        'refusee': refusees,
        'annulee': annulees,
        'terminee': terminees,
      };
    } catch (e) {
      print('❌ Erreur lors du calcul des stats: $e');
      return {
        'total': 0,
        'en_attente': 0,
        'confirmee': 0,
        'refusee': 0,
        'annulee': 0,
        'terminee': 0,
      };
    }
  }
}
