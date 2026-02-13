import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String initiales;
  final double radius;

  const AvatarWidget({
    Key? key,
    this.photoUrl,
    required this.initiales,
    this.radius = 30,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si photoUrl existe et commence par assets/
    if (photoUrl != null && photoUrl!.startsWith('assets/')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blue.shade100,
        backgroundImage: AssetImage(photoUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          print('❌ Erreur chargement avatar: $photoUrl');
        },
      );
    }

    // Si photoUrl est une URL internet
    if (photoUrl != null && photoUrl!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blue.shade100,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }

    // Sinon, afficher les initiales
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade100,
      child: Text(
        initiales,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}
