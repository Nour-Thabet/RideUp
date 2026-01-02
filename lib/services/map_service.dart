import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/geo_point.dart';
import 'location_service.dart';

class MapService {
  final LocationService _locationService = LocationService();

  // URL pour OSRM (Open Source Routing Machine) - Service de routage gratuit
  static const String _osrmUrl =
      'https://router.project-osrm.org/route/v1/driving';

  // Calculer l'itinéraire entre deux points avec OSRM
  Future<Map<String, dynamic>?> getRoute(
    AppGeoPoint origin,
    AppGeoPoint destination, {
    List<AppGeoPoint>? waypoints,
  }) async {
    try {
      // Construire l'URL avec les coordonnées
      String coordinates = '${origin.longitude},${origin.latitude}';

      // Ajouter les waypoints
      if (waypoints != null && waypoints.isNotEmpty) {
        for (var point in waypoints) {
          coordinates += ';${point.longitude},${point.latitude}';
        }
      }

      coordinates += ';${destination.longitude},${destination.latitude}';

      final url = Uri.parse(
        '$_osrmUrl/$coordinates?'
        'overview=full&'
        'geometries=geojson&'
        'steps=true',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok') {
          final route = data['routes'][0];
          return {
            'distance': route['distance'], // en mètres
            'duration': route['duration'], // en secondes
            'geometry':
                route['geometry']['coordinates'], // Liste de coordonnées
            'legs': route['legs'],
          };
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors du calcul de l\'itinéraire: $e');
      return null;
    }
  }

  // Obtenir les informations détaillées d'un trajet
  Future<RouteInfo?> getRouteInfo(
    AppGeoPoint origin,
    AppGeoPoint destination, {
    List<AppGeoPoint>? waypoints,
  }) async {
    final routeData = await getRoute(origin, destination, waypoints: waypoints);

    if (routeData == null) return null;

    double distanceKm = routeData['distance'] / 1000;
    int durationSeconds = routeData['duration'].toInt();

    // Convertir les coordonnées GeoJSON en liste de AppGeoPoint
    List<AppGeoPoint> polylinePoints = [];
    for (var coord in routeData['geometry']) {
      polylinePoints.add(AppGeoPoint(latitude: coord[1], longitude: coord[0]));
    }

    return RouteInfo(
      distance: distanceKm,
      duration: Duration(seconds: durationSeconds),
      polylinePoints: polylinePoints,
      distanceText: _locationService.formatDistance(distanceKm),
      durationText: _locationService.formatDuration(
        Duration(seconds: durationSeconds),
      ),
    );
  }

  // Trouver les trajets à proximité d'un point
  List<T> findNearbyTrips<T>({
    required List<T> allTrips,
    required AppGeoPoint userLocation,
    required double radiusKm,
    required AppGeoPoint Function(T) getStartPoint,
    required AppGeoPoint Function(T) getEndPoint,
  }) {
    return allTrips.where((trip) {
      final startPoint = getStartPoint(trip);
      final endPoint = getEndPoint(trip);

      // Vérifier si le point de départ ou d'arrivée est dans le rayon
      bool nearStart = _locationService.isWithinRadius(
        userLocation,
        startPoint,
        radiusKm,
      );

      bool nearEnd = _locationService.isWithinRadius(
        userLocation,
        endPoint,
        radiusKm,
      );

      return nearStart || nearEnd;
    }).toList();
  }

  // Calculer le prix suggéré basé sur la distance (0.5 DT/km en Tunisie)
  double calculateSuggestedPrice(double distanceKm, {double pricePerKm = 0.5}) {
    return (distanceKm * pricePerKm).roundToDouble();
  }

  // Vérifier si deux trajets ont un chemin similaire
  bool areRoutesSimilar(
    AppGeoPoint start1,
    AppGeoPoint end1,
    AppGeoPoint start2,
    AppGeoPoint end2, {
    double thresholdKm = 5.0,
  }) {
    double startDistance = _locationService.calculateDistance(start1, start2);
    double endDistance = _locationService.calculateDistance(end1, end2);

    return startDistance <= thresholdKm && endDistance <= thresholdKm;
  }

  // Obtenir les alternatives de style de carte
  Map<String, String> get tileLayerUrls => {
    'standard': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'carto_light':
        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    'carto_dark':
        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    'carto_voyager':
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    'humanitarian': 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
  };
}

// Classe pour stocker les informations d'un itinéraire
class RouteInfo {
  final double distance; // en km
  final Duration duration;
  final List<AppGeoPoint> polylinePoints;
  final String distanceText;
  final String durationText;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
  });

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'duration': duration.inSeconds,
      'distanceText': distanceText,
      'durationText': durationText,
      'polylinePoints': polylinePoints.map((p) => p.toJson()).toList(),
    };
  }

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      distance: json['distance'],
      duration: Duration(seconds: json['duration']),
      distanceText: json['distanceText'],
      durationText: json['durationText'],
      polylinePoints: (json['polylinePoints'] as List)
          .map((p) => AppGeoPoint.fromJson(p))
          .toList(),
    );
  }
}
