import 'package:rivil/features/favorite/domain/model/favorite_destination.dart';
import 'package:rivil/features/favorite/domain/repository/favorite_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rivil/core/services/location_service.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final SupabaseClient _client;
  final LocationService _locationService = LocationService();

  FavoriteRepositoryImpl(this._client);

  @override
  Future<List<FavoriteDestination>> getFavoriteDestinations() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      // Get user's current location
      Position? userPosition;
      try {
        final hasPermission =
            await _locationService.requestLocationPermission();
        if (hasPermission) {
          final serviceEnabled =
              await _locationService.isLocationServiceEnabled();
          if (serviceEnabled) {
            userPosition = await _locationService.getCurrentPosition();
          }
        }
      } catch (e) {
        print('Error getting user location: $e');
      }

      final response = await _client.from('favorite_destination').select('''
            id,
            destination_id,
            destination:destination_id (
              id,
              name, 
              image_url, 
              address, 
              rating,
              latitude,
              longitude,
              category:category_id (
                id, 
                name
              )
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return response.map<FavoriteDestination>((item) {
        final destination = item['destination'] as Map<String, dynamic>;
        final category = destination['category'] as Map<String, dynamic>;

        // Calculate distance if we have user's location and destination coordinates
        double distance = 0.0;
        if (userPosition != null) {
          final destLatStr = destination['latitude'] as String?;
          final destLngStr = destination['longitude'] as String?;

          if (destLatStr != null && destLngStr != null) {
            final destLat = double.tryParse(destLatStr);
            final destLng = double.tryParse(destLngStr);

            if (destLat != null && destLng != null) {
              distance = Geolocator.distanceBetween(
                    userPosition.latitude,
                    userPosition.longitude,
                    destLat,
                    destLng,
                  ) /
                  1000; // Convert to kilometers
            }
          }
        }

        return FavoriteDestination(
          id: item['id'],
          destinationId: item['destination_id'],
          name: destination['name'] ?? '',
          imageUrl: destination['image_url'] ?? '',
          location: destination['address'] ?? '',
          category: category['name'] ?? '',
          rating: destination['rating']?.toDouble() ?? 0.0,
          distance: distance,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get favorites: $e');
    }
  }

  @override
  Future<void> addFavoriteDestination(int destinationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already in favorites
      final existing = await _client
          .from('favorite_destination')
          .select()
          .eq('user_id', userId)
          .eq('destination_id', destinationId)
          .maybeSingle();

      if (existing != null) {
        return; // Already favorited
      }

      await _client.from('favorite_destination').insert({
        'user_id': userId,
        'destination_id': destinationId,
      });
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  @override
  Future<void> removeFavoriteDestination(int destinationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('favorite_destination')
          .delete()
          .eq('user_id', userId)
          .eq('destination_id', destinationId);
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  @override
  Future<bool> isFavorite(int destinationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return false;
      }

      final response = await _client
          .from('favorite_destination')
          .select()
          .eq('user_id', userId)
          .eq('destination_id', destinationId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
