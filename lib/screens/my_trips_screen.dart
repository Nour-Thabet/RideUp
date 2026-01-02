import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/reservation.dart';
import '../models/user.dart';
import '../services/trip_service.dart';
import '../services/reservation_service.dart';
import '../services/user_service.dart';
import '../services/rating_service.dart';
import '../widgets/trip_tile.dart';
import 'trip_detail_screen.dart';
import 'add_trip_screen.dart';
import 'rating_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripService _tripService = TripService();
  final ReservationService _reservationService = ReservationService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes trajets'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Conducteur', icon: Icon(Icons.directions_car)),
            Tab(text: 'Passager', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ConducteurTab(), _PassagerTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTripScreen()),
          );
          if (result == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trajet créé !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau trajet'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ==================== ONGLET CONDUCTEUR ====================
class _ConducteurTab extends StatelessWidget {
  const _ConducteurTab();

  @override
  Widget build(BuildContext context) {
    final tripService = TripService();
    final userService = UserService();

    return StreamBuilder<List<Trip>>(
      stream: tripService.getMyTrips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final errorMessage = snapshot.error.toString();

          if (errorMessage.contains('index') ||
              errorMessage.contains('Index')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 80,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Index Firestore manquant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Veuillez créer l\'index composite dans Firebase Console.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
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
                    errorMessage,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final trips = snapshot.data ?? [];

        if (trips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun trajet proposé',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre premier trajet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<User?>(
          future: userService.getCurrentUser(),
          builder: (context, userSnapshot) {
            return ListView.builder(
              itemCount: trips.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _TripWithReservationsCard(
                  trip: trip,
                  conducteur: userSnapshot.data,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==================== CARTE TRAJET AVEC RÉSERVATIONS ====================
class _TripWithReservationsCard extends StatelessWidget {
  final Trip trip;
  final User? conducteur;

  const _TripWithReservationsCard({required this.trip, this.conducteur});

  @override
  Widget build(BuildContext context) {
    final reservationService = ReservationService();
    final tripService = TripService();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Column(
        children: [
          // Détails du trajet avec bouton supprimer
          Stack(
            children: [
              TripTile(
                trip: trip,
                conducteur: conducteur,
                showStatus: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TripDetailScreen(trip: trip, conducteur: conducteur),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteTrip(context, tripService, trip),
                  tooltip: 'Supprimer le trajet',
                ),
              ),
            ],
          ),

          // Liste des réservations
          StreamBuilder<List<Reservation>>(
            stream: reservationService.getReservationsForTrip(trip.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                );
              }

              final reservations = snapshot.data ?? [];

              if (reservations.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aucune réservation pour ce trajet',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // Afficher les réservations
              return Column(
                children: [
                  const Divider(height: 1),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${reservations.length} réservation${reservations.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...reservations.map(
                    (reservation) => _ReservationItem(
                      reservation: reservation,
                      tripId: trip.id,
                      isConducteur: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Supprimer un trajet
  Future<void> _deleteTrip(
    BuildContext context,
    TripService tripService,
    Trip trip,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le trajet'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce trajet ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await tripService.deleteTrip(trip.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trajet supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ==================== ITEM RÉSERVATION AVEC ÉVALUATION ====================
class _ReservationItem extends StatelessWidget {
  final Reservation reservation;
  final String tripId;
  final bool isConducteur;

  const _ReservationItem({
    required this.reservation,
    required this.tripId,
    this.isConducteur = false,
  });

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final reservationService = ReservationService();
    final ratingService = RatingService();

    return FutureBuilder<User?>(
      future: userService.getUserById(reservation.passagerId),
      builder: (context, snapshot) {
        final passager = snapshot.data;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  passager?.initiales ?? '?',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Infos passager
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passager?.nomComplet ?? 'Chargement...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Évaluation moyenne du passager
                    if (passager != null && passager.nombreAvis > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${passager.noteMoyenne.toStringAsFixed(1)} (${passager.nombreAvis} avis)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(reservation.statut),
                          size: 14,
                          color: _getStatusColor(reservation.statut),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(reservation.statut),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(reservation.statut),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${reservation.nombrePlaces} place${reservation.nombrePlaces > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Boutons d'action
              if (reservation.statut == 'en_attente' && isConducteur) ...[
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _confirmerReservation(
                    context,
                    reservationService,
                    reservation.id,
                    passager?.nomComplet ?? 'ce passager',
                  ),
                  tooltip: 'Accepter',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _refuserReservation(
                    context,
                    reservationService,
                    reservation.id,
                    passager?.nomComplet ?? 'ce passager',
                  ),
                  tooltip: 'Refuser',
                ),
              ] else if (reservation.statut == 'confirmee' &&
                  isConducteur &&
                  passager != null) ...[
                // Bouton Noter pour le conducteur
                FutureBuilder<bool>(
                  future: ratingService.hasRatedUser(tripId, passager.id),
                  builder: (context, ratingSnapshot) {
                    final hasRated = ratingSnapshot.data ?? false;

                    if (hasRated) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Noté',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RatingScreen(
                              trajetId: tripId,
                              evalueId: passager.id,
                              evalueNom: passager.nomComplet,
                              type: 'passager',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.star, size: 18),
                      label: const Text('Noter'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Confirmer une réservation
  Future<void> _confirmerReservation(
    BuildContext context,
    ReservationService reservationService,
    String reservationId,
    String passagerNom,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la réservation'),
        content: Text('Voulez-vous accepter la réservation de $passagerNom ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await reservationService.confirmerReservation(reservationId, tripId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation confirmée'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Refuser une réservation
  Future<void> _refuserReservation(
    BuildContext context,
    ReservationService reservationService,
    String reservationId,
    String passagerNom,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la réservation'),
        content: Text('Voulez-vous refuser la réservation de $passagerNom ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await reservationService.refuserReservation(reservationId, tripId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation refusée'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'confirmee':
        return Colors.green;
      case 'refusee':
        return Colors.red;
      case 'annulee':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String statut) {
    switch (statut) {
      case 'en_attente':
        return Icons.schedule;
      case 'confirmee':
        return Icons.check_circle;
      case 'refusee':
        return Icons.cancel;
      case 'annulee':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'confirmee':
        return 'Confirmée';
      case 'refusee':
        return 'Refusée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }
}

// ==================== ONGLET PASSAGER ====================
class _PassagerTab extends StatelessWidget {
  const _PassagerTab();

  @override
  Widget build(BuildContext context) {
    final reservationService = ReservationService();
    final tripService = TripService();
    final userService = UserService();

    return StreamBuilder<List<Reservation>>(
      stream: reservationService.getMyReservations(),
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
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
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

        final reservations = snapshot.data ?? [];

        if (reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune réservation',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recherchez un trajet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: reservations.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final reservation = reservations[index];

            return FutureBuilder<Trip?>(
              future: tripService.getTripById(reservation.trajetId),
              builder: (context, tripSnapshot) {
                if (!tripSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final trip = tripSnapshot.data!;

                return FutureBuilder<User?>(
                  future: userService.getUserById(trip.conducteurId),
                  builder: (context, userSnapshot) {
                    final conducteur = userSnapshot.data;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: _getReservationStatusColor(
                              reservation.statut,
                            ).withOpacity(0.1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getReservationStatusIcon(
                                        reservation.statut,
                                      ),
                                      size: 16,
                                      color: _getReservationStatusColor(
                                        reservation.statut,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getReservationStatusText(
                                        reservation.statut,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getReservationStatusColor(
                                          reservation.statut,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${reservation.nombrePlaces} place${reservation.nombrePlaces > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    // Badge "Annulable" si en attente
                                    if (reservation.statut == 'en_attente') ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.orange.shade300,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 12,
                                              color: Colors.orange.shade800,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Annulable',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          TripTile(
                            trip: trip,
                            conducteur: conducteur,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TripDetailScreen(
                                    trip: trip,
                                    conducteur: conducteur,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Bouton Annuler la réservation (si en attente)
                          if (reservation.statut == 'en_attente')
                            _CancelReservationButton(
                              reservationId: reservation.id,
                              tripId: trip.id,
                              nombrePlaces: reservation.nombrePlaces,
                            ),

                          // Bouton Noter le conducteur (si confirmée)
                          if (reservation.statut == 'confirmee' &&
                              conducteur != null)
                            _RateDriverButton(
                              tripId: trip.id,
                              conducteurId: conducteur.id,
                              conducteurNom: conducteur.nomComplet,
                              conducteur: conducteur,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getReservationStatusColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'confirmee':
        return Colors.green;
      case 'refusee':
        return Colors.red;
      case 'annulee':
        return Colors.grey;
      case 'terminee':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getReservationStatusIcon(String statut) {
    switch (statut) {
      case 'en_attente':
        return Icons.schedule;
      case 'confirmee':
        return Icons.check_circle;
      case 'refusee':
        return Icons.cancel;
      case 'annulee':
        return Icons.block;
      case 'terminee':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  String _getReservationStatusText(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'confirmee':
        return 'Confirmée';
      case 'refusee':
        return 'Refusée';
      case 'annulee':
        return 'Annulée';
      case 'terminee':
        return 'Terminée';
      default:
        return statut;
    }
  }
}

// ==================== BOUTON ANNULER LA RÉSERVATION ====================
class _CancelReservationButton extends StatelessWidget {
  final String reservationId;
  final String tripId;
  final int nombrePlaces;

  const _CancelReservationButton({
    required this.reservationId,
    required this.tripId,
    required this.nombrePlaces,
  });

  @override
  Widget build(BuildContext context) {
    final reservationService = ReservationService();
    final tripService = TripService();

    return Container(
      padding: const EdgeInsets.all(12),
      child: ElevatedButton.icon(
        onPressed: () =>
            _showCancelDialog(context, reservationService, tripService),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Annuler ma réservation'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    ReservationService reservationService,
    TripService tripService,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette réservation ?\n\n'
          'Les places seront à nouveau disponibles pour d\'autres passagers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non, garder'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Annuler la réservation
        await reservationService.annulerReservation(reservationId);

        // Remettre les places disponibles
        await tripService.increasePlacesDisponibles(tripId, nombrePlaces);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation annulée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ==================== BOUTON NOTER LE CONDUCTEUR AVEC ÉVALUATION ====================
class _RateDriverButton extends StatelessWidget {
  final String tripId;
  final String conducteurId;
  final String conducteurNom;
  final User conducteur;

  const _RateDriverButton({
    required this.tripId,
    required this.conducteurId,
    required this.conducteurNom,
    required this.conducteur,
  });

  @override
  Widget build(BuildContext context) {
    final ratingService = RatingService();

    return FutureBuilder<bool>(
      future: ratingService.hasRatedUser(tripId, conducteurId),
      builder: (context, snapshot) {
        final hasRated = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Afficher l'évaluation du conducteur
              if (conducteur.nombreAvis > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${conducteur.noteMoyenne.toStringAsFixed(1)} (${conducteur.nombreAvis} avis)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Bouton pour noter
              if (hasRated)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vous avez noté ce conducteur',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RatingScreen(
                          trajetId: tripId,
                          evalueId: conducteurId,
                          evalueNom: conducteurNom,
                          type: 'conducteur',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Noter le conducteur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
