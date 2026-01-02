import 'dart:convert';
import 'dart:math' show cos, sqrt, asin, sin;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/geo_point.dart';

class LocationService {
  // Base URL pour Nominatim (service de geocoding OpenStreetMap)
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';

  // User-Agent requis par Nominatim
  static const String _userAgent = 'CovoiturageApp/1.0';

  // Vérifier et demander les permissions de localisation
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si le service de localisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Vérifier les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Obtenir la position actuelle de l'utilisateur
  Future<AppGeoPoint?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Obtenir l'adresse à partir des coordonnées
      AppGeoPoint? point = await reverseGeocode(
        position.latitude,
        position.longitude,
      );

      return point ??
          AppGeoPoint(
            latitude: position.latitude,
            longitude: position.longitude,
          );
    } catch (e) {
      print('Erreur lors de l\'obtention de la localisation: $e');
      return null;
    }
  }

  // Reverse Geocoding : Coordonnées → Adresse (Nominatim)
  Future<AppGeoPoint?> reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_nominatimUrl/reverse?'
        'lat=$latitude&'
        'lon=$longitude&'
        'format=json&'
        'addressdetails=1',
      );

      final response = await http.get(url, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String? address = data['display_name'];
        String? city = data['address']?['city'] ??
            data['address']?['town'] ??
            data['address']?['village'];
        String? country = data['address']?['country'];

        return AppGeoPoint(
          latitude: latitude,
          longitude: longitude,
          address: address,
          city: city,
          country: country,
        );
      }
      return null;
    } catch (e) {
      print('Erreur lors du reverse geocoding: $e');
      return null;
    }
  }

  // Geocoding : Adresse → Coordonnées (Nominatim)
  Future<List<AppGeoPoint>> searchAddress(String query) async {
    try {
      // Attendre 1 seconde pour respecter la politique d'utilisation de Nominatim
      await Future.delayed(const Duration(seconds: 1));

      final url = Uri.parse(
        '$_nominatimUrl/search?'
        'q=${Uri.encodeComponent(query)}&'
        'format=json&'
        'addressdetails=1&'
        'limit=5',
      );

      final response = await http.get(url, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data.map((item) {
          return AppGeoPoint(
            latitude: double.parse(item['lat']),
            longitude: double.parse(item['lon']),
            address: item['display_name'],
            city: item['address']?['city'] ??
                item['address']?['town'] ??
                item['address']?['village'],
            country: item['address']?['country'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors du geocoding: $e');
      return [];
    }
  }

  // Calculer la distance entre deux points en kilomètres (Haversine formula)
  double calculateDistance(AppGeoPoint start, AppGeoPoint end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000; // Conversion en km
  }

  // Calculer la distance avec formule Haversine (alternative)
  double haversineDistance(AppGeoPoint start, AppGeoPoint end) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    double lat1 = start.latitude * (3.141592653589793 / 180);
    double lat2 = end.latitude * (3.141592653589793 / 180);
    double lon1 = start.longitude * (3.141592653589793 / 180);
    double lon2 = end.longitude * (3.141592653589793 / 180);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1) * cos(lat2) * (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Calculer la durée estimée du trajet (60 km/h moyenne)
  Duration estimateDuration(double distanceKm, {double averageSpeed = 60.0}) {
    double hours = distanceKm / averageSpeed;
    return Duration(minutes: (hours * 60).round());
  }

  // Formater la durée en texte lisible
  String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  // Formater la distance en texte lisible
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  // Obtenir un flux de position en temps réel
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mise à jour tous les 10 mètres
      ),
    );
  }

  // Vérifier si un point est dans un rayon donné
  bool isWithinRadius(AppGeoPoint center, AppGeoPoint point, double radiusKm) {
    double distance = calculateDistance(center, point);
    return distance <= radiusKm;
  }
}
