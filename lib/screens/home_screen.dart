import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart' as app_user;
import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../services/trip_service.dart';
import '../widgets/avatar_widget.dart'; // ✅ Import du widget avatar
import 'map_screen.dart';
import 'add_trip_screen.dart';
import 'search_trips_screen.dart';
import 'my_trips_screen.dart';
import 'messages_screen.dart';
import 'trip_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'user_ratings_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const SearchTripsScreen(),
    const MyTripsScreen(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Mise à jour du FCM Token au démarrage
    UserService().updateFcmToken();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await UserService().removeFcmToken();
        await AuthService().signOut();
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Covoiturage'),
        actions: [
          // Badge messages non lus
          StreamBuilder<int>(
            stream: MessageService().getTotalUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return _buildBadgeIcon(
                icon: Icons.message,
                count: unreadCount,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen()),
                ),
              );
            },
          ),

          // Badge notifications non lues
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(),
            builder: (context, snapshot) {
              final unreadNotif = snapshot.data ?? 0;
              return _buildBadgeIcon(
                icon: Icons.notifications_outlined,
                count: unreadNotif,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Rechercher'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car), label: 'Mes trajets'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon({
    required IconData icon,
    required int count,
    required VoidCallback onPressed,
  }) {
    return Stack(
      children: [
        IconButton(icon: Icon(icon), onPressed: onPressed),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== ONGLET ACCUEIL ====================
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = auth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Message de bienvenue avec AvatarWidget
              StreamBuilder<app_user.User?>(
                stream: UserService().getCurrentUserStream(),
                builder: (context, snapshot) {
                  final appUser = snapshot.data;

                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          AvatarWidget(
                            // ✅ Utilisation du widget
                            photoUrl: appUser?.photoUrl,
                            initiales: appUser?.initiales ??
                                user?.email?.substring(0, 1).toUpperCase() ??
                                'U',
                            radius: 30,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bienvenue !',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  appUser?.nomComplet ??
                                      user?.email ??
                                      'Utilisateur',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Actions rapides
              const Text(
                'Actions rapides',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_circle_outline,
                      title: 'Proposer\nun trajet',
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddTripScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.search,
                      title: 'Rechercher\nun trajet',
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SearchTripsScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.map_outlined,
                      title: 'Voir\nla carte',
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.message_outlined,
                      title: 'Messages',
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MessagesScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Trajets disponibles
              const Text(
                'Trajets disponibles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              StreamBuilder<List<Trip>>(
                stream: TripService().getActiveTrips(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _EmptyStateWidget(
                      icon: Icons.error_outline,
                      message: 'Erreur de chargement',
                      subtitle: 'Impossible de récupérer les trajets',
                    );
                  }

                  final trips = snapshot.data ?? [];
                  if (trips.isEmpty) {
                    return _EmptyStateWidget(
                      icon: Icons.directions_car_outlined,
                      message: 'Aucun trajet disponible',
                      subtitle: 'Revenez plus tard ou proposez un trajet !',
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child:
                                Icon(Icons.directions_car, color: Colors.white),
                          ),
                          title: Text(
                            '${trip.pointDepart.city} → ${trip.pointArrivee.city}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${trip.placesDisponibles} places • ${trip.prix.toStringAsFixed(2)} DT',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripDetailScreen(trip: trip),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ONGLET PROFIL ====================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = auth.FirebaseAuth.instance.currentUser;
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<app_user.User?>(
        stream: userService.getCurrentUserStream(),
        builder: (context, snapshot) {
          final appUser = snapshot.data;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    // ✅ Avatar avec AvatarWidget
                    AvatarWidget(
                      photoUrl: appUser?.photoUrl,
                      initiales: appUser?.initiales ??
                          user?.email?.substring(0, 1).toUpperCase() ??
                          'U',
                      radius: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appUser?.nomComplet ?? user?.email ?? 'Utilisateur',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (appUser != null && appUser.nombreAvis > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${appUser.noteMoyenne.toStringAsFixed(1)} (${appUser.nombreAvis} avis)',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Options du profil
              _ProfileOption(
                icon: Icons.person_outline,
                title: 'Modifier le profil',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen()),
                ),
              ),
              _ProfileOption(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
              ),
              _ProfileOption(
                icon: Icons.star_outline,
                title: 'Mes évaluations',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserRatingsScreen()),
                ),
              ),
              _ProfileOption(
                icon: Icons.settings_outlined,
                title: 'Paramètres',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('À venir')),
                ),
              ),
              _ProfileOption(
                icon: Icons.help_outline,
                title: 'Aide et support',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('À venir')),
                ),
              ),
              const Divider(height: 32),
              _ProfileOption(
                icon: Icons.logout,
                title: 'Se déconnecter',
                color: Colors.red,
                onTap: () async {
                  try {
                    await UserService().removeFcmToken();
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==================== WIDGETS RÉUTILISABLES ====================
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: color ?? Colors.grey),
      onTap: onTap,
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyStateWidget({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
