import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/message.dart';
import '../models/user.dart';
import '../services/message_service.dart';
import '../services/user_service.dart';
import '../widgets/message_tile.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String? trajetId;

  const ChatScreen({Key? key, required this.otherUserId, this.trajetId})
    : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  User? _otherUser;
  String? _conversationId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndConversation() async {
    try {
      // Charger les infos de l'autre utilisateur
      User? otherUser = await _userService.getUserById(widget.otherUserId);

      // Créer ou obtenir la conversation
      Conversation conversation = await _messageService.getOrCreateConversation(
        otherUserId: widget.otherUserId,
        trajetId: widget.trajetId,
      );

      // Marquer les messages comme lus
      await _messageService.markMessagesAsRead(conversation.id);

      setState(() {
        _otherUser = otherUser;
        _conversationId = conversation.id;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String content = _messageController.text.trim();
    _messageController.clear();

    try {
      await _messageService.sendMessage(
        receiverId: widget.otherUserId,
        content: content,
        trajetId: widget.trajetId,
      );

      // Scroller vers le bas
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_conversationId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Erreur lors du chargement de la conversation'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _otherUser?.initiales ?? '?',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUser?.nomComplet ?? 'Utilisateur',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_otherUser != null && _otherUser!.nombreAvis > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          _otherUser!.noteMoyenne.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageService.getMessages(_conversationId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
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
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envoyez le premier message',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Scroller vers le bas après le chargement
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _auth.currentUser?.uid;

                    return MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrivez un message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
