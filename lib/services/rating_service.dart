import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/rating.dart';
import 'user_service.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Collection des évaluations
  CollectionReference get _ratingsCollection =>
      _firestore.collection('ratings');

  // Créer une évaluation
  Future<String?> createRating({
    required String trajetId,
    required String evalueId,
    required double note,
    String? commentaire,
    required String type, // 'conducteur' ou 'passager'
  }) async {
    try {
      String evaluateurId = _auth.currentUser!.uid;

      // Vérifier si l'utilisateur a déjà noté cette personne pour ce trajet
      bool hasRated = await hasRatedUser(trajetId, evalueId);
      if (hasRated) {
        throw Exception('Vous avez déjà noté cet utilisateur pour ce trajet');
      }

      Rating newRating = Rating(
        id: '',
        trajetId: trajetId,
        evaluateurId: evaluateurId,
        evalueId: evalueId,
        note: note,
        commentaire: commentaire,
        dateEvaluation: DateTime.now(),
        type: type,
      );

      DocumentReference docRef = await _ratingsCollection.add(
        newRating.toFirestore(),
      );

      // Mettre à jour la note moyenne de l'utilisateur évalué
      await _userService.updateNoteMoyenne(evalueId, note);

      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de l\'évaluation: $e');
      rethrow;
    }
  }

  // Vérifier si un utilisateur a déjà noté un autre pour un trajet
  Future<bool> hasRatedUser(String trajetId, String evalueId) async {
    try {
      String evaluateurId = _auth.currentUser!.uid;

      QuerySnapshot snapshot = await _ratingsCollection
          .where('trajetId', isEqualTo: trajetId)
          .where('evaluateurId', isEqualTo: evaluateurId)
          .where('evalueId', isEqualTo: evalueId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      return false;
    }
  }

  // Obtenir les évaluations reçues par un utilisateur (Future - pour compatibilité)
  Future<List<Rating>> getRatingsForUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _ratingsCollection
          .where('evalueId', isEqualTo: userId)
          .orderBy('dateEvaluation', descending: true)
          .get();

      return snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des évaluations: $e');
      return [];
    }
  }

  // Obtenir les évaluations données par un utilisateur (Future - pour compatibilité)
  Future<List<Rating>> getRatingsByUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _ratingsCollection
          .where('evaluateurId', isEqualTo: userId)
          .orderBy('dateEvaluation', descending: true)
          .get();

      return snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des évaluations: $e');
      return [];
    }
  }

  // === NOUVELLES MÉTHODES : STREAMS EN TEMPS RÉEL ===

  /// Stream des évaluations reçues par un utilisateur
  Stream<List<Rating>> getRatingsReceivedStream(String userId) {
    return _ratingsCollection
        .where('evalueId', isEqualTo: userId)
        .orderBy('dateEvaluation', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList(),
        );
  }

  /// Stream des évaluations données par un utilisateur
  Stream<List<Rating>> getRatingsGivenStream(String userId) {
    return _ratingsCollection
        .where('evaluateurId', isEqualTo: userId)
        .orderBy('dateEvaluation', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList(),
        );
  }

  // Obtenir les évaluations d'un trajet
  Future<List<Rating>> getRatingsForTrip(String trajetId) async {
    try {
      QuerySnapshot snapshot = await _ratingsCollection
          .where('trajetId', isEqualTo: trajetId)
          .orderBy('dateEvaluation', descending: true)
          .get();

      return snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des évaluations: $e');
      return [];
    }
  }

  // Obtenir une évaluation spécifique
  Future<Rating?> getRating(
    String trajetId,
    String evaluateurId,
    String evalueId,
  ) async {
    try {
      QuerySnapshot snapshot = await _ratingsCollection
          .where('trajetId', isEqualTo: trajetId)
          .where('evaluateurId', isEqualTo: evaluateurId)
          .where('evalueId', isEqualTo: evalueId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Rating.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'évaluation: $e');
      return null;
    }
  }

  // Calculer les statistiques des évaluations d'un utilisateur
  Future<Map<String, dynamic>> getRatingStats(String userId) async {
    try {
      List<Rating> ratings = await getRatingsForUser(userId);

      if (ratings.isEmpty) {
        return {
          'totalRatings': 0,
          'averageRating': 0.0,
          'starsDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      // Distribution des étoiles
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (var rating in ratings) {
        int stars = rating.note.round();
        distribution[stars] = (distribution[stars] ?? 0) + 1;
      }

      double average =
          ratings.map((r) => r.note).reduce((a, b) => a + b) / ratings.length;

      return {
        'totalRatings': ratings.length,
        'averageRating': average,
        'starsDistribution': distribution,
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {
        'totalRatings': 0,
        'averageRating': 0.0,
        'starsDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }
  }

  // Supprimer une évaluation (admin uniquement)
  Future<void> deleteRating(String ratingId) async {
    try {
      await _ratingsCollection.doc(ratingId).delete();
    } catch (e) {
      print('Erreur lors de la suppression de l\'évaluation: $e');
      rethrow;
    }
  }
}


/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/rating.dart';
import 'user_service.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Collection des évaluations
  CollectionReference get _ratingsCollection =>
      _firestore.collection('ratings');

  // Créer une évaluation
  Future<String?> createRating({
    required String trajetId,
    required String evalueId,
    required double note,
    String? commentaire,
    required String type, // 'conducteur' ou 'passager'
  }) async {
    try {
      String evaluateurId = _auth.currentUser!.uid;

      // Vérifier si l'utilisateur a déjà noté cette personne pour ce trajet
      bool hasRated = await hasRatedUser(trajetId, evalueId);
      if (hasRated) {
        throw Exception('Vous avez déjà noté cet utilisateur pour ce trajet');
      }

      Rating newRating = Rating(
        id: '',
        trajetId: trajetId,
        evaluateurId: evaluateurId,
        evalueId: evalueId,
        note: note,
        commentaire: commentaire,
        dateEvaluation: DateTime.now(),
        type: type,
      );

      DocumentReference docRef = await _ratingsCollection.add(
        newRating.toFirestore(),
      );

      // Mettre à jour la note moyenne de l'utilisateur évalué
      await _userService.updateNoteMoyenne(evalueId, note);

      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de l\'évaluation: $e');
      rethrow;
    }
  }

  // Vérifier si un utilisateur a déjà noté un autre pour un trajet
  Future<bool> hasRatedUser(String trajetId, String evalueId) async {
    try {
      String evaluateurId = _auth.currentUser!.uid;

      QuerySnapshot snapshot = await _ratingsCollection
          .where('trajetId', isEqualTo: trajetId)
          .where('evaluateurId', isEqualTo: evaluateurId)
          .where('evalueId', isEqualTo: evalueId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      return false;
    }
  }

  // Obtenir les évaluations d'un utilisateur
  Future<List<Rating>> getRatingsForUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _ratingsCollection
          .where('evalueId', isEqualTo: userId)
          .orderBy('dateEvaluation', descending: true)
          .get();

      return snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des évaluations: $e');
      return [];
    }
  }

  // Obtenir les évaluations données par un utilisateur
  Future<List<Rating>> getRatingsByUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _ratingsCollection
          .where('evaluateurId', isEqualTo: userId)
          .orderBy('dateEvaluation', descending: true)
          .get();

      return snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des évaluations: $e');
      return [];
    }
  }

  // Obtenir les évaluations d'un trajet
  Future<List<Rating>> getRatingsForTrip(String trajetId) async {
    try {
      QuerySnapshot snapshot = await _ratingsCollection
          .where('trajetId', isEqualTo: trajetId)
          .orderBy('dateEvaluation', descending: true)
          .get();

      return snapshot.docs.map((doc) => Rating.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des évaluations: $e');
      return [];
    }
  }

  // Obtenir une évaluation spécifique
  Future<Rating?> getRating(
    String trajetId,
    String evaluateurId,
    String evalueId,
  ) async {
    try {
      QuerySnapshot snapshot = await _ratingsCollection
          .where('trajetId', isEqualTo: trajetId)
          .where('evaluateurId', isEqualTo: evaluateurId)
          .where('evalueId', isEqualTo: evalueId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Rating.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'évaluation: $e');
      return null;
    }
  }

  // Calculer les statistiques des évaluations d'un utilisateur
  Future<Map<String, dynamic>> getRatingStats(String userId) async {
    try {
      List<Rating> ratings = await getRatingsForUser(userId);

      if (ratings.isEmpty) {
        return {
          'totalRatings': 0,
          'averageRating': 0.0,
          'starsDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      // Distribution des étoiles
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (var rating in ratings) {
        int stars = rating.note.round();
        distribution[stars] = (distribution[stars] ?? 0) + 1;
      }

      double average =
          ratings.map((r) => r.note).reduce((a, b) => a + b) / ratings.length;

      return {
        'totalRatings': ratings.length,
        'averageRating': average,
        'starsDistribution': distribution,
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {
        'totalRatings': 0,
        'averageRating': 0.0,
        'starsDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }
  }

  // Supprimer une évaluation (admin uniquement)
  Future<void> deleteRating(String ratingId) async {
    try {
      await _ratingsCollection.doc(ratingId).delete();
    } catch (e) {
      print('Erreur lors de la suppression de l\'évaluation: $e');
      rethrow;
    }
  }
}
*/