import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/trip.dart';
import '../models/user.dart';
import '../services/reservation_service.dart';
import '../widgets/map_widget.dart';
import 'chat_screen.dart';
import '../widgets/avatar_widget.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  final User? conducteur;

  const TripDetailScreen({Key? key, required this.trip, this.conducteur})
      : super(key: key);

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final ReservationService _reservationService = ReservationService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  int _nombrePlaces = 1;
  bool _isReserving = false;

  bool get _isMyTrip => widget.trip.conducteurId == _auth.currentUser?.uid;

  Future<void> _makeReservation() async {
    if (_isMyTrip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas réserver votre propre trajet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.trip.placesDisponibles < _nombrePlaces) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pas assez de places disponibles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier si déjà réservé
    bool hasReservation = await _reservationService.hasReservation(
      _auth.currentUser!.uid,
      widget.trip.id,
    );

    if (hasReservation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez déjà réservé ce trajet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirmer la réservation
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la réservation'),
        content: Text(
          'Réserver $_nombrePlaces place${_nombrePlaces > 1 ? 's' : ''} pour '
          '${(widget.trip.prix * _nombrePlaces).toStringAsFixed(2)} DT ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isReserving = true);

    try {
      String? reservationId = await _reservationService.createReservation(
        trajetId: widget.trip.id,
        conducteurId: widget.trip.conducteurId,
        nombrePlaces: _nombrePlaces,
        montantTotal: widget.trip.prix * _nombrePlaces,
      );

      if (reservationId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation effectuée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isReserving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du trajet'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte
                SizedBox(
                  height: 250,
                  child: MapWidget(
                    startPoint: widget.trip.pointDepart,
                    endPoint: widget.trip.pointArrivee,
                    showCurrentLocation: false,
                    showZoomControls: false,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date et heure
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateFormat.format(
                                        widget.trip.dateHeureDepart,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Départ à ${timeFormat.format(widget.trip.dateHeureDepart)}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Itinéraire
                      const Text(
                        'Itinéraire',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _ItineraireCard(
                        icon: Icons.radio_button_checked,
                        color: Colors.green,
                        title: 'Départ',
                        location: widget.trip.pointDepart.displayName,
                      ),
                      const SizedBox(height: 8),
                      _ItineraireCard(
                        icon: Icons.location_on,
                        color: Colors.red,
                        title: 'Arrivée',
                        location: widget.trip.pointArrivee.displayName,
                      ),

                      // Distance et durée
                      if (widget.trip.distance != null &&
                          widget.trip.duree != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.straighten,
                                label: 'Distance',
                                value:
                                    '${widget.trip.distance!.toStringAsFixed(0)} km',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.access_time,
                                label: 'Durée',
                                value: widget.trip.duree!,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Conducteur
                      // Conducteur
                      if (widget.conducteur != null) ...[
                        const Text(
                          'Conducteur',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    AvatarWidget(
                                      // ✅ UTILISER AVATARWIDGET
                                      photoUrl: widget.conducteur!.photoUrl,
                                      initiales: widget.conducteur!.initiales,
                                      radius: 30,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.conducteur!.nomComplet,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (widget.conducteur!.nombreAvis > 0)
                                            Row(
                                              children: [
                                                const Icon(Icons.star,
                                                    size: 16,
                                                    color: Colors.amber),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${widget.conducteur!.noteMoyenne.toStringAsFixed(1)} '
                                                  '(${widget.conducteur!.nombreAvis} avis)',
                                                ),
                                              ],
                                            )
                                          else
                                            const Text('Nouveau conducteur'),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.message,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              otherUserId:
                                                  widget.trip.conducteurId,
                                              trajetId: widget.trip.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                // ✅ AFFICHER LES INFOS DU VÉHICULE
                                if (widget.conducteur!.marqueVehicule != null ||
                                    widget.conducteur!.immatriculation !=
                                        null) ...[
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_car,
                                          color: Colors.blue),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (widget.conducteur!
                                                        .marqueVehicule !=
                                                    null &&
                                                widget.conducteur!
                                                        .modeleVehicule !=
                                                    null)
                                              Text(
                                                '${widget.conducteur!.marqueVehicule} ${widget.conducteur!.modeleVehicule}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            if (widget.conducteur!
                                                    .couleurVehicule !=
                                                null)
                                              Text(
                                                widget.conducteur!
                                                    .couleurVehicule!,
                                                style: TextStyle(
                                                    color: Colors.grey[600]),
                                              ),
                                            if (widget.conducteur!
                                                    .immatriculation !=
                                                null)
                                              Text(
                                                widget.conducteur!
                                                    .immatriculation!,
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontFamily: 'Monospace',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Préférences
                      const Text(
                        'Préférences du trajet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PreferenceChip(
                            icon: widget.trip.fumeursAcceptes
                                ? Icons.smoking_rooms
                                : Icons.smoke_free,
                            label: widget.trip.fumeursAcceptes
                                ? 'Fumeurs acceptés'
                                : 'Non-fumeurs',
                            color: widget.trip.fumeursAcceptes
                                ? Colors.orange
                                : Colors.green,
                          ),
                          _PreferenceChip(
                            icon: widget.trip.animauxAcceptes
                                ? Icons.pets
                                : Icons.not_interested,
                            label: widget.trip.animauxAcceptes
                                ? 'Animaux acceptés'
                                : 'Pas d\'animaux',
                            color: widget.trip.animauxAcceptes
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          _PreferenceChip(
                            icon: Icons.music_note,
                            label: widget.trip.musiqueOk
                                ? 'Musique OK'
                                : 'Pas de musique',
                            color: widget.trip.musiqueOk
                                ? Colors.purple
                                : Colors.grey,
                          ),
                          _PreferenceChip(
                            icon: Icons.chat_bubble_outline,
                            label: widget.trip.discussionOk
                                ? 'Discussion'
                                : 'Silence',
                            color: widget.trip.discussionOk
                                ? Colors.teal
                                : Colors.grey,
                          ),
                        ],
                      ),

                      // Commentaire
                      if (widget.trip.commentaire != null) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Informations supplémentaires',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          color: Colors.grey.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(widget.trip.commentaire!),
                          ),
                        ),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barre de réservation en bas
          // Barre de réservation en bas (avec bouton message)
          if (!_isMyTrip && widget.trip.estActif)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton Contacter le conducteur (au-dessus du bouton Réserver)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                otherUserId: widget.trip.conducteurId,
                                trajetId: widget.trip.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.message, color: Colors.blue),
                        label: const Text(
                          'Contacter le conducteur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sélecteur de places + Bouton Réserver
                    Row(
                      children: [
                        // Sélecteur de places
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _nombrePlaces > 1
                                    ? () => setState(() => _nombrePlaces--)
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              Text(
                                '$_nombrePlaces',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: _nombrePlaces <
                                        widget.trip.placesDisponibles
                                    ? () => setState(() => _nombrePlaces++)
                                    : null,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Bouton réserver
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isReserving ? null : _makeReservation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isReserving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Réserver - ${(widget.trip.prix * _nombrePlaces).toStringAsFixed(2)} DT',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

// Widgets auxiliaires
class _ItineraireCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String location;

  const _ItineraireCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          location,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PreferenceChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
    );
  }
}
