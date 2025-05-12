import 'package:geolocator/geolocator.dart';
import 'package:rivil/core/services/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DestinationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocationService _locationService = LocationService();

  // Get full destination details by ID
  Future<Map<String, dynamic>> getDestinationById(int destinationId) async {
    try {
      final response = await _supabase
          .from('destination')
          .select()
          .eq('id', destinationId)
          .single();

      // Ensure rating_count exists, initialize with default values if missing
      if (response['rating_count'] == null) {
        response['rating_count'] = 0;
      }

      if (response['rating'] == null) {
        response['rating'] = 0.0;
      }

      return response;
    } catch (e) {
      print('Error fetching destination: $e');
      throw Exception('Failed to fetch destination details');
    }
  }

  // Check if a destination is favorited by the current user
  Future<bool> isDestinationFavorited(int destinationId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('favorite_destination')
          .select()
          .eq('user_id', currentUser.id)
          .eq('destination_id', destinationId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(int destinationId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final isFavorited = await isDestinationFavorited(destinationId);

      if (isFavorited) {
        // Remove from favorites
        await _supabase
            .from('favorite_destination')
            .delete()
            .eq('user_id', currentUser.id)
            .eq('destination_id', destinationId);
        return false;
      } else {
        // Add to favorites
        await _supabase.from('favorite_destination').insert({
          'user_id': currentUser.id,
          'destination_id': destinationId,
        });
        return true;
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      throw Exception('Failed to update favorite status');
    }
  }

  // Track destination view
  Future<void> trackDestinationView(int destinationId, int categoryId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase.from('user_destination_interaction').insert({
        'user_id': currentUser.id,
        'destination_id': destinationId,
        'type': 'view',
        'category_id': categoryId,
      });
    } catch (e) {
      print('Error tracking destination view: $e');
    }
  }

  // Load comments with pagination
  Future<List<Map<String, dynamic>>> loadComments({
    required int destinationId,
    required int page,
    required int commentsPerPage,
  }) async {
    try {
      final offset = (page - 1) * commentsPerPage;

      final response = await _supabase
          .from('destination_comment')
          .select()
          .eq('destination_id', destinationId)
          .order('created_at', ascending: false)
          .range(offset, offset + commentsPerPage - 1);

      final commentsData = List<Map<String, dynamic>>.from(response);

      // Fetch user data for each comment
      final commentsWithUsers =
          await Future.wait(commentsData.map((comment) async {
        try {
          final userId = comment['user_id'] as String?;
          if (userId == null) {
            return {...comment, 'user_data': null};
          }

          Map<String, dynamic>? userData;
          try {
            final profileData = await _supabase
                .from('user_profile')
                .select()
                .eq('user_id', userId)
                .single();

            userData = {
              'profile_data': {
                'name': profileData['full_name'] ??
                    profileData['username'] ??
                    'Anonymous',
                'avatar_url': profileData['avatar_url']
              }
            };
          } catch (e) {
            print('Error fetching profile data: $e');
            userData = {
              'profile_data': {'name': 'Anonymous', 'avatar_url': null}
            };
          }

          return {...comment, 'user_data': userData};
        } catch (e) {
          print('Error fetching user data: $e');
          return {...comment, 'user_data': null};
        }
      }));

      return commentsWithUsers;
    } catch (e) {
      print('Error loading comments: $e');
      return [];
    }
  }

  // Submit a comment
  Future<void> submitComment({
    required int destinationId,
    required String comment,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase.from('destination_comment').insert({
        'user_id': currentUser.id,
        'destination_id': destinationId,
        'comment': comment.trim(),
      });
    } catch (e) {
      print('Error submitting comment: $e');
      throw Exception('Failed to submit comment');
    }
  }

  // Calculate distance to destination
  Future<double?> calculateDistance({
    required double? destinationLat,
    required double? destinationLng,
  }) async {
    try {
      if (destinationLat == null || destinationLng == null) {
        return null;
      }

      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) return null;

      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final position = await _locationService.getCurrentPosition();
      if (position == null) return null;

      final distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        destinationLat,
        destinationLng,
      );

      return distanceInMeters / 1000; // Convert to kilometers
    } catch (e) {
      print('Error calculating distance: $e');
      return null;
    }
  }

  // Load user rating
  Future<Map<String, dynamic>?> loadUserRating(int destinationId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase
          .from('destination_rating')
          .select()
          .eq('user_id', currentUser.id)
          .eq('destination_id', destinationId)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }

      return null;
    } catch (e) {
      print('Error loading user rating: $e');
      return null;
    }
  }

  // Load app rating (average and count)
  Future<Map<String, dynamic>> loadAppRating(int destinationId) async {
    try {
      final response = await _supabase
          .from('destination_rating')
          .select('rating')
          .eq('destination_id', destinationId);

      if (response.isNotEmpty) {
        final ratings = List<Map<String, dynamic>>.from(response);
        final ratingSum = ratings.fold<int>(
            0, (sum, rating) => sum + (rating['rating'] as int? ?? 0));

        return {
          'count': ratings.length,
          'average': ratings.isEmpty ? 0.0 : ratingSum / ratings.length,
        };
      }

      return {'count': 0, 'average': 0.0};
    } catch (e) {
      print('Error loading app rating: $e');
      return {'count': 0, 'average': 0.0};
    }
  }

  // Submit or update rating
  Future<void> submitRating({
    required int destinationId,
    required int rating,
    int? ratingId,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      if (ratingId != null) {
        // Update existing rating
        await _supabase
            .from('destination_rating')
            .update({'rating': rating}).eq('id', ratingId);
      } else {
        // Insert new rating
        await _supabase.from('destination_rating').insert({
          'user_id': currentUser.id,
          'destination_id': destinationId,
          'rating': rating,
        });
      }
    } catch (e) {
      print('Error submitting rating: $e');
      throw Exception('Failed to submit rating');
    }
  }

  // Delete rating
  Future<void> deleteRating(int ratingId) async {
    try {
      await _supabase.from('destination_rating').delete().eq('id', ratingId);
    } catch (e) {
      print('Error deleting rating: $e');
      throw Exception('Failed to delete rating');
    }
  }
}
