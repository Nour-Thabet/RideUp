import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class AppGeoPoint {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;

  AppGeoPoint({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
  });

  // 🔹 Depuis Firestore GeoPoint
  factory AppGeoPoint.fromFirestore(
    firestore.GeoPoint geoPoint, {
    String? address,
    String? city,
    String? country,
  }) {
    return AppGeoPoint(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      address: address,
      city: city,
      country: country,
    );
  }

  // 🔹 Depuis JSON
  factory AppGeoPoint.fromJson(Map<String, dynamic> json) {
    return AppGeoPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }

  // 🔹 Vers JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
    };
  }

  // 🔹 Vers Firestore GeoPoint
  firestore.GeoPoint toFirestore() {
    return firestore.GeoPoint(latitude, longitude);
  }

  String get displayName {
    if (city != null) return city!;
    if (address != null) return address!;
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  String get fullAddress {
    if (address != null && city != null && country != null) {
      return '$address, $city, $country';
    }
    if (address != null) return address!;
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  @override
  String toString() {
    return 'AppGeoPoint(lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppGeoPoint &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  AppGeoPoint copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
  }) {
    return AppGeoPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }
}
