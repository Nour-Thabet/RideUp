import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Collection des utilisateurs
  CollectionReference get _usersCollection => _firestore.collection('users');

  // ==================== METTRE À JOUR LE FCM TOKEN ====================
  Future<void> updateFcmToken() async {
    try {
      // 1. Vérifier si l'utilisateur est connecté
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      // 2. Demander la permission pour les notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('❌ Permissions de notification refusées');
        return;
      }

      // 3. Obtenir le FCM Token
      String? token = await _messaging.getToken();

      if (token == null) {
        print('❌ Impossible d\'obtenir le FCM Token');
        return;
      }

      print('✅ FCM Token obtenu: $token');

      // 4. Sauvegarder le token dans Firestore
      await _usersCollection.doc(currentUser.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ FCM Token sauvegardé dans Firestore');

      // 5. Écouter les rafraîchissements de token
      _messaging.onTokenRefresh.listen((newToken) {
        _updateTokenInFirestore(currentUser.uid, newToken);
      });
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du FCM Token: $e');
    }
  }

  /// Mettre à jour le token en cas de rafraîchissement
  Future<void> _updateTokenInFirestore(String userId, String token) async {
    try {
      await _usersCollection.doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      print('✅ FCM Token rafraîchi et mis à jour');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du token: $e');
    }
  }

  /// Supprimer le FCM Token (à la déconnexion)
  Future<void> removeFcmToken() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _usersCollection.doc(currentUser.uid).update({
        'fcmToken': FieldValue.delete(),
      });

      await _messaging.deleteToken();
      print('✅ FCM Token supprimé');
    } catch (e) {
      print('❌ Erreur lors de la suppression du FCM Token: $e');
    }
  }

  // ==================== CRÉER UN UTILISATEUR ====================
  Future<void> createUser({
    required String userId,
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    String? photoUrl,
  }) async {
    try {
      User newUser = User(
        id: userId,
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        photoUrl: photoUrl,
        dateInscription: DateTime.now(),
        noteMoyenne: 0.0,
        nombreAvis: 0,
        estPassager: true,
        estConducteur: false,
      );

      await _usersCollection.doc(userId).set(newUser.toFirestore());
      print('✅ Utilisateur créé avec succès: $userId');
    } catch (e) {
      print('❌ Erreur lors de la création de l\'utilisateur: $e');
      rethrow;
    }
  }

  // ==================== OBTENIR L'UTILISATEUR ACTUEL ====================
  Future<User?> getCurrentUser() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('⚠️ Aucun utilisateur connecté');
        return null;
      }

      DocumentSnapshot doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        return User.fromFirestore(doc);
      }

      print('⚠️ Document utilisateur introuvable pour: $userId');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  // ==================== OBTENIR UN UTILISATEUR PAR ID ====================
  Future<User?> getUserById(String userId) async {
    try {
      if (userId.isEmpty) {
        print('⚠️ getUserById: userId est vide');
        return null;
      }

      DocumentSnapshot doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        return User.fromFirestore(doc);
      }

      print('⚠️ Utilisateur $userId n\'existe pas dans Firestore');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'utilisateur $userId: $e');
      return null;
    }
  }

  // ==================== METTRE À JOUR LE PROFIL UTILISATEUR ====================
  Future<void> updateUser({
    required String userId,
    String? nom,
    String? prenom,
    String? telephone,
    String? photoUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (nom != null) updates['nom'] = nom;
      if (prenom != null) updates['prenom'] = prenom;
      if (telephone != null) updates['telephone'] = telephone;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isNotEmpty) {
        await _usersCollection.doc(userId).update(updates);
        print('✅ Utilisateur mis à jour: $userId');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de l\'utilisateur: $e');
      rethrow;
    }
  }

  // ==================== ACTIVER LE MODE CONDUCTEUR ====================
  Future<void> activerModeConducteur({
    required String userId,
    required String permisConduire,
    required String marqueVehicule,
    required String modeleVehicule,
    required String immatriculation,
    int? anneeFabrication,
    String? couleurVehicule,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'estConducteur': true,
        'permisConduire': permisConduire,
        'marqueVehicule': marqueVehicule,
        'modeleVehicule': modeleVehicule,
        'immatriculation': immatriculation,
        if (anneeFabrication != null) 'anneeFabrication': anneeFabrication,
        if (couleurVehicule != null) 'couleurVehicule': couleurVehicule,
      });
      print('✅ Mode conducteur activé pour: $userId');
    } catch (e) {
      print('❌ Erreur lors de l\'activation du mode conducteur: $e');
      rethrow;
    }
  }

  // ==================== DÉSACTIVER LE MODE CONDUCTEUR ====================
  Future<void> desactiverModeConducteur(String userId) async {
    try {
      await _usersCollection.doc(userId).update({'estConducteur': false});
      print('✅ Mode conducteur désactivé pour: $userId');
    } catch (e) {
      print('❌ Erreur lors de la désactivation du mode conducteur: $e');
      rethrow;
    }
  }

  // ==================== METTRE À JOUR LES INFORMATIONS DU VÉHICULE ====================
  Future<void> updateVehiculeInfo({
    required String userId,
    String? marqueVehicule,
    String? modeleVehicule,
    String? immatriculation,
    int? anneeFabrication,
    String? couleurVehicule,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (marqueVehicule != null) updates['marqueVehicule'] = marqueVehicule;
      if (modeleVehicule != null) updates['modeleVehicule'] = modeleVehicule;
      if (immatriculation != null) updates['immatriculation'] = immatriculation;
      if (anneeFabrication != null)
        updates['anneeFabrication'] = anneeFabrication;
      if (couleurVehicule != null) updates['couleurVehicule'] = couleurVehicule;

      if (updates.isNotEmpty) {
        await _usersCollection.doc(userId).update(updates);
        print('✅ Informations du véhicule mises à jour: $userId');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du véhicule: $e');
      rethrow;
    }
  }

  // ==================== METTRE À JOUR LA NOTE MOYENNE ====================
  Future<void> updateNoteMoyenne(String userId, double nouvelleNote) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();

      if (!doc.exists) {
        throw Exception('Utilisateur introuvable');
      }

      User user = User.fromFirestore(doc);

      // Calculer la nouvelle note moyenne
      double totalNotes = user.noteMoyenne * user.nombreAvis;
      int nouveauNombreAvis = user.nombreAvis + 1;
      double nouvelleNoteMoyenne =
          (totalNotes + nouvelleNote) / nouveauNombreAvis;

      await _usersCollection.doc(userId).update({
        'noteMoyenne': nouvelleNoteMoyenne,
        'nombreAvis': nouveauNombreAvis,
      });

      print(
          '✅ Note mise à jour pour $userId: $nouvelleNoteMoyenne ($nouveauNombreAvis avis)');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la note: $e');
      rethrow;
    }
  }

  // ==================== STREAM DE L'UTILISATEUR ACTUEL ====================
  Stream<User?> getCurrentUserStream() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(null);

    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    });
  }

  // ==================== STREAM D'UN UTILISATEUR SPÉCIFIQUE ====================
  Stream<User?> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    });
  }

  // ==================== RECHERCHER DES UTILISATEURS PAR NOM ====================
  Future<List<User>> searchUsersByName(String query) async {
    try {
      if (query.isEmpty) return [];

      QuerySnapshot snapshot = await _usersCollection
          .where('nom', isGreaterThanOrEqualTo: query)
          .where('nom', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Erreur lors de la recherche d\'utilisateurs: $e');
      return [];
    }
  }

  // ==================== RECHERCHER DES CONDUCTEURS ====================
  Future<List<User>> searchConducteurs() async {
    try {
      QuerySnapshot snapshot = await _usersCollection
          .where('estConducteur', isEqualTo: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Erreur lors de la recherche de conducteurs: $e');
      return [];
    }
  }

  // ==================== VÉRIFIER SI L'UTILISATEUR EXISTE ====================
  Future<bool> userExists(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'existence: $e');
      return false;
    }
  }

  // ==================== SUPPRIMER UN UTILISATEUR ====================
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      print('✅ Utilisateur supprimé: $userId');
    } catch (e) {
      print('❌ Erreur lors de la suppression de l\'utilisateur: $e');
      rethrow;
    }
  }

  // ==================== OBTENIR LES STATISTIQUES D'UN UTILISATEUR ====================
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      User? user = await getUserById(userId);

      if (user == null) {
        return {
          'noteMoyenne': 0.0,
          'nombreAvis': 0,
          'estConducteur': false,
          'estPassager': false,
        };
      }

      return {
        'noteMoyenne': user.noteMoyenne,
        'nombreAvis': user.nombreAvis,
        'estConducteur': user.estConducteur,
        'estPassager': user.estPassager,
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des stats: $e');
      return {
        'noteMoyenne': 0.0,
        'nombreAvis': 0,
        'estConducteur': false,
        'estPassager': false,
      };
    }
  }
}
