import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/message.dart';
import '../models/user.dart';
import '../services/message_service.dart';
import '../services/user_service.dart';
import '../widgets/message_tile.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // ==================== MÉTHODE CORRIGÉE ====================
  Future<User?> _getOtherUser(Conversation conversation) async {
    String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) return null;

    String otherUserId = conversation.getOtherUserId(currentUserId);
    return await _userService.getUserById(otherUserId);
  }

  // ==================== MÉTHODE POUR OBTENIR LE NOMBRE DE NON-LUS ====================
  int _getUnreadCount(Conversation conversation) {
    String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) return 0;

    return conversation.getUnreadCount(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _messageService.getConversations(),
        builder: (context, snapshot) {
          // État de chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Gestion d'erreur
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          // État vide
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun message',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos conversations apparaîtront ici',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Liste des conversations
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              final conversation = conversations[index];

              return FutureBuilder<User?>(
                future: _getOtherUser(conversation),
                builder: (context, userSnapshot) {
                  // En attente du chargement de l'utilisateur
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Container(
                        height: 16,
                        width: 100,
                        color: Colors.grey.shade200,
                      ),
                      subtitle: Container(
                        height: 14,
                        width: 150,
                        color: Colors.grey.shade200,
                        margin: const EdgeInsets.only(top: 8),
                      ),
                    );
                  }

                  // Erreur de chargement de l'utilisateur
                  if (userSnapshot.hasError || !userSnapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      title: const Text('Utilisateur inconnu'),
                      subtitle: Text(
                        conversation.lastMessage ?? 'Aucun message',
                      ),
                      trailing: _buildTrailingWidget(conversation),
                    );
                  }

                  final otherUser = userSnapshot.data!;
                  final unreadCount = _getUnreadCount(conversation);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                          otherUser.photoUrl != null &&
                              otherUser.photoUrl!.isNotEmpty
                          ? NetworkImage(otherUser.photoUrl!)
                          : null,
                      child:
                          otherUser.photoUrl == null ||
                              otherUser.photoUrl!.isEmpty
                          ? Text(
                              otherUser.initiales,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      otherUser.nomComplet,
                      style: TextStyle(
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      conversation.lastMessageOrDefault,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: _buildTrailingWidget(conversation),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            otherUserId: otherUser.id,
                            trajetId: conversation.trajetId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Widget pour afficher l'heure et le badge de non-lus
  Widget _buildTrailingWidget(Conversation conversation) {
    final unreadCount = _getUnreadCount(conversation);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (conversation.lastMessageTime != null)
          Text(
            _formatTime(conversation.lastMessageTime!),
            style: TextStyle(
              fontSize: 12,
              color: unreadCount > 0 ? Colors.blue : Colors.grey,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        if (unreadCount > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Text(
              unreadCount > 9 ? '9+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return jours[time.weekday - 1];
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
