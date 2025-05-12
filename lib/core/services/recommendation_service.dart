import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class RecommendationService {
  final SupabaseClient _supabase;

  RecommendationService(this._supabase);

  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // 1. Get user's favorite destinations
      final favoriteResponse = await _supabase
          .from('favorite_destination')
          .select('destination_id')
          .eq('user_id', userId);

      final favoriteIds =
          favoriteResponse.map((fav) => fav['destination_id'] as int).toList();

      // 2. Get all destinations with their details
      final destinationsResponse = await _supabase
          .from('destination')
          .select('*, category:category_id(*)');

      // 3. Get user's interaction history (views)
      final userInteractions = await _supabase
          .from('user_destination_interaction')
          .select()
          .eq('user_id', userId);

      // 4. Calculate recommendation scores
      final scoredDestinations = await _calculateRecommendationScores(
        destinations: destinationsResponse,
        favoriteIds: favoriteIds,
        userInteractions: userInteractions,
      );

      // 5. Sort by score and return top recommendations
      scoredDestinations.sort(
          (a, b) => (b['score'] as double).compareTo(a['score'] as double));

      return scoredDestinations.take(limit).map((dest) {
        // Remove the score from the final result
        final result = Map<String, dynamic>.from(dest);
        result.remove('score');
        return result;
      }).toList();
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      // Fallback to popular destinations if recommendation fails
      return _getFallbackRecommendations();
    }
  }

  Future<List<Map<String, dynamic>>> _calculateRecommendationScores({
    required List<dynamic> destinations,
    required List<int> favoriteIds,
    required List<dynamic> userInteractions,
  }) async {
    final scoredDestinations = <Map<String, dynamic>>[];

    // Calculate user preferences from interactions
    final userPreferences = _calculateUserPreferences(
      favoriteIds: favoriteIds,
      userInteractions: userInteractions,
    );

    // Get user's last viewed location if available
    final userLocation = await _getUserLastLocation(userInteractions);

    for (final destination in destinations) {
      double score = 0.0;

      // 1. Category preference score (40% weight)
      final categoryId = destination['category_id'];
      if (userPreferences['preferred_categories'].contains(categoryId)) {
        score += 0.4;
      }

      // 2. Rating score (30% weight)
      final rating = destination['rating'] as double? ?? 0.0;
      final ratingCount = destination['rating_count'] as int? ?? 0;
      final ratingScore = _calculateRatingScore(rating, ratingCount);
      score += ratingScore * 0.3;

      // 3. Location proximity score (30% weight)
      if (userLocation != null &&
          destination['latitude'] != null &&
          destination['longitude'] != null) {
        final userLat =
            double.tryParse(userLocation['latitude'] as String) ?? 0.0;
        final userLon =
            double.tryParse(userLocation['longitude'] as String) ?? 0.0;
        final destLat =
            double.tryParse(destination['latitude'] as String) ?? 0.0;
        final destLon =
            double.tryParse(destination['longitude'] as String) ?? 0.0;

        final distance = _calculateDistance(
          userLat,
          userLon,
          destLat,
          destLon,
        );
        final proximityScore = _calculateProximityScore(distance);
        score += proximityScore * 0.3;
      } else {
        // If location data is not available, distribute the weight to other factors
        score += ratingScore * 0.15; // Add half of location weight to rating
        score += (userPreferences['preferred_categories'].contains(categoryId)
                ? 0.4
                : 0.0) *
            0.15; // Add half to category
      }

      // Add score to destination data
      final destinationWithScore = Map<String, dynamic>.from(destination);
      destinationWithScore['score'] = score;
      scoredDestinations.add(destinationWithScore);
    }

    return scoredDestinations;
  }

  Map<String, dynamic> _calculateUserPreferences({
    required List<int> favoriteIds,
    required List<dynamic> userInteractions,
  }) {
    // Extract preferred categories from interactions
    final preferredCategories = <int>{};
    final viewedDestinations = <int>{};

    // Process user interactions to build preferences
    for (final interaction in userInteractions) {
      if (interaction['type'] == 'view') {
        preferredCategories.add(interaction['category_id'] as int);
        viewedDestinations.add(interaction['destination_id'] as int);
      }
    }

    return {
      'preferred_categories': preferredCategories.toList(),
      'viewed_destinations': viewedDestinations.toList(),
    };
  }

  Future<Map<String, dynamic>?> _getUserLastLocation(
      List<dynamic> userInteractions) async {
    if (userInteractions.isEmpty) return null;

    // Get the most recent view interaction
    final sortedInteractions = List<Map<String, dynamic>>.from(userInteractions)
      ..sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));

    final lastInteraction = sortedInteractions.firstWhere(
      (interaction) => interaction['type'] == 'view',
      orElse: () => {},
    );

    if (lastInteraction.isEmpty) return null;

    // Get the destination details for the last viewed location
    final destinationId = lastInteraction['destination_id'] as int;
    final response = await _supabase
        .from('destination')
        .select('latitude, longitude')
        .eq('id', destinationId)
        .single();

    return response;
  }

  double _calculateRatingScore(double rating, int ratingCount) {
    // Normalize rating count (assuming max 1000 reviews)
    final normalizedCount = (ratingCount / 1000).clamp(0.0, 1.0);

    // Weight rating more heavily than review count
    return (rating / 5.0) * 0.7 + normalizedCount * 0.3;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert latitude and longitude from degrees to radians
    final lat1Rad = math.pi * lat1 / 180;
    final lon1Rad = math.pi * lon1 / 180;
    final lat2Rad = math.pi * lat2 / 180;
    final lon2Rad = math.pi * lon2 / 180;

    // Haversine formula
    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;

    return distance;
  }

  double _calculateProximityScore(double distance) {
    // Convert distance to a score between 0 and 1
    // Closer destinations get higher scores
    // Using an exponential decay function
    const maxDistance = 50.0; // Maximum distance to consider (50 km)
    return math.exp(-distance / maxDistance);
  }

  Future<List<Map<String, dynamic>>> _getFallbackRecommendations() async {
    // Fallback to popular destinations if recommendation fails
    final response = await _supabase
        .from('destination')
        .select('*, category:category_id(*)')
        .order('rating', ascending: false)
        .limit(10);

    return response.map((dest) => dest).toList();
  }
}
