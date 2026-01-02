import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String trajetId;
  final String evaluateurId; // Celui qui note
  final String evalueId; // Celui qui est noté
  final double note; // 1 à 5 étoiles
  final String? commentaire;
  final DateTime dateEvaluation;
  final String type; // 'conducteur' ou 'passager'

  Rating({
    required this.id,
    required this.trajetId,
    required this.evaluateurId,
    required this.evalueId,
    required this.note,
    this.commentaire,
    required this.dateEvaluation,
    required this.type,
  });

  // Conversion depuis Firestore
  factory Rating.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Rating(
      id: doc.id,
      trajetId: data['trajetId'] ?? '',
      evaluateurId: data['evaluateurId'] ?? '',
      evalueId: data['evalueId'] ?? '',
      note: (data['note'] ?? 0.0).toDouble(),
      commentaire: data['commentaire'],
      dateEvaluation: (data['dateEvaluation'] as Timestamp).toDate(),
      type: data['type'] ?? '',
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'trajetId': trajetId,
      'evaluateurId': evaluateurId,
      'evalueId': evalueId,
      'note': note,
      'commentaire': commentaire,
      'dateEvaluation': Timestamp.fromDate(dateEvaluation),
      'type': type,
    };
  }

  // Copier avec modifications
  Rating copyWith({
    String? trajetId,
    String? evaluateurId,
    String? evalueId,
    double? note,
    String? commentaire,
    DateTime? dateEvaluation,
    String? type,
  }) {
    return Rating(
      id: this.id,
      trajetId: trajetId ?? this.trajetId,
      evaluateurId: evaluateurId ?? this.evaluateurId,
      evalueId: evalueId ?? this.evalueId,
      note: note ?? this.note,
      commentaire: commentaire ?? this.commentaire,
      dateEvaluation: dateEvaluation ?? this.dateEvaluation,
      type: type ?? this.type,
    );
  }
}
