import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? trajetId; // Optionnel : lier à un trajet spécifique

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.trajetId,
  });

  // Conversion depuis Firestore
  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Message(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      trajetId: data['trajetId'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      if (trajetId != null) 'trajetId': trajetId,
    };
  }

  // Copier avec modifications
  Message copyWith({
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? trajetId,
  }) {
    return Message(
      id: this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      trajetId: trajetId ?? this.trajetId,
    );
  }
}

// Classe pour représenter une conversation
class Conversation {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCountUser1;
  final int unreadCountUser2;
  final String? trajetId;

  Conversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCountUser1 = 0,
    this.unreadCountUser2 = 0,
    this.trajetId,
  });

  // Conversion depuis Firestore
  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Conversation(
      id: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCountUser1: data['unreadCountUser1'] ?? 0,
      unreadCountUser2: data['unreadCountUser2'] ?? 0,
      trajetId: data['trajetId'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCountUser1': unreadCountUser1,
      'unreadCountUser2': unreadCountUser2,
      if (trajetId != null) 'trajetId': trajetId,
    };
  }

  // Obtenir l'ID de l'autre utilisateur
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  // Obtenir le nombre de messages non lus pour un utilisateur
  int getUnreadCount(String userId) {
    return userId == user1Id ? unreadCountUser1 : unreadCountUser2;
  }

  // ==================== MÉTHODE AJOUTÉE POUR GÉRER LE NULLABLE ====================
  // Obtenir le lastMessage avec valeur par défaut
  String get lastMessageOrDefault => lastMessage ?? 'Aucun message';

  // Vérifier si la conversation a des messages
  bool get hasMessages => lastMessage != null && lastMessage!.isNotEmpty;

  // Vérifier si l'utilisateur fait partie de cette conversation
  bool hasParticipant(String userId) {
    return user1Id == userId || user2Id == userId;
  }
}
