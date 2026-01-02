import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'trip_detail_screen.dart';
import 'messages_screen.dart';
import 'user_ratings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tout marquer comme lu',
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Toutes les notifications marquées comme lues',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete_read') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer les notifications'),
                    content: const Text(
                      'Voulez-vous supprimer toutes les notifications lues ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _notificationService.deleteAllRead();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications lues supprimées'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_read',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Supprimer les lues'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
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

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les notifications apparaîtront ici',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
                onDismissed: () =>
                    _notificationService.deleteNotification(notification.id),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Marquer comme lue
    _notificationService.markAsRead(notification.id);

    // Navigation selon le type
    switch (notification.type) {
      case 'reservation':
      case 'confirmation':
      case 'refus':
      case 'annulation':
        // Naviguer vers mes trajets
        Navigator.pop(context);
        break;

      case 'message':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessagesScreen()),
        );
        break;

      case 'rating':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserRatingsScreen()),
        );
        break;
    }
  }
}

// ==================== TILE NOTIFICATION ====================
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(
            notification.type,
          ).withOpacity(0.2),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
          ),
        ),
        title: Text(
          notification.titre,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.dateCreation),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        tileColor: notification.isRead ? null : Colors.blue.shade50,
        onTap: onTap,
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'reservation':
        return Colors.blue;
      case 'confirmation':
        return Colors.green;
      case 'refus':
        return Colors.red;
      case 'message':
        return Colors.purple;
      case 'rating':
        return Colors.orange;
      case 'annulation':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'reservation':
        return Icons.event_seat;
      case 'confirmation':
        return Icons.check_circle;
      case 'refus':
        return Icons.cancel;
      case 'message':
        return Icons.message;
      case 'rating':
        return Icons.star;
      case 'annulation':
        return Icons.event_busy;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
