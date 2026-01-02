import 'package:flutter/material.dart';
import '../models/geo_point.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../widgets/map_widget.dart';

class MapScreen extends StatefulWidget {
  final AppGeoPoint? startPoint;
  final AppGeoPoint? endPoint;
  final bool selectMode; // Mode sélection de point sur la carte
  final String? title;

  const MapScreen({
    Key? key,
    this.startPoint,
    this.endPoint,
    this.selectMode = false,
    this.title,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  final TextEditingController _searchController = TextEditingController();

  AppGeoPoint? _selectedPoint;
  AppGeoPoint? _currentStartPoint;
  AppGeoPoint? _currentEndPoint;
  List<AppGeoPoint>? _routePoints;

  bool _isSearching = false;
  bool _isLoadingLocation = false;
  bool _isCalculatingRoute = false;
  List<AppGeoPoint> _searchResults = [];
  bool _showResults = false;

  String? _routeDistance;
  String? _routeDuration;

  @override
  void initState() {
    super.initState();
    _currentStartPoint = widget.startPoint;
    _currentEndPoint = widget.endPoint;

    if (widget.selectMode && widget.startPoint != null) {
      _selectedPoint = widget.startPoint;
    }

    // Calculer la route si on a départ et arrivée
    if (_currentStartPoint != null && _currentEndPoint != null) {
      _calculateRoute();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _calculateRoute() async {
    if (_currentStartPoint == null || _currentEndPoint == null) return;

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      final routeInfo = await _mapService.getRouteInfo(
        _currentStartPoint!,
        _currentEndPoint!,
      );

      if (routeInfo != null) {
        setState(() {
          _routePoints = routeInfo.polylinePoints;
          _routeDistance = routeInfo.distanceText;
          _routeDuration = routeInfo.durationText;
          _isCalculatingRoute = false;
        });
      } else {
        setState(() {
          _isCalculatingRoute = false;
        });
        _showSnackBar('Impossible de calculer l\'itinéraire', Colors.orange);
      }
    } catch (e) {
      setState(() {
        _isCalculatingRoute = false;
      });
      _showSnackBar('Erreur lors du calcul de la route', Colors.red);
    }
  }

  Future<void> _searchAddress() async {
    if (_searchController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = false;
    });

    try {
      List<AppGeoPoint> results = await _locationService.searchAddress(
        _searchController.text.trim(),
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
        _showResults = results.isNotEmpty;
      });

      if (results.isEmpty) {
        _showSnackBar('Aucun résultat trouvé', Colors.orange);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showSnackBar('Erreur lors de la recherche', Colors.red);
    }
  }

  void _selectSearchResult(AppGeoPoint point) {
    setState(() {
      _selectedPoint = point;
      _showResults = false;
      _searchController.text = point.displayName;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      AppGeoPoint? location = await _locationService.getCurrentLocation();

      if (location != null) {
        setState(() {
          _selectedPoint = location;
          _isLoadingLocation = false;
        });
        _showSnackBar('Position actuelle obtenue', Colors.green);
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
        _showSnackBar(
          'Impossible d\'obtenir la localisation. Vérifiez les permissions.',
          Colors.red,
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _onMapTap(AppGeoPoint point) async {
    if (!widget.selectMode) return;

    setState(() {
      _isLoadingLocation = true;
    });

    // Obtenir l'adresse du point tapé
    AppGeoPoint? pointWithAddress = await _locationService.reverseGeocode(
      point.latitude,
      point.longitude,
    );

    setState(() {
      _selectedPoint = pointWithAddress ?? point;
      _isLoadingLocation = false;
      _searchController.text = _selectedPoint!.displayName;
    });
  }

  void _confirmSelection() {
    if (_selectedPoint != null) {
      Navigator.pop(context, _selectedPoint);
    } else {
      _showSnackBar('Veuillez sélectionner un point', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ??
              (widget.selectMode ? 'Sélectionner un lieu' : 'Carte'),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (widget.selectMode && _selectedPoint != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmSelection,
              tooltip: 'Confirmer',
            ),
        ],
      ),
      body: Stack(
        children: [
          // La carte OpenStreetMap
          MapWidget(
            startPoint: widget.selectMode ? _selectedPoint : _currentStartPoint,
            endPoint: _currentEndPoint,
            routePoints: _routePoints,
            showCurrentLocation: true,
            onMapTap: _onMapTap,
            zoom: 12.0,
          ),

          // Barre de recherche
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Rechercher une adresse...',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _searchAddress(),
                          ),
                        ),
                        if (_isSearching)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _searchAddress,
                          ),
                      ],
                    ),
                  ),
                ),

                // Résultats de recherche
                if (_showResults && _searchResults.isNotEmpty)
                  Card(
                    elevation: 8,
                    margin: const EdgeInsets.only(top: 8),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(
                              result.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: result.address != null
                                ? Text(
                                    result.address!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                            onTap: () => _selectSearchResult(result),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Informations de la route (si départ et arrivée définis)
          if (_routeDistance != null &&
              _routeDuration != null &&
              !widget.selectMode)
            Positioned(
              top: 16,
              left: 16,
              child: Card(
                elevation: 8,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _routeDistance!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _routeDuration!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Informations du point sélectionné
          if (_selectedPoint != null && widget.selectMode)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Point sélectionné',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedPoint!.address ?? _selectedPoint!.displayName,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${_selectedPoint!.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_selectedPoint!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirmSelection,
                          icon: const Icon(Icons.check),
                          label: const Text('Confirmer ce lieu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Indicateur de chargement
          if (_isLoadingLocation || _isCalculatingRoute)
            Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _isCalculatingRoute
                              ? 'Calcul de l\'itinéraire...'
                              : 'Chargement...',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        icon: const Icon(Icons.my_location),
        label: const Text('Ma position'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
