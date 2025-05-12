import 'package:rivil/features/home/domain/repository/destination_repository.dart';
import 'package:rivil/core/services/recommendation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DestinationRepositoryImpl implements DestinationRepository {
  final SupabaseClient _supabase;
  final RecommendationService _recommendationService;

  DestinationRepositoryImpl(this._supabase)
      : _recommendationService = RecommendationService(_supabase);

  @override
  Future<List<Map<String, dynamic>>> getDestinations() async {
    try {
      final response = await _supabase
          .from('destination')
          .select()
          .order('created_at', ascending: false);

      return _transformDestinations(response);
    } catch (e) {
      throw Exception('Failed to fetch destinations: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPopularDestinations() async {
    try {
      final response = await _supabase
          .from('destination')
          .select()
          .order('rating', ascending: false)
          .limit(5);

      return _transformDestinations(response);
    } catch (e) {
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
      return await _recommendationService.getPersonalizedRecommendations(
        userId: currentUser.id,
        limit: 10,
      );
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

    return _transformDestinations(response);
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

      final destinationsWithDistance = allDestinations.map((destination) {
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

      // Add placeholder distance
      return destinations.map((destination) {
        destination['distance'] =
            ((2 + destinations.indexOf(destination)) * 1.5).toStringAsFixed(1);
        return destination;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch fallback nearby destinations: $e');
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
      };
    }).toList();
  }
}
