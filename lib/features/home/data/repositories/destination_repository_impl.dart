import 'package:rivil/features/home/domain/repository/destination_repository.dart';
import 'package:rivil/core/services/recommendation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DestinationRepositoryImpl implements DestinationRepository {
  final SupabaseClient _supabase;
  final RecommendationService _recommendationService;

  // Add caching for destinations
  final Map<String, List<Map<String, dynamic>>> _destinationsCache = {};
  final Map<int, Map<String, dynamic>> _appRatingsCache = {};
  final Duration _cacheDuration = const Duration(minutes: 15);
  DateTime? _lastFetchTime;

  DestinationRepositoryImpl(this._supabase)
      : _recommendationService = RecommendationService(_supabase);

  bool get _isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < _cacheDuration;

  @override
  Future<List<Map<String, dynamic>>> getDestinations() async {
    // Check if we have a valid cache
    if (_isCacheValid && _destinationsCache.containsKey('all')) {
      return _destinationsCache['all']!;
    }

    try {
      final response = await _supabase
          .from('destination')
          .select()
          .order('created_at', ascending: false);

      final destinations = _transformDestinations(response);
      final destinationsWithRatings = await _addAppRatings(destinations);

      // Cache the result
      _destinationsCache['all'] = destinationsWithRatings;
      _lastFetchTime = DateTime.now();

      return destinationsWithRatings;
    } catch (e) {
      // Return cached data even if expired in case of error
      if (_destinationsCache.containsKey('all')) {
        return _destinationsCache['all']!;
      }
      throw Exception('Failed to fetch destinations: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPopularDestinations() async {
    // Check if we have a valid cache
    if (_isCacheValid && _destinationsCache.containsKey('popular')) {
      return _destinationsCache['popular']!;
    }

    try {
      final response = await _supabase
          .from('destination')
          .select()
          .order('rating', ascending: false)
          .limit(5);

      final destinations = _transformDestinations(response);
      final destinationsWithRatings = await _addAppRatings(destinations);

      // Cache the result
      _destinationsCache['popular'] = destinationsWithRatings;

      return destinationsWithRatings;
    } catch (e) {
      // Return cached data even if expired in case of error
      if (_destinationsCache.containsKey('popular')) {
        return _destinationsCache['popular']!;
      }
      throw Exception('Failed to fetch popular destinations: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecommendedDestinations() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        // If user is not logged in, return popular destinations
        return _getFallbackRecommendations();
      }

      // Get personalized recommendations for the current user
      final recommendations =
          await _recommendationService.getPersonalizedRecommendations(
        userId: currentUser.id,
        limit: 10,
      );

      return await _addAppRatings(recommendations);
    } catch (e) {
      print('Error getting recommended destinations: $e');
      return _getFallbackRecommendations();
    }
  }

  Future<List<Map<String, dynamic>>> _getFallbackRecommendations() async {
    // Fallback to popular destinations if recommendation fails
    final response = await _supabase
        .from('destination')
        .select()
        .order('rating', ascending: false)
        .limit(10);

    final destinations = _transformDestinations(response);
    return await _addAppRatings(destinations);
  }

  @override
  Future<List<Map<String, dynamic>>> getNearbyDestinations(
      {double? latitude,
      double? longitude,
      double maxDistanceKm = 50,
      int limit = 3}) async {
    try {
      // If we don't have location data, return a fallback list
      if (latitude == null || longitude == null) {
        return _getFallbackNearbyDestinations();
      }

      // Fetch all destinations
      final response = await _supabase.from('destination').select();
      final allDestinations = _transformDestinations(response);
      final destinationsWithAppRatings = await _addAppRatings(allDestinations);

      final destinationsWithDistance =
          destinationsWithAppRatings.map((destination) {
        final destLat =
            double.tryParse(destination['latitude'] as String? ?? '0') ?? 0.0;
        final destLon =
            double.tryParse(destination['longitude'] as String? ?? '0') ?? 0.0;

        final distance = _calculateDistance(
          latitude,
          longitude,
          destLat,
          destLon,
        );

        destination['distance'] = distance.toStringAsFixed(1);
        return destination;
      }).toList();

      final nearbyDestinations = destinationsWithDistance.where((destination) {
        final distance = double.tryParse(destination['distance'] as String) ??
            double.infinity;
        return distance <= maxDistanceKm;
      }).toList();

      // Sort by distance (closest first)
      nearbyDestinations.sort((a, b) {
        final distanceA =
            double.tryParse(a['distance'] as String) ?? double.infinity;
        final distanceB =
            double.tryParse(b['distance'] as String) ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });

      // Limit results
      return nearbyDestinations.take(limit).toList();
    } catch (e) {
      print('Error fetching nearby destinations: $e');
      return _getFallbackNearbyDestinations();
    }
  }

  // Add Haversine formula distance calculation function
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  // Helper method to get full destination details by ID
  // Future<Map<String, dynamic>?> _getDestinationById(int id) async {
  //   try {
  //     final response =
  //         await _supabase.from('destination').select().eq('id', id).single();

  //     final transformed = _transformDestinations([response]);
  //     return transformed.isNotEmpty ? transformed.first : null;
  //   } catch (e) {
  //     print('Error fetching destination by ID: $e');
  //     return null;
  //   }
  // }

  // Fallback method for when location data is unavailable
  Future<List<Map<String, dynamic>>> _getFallbackNearbyDestinations() async {
    try {
      final response = await _supabase
          .from('destination')
          .select()
          .order('rating', ascending: false)
          .limit(5);

      final destinations = _transformDestinations(response);
      final destinationsWithAppRatings = await _addAppRatings(destinations);

      // Add placeholder distance
      return destinationsWithAppRatings.map((destination) {
        destination['distance'] =
            ((2 + destinationsWithAppRatings.indexOf(destination)) * 1.5)
                .toStringAsFixed(1);
        return destination;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch fallback nearby destinations: $e');
    }
  }

  // Method to get app ratings for destinations
  Future<List<Map<String, dynamic>>> _addAppRatings(
      List<Map<String, dynamic>> destinations) async {
    try {
      // Filter out destinations that already have ratings in cache
      final destinationsToProcess = destinations.where((destination) {
        final id = destination['id'] as int;
        return !_appRatingsCache.containsKey(id);
      }).toList();

      // If there are destinations that need ratings
      if (destinationsToProcess.isNotEmpty) {
        // Get all needed destination ids
        final ids = destinationsToProcess.map((d) => d['id'] as int).toList();

        // Fetch ratings for all destinations in a single query
        final response = await _supabase
            .from('destination_rating')
            .select('destination_id, rating')
            .filter('destination_id', 'in', '(${ids.join(",")})');

        // Group ratings by destination
        final Map<int, List<Map<String, dynamic>>> ratingsByDestination = {};
        for (var rating in response) {
          final destId = rating['destination_id'] as int;
          ratingsByDestination[destId] ??= [];
          ratingsByDestination[destId]!.add(rating);
        }

        // Process ratings for each destination
        for (var destination in destinationsToProcess) {
          final destinationId = destination['id'] as int;
          final ratings = ratingsByDestination[destinationId] ?? [];

          final ratingSum = ratings.fold<int>(
              0, (sum, rating) => sum + (rating['rating'] as int? ?? 0));

          final appRatingAverage =
              ratings.isEmpty ? 0.0 : ratingSum / ratings.length;

          // Update the destination
          destination['app_rating_average'] = appRatingAverage;
          destination['app_rating_count'] = ratings.length;

          // Cache the rating info
          _appRatingsCache[destinationId] = {
            'app_rating_average': appRatingAverage,
            'app_rating_count': ratings.length,
          };
        }
      }

      // Apply cached ratings to all destinations
      for (var destination in destinations) {
        final id = destination['id'] as int;
        if (_appRatingsCache.containsKey(id)) {
          destination['app_rating_average'] =
              _appRatingsCache[id]!['app_rating_average'];
          destination['app_rating_count'] =
              _appRatingsCache[id]!['app_rating_count'];
        } else {
          destination['app_rating_average'] = 0.0;
          destination['app_rating_count'] = 0;
        }
      }

      return destinations;
    } catch (e) {
      print('Error adding app ratings: $e');
      return destinations; // Return original list if adding ratings fails
    }
  }

  List<Map<String, dynamic>> _transformDestinations(List<dynamic> response) {
    return response.map((data) {
      return {
        'id': data['id'] as int,
        'category_id': data['category_id'] as int?,
        'url': data['url'] as String?,
        'name': data['name'] as String?,
        'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
        'rating_count': (data['rating_count'] as num?)?.toInt() ?? 0,
        'address': data['address'] as String?,
        'description': data['description'] as String?,
        'created_at': data['created_at'] as String,
        'latitude': data['latitude'] as String?,
        'longitude': data['longitude'] as String?,
        'image_url': data['image_url'] as String?,
        'added_by': data['added_by'] as String?,
        'type': data['type'] as String? ?? 'added_by_google',
      };
    }).toList();
  }
}
