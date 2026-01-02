import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String
  type; // 'reservation', 'confirmation', 'refus', 'message', 'rating', 'annulation'
  final String titre;
  final String message;
  final DateTime dateCreation;
  final bool isRead;
  final Map<String, dynamic>?
  data; // Données supplémentaires (trajetId, reservationId, etc.)

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.titre,
    required this.message,
    required this.dateCreation,
    this.isRead = false,
    this.data,
  });

  // Conversion depuis Firestore
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      titre: data['titre'] ?? '',
      message: data['message'] ?? '',
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'titre': titre,
      'message': message,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'isRead': isRead,
      if (data != null) 'data': data,
    };
  }

  // Copier avec modifications
  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? titre,
    String? message,
    DateTime? dateCreation,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      dateCreation: dateCreation ?? this.dateCreation,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}
