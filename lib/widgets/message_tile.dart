import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({Key? key, required this.message, required this.isMe})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 16,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeFormat.format(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead
                        ? Colors.blue.shade200
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour afficher une conversation dans la liste
class ConversationTile extends StatelessWidget {
  final String otherUserName;
  final String? otherUserPhoto;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final VoidCallback onTap;

  const ConversationTile({
    Key? key,
    required this.otherUserName,
    this.otherUserPhoto,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM');
    final timeFormat = DateFormat('HH:mm');

    String formattedTime = '';
    if (lastMessageTime != null) {
      final now = DateTime.now();
      final difference = now.difference(lastMessageTime!);

      if (difference.inDays == 0) {
        formattedTime = timeFormat.format(lastMessageTime!);
      } else if (difference.inDays < 7) {
        formattedTime = DateFormat('EEE', 'fr_FR').format(lastMessageTime!);
      } else {
        formattedTime = dateFormat.format(lastMessageTime!);
      }
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.blue.shade100,
        backgroundImage: otherUserPhoto != null
            ? NetworkImage(otherUserPhoto!)
            : null,
        child: otherUserPhoto == null
            ? Text(
                otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              )
            : null,
      ),
      title: Text(
        otherUserName,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: lastMessage != null
          ? Text(
              lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unreadCount > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (formattedTime.isNotEmpty)
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 12,
                color: unreadCount > 0 ? Colors.blue : Colors.grey,
                fontWeight: unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
