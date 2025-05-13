import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class RecommendationService {
  final SupabaseClient _supabase;

  final Map<String, Map<String, dynamic>> _userPreferencesCache = {};
  final Duration _cacheDuration = const Duration(minutes: 10);
  final Map<String, DateTime> _lastPreferenceCalculation = {};

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

      // 3. Get user's interaction history (views, ratings, etc.)
      final userInteractions = await _supabase
          .from('user_destination_interaction')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // 4. Calculate recommendation scores
      final scoredDestinations = await _calculateRecommendationScores(
        destinations: destinationsResponse,
        favoriteIds: favoriteIds,
        userInteractions: userInteractions,
        userId: userId,
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
    required String userId,
  }) async {
    final scoredDestinations = <Map<String, dynamic>>[];

    // Check if we have cached preferences that are still valid
    bool hasValidCache = _userPreferencesCache.containsKey(userId) &&
        _lastPreferenceCalculation.containsKey(userId) &&
        DateTime.now().difference(_lastPreferenceCalculation[userId]!) <
            _cacheDuration;

    // Calculate user preferences from interactions or use cache
    final userPreferences = hasValidCache
        ? _userPreferencesCache[userId]!
        : _calculateUserPreferences(
            favoriteIds: favoriteIds,
            userInteractions: userInteractions,
            userId: userId,
          );

    // Get user's last viewed location if available
    final userLocation = await _getUserLastLocation(userInteractions);

    // Extract interaction data for weighing
    final interactionWeights = _getInteractionWeights(userInteractions);
    final recencyFactors = _calculateRecencyFactors(userInteractions);

    // Get recently viewed category IDs (for variety)
    final recentCategoryIds = _getRecentCategoryIds(userInteractions);

    for (final destination in destinations) {
      double score = 0.0;
      final destinationId = destination['id'] as int;

      // Skip destinations that the user has already favorited
      if (favoriteIds.contains(destinationId)) {
        continue;
      }

      // 1. Category preference score
      final categoryId = destination['category_id'] as int?;
      if (categoryId != null) {
        if (userPreferences['preferred_categories'].contains(categoryId)) {
          score += 0.3;
          if (recentCategoryIds.contains(categoryId)) {
            score -= 0.05;
          }
        }
      }
      // 2. Rating score
      final rating = (destination['rating'] as num?)?.toDouble() ?? 0.0;
      final ratingCount = (destination['rating_count'] as num?)?.toInt() ?? 0;
      final ratingScore = _calculateRatingScore(rating, ratingCount);
      score += ratingScore * 0.25;
      // 3. Interaction similarity score
      final similarityScore = _calculateSimilarityScore(destination,
          interactionWeights, userPreferences['viewed_destinations']);
      score += similarityScore * 0.25;
      // 4. Location proximity score
      if (userLocation != null &&
          destination['latitude'] != null &&
          destination['longitude'] != null) {
        final userLat = _parseDouble(userLocation['latitude']) ?? 0.0;
        final userLon = _parseDouble(userLocation['longitude']) ?? 0.0;
        final destLat = _parseDouble(destination['latitude']) ?? 0.0;
        final destLon = _parseDouble(destination['longitude']) ?? 0.0;

        final distance = _calculateDistance(
          userLat,
          userLon,
          destLat,
          destLon,
        );
        final proximityScore = _calculateProximityScore(distance);
        score += proximityScore * 0.2;
      } else {
        // If location data is not available, distribute the weight to other factors
        score += ratingScore * 0.1;
        score += similarityScore * 0.1;
      }

      // Apply recency bonus if the destination is from a category the user recently viewed
      if (categoryId != null && recencyFactors.containsKey(categoryId)) {
        score += recencyFactors[categoryId]! * 0.1;
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
    required String userId,
  }) {
    // Extract preferred categories from interactions
    final Map<int, int> categoryFrequency = {};
    final viewedDestinations = <int>{};
    final interactionsByCategory = <int, List<Map<String, dynamic>>>{};

    // Process user interactions to build preferences
    for (final interaction in userInteractions) {
      if (interaction['destination_id'] != null) {
        viewedDestinations.add(interaction['destination_id'] as int);
      }

      final categoryId = interaction['category_id'] as int?;
      if (categoryId != null) {
        // Count category frequency
        categoryFrequency[categoryId] =
            (categoryFrequency[categoryId] ?? 0) + 1;

        // Group interactions by category
        interactionsByCategory[categoryId] ??= [];
        interactionsByCategory[categoryId]!
            .add(Map<String, dynamic>.from(interaction));
      }
    }

    // Sort categories by frequency to get top preferences
    final sortedCategories = categoryFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final preferredCategories = sortedCategories
        .take(5) // Take top 5 categories
        .map((e) => e.key)
        .toList();

    // Store results in cache
    final preferences = {
      'preferred_categories': preferredCategories,
      'viewed_destinations': viewedDestinations.toList(),
      'category_frequency': categoryFrequency,
      'interactions_by_category': interactionsByCategory,
    };

    // Update cache
    _userPreferencesCache[userId] = preferences;
    _lastPreferenceCalculation[userId] = DateTime.now();

    return preferences;
  }

  // Calculate similarity between destinations based on user interaction patterns
  double _calculateSimilarityScore(
    Map<String, dynamic> destination,
    Map<int, double> interactionWeights,
    List<dynamic> viewedDestinations,
  ) {
    final destinationId = destination['id'] as int;

    // If user has interacted with this destination, give it a lower score
    // to encourage variety in recommendations
    if (viewedDestinations.contains(destinationId)) {
      return 0.0;
    }

    // Calculate similarity based on category and interaction weights
    double similarityScore = 0.0;
    final categoryId = destination['category_id'] as int?;

    if (categoryId != null && interactionWeights.containsKey(categoryId)) {
      similarityScore += interactionWeights[categoryId]! * 0.8;
    }

    return similarityScore.clamp(0.0, 1.0);
  }

  // Calculate weights for categories based on user interactions
  Map<int, double> _getInteractionWeights(List<dynamic> userInteractions) {
    final Map<int, int> interactions = {};
    final Map<int, double> weights = {};
    int totalInteractions = 0;

    // Count interactions by category
    for (final interaction in userInteractions) {
      final categoryId = interaction['category_id'] as int?;
      if (categoryId != null) {
        interactions[categoryId] = (interactions[categoryId] ?? 0) + 1;
        totalInteractions++;
      }
    }

    // Calculate normalized weights
    if (totalInteractions > 0) {
      interactions.forEach((categoryId, count) {
        weights[categoryId] = count / totalInteractions;
      });
    }

    return weights;
  }

  // Get recency factors for categories (higher values for more recent interactions)
  Map<int, double> _calculateRecencyFactors(List<dynamic> userInteractions) {
    final Map<int, double> recencyFactors = {};
    final recencyMax = userInteractions.isNotEmpty ? 10.0 : 0.0;

    // Take the 10 most recent interactions to calculate recency
    final recentInteractions = userInteractions.take(10).toList();

    for (int i = 0; i < recentInteractions.length; i++) {
      final interaction = recentInteractions[i];
      final categoryId = interaction['category_id'] as int?;
      if (categoryId != null) {
        // More recent interactions get higher values
        final recencyValue = recencyMax - i;
        recencyFactors[categoryId] = math.max(
            recencyValue / recencyMax, recencyFactors[categoryId] ?? 0);
      }
    }

    return recencyFactors;
  }

  // Get the most recently viewed categories for variety adjustments
  Set<int> _getRecentCategoryIds(List<dynamic> userInteractions) {
    final recentCategories = <int>{};

    // Only consider the 3 most recent interactions for "very recent" status
    for (int i = 0; i < math.min(3, userInteractions.length); i++) {
      final categoryId = userInteractions[i]['category_id'] as int?;
      if (categoryId != null) {
        recentCategories.add(categoryId);
      }
    }

    return recentCategories;
  }

  Future<Map<String, dynamic>?> _getUserLastLocation(
      List<dynamic> userInteractions) async {
    if (userInteractions.isEmpty) return null;

    // Get the most recent view interaction
    final lastInteraction = userInteractions.firstWhere(
      (interaction) => interaction['type'] == 'view',
      orElse: () => <String, dynamic>{},
    );

    if (lastInteraction.isEmpty) return null;

    // Get the destination details for the last viewed location
    try {
      final destinationId = lastInteraction['destination_id'] as int;
      final response = await _supabase
          .from('destination')
          .select('latitude, longitude')
          .eq('id', destinationId)
          .single();

      return response;
    } catch (e) {
      print('Error getting user last location: $e');
      return null;
    }
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

  // Safe parsing for string to double conversion
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<List<Map<String, dynamic>>> _getFallbackRecommendations() async {
    // Fallback to popular destinations if recommendation fails
    final response = await _supabase
        .from('destination')
        .select('*, category:category_id(*)')
        .order('rating', ascending: false)
        .limit(10);

    return response.map((dest) => Map<String, dynamic>.from(dest)).toList();
  }
}
