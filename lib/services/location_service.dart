import 'dart:convert';
import 'dart:math' show cos, sqrt, asin, sin;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/geo_point.dart';

class LocationService {
  // Base URL pour Nominatim (service de geocoding OpenStreetMap)
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';

  // User-Agent requis par Nominatim
  static const String _userAgent = 'RideUpApp/1.0 (contact@rideup.tn)';

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
            address: 'Position actuelle',
            city: '',
            country: 'Tunisie',
          );
    } catch (e) {
      print('Erreur lors de l\'obtention de la localisation: $e');
      return null;
    }
  }

  // Reverse Geocoding : Coordonnées → Adresse (Nominatim) avec support multilingue
  Future<AppGeoPoint?> reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_nominatimUrl/reverse?'
        'lat=$latitude&'
        'lon=$longitude&'
        'format=json&'
        'addressdetails=1&'
        'accept-language=fr,en,ar&'
        'namedetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': _userAgent,
          'Accept-Language': 'fr,en,ar;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String? address = _extractFrenchAddress(data);
        String? city = _extractFrenchCity(data);
        String? country = data['address']?['country'] ?? 'Tunisie';

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

  // Geocoding : Adresse → Coordonnées (Nominatim) avec support multilingue
  Future<List<AppGeoPoint>> searchAddress(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      // Normaliser la requête (convertir arabe en français)
      final cleanQuery = _normalizeQuery(query.trim());

      // Attendre 1 seconde pour respecter la politique d'utilisation de Nominatim
      await Future.delayed(const Duration(seconds: 1));

      final url = Uri.parse(
        '$_nominatimUrl/search?'
        'q=${Uri.encodeComponent(cleanQuery)}&'
        'format=json&'
        'addressdetails=1&'
        'limit=10&'
        'countrycodes=tn&'
        'accept-language=fr,en,ar&'
        'namedetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': _userAgent,
          'Accept-Language': 'fr,en,ar;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data.map((item) {
          return AppGeoPoint(
            latitude: double.parse(item['lat']),
            longitude: double.parse(item['lon']),
            address: _extractFrenchName(item),
            city: _extractFrenchCity(item),
            country: item['address']?['country'] ?? 'Tunisie',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors du geocoding: $e');
      return [];
    }
  }

  /// Extraire le nom français d'un résultat Nominatim
  String _extractFrenchName(Map<String, dynamic> result) {
    final nameDetails = result['namedetails'] as Map<String, dynamic>?;

    // Priorité : name:fr > name:en > name
    if (nameDetails != null) {
      if (nameDetails.containsKey('name:fr')) return nameDetails['name:fr'];
      if (nameDetails.containsKey('name:en')) return nameDetails['name:en'];
      if (nameDetails.containsKey('name')) return nameDetails['name'];
    }

    // Sinon, construire à partir de l'adresse
    final address = result['address'] as Map<String, dynamic>?;
    if (address != null) {
      List<String> parts = [];
      if (address.containsKey('road')) parts.add(address['road']);
      if (address.containsKey('suburb')) parts.add(address['suburb']);
      if (address.containsKey('city')) parts.add(address['city']);
      if (address.containsKey('town')) parts.add(address['town']);
      if (address.containsKey('village')) parts.add(address['village']);
      if (parts.isNotEmpty) return parts.join(', ');
    }

    return result['display_name'] ?? 'Lieu inconnu';
  }

  /// Extraire le nom de ville en français
  String _extractFrenchCity(Map<String, dynamic> result) {
    final address = result['address'] as Map<String, dynamic>?;
    if (address == null) return '';

    return address['city'] ??
        address['town'] ??
        address['village'] ??
        address['municipality'] ??
        '';
  }

  /// Extraire l'adresse complète en français
  String _extractFrenchAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address != null) {
      List<String> parts = [];
      if (address.containsKey('house_number'))
        parts.add(address['house_number']);
      if (address.containsKey('road')) parts.add(address['road']);
      if (address.containsKey('suburb')) parts.add(address['suburb']);
      if (address.containsKey('city')) parts.add(address['city']);
      if (address.containsKey('town')) parts.add(address['town']);
      if (address.containsKey('village')) parts.add(address['village']);
      return parts.isNotEmpty ? parts.join(', ') : data['display_name'] ?? '';
    }
    return data['display_name'] ?? '';
  }

  /// Mapping arabe → français pour les villes tunisiennes
  String _normalizeQuery(String query) {
    final Map<String, String> cityMapping = {
      'تونس': 'Tunis',
      'صفاقس': 'Sfax',
      'سوسة': 'Sousse',
      'القيروان': 'Kairouan',
      'بنزرت': 'Bizerte',
      'قابس': 'Gabès',
      'أريانة': 'Ariana',
      'قفصة': 'Gafsa',
      'المنستير': 'Monastir',
      'تطاوين': 'Tataouine',
      'قبلي': 'Kebili',
      'المهدية': 'Mahdia',
      'مدنين': 'Medenine',
      'نابل': 'Nabeul',
      'توزر': 'Tozeur',
      'جندوبة': 'Jendouba',
      'الكاف': 'El Kef',
      'سليانة': 'Siliana',
      'زغوان': 'Zaghouan',
      'باجة': 'Béja',
      'القصرين': 'Kasserine',
      'سيدي بوزيد': 'Sidi Bouzid',
      'المرسى': 'La Marsa',
      'قرطاج': 'Carthage',
      'حمام الأنف': 'Hammam-Lif',
      'رادس': 'Radès',
      'بن عروس': 'Ben Arous',
    };

    String normalized = query;
    cityMapping.forEach((arabic, french) {
      if (normalized.contains(arabic)) {
        normalized = normalized.replaceAll(arabic, french);
      }
    });
    return normalized;
  }

  /// Liste des grandes villes tunisiennes (pour suggestions)
  List<String> getTunisianCities() {
    return [
      'Tunis',
      'Sfax',
      'Sousse',
      'Kairouan',
      'Bizerte',
      'Gabès',
      'Ariana',
      'Gafsa',
      'Monastir',
      'La Marsa',
      'Hammam-Lif',
      'Ben Arous',
      'Nabeul',
      'Hammamet',
      'Mahdia',
      'Tozeur',
      'Jendouba',
      'El Kef',
      'Béja',
      'Kasserine',
      'Sidi Bouzid',
      'Medenine',
      'Tataouine',
      'Kebili',
    ];
  }

  /// Recherche locale parmi les villes tunisiennes
  List<String> searchLocalCities(String query) {
    final lowerQuery = query.toLowerCase();
    return getTunisianCities()
        .where((city) => city.toLowerCase().contains(lowerQuery))
        .toList();
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
