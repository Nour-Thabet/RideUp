import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../models/user.dart';

class TripTile extends StatelessWidget {
  final Trip trip;
  final User? conducteur;
  final VoidCallback onTap;
  final bool showStatus;

  const TripTile({
    Key? key,
    required this.trip,
    this.conducteur,
    required this.onTap,
    this.showStatus = false,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (trip.statut) {
      case 'actif':
        return Colors.green;
      case 'complet':
        return Colors.orange;
      case 'termine':
        return Colors.grey;
      case 'annule':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (trip.statut) {
      case 'actif':
        return 'Actif';
      case 'complet':
        return 'Complet';
      case 'termine':
        return 'Terminé';
      case 'annule':
        return 'Annulé';
      default:
        return trip.statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE dd MMM', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec date et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(trip.dateHeureDepart),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeFormat.format(trip.dateHeureDepart),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  if (showStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Itinéraire
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(width: 2, height: 30, color: Colors.grey[300]),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.pointDepart.city ?? trip.pointDepart.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          trip.pointArrivee.city ??
                              trip.pointArrivee.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Informations supplémentaires
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Conducteur
                  if (conducteur != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            conducteur!.initiales,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conducteur!.prenom,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (conducteur!.nombreAvis > 0)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    conducteur!.noteMoyenne.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),

                  // Places et prix
                  Row(
                    children: [
                      // Places
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.airline_seat_recline_normal,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.placesDisponibles}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Prix
                      Text(
                        '${trip.prix.toStringAsFixed(1)} DT',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Distance et durée
              if (trip.distance != null && trip.duree != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.distance!.toStringAsFixed(0)} km',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      trip.duree!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
