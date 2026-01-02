import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/geo_point.dart';
import '../services/trip_service.dart';
import '../services/map_service.dart';
import 'map_screen.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({Key? key}) : super(key: key);

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final TripService _tripService = TripService();
  final MapService _mapService = MapService();

  // Données du formulaire
  AppGeoPoint? _pointDepart;
  AppGeoPoint? _pointArrivee;
  DateTime? _dateDepart;
  TimeOfDay? _heureDepart;
  int _placesTotal = 1;
  double _prix = 0.0;
  String _commentaire = '';

  // Préférences
  bool _fumeursAcceptes = false;
  bool _animauxAcceptes = false;
  bool _musiqueOk = true;
  bool _discussionOk = true;

  // États
  bool _isLoading = false;
  String? _distanceEstimee;
  String? _dureeEstimee;

  // Calculer l'itinéraire
  Future<void> _calculateRoute() async {
    if (_pointDepart == null || _pointArrivee == null) return;

    setState(() => _isLoading = true);

    try {
      final routeInfo = await _mapService.getRouteInfo(
        _pointDepart!,
        _pointArrivee!,
      );

      if (routeInfo != null) {
        setState(() {
          _distanceEstimee = routeInfo.distanceText;
          _dureeEstimee = routeInfo.durationText;

          // Suggérer un prix basé sur la distance
          if (_prix == 0.0) {
            _prix = _mapService.calculateSuggestedPrice(routeInfo.distance);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Erreur lors du calcul de l\'itinéraire', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Sélectionner le point de départ
  Future<void> _selectDepartPoint() async {
    final point = await Navigator.push<AppGeoPoint>(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          selectMode: true,
          title: 'Point de départ',
          startPoint: _pointDepart,
        ),
      ),
    );

    if (point != null) {
      setState(() {
        _pointDepart = point;
      });
      _calculateRoute();
    }
  }

  // Sélectionner le point d'arrivée
  Future<void> _selectArriveePoint() async {
    final point = await Navigator.push<AppGeoPoint>(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          selectMode: true,
          title: 'Point d\'arrivée',
          startPoint: _pointArrivee,
        ),
      ),
    );

    if (point != null) {
      setState(() {
        _pointArrivee = point;
      });
      _calculateRoute();
    }
  }

  // Sélectionner la date
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      setState(() {
        _dateDepart = date;
      });
    }
  }

  // Sélectionner l'heure
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _heureDepart = time;
      });
    }
  }

  // Créer le trajet
  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pointDepart == null) {
      _showSnackBar('Veuillez sélectionner un point de départ', Colors.orange);
      return;
    }

    if (_pointArrivee == null) {
      _showSnackBar('Veuillez sélectionner un point d\'arrivée', Colors.orange);
      return;
    }

    if (_dateDepart == null || _heureDepart == null) {
      _showSnackBar('Veuillez sélectionner la date et l\'heure', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Combiner date et heure
      DateTime dateHeureDepart = DateTime(
        _dateDepart!.year,
        _dateDepart!.month,
        _dateDepart!.day,
        _heureDepart!.hour,
        _heureDepart!.minute,
      );

      String? tripId = await _tripService.createTrip(
        pointDepart: _pointDepart!,
        pointArrivee: _pointArrivee!,
        dateHeureDepart: dateHeureDepart,
        placesTotal: _placesTotal,
        prix: _prix,
        commentaire: _commentaire.isNotEmpty ? _commentaire : null,
        fumeursAcceptes: _fumeursAcceptes,
        animauxAcceptes: _animauxAcceptes,
        musiqueOk: _musiqueOk,
        discussionOk: _discussionOk,
      );

      if (tripId != null) {
        _showSnackBar('Trajet créé avec succès !', Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposer un trajet'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section itinéraire
                const Text(
                  'Itinéraire',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Point de départ
                _LocationCard(
                  title: 'Point de départ',
                  location: _pointDepart,
                  icon: Icons.radio_button_checked,
                  color: Colors.green,
                  onTap: _selectDepartPoint,
                ),
                const SizedBox(height: 12),

                // Point d'arrivée
                _LocationCard(
                  title: 'Point d\'arrivée',
                  location: _pointArrivee,
                  icon: Icons.location_on,
                  color: Colors.red,
                  onTap: _selectArriveePoint,
                ),

                // Informations de l'itinéraire
                if (_distanceEstimee != null && _dureeEstimee != null)
                  Card(
                    margin: const EdgeInsets.only(top: 12),
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoChip(
                            icon: Icons.straighten,
                            label: _distanceEstimee!,
                            color: Colors.blue,
                          ),
                          _InfoChip(
                            icon: Icons.access_time,
                            label: _dureeEstimee!,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Section date et heure
                const Text(
                  'Date et heure',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _dateDepart != null
                              ? DateFormat('dd/MM/yyyy').format(_dateDepart!)
                              : 'Sélectionner',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          _heureDepart != null
                              ? _heureDepart!.format(context)
                              : 'Sélectionner',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section places et prix
                const Text(
                  'Places et prix',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _placesTotal.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de places',
                          prefixIcon: Icon(Icons.airline_seat_recline_normal),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          int? places = int.tryParse(value);
                          if (places == null || places < 1 || places > 8) {
                            return '1-8 places';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _placesTotal = int.tryParse(value) ?? 1;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _prix.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prix par place (DT)',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          double? prix = double.tryParse(value);
                          if (prix == null || prix < 0) {
                            return 'Prix invalide';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _prix = double.tryParse(value) ?? 0.0;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Préférences
                const Text(
                  'Préférences',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  title: const Text('Fumeurs acceptés'),
                  subtitle: const Text('Autoriser les passagers fumeurs'),
                  value: _fumeursAcceptes,
                  onChanged: (value) =>
                      setState(() => _fumeursAcceptes = value),
                ),
                SwitchListTile(
                  title: const Text('Animaux acceptés'),
                  subtitle: const Text('Autoriser les animaux de compagnie'),
                  value: _animauxAcceptes,
                  onChanged: (value) =>
                      setState(() => _animauxAcceptes = value),
                ),
                SwitchListTile(
                  title: const Text('Musique'),
                  subtitle: const Text(
                    'Écouter de la musique pendant le trajet',
                  ),
                  value: _musiqueOk,
                  onChanged: (value) => setState(() => _musiqueOk = value),
                ),
                SwitchListTile(
                  title: const Text('Discussion'),
                  subtitle: const Text('Ouvert à la conversation'),
                  value: _discussionOk,
                  onChanged: (value) => setState(() => _discussionOk = value),
                ),

                const SizedBox(height: 16),

                // Commentaire
                TextFormField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Commentaire (optionnel)',
                    hintText: 'Informations supplémentaires...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _commentaire = value,
                ),

                const SizedBox(height: 24),

                // Bouton créer
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createTrip,
                    icon: const Icon(Icons.check),
                    label: const Text('Créer le trajet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// Widget pour afficher les cartes de localisation
class _LocationCard extends StatelessWidget {
  final String title;
  final AppGeoPoint? location;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LocationCard({
    required this.title,
    required this.location,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        subtitle: Text(
          location?.displayName ?? 'Tap pour sélectionner',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// Widget pour afficher des informations avec icône
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
