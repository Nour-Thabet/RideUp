import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/rating_service.dart';
import '../widgets/rating_tile.dart';

class RatingScreen extends StatefulWidget {
  final String trajetId;
  final String evalueId;
  final String evalueNom;
  final String type; // 'conducteur' ou 'passager'

  const RatingScreen({
    Key? key,
    required this.trajetId,
    required this.evalueId,
    required this.evalueNom,
    required this.type,
  }) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final RatingService _ratingService = RatingService();
  final TextEditingController _commentController = TextEditingController();

  double _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une note'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _ratingService.createRating(
        trajetId: widget.trajetId,
        evalueId: widget.evalueId,
        note: _rating,
        commentaire: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        type: widget.type,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Évaluation enregistrée !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Évaluation'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icône
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, size: 60, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 24),

            // Texte
            Text(
              'Comment s\'est passé le trajet avec ${widget.evalueNom} ?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Sélection d'étoiles
            Center(
              child: StarRating(
                initialRating: _rating,
                onRatingChanged: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),

            // Texte de la note
            Center(
              child: Text(
                _getRatingText(_rating),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Champ commentaire
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Commentaire (optionnel)',
                hintText: 'Partagez votre expérience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Bouton soumettre
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Envoyer l\'évaluation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating == 0) return 'Sélectionnez une note';
    if (rating <= 1) return 'Très décevant';
    if (rating <= 2) return 'Décevant';
    if (rating <= 3) return 'Moyen';
    if (rating <= 4) return 'Bien';
    return 'Excellent !';
  }
}
