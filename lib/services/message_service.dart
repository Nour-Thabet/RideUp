import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/message.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Collections
  CollectionReference get _conversationsCollection =>
      _firestore.collection('conversations');
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');

  // Générer un ID de conversation unique entre deux utilisateurs
  String _getConversationId(String user1Id, String user2Id) {
    List<String> ids = [user1Id, user2Id];
    ids.sort();
    return ids.join('_');
  }

  // Créer ou obtenir une conversation
  Future<Conversation> getOrCreateConversation({
    required String otherUserId,
    String? trajetId,
  }) async {
    try {
      String currentUserId = _auth.currentUser!.uid;
      String conversationId = _getConversationId(currentUserId, otherUserId);

      DocumentSnapshot doc = await _conversationsCollection
          .doc(conversationId)
          .get();

      if (doc.exists) {
        return Conversation.fromFirestore(doc);
      } else {
        // Créer une nouvelle conversation
        Conversation newConversation = Conversation(
          id: conversationId,
          user1Id: currentUserId.compareTo(otherUserId) < 0
              ? currentUserId
              : otherUserId,
          user2Id: currentUserId.compareTo(otherUserId) < 0
              ? otherUserId
              : currentUserId,
          trajetId: trajetId,
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          unreadCountUser1: 0,
          unreadCountUser2: 0,
        );

        await _conversationsCollection
            .doc(conversationId)
            .set(newConversation.toFirestore());

        return newConversation;
      }
    } catch (e) {
      print('Erreur lors de la création de la conversation: $e');
      rethrow;
    }
  }

  // Envoyer un message
  Future<String?> sendMessage({
    required String receiverId,
    required String content,
    String? trajetId,
  }) async {
    try {
      String senderId = _auth.currentUser!.uid;
      String conversationId = _getConversationId(senderId, receiverId);

      // Créer ou obtenir la conversation d'abord
      await getOrCreateConversation(
        otherUserId: receiverId,
        trajetId: trajetId,
      );

      // Créer le message
      Message newMessage = Message(
        id: '',
        conversationId: conversationId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        trajetId: trajetId,
      );

      // Ajouter le message à Firestore
      DocumentReference messageRef = await _messagesCollection.add(
        newMessage.toFirestore(),
      );

      // Mettre à jour la conversation
      await _updateConversationAfterMessage(
        conversationId: conversationId,
        senderId: senderId,
        receiverId: receiverId,
        lastMessage: content,
        trajetId: trajetId,
      );

      return messageRef.id;
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }

  // Mettre à jour la conversation après un message
  Future<void> _updateConversationAfterMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String lastMessage,
    String? trajetId,
  }) async {
    try {
      DocumentSnapshot doc = await _conversationsCollection
          .doc(conversationId)
          .get();

      if (doc.exists) {
        Conversation conversation = Conversation.fromFirestore(doc);

        // Incrémenter le compteur de messages non lus du destinataire
        int newUnreadCountUser1 = conversation.unreadCountUser1;
        int newUnreadCountUser2 = conversation.unreadCountUser2;

        if (receiverId == conversation.user1Id) {
          newUnreadCountUser1++;
        } else {
          newUnreadCountUser2++;
        }

        await _conversationsCollection.doc(conversationId).update({
          'lastMessage': lastMessage,
          'lastMessageTime': Timestamp.fromDate(DateTime.now()),
          'unreadCountUser1': newUnreadCountUser1,
          'unreadCountUser2': newUnreadCountUser2,
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de la conversation: $e');
    }
  }

  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      String currentUserId = _auth.currentUser!.uid;

      // Marquer tous les messages non lus de cette conversation comme lus
      QuerySnapshot unreadMessages = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }

      // Réinitialiser le compteur de messages non lus
      DocumentSnapshot convDoc = await _conversationsCollection
          .doc(conversationId)
          .get();

      if (convDoc.exists) {
        Conversation conversation = Conversation.fromFirestore(convDoc);

        if (currentUserId == conversation.user1Id) {
          await _conversationsCollection.doc(conversationId).update({
            'unreadCountUser1': 0,
          });
        } else {
          await _conversationsCollection.doc(conversationId).update({
            'unreadCountUser2': 0,
          });
        }
      }
    } catch (e) {
      print('Erreur lors du marquage des messages comme lus: $e');
    }
  }

  // Obtenir les messages d'une conversation (stream)
  Stream<List<Message>> getMessages(String conversationId) {
    return _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  // ==================== MÉTHODE CORRIGÉE ====================
  // Obtenir toutes les conversations d'un utilisateur (stream)
  Stream<List<Conversation>> getConversations() {
    String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Récupérer toutes les conversations et filtrer en mémoire
    return _conversationsCollection
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          List<Conversation> conversations = [];

          for (var doc in snapshot.docs) {
            try {
              Conversation conversation = Conversation.fromFirestore(doc);

              // Vérifier si l'utilisateur fait partie de cette conversation
              if (conversation.user1Id == currentUserId ||
                  conversation.user2Id == currentUserId) {
                conversations.add(conversation);
              }
            } catch (e) {
              print('Erreur lors du parsing de la conversation ${doc.id}: $e');
            }
          }

          return conversations;
        });
  }

  // Obtenir une conversation par ID
  Future<Conversation?> getConversationById(String conversationId) async {
    try {
      DocumentSnapshot doc = await _conversationsCollection
          .doc(conversationId)
          .get();

      if (doc.exists) {
        return Conversation.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la conversation: $e');
      return null;
    }
  }

  // ==================== MÉTHODE CORRIGÉE ====================
  // Compter le nombre total de messages non lus
  Stream<int> getTotalUnreadCount() {
    String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _conversationsCollection.snapshots().map((snapshot) {
      int total = 0;

      for (var doc in snapshot.docs) {
        try {
          Conversation conv = Conversation.fromFirestore(doc);

          // Ajouter les messages non lus selon le rôle de l'utilisateur
          if (conv.user1Id == currentUserId) {
            total += conv.unreadCountUser1;
          } else if (conv.user2Id == currentUserId) {
            total += conv.unreadCountUser2;
          }
        } catch (e) {
          print('Erreur lors du calcul des non-lus: $e');
        }
      }

      return total;
    });
  }

  // Supprimer une conversation (optionnel)
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Supprimer tous les messages de la conversation
      QuerySnapshot messages = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Supprimer la conversation
      await _conversationsCollection.doc(conversationId).delete();
    } catch (e) {
      print('Erreur lors de la suppression de la conversation: $e');
      rethrow;
    }
  }
}
