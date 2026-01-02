import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../models/user.dart';
import '../services/trip_service.dart';
import '../services/user_service.dart';
import '../widgets/trip_tile.dart';
import 'trip_detail_screen.dart';

class SearchTripsScreen extends StatefulWidget {
  const SearchTripsScreen({Key? key}) : super(key: key);

  @override
  State<SearchTripsScreen> createState() => _SearchTripsScreenState();
}

class _SearchTripsScreenState extends State<SearchTripsScreen> {
  final TripService _tripService = TripService();
  final UserService _userService = UserService();

  final TextEditingController _departController = TextEditingController();
  final TextEditingController _arriveeController = TextEditingController();

  DateTime? _dateRecherche;
  List<Trip> _resultatsTrajets = [];
  Map<String, User> _conducteursCache = {};
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _departController.dispose();
    _arriveeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      setState(() {
        _dateRecherche = date;
      });
    }
  }

  Future<void> _searchTrips() async {
    if (_departController.text.trim().isEmpty ||
        _arriveeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir le départ et l\'arrivée'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      List<Trip> trips = await _tripService.searchTrips(
        villeDepart: _departController.text.trim(),
        villeArrivee: _arriveeController.text.trim(),
        date: _dateRecherche,
      );

      // Charger les infos des conducteurs
      _conducteursCache.clear();
      for (var trip in trips) {
        if (!_conducteursCache.containsKey(trip.conducteurId)) {
          User? conducteur = await _userService.getUserById(trip.conducteurId);
          if (conducteur != null) {
            _conducteursCache[trip.conducteurId] = conducteur;
          }
        }
      }

      setState(() {
        _resultatsTrajets = trips;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openTripDetail(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailScreen(
          trip: trip,
          conducteur: _conducteursCache[trip.conducteurId],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher un trajet'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Formulaire de recherche
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Ville de départ
                TextField(
                  controller: _departController,
                  decoration: InputDecoration(
                    labelText: 'Ville de départ',
                    prefixIcon: const Icon(
                      Icons.radio_button_checked,
                      color: Colors.green,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Ville d'arrivée
                TextField(
                  controller: _arriveeController,
                  decoration: InputDecoration(
                    labelText: 'Ville d\'arrivée',
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Date (optionnelle)
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date (optionnelle)',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _dateRecherche != null
                          ? DateFormat('dd/MM/yyyy').format(_dateRecherche!)
                          : 'Toutes les dates',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton rechercher
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchTrips,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isSearching ? 'Recherche...' : 'Rechercher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Résultats
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched
                ? _resultatsTrajets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun trajet trouvé',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Essayez avec d\'autres critères',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _resultatsTrajets.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final trip = _resultatsTrajets[index];
                            return TripTile(
                              trip: trip,
                              conducteur: _conducteursCache[trip.conducteurId],
                              onTap: () => _openTripDetail(trip),
                            );
                          },
                        )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Recherchez un trajet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entrez votre destination',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
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
