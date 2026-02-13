import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/trip.dart';
import '../models/geo_point.dart';
import 'map_service.dart';
import 'user_service.dart'; // ✅ AJOUTER CET IMPORT

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final MapService _mapService = MapService();
  final UserService _userService = UserService(); // ✅ AJOUTER CETTE LIGNE

  // Collection des trajets
  CollectionReference get _tripsCollection => _firestore.collection('trips');

  // Créer un nouveau trajet
  Future<String?> createTrip({
    required AppGeoPoint pointDepart,
    required AppGeoPoint pointArrivee,
    required DateTime dateHeureDepart,
    required int placesTotal,
    required double prix,
    String? commentaire,
    bool fumeursAcceptes = false,
    bool animauxAcceptes = false,
    bool musiqueOk = true,
    bool discussionOk = true,
  }) async {
    try {
      // 🔐 Vérifier utilisateur connecté
      final conducteurId = _auth.currentUser?.uid;
      if (conducteurId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // 👤 Récupérer l'utilisateur
      final currentUser =
          await _userService.getCurrentUser(); // ✅ UTILISER _userService

      if (currentUser == null) {
        throw Exception('Utilisateur introuvable');
      }

      // 🚗 Vérifier qu'il est conducteur
      if (!currentUser.estConducteur) {
        throw Exception('Vous devez être conducteur pour créer un trajet');
      }

      // 🚘 Vérifier les infos du véhicule (obligatoires)
      if (currentUser.immatriculation == null ||
          currentUser.immatriculation!.trim().isEmpty) {
        throw Exception(
          'Informations du véhicule manquantes. Veuillez compléter votre profil.',
        );
      }

      // 🗺️ Calculer la distance et la durée
      final routeInfo = await _mapService.getRouteInfo(
        pointDepart,
        pointArrivee,
      );

      // 🧳 Créer le trajet
      final Trip newTrip = Trip(
        id: '',
        conducteurId: conducteurId,
        pointDepart: pointDepart,
        pointArrivee: pointArrivee,
        dateHeureDepart: dateHeureDepart,
        placesDisponibles: placesTotal,
        placesTotal: placesTotal,
        prix: prix,
        commentaire: commentaire,
        statut: 'actif',
        dateCreation: DateTime.now(),
        distance: routeInfo?.distance,
        duree: routeInfo?.durationText,
        fumeursAcceptes: fumeursAcceptes,
        animauxAcceptes: animauxAcceptes,
        musiqueOk: musiqueOk,
        discussionOk: discussionOk,
      );

      // 💾 Enregistrer dans Firestore
      final docRef = await _tripsCollection.add(newTrip.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création du trajet: $e');
      rethrow;
    }
  }

  // Obtenir un trajet par son ID
  Future<Trip?> getTripById(String tripId) async {
    try {
      DocumentSnapshot doc = await _tripsCollection.doc(tripId).get();

      if (doc.exists) {
        return Trip.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du trajet: $e');
      return null;
    }
  }

  // Obtenir tous les trajets actifs
  Stream<List<Trip>> getActiveTrips() {
    return _tripsCollection
        .where('statut', isEqualTo: 'actif')
        .where('dateHeureDepart', isGreaterThan: Timestamp.now())
        .orderBy('dateHeureDepart')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList(),
        );
  }

  // Obtenir les trajets d'un conducteur
  Stream<List<Trip>> getTripsByConducteur(String conducteurId) {
    return _tripsCollection
        .where('conducteurId', isEqualTo: conducteurId)
        .orderBy('dateHeureDepart', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList(),
        );
  }

  // Obtenir mes trajets (conducteur)
  Stream<List<Trip>> getMyTrips() {
    String? conducteurId = _auth.currentUser?.uid;
    if (conducteurId == null) return Stream.value([]);

    return getTripsByConducteur(conducteurId);
  }

  // Rechercher des trajets par ville de départ et d'arrivée
  Future<List<Trip>> searchTrips({
    required String villeDepart,
    required String villeArrivee,
    DateTime? date,
  }) async {
    try {
      Query query = _tripsCollection
          .where('statut', isEqualTo: 'actif')
          .where('dateHeureDepart', isGreaterThan: Timestamp.now());

      // Si une date est spécifiée, filtrer par date
      if (date != null) {
        DateTime startOfDay = DateTime(date.year, date.month, date.day);
        DateTime endOfDay = startOfDay.add(const Duration(days: 1));

        query = query
            .where(
              'dateHeureDepart',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('dateHeureDepart', isLessThan: Timestamp.fromDate(endOfDay));
      }

      QuerySnapshot snapshot = await query.get();

      List<Trip> trips =
          snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();

      // Filtrer par ville (car Firestore ne peut pas faire de recherche sur plusieurs champs)
      trips = trips.where((trip) {
        bool departMatch = trip.pointDepart.city?.toLowerCase().contains(
                  villeDepart.toLowerCase(),
                ) ??
            false;
        bool arriveeMatch = trip.pointArrivee.city?.toLowerCase().contains(
                  villeArrivee.toLowerCase(),
                ) ??
            false;

        return departMatch && arriveeMatch;
      }).toList();

      return trips;
    } catch (e) {
      print('Erreur lors de la recherche de trajets: $e');
      return [];
    }
  }

  // Mettre à jour le statut d'un trajet
  Future<void> updateTripStatus(String tripId, String statut) async {
    try {
      await _tripsCollection.doc(tripId).update({'statut': statut});
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      rethrow;
    }
  }

  // Réduire le nombre de places disponibles
  Future<void> reducePlacesDisponibles(String tripId, int nombrePlaces) async {
    try {
      DocumentSnapshot doc = await _tripsCollection.doc(tripId).get();
      Trip trip = Trip.fromFirestore(doc);

      int nouvellesPlaces = trip.placesDisponibles - nombrePlaces;

      // Mettre à jour le statut si complet
      String nouveauStatut = nouvellesPlaces <= 0 ? 'complet' : trip.statut;

      await _tripsCollection.doc(tripId).update({
        'placesDisponibles': nouvellesPlaces,
        'statut': nouveauStatut,
      });
    } catch (e) {
      print('Erreur lors de la réduction des places: $e');
      rethrow;
    }
  }

  // Augmenter le nombre de places disponibles (annulation)
  Future<void> increasePlacesDisponibles(
    String tripId,
    int nombrePlaces,
  ) async {
    try {
      DocumentSnapshot doc = await _tripsCollection.doc(tripId).get();
      Trip trip = Trip.fromFirestore(doc);

      int nouvellesPlaces = trip.placesDisponibles + nombrePlaces;

      await _tripsCollection.doc(tripId).update({
        'placesDisponibles': nouvellesPlaces,
        'statut': 'actif',
      });
    } catch (e) {
      print('Erreur lors de l\'augmentation des places: $e');
      rethrow;
    }
  }

  // Supprimer un trajet (seulement si c'est le conducteur)
  Future<void> deleteTrip(String tripId) async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier que l'utilisateur est bien le conducteur du trajet
      DocumentSnapshot tripDoc = await _tripsCollection.doc(tripId).get();

      if (!tripDoc.exists) {
        throw Exception('Trajet introuvable');
      }

      Trip trip = Trip.fromFirestore(tripDoc);

      if (trip.conducteurId != currentUserId) {
        throw Exception('Vous n\'êtes pas autorisé à supprimer ce trajet');
      }

      // Supprimer toutes les réservations associées
      QuerySnapshot reservations = await _firestore
          .collection('reservations')
          .where('trajetId', isEqualTo: tripId)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in reservations.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer le trajet
      batch.delete(_tripsCollection.doc(tripId));

      await batch.commit();

      print(
        '✅ Trajet $tripId et ${reservations.docs.length} réservation(s) supprimé(s)',
      );
    } catch (e) {
      print('❌ Erreur lors de la suppression du trajet: $e');
      rethrow;
    }
  }

  // Supprimer automatiquement les trajets expirés (à appeler périodiquement)
  Future<void> deleteExpiredTrips({int hoursAfterDeparture = 48}) async {
    try {
      final now = DateTime.now();
      final expirationDate = now.subtract(Duration(hours: hoursAfterDeparture));

      // Récupérer les trajets expirés
      QuerySnapshot expiredTrips = await _tripsCollection
          .where(
            'dateHeureDepart',
            isLessThan: Timestamp.fromDate(expirationDate),
          )
          .get();

      if (expiredTrips.docs.isEmpty) {
        print('ℹ️ Aucun trajet expiré à supprimer');
        return;
      }

      WriteBatch batch = _firestore.batch();
      int reservationsCount = 0;

      for (var tripDoc in expiredTrips.docs) {
        // Supprimer les réservations associées
        QuerySnapshot reservations = await _firestore
            .collection('reservations')
            .where('trajetId', isEqualTo: tripDoc.id)
            .get();

        for (var resDoc in reservations.docs) {
          batch.delete(resDoc.reference);
          reservationsCount++;
        }

        // Supprimer le trajet
        batch.delete(tripDoc.reference);
      }

      await batch.commit();

      print(
        '✅ ${expiredTrips.docs.length} trajet(s) expiré(s) et $reservationsCount réservation(s) supprimé(s)',
      );
    } catch (e) {
      print('❌ Erreur lors de la suppression des trajets expirés: $e');
      // Ne pas relancer l'erreur pour ne pas bloquer l'application
    }
  }

  // Vérifier si un trajet est expiré
  bool isTripExpired(Trip trip, {int hoursAfterDeparture = 48}) {
    final now = DateTime.now();
    final expirationDate = trip.dateHeureDepart.add(
      Duration(hours: hoursAfterDeparture),
    );
    return now.isAfter(expirationDate);
  }

  // Annuler un trajet
  Future<void> cancelTrip(String tripId) async {
    try {
      await updateTripStatus(tripId, 'annule');
    } catch (e) {
      print('Erreur lors de l\'annulation du trajet: $e');
      rethrow;
    }
  }
}
