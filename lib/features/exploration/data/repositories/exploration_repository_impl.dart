import 'package:rivil/features/exploration/domain/repositories/exploration_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ExplorationRepositoryImpl implements ExplorationRepository {
  final SupabaseClient _supabase;

  ExplorationRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getAllDestinations(
      {int page = 1, int pageSize = 10}) async {
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      final response = await _supabase
          .from('destination')
          .select('*, category:category_id(name)')
          .order('created_at', ascending: false)
          .range(from, to);

      final destinations = _transformDestinations(response);
      return await _addAppRatings(destinations);
    } catch (e) {
      throw Exception('Failed to fetch destinations: $e');
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('category')
          .select('name')
          .order('name', ascending: true);

      return response
          .map<String>((category) => category['name'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchDestinations(String query,
      {int page = 1, int pageSize = 10}) async {
    try {
      final lowercaseQuery = query.toLowerCase();
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      final response = await _supabase
          .from('destination')
          .select('*, category:category_id(name)')
          .or('name.ilike.%$lowercaseQuery%,address.ilike.%$lowercaseQuery%')
          .range(from, to);

      final destinations = _transformDestinations(response);
      return await _addAppRatings(destinations);
    } catch (e) {
      throw Exception('Failed to search destinations: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> filterDestinations({
    String? category,
    double? minRating,
    double? latitude,
    double? longitude,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      var query =
          _supabase.from('destination').select('*, category:category_id(name)');

      // Apply category filter if provided
      if (category != null) {
        // First get the category id
        final categoryResponse = await _supabase
            .from('category')
            .select('id')
            .eq('name', category)
            .single();

        final categoryId = categoryResponse['id'] as int;
        query = query.eq('category_id', categoryId);
      }

      // Apply rating filter if provided
      if (minRating != null && minRating > 0) {
        query = query.gte('rating', minRating);
      }

      // Apply pagination and ordering
      final response =
          await query.order('rating', ascending: false).range(from, to);
      final destinations = _transformDestinations(response);
      final destinationsWithAppRatings = await _addAppRatings(destinations);

      // Apply distance calculation if coordinates are provided
      if (latitude != null && longitude != null) {
        return destinationsWithAppRatings.map((destination) {
          final destLatStr = destination['latitude'] as String?;
          final destLonStr = destination['longitude'] as String?;

          final destLat = destLatStr != null && destLatStr.isNotEmpty
              ? double.tryParse(destLatStr) ?? 0.0
              : 0.0;
          final destLon = destLonStr != null && destLonStr.isNotEmpty
              ? double.tryParse(destLonStr) ?? 0.0
              : 0.0;

          final distance = _calculateDistance(
            latitude,
            longitude,
            destLat,
            destLon,
          );

          destination['distance'] = distance;
          return destination;
        }).toList();
      }

      // Add placeholder distance if no coordinates
      return destinationsWithAppRatings.map((destination) {
        destination['distance'] = 0.0;
        return destination;
      }).toList();
    } catch (e) {
      throw Exception('Failed to filter destinations: $e');
    }
  }

  // Calculate distance between two coordinates using Geolocator
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  // Method to get app ratings for destinations
  Future<List<Map<String, dynamic>>> _addAppRatings(
      List<Map<String, dynamic>> destinations) async {
    try {
      // For each destination, fetch app ratings
      for (var destination in destinations) {
        final destinationId = destination['id'] as int;

        try {
          final response = await _supabase
              .from('destination_rating')
              .select('rating')
              .eq('destination_id', destinationId);

          if (response.isNotEmpty) {
            final ratings = List<Map<String, dynamic>>.from(response);
            final ratingSum = ratings.fold<int>(
                0, (sum, rating) => sum + (rating['rating'] as int? ?? 0));

            destination['app_rating_average'] =
                ratings.isEmpty ? 0.0 : ratingSum / ratings.length;
            destination['app_rating_count'] = ratings.length;
          } else {
            destination['app_rating_average'] = 0.0;
            destination['app_rating_count'] = 0;
          }
        } catch (e) {
          print('Error loading app rating for destination $destinationId: $e');
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

  // Transform the Supabase response to the expected format
  List<Map<String, dynamic>> _transformDestinations(List<dynamic> response) {
    return response.map((data) {
      final categoryData = data['category'] as Map<String, dynamic>?;

      return {
        'id': data['id'] as int,
        'name': data['name'] as String? ?? 'Unknown',
        'address': data['address'] as String? ?? 'Unknown location',
        'description': data['description'] as String? ?? '',
        'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
        'rating_count': (data['rating_count'] as num?)?.toInt() ?? 0,
        'image_url':
            data['image_url'] as String? ?? 'assets/images/bromo-image.jpg',
        'latitude': data['latitude'] as String?,
        'longitude': data['longitude'] as String?,
        'category': categoryData?['name'] as String? ?? 'Uncategorized',
        'category_id': data['category_id'] as int?,
        'url': data['url'] as String?,
        'created_at': data['created_at'] as String?,
        'added_by': data['added_by'] as String?,
        'type': data['type'] as String? ?? 'added_by_google',
      };
    }).toList();
  }
}
