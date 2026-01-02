import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/rating.dart';
import '../models/user.dart';
import '../services/rating_service.dart';
import '../services/user_service.dart';
import '../widgets/rating_tile.dart';

class UserRatingsScreen extends StatefulWidget {
  const UserRatingsScreen({Key? key}) : super(key: key);

  @override
  State<UserRatingsScreen> createState() => _UserRatingsScreenState();
}

class _UserRatingsScreenState extends State<UserRatingsScreen>
    with SingleTickerProviderStateMixin {
  final RatingService _ratingService = RatingService();
  final UserService _userService = UserService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  late TabController _tabController;
  bool _isLoadingStats = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final stats = await _ratingService.getRatingStats(userId);
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Erreur chargement stats: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes évaluations'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes évaluations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Reçues', icon: Icon(Icons.star)),
            Tab(text: 'Données', icon: Icon(Icons.rate_review)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistiques
          if (!_isLoadingStats) _buildStatsCard(),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ReceivedRatingsTab(userId: userId),
                _GivenRatingsTab(userId: userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalRatings = _stats['totalRatings'] ?? 0;
    final averageRating = _stats['averageRating'] ?? 0.0;
    final starsDistribution = _stats['starsDistribution'] ?? {};

    if (totalRatings == 0) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Vous n\'avez pas encore reçu d\'évaluations',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RatingStats(
      totalRatings: totalRatings,
      averageRating: averageRating,
      starsDistribution: Map<int, int>.from(starsDistribution),
    );
  }
}

// ==================== ONGLET ÉVALUATIONS REÇUES ====================
class _ReceivedRatingsTab extends StatelessWidget {
  final String userId;

  const _ReceivedRatingsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final ratingService = RatingService();
    final userService = UserService();

    return StreamBuilder<List<Rating>>(
      stream: ratingService.getRatingsReceivedStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final ratings = snapshot.data ?? [];

        if (ratings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune évaluation reçue',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les évaluations apparaîtront ici',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];

            return FutureBuilder<User?>(
              future: userService.getUserById(rating.evaluateurId),
              builder: (context, userSnapshot) {
                return RatingTile(
                  rating: rating,
                  evaluateur: userSnapshot.data,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==================== ONGLET ÉVALUATIONS DONNÉES ====================
class _GivenRatingsTab extends StatelessWidget {
  final String userId;

  const _GivenRatingsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final ratingService = RatingService();
    final userService = UserService();

    return StreamBuilder<List<Rating>>(
      stream: ratingService.getRatingsGivenStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final ratings = snapshot.data ?? [];

        if (ratings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune évaluation donnée',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notez vos conducteurs et passagers',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];

            return FutureBuilder<User?>(
              future: userService.getUserById(rating.evalueId),
              builder: (context, userSnapshot) {
                final evalueUser = userSnapshot.data;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                evalueUser?.initiales ?? '?',
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
                                    'Évaluation de ${evalueUser?.nomComplet ?? 'Utilisateur'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(rating.dateEvaluation),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Note donnée
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
                                  const Icon(
                                    Icons.star,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rating.commentaire!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],

                        // Type d'évaluation
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: rating.type == 'conducteur'
                                ? Colors.blue.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rating.type == 'conducteur'
                                ? 'En tant que conducteur'
                                : 'En tant que passager',
                            style: TextStyle(
                              fontSize: 12,
                              color: rating.type == 'conducteur'
                                  ? Colors.blue.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }
}



/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/rating.dart';
import '../models/user.dart';
import '../services/rating_service.dart';
import '../services/user_service.dart';
import '../widgets/rating_tile.dart';

class UserRatingsScreen extends StatefulWidget {
  const UserRatingsScreen({Key? key}) : super(key: key);

  @override
  State<UserRatingsScreen> createState() => _UserRatingsScreenState();
}

class _UserRatingsScreenState extends State<UserRatingsScreen>
    with SingleTickerProviderStateMixin {
  final RatingService _ratingService = RatingService();
  final UserService _userService = UserService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  late TabController _tabController;
  bool _isLoadingStats = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final stats = await _ratingService.getRatingStats(userId);
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Erreur chargement stats: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes évaluations'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes évaluations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Reçues', icon: Icon(Icons.star)),
            Tab(text: 'Données', icon: Icon(Icons.rate_review)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistiques
          if (!_isLoadingStats) _buildStatsCard(),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ReceivedRatingsTab(userId: userId),
                _GivenRatingsTab(userId: userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalRatings = _stats['totalRatings'] ?? 0;
    final averageRating = _stats['averageRating'] ?? 0.0;
    final starsDistribution = _stats['starsDistribution'] ?? {};

    if (totalRatings == 0) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Vous n\'avez pas encore reçu d\'évaluations',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RatingStats(
      totalRatings: totalRatings,
      averageRating: averageRating,
      starsDistribution: Map<int, int>.from(starsDistribution),
    );
  }
}

// ==================== ONGLET ÉVALUATIONS REÇUES ====================
class _ReceivedRatingsTab extends StatelessWidget {
  final String userId;

  const _ReceivedRatingsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final ratingService = RatingService();
    final userService = UserService();

    return FutureBuilder<List<Rating>>(
      future: ratingService.getRatingsForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final ratings = snapshot.data ?? [];

        if (ratings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune évaluation reçue',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les évaluations apparaîtront ici',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];

            return FutureBuilder<User?>(
              future: userService.getUserById(rating.evaluateurId),
              builder: (context, userSnapshot) {
                return RatingTile(
                  rating: rating,
                  evaluateur: userSnapshot.data,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==================== ONGLET ÉVALUATIONS DONNÉES ====================
class _GivenRatingsTab extends StatelessWidget {
  final String userId;

  const _GivenRatingsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final ratingService = RatingService();
    final userService = UserService();

    return FutureBuilder<List<Rating>>(
      future: ratingService.getRatingsByUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final ratings = snapshot.data ?? [];

        if (ratings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune évaluation donnée',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notez vos conducteurs et passagers',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];

            return FutureBuilder<User?>(
              future: userService.getUserById(rating.evalueId),
              builder: (context, userSnapshot) {
                final evalueUser = userSnapshot.data;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                evalueUser?.initiales ?? '?',
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
                                    'Évaluation de ${evalueUser?.nomComplet ?? 'Utilisateur'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(rating.dateEvaluation),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Note donnée
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
                                  const Icon(
                                    Icons.star,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rating.commentaire!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],

                        // Type d'évaluation
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: rating.type == 'conducteur'
                                ? Colors.blue.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rating.type == 'conducteur'
                                ? 'En tant que conducteur'
                                : 'En tant que passager',
                            style: TextStyle(
                              fontSize: 12,
                              color: rating.type == 'conducteur'
                                  ? Colors.blue.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }
}*/









/*import 'package:flutter/material.dart';
import '../models/rating.dart';
import '../models/user.dart';
import '../services/rating_service.dart';
import '../services/user_service.dart';
import '../widgets/rating_tile.dart';

class UserRatingsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserRatingsScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<UserRatingsScreen> createState() => _UserRatingsScreenState();
}

class _UserRatingsScreenState extends State<UserRatingsScreen> {
  final RatingService _ratingService = RatingService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avis de ${widget.userName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final stats = snapshot.data!['stats'] as Map<String, dynamic>;
          final ratings = snapshot.data!['ratings'] as List<Rating>;
          final evaluateurs =
              snapshot.data!['evaluateurs'] as Map<String, User>;

          return ListView(
            children: [
              // Statistiques
              RatingStats(
                totalRatings: stats['totalRatings'],
                averageRating: stats['averageRating'],
                starsDistribution: Map<int, int>.from(
                  stats['starsDistribution'],
                ),
              ),

              // Liste des avis
              if (ratings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.star_border,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun avis pour le moment',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...ratings.map((rating) {
                  return RatingTile(
                    rating: rating,
                    evaluateur: evaluateurs[rating.evaluateurId],
                  );
                }).toList(),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadData() async {
    // Charger les statistiques
    Map<String, dynamic> stats = await _ratingService.getRatingStats(
      widget.userId,
    );

    // Charger les évaluations
    List<Rating> ratings = await _ratingService.getRatingsForUser(
      widget.userId,
    );

    // Charger les infos des évaluateurs
    Map<String, User> evaluateurs = {};
    for (var rating in ratings) {
      if (!evaluateurs.containsKey(rating.evaluateurId)) {
        User? user = await _userService.getUserById(rating.evaluateurId);
        if (user != null) {
          evaluateurs[rating.evaluateurId] = user;
        }
      }
    }

    return {'stats': stats, 'ratings': ratings, 'evaluateurs': evaluateurs};
  }
}
*/