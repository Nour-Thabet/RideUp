// lib/providers.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/reservation_service.dart';
import '../services/notification_service.dart';
import '../services/trip_service.dart';
import '../services/user_service.dart'; // si tu l'as

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Tous tes services en Provider
        Provider<ReservationService>(
          create: (context) => ReservationService(),
        ),
        Provider<NotificationService>(
          create: (context) => NotificationService(),
        ),
        Provider<TripService>(
          create: (context) => TripService(),
        ),
        Provider<UserService>(
          create: (context) => UserService(),
        ),
        // Ajoute ici d'autres services si besoin
      ],
      child: child,
    );
  }
}
