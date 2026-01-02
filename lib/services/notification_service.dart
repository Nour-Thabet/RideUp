import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  // ==================== CRÉER UNE NOTIFICATION ====================
  Future<String?> createNotification({
    required String userId,
    required String type,
    required String titre,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      AppNotification notification = AppNotification(
        id: '',
        userId: userId,
        type: type,
        titre: titre,
        message: message,
        dateCreation: DateTime.now(),
        isRead: false,
        data: data,
      );

      DocumentReference docRef = await _notificationsCollection.add(
        notification.toFirestore(),
      );

      print('✅ Notification créée: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur création notification: $e');
      return null;
    }
  }

  // ==================== NOTIFICATIONS SPÉCIFIQUES ====================

  // Nouvelle réservation (pour le conducteur)
  Future<void> notifyNewReservation({
    required String conducteurId,
    required String passagerNom,
    required String trajetId,
    required String reservationId,
  }) async {
    await createNotification(
      userId: conducteurId,
      type: 'reservation',
      titre: '🚗 Nouvelle réservation',
      message: '$passagerNom a réservé une place sur votre trajet',
      data: {'trajetId': trajetId, 'reservationId': reservationId},
    );
  }

  // Réservation confirmée (pour le passager)
  Future<void> notifyReservationConfirmed({
    required String passagerId,
    required String conducteurNom,
    required String trajetId,
    required String reservationId,
  }) async {
    await createNotification(
      userId: passagerId,
      type: 'confirmation',
      titre: '✅ Réservation confirmée',
      message: '$conducteurNom a accepté votre réservation',
      data: {'trajetId': trajetId, 'reservationId': reservationId},
    );
  }

  // Réservation refusée (pour le passager)
  Future<void> notifyReservationRefused({
    required String passagerId,
    required String conducteurNom,
    required String trajetId,
    required String reservationId,
  }) async {
    await createNotification(
      userId: passagerId,
      type: 'refus',
      titre: '❌ Réservation refusée',
      message: '$conducteurNom a refusé votre réservation',
      data: {'trajetId': trajetId, 'reservationId': reservationId},
    );
  }

  // Nouveau message
  Future<void> notifyNewMessage({
    required String receiverId,
    required String senderNom,
    required String conversationId,
  }) async {
    await createNotification(
      userId: receiverId,
      type: 'message',
      titre: '💬 Nouveau message',
      message: '$senderNom vous a envoyé un message',
      data: {'conversationId': conversationId},
    );
  }

  // Nouvelle évaluation
  Future<void> notifyNewRating({
    required String userId,
    required String evaluateurNom,
    required double note,
    required String trajetId,
  }) async {
    String emoji = note >= 4.5
        ? '🌟'
        : note >= 3.5
        ? '⭐'
        : '⚠️';
    await createNotification(
      userId: userId,
      type: 'rating',
      titre: '$emoji Nouvelle évaluation',
      message: '$evaluateurNom vous a donné ${note.toStringAsFixed(1)} étoiles',
      data: {'trajetId': trajetId, 'note': note},
    );
  }

  // Réservation annulée (pour le conducteur)
  Future<void> notifyReservationCancelled({
    required String conducteurId,
    required String passagerNom,
    required String trajetId,
  }) async {
    await createNotification(
      userId: conducteurId,
      type: 'annulation',
      titre: '🚫 Réservation annulée',
      message: '$passagerNom a annulé sa réservation',
      data: {'trajetId': trajetId},
    );
  }

  // Trajet bientôt (rappel 24h avant)
  Future<void> notifyTripReminder({
    required String userId,
    required String depart,
    required String arrivee,
    required String trajetId,
  }) async {
    await createNotification(
      userId: userId,
      type: 'rappel',
      titre: '⏰ Rappel de trajet',
      message: 'Votre trajet $depart → $arrivee a lieu demain',
      data: {'trajetId': trajetId},
    );
  }

  // ==================== OBTENIR LES NOTIFICATIONS ====================

  // Stream des notifications de l'utilisateur
  Stream<List<AppNotification>> getNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('dateCreation', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList(),
        );
  }

  // Obtenir les notifications non lues
  Stream<List<AppNotification>> getUnreadNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList(),
        );
  }

  // Compter les notifications non lues
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Future pour obtenir le compte de non-lus (pour usage unique)
  Future<int> getUnreadCountOnce() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      QuerySnapshot snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Erreur comptage notifications: $e');
      return 0;
    }
  }

  // ==================== MARQUER COMME LUE ====================

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
      print('✅ Notification $notificationId marquée comme lue');
    } catch (e) {
      print('❌ Erreur marquage notification: $e');
    }
  }

  // Marquer toutes comme lues
  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      QuerySnapshot unreadNotifications = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      print('✅ Toutes les notifications marquées comme lues');
    } catch (e) {
      print('❌ Erreur marquage toutes notifications: $e');
    }
  }

  // ==================== SUPPRIMER ====================

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      print('✅ Notification $notificationId supprimée');
    } catch (e) {
      print('❌ Erreur suppression notification: $e');
    }
  }

  // Supprimer toutes les notifications lues
  Future<void> deleteAllRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      QuerySnapshot readNotifications = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: true)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in readNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Toutes les notifications lues supprimées');
    } catch (e) {
      print('❌ Erreur suppression notifications: $e');
    }
  }

  // Supprimer toutes les notifications
  Future<void> deleteAll() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      QuerySnapshot allNotifications = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in allNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Toutes les notifications supprimées');
    } catch (e) {
      print('❌ Erreur suppression toutes notifications: $e');
    }
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, int>> getNotificationStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      QuerySnapshot snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      Map<String, int> stats = {
        'total': 0,
        'reservation': 0,
        'confirmation': 0,
        'refus': 0,
        'message': 0,
        'rating': 0,
        'annulation': 0,
        'unread': 0,
      };

      for (var doc in snapshot.docs) {
        AppNotification notif = AppNotification.fromFirestore(doc);
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[notif.type] = (stats[notif.type] ?? 0) + 1;
        if (!notif.isRead) {
          stats['unread'] = (stats['unread'] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('❌ Erreur stats notifications: $e');
      return {};
    }
  }

  // ==================== NETTOYAGE AUTOMATIQUE ====================

  // Supprimer les notifications de plus de 30 jours
  Future<void> cleanOldNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      DateTime cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      QuerySnapshot oldNotifications = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('dateCreation', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Anciennes notifications nettoyées');
    } catch (e) {
      print('❌ Erreur nettoyage notifications: $e');
    }
  }
}
