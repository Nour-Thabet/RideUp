import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/rating.dart';
import '../models/user.dart';

// Widget pour afficher une évaluation
class RatingTile extends StatelessWidget {
  final Rating rating;
  final User? evaluateur;

  const RatingTile({Key? key, required this.rating, this.evaluateur})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec évaluateur et date
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    evaluateur?.initiales ?? '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evaluateur?.nomComplet ?? 'Utilisateur',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dateFormat.format(rating.dateEvaluation),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Note
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        rating.note.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Commentaire
            if (rating.commentaire != null &&
                rating.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(rating.commentaire!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget pour afficher les statistiques de notation
class RatingStats extends StatelessWidget {
  final int totalRatings;
  final double averageRating;
  final Map<int, int> starsDistribution;

  const RatingStats({
    Key? key,
    required this.totalRatings,
    required this.averageRating,
    required this.starsDistribution,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Note moyenne
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStars(averageRating),
                    const SizedBox(height: 4),
                    Text(
                      '$totalRatings avis',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Distribution des étoiles
            for (int stars = 5; stars >= 1; stars--)
              _buildStarDistribution(
                stars,
                starsDistribution[stars] ?? 0,
                totalRatings,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.orange, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.orange, size: 20);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[400], size: 20);
        }
      }),
    );
  }

  Widget _buildStarDistribution(int stars, int count, int total) {
    double percentage = total > 0 ? (count / total) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$stars', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 16, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour sélectionner une note (étoiles cliquables)
class StarRating extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;

  const StarRating({
    Key? key,
    this.initialRating = 0,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = index + 1.0;
            });
            widget.onRatingChanged(_rating);
          },
          child: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.orange,
            size: 40,
          ),
        );
      }),
    );
  }
}
