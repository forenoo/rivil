import 'package:rivil/features/add_destination/domain/repository/destination_add_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class DestinationAddRepositoryImpl implements DestinationAddRepository {
  final SupabaseClient _supabase;

  DestinationAddRepositoryImpl(this._supabase);

  @override
  Future<bool> addDestination({
    required String name,
    required int categoryId,
    required String description,
    required String address,
    required String latitude,
    required String longitude,
    required double rating,
    String? imageUrl,
  }) async {
    try {
      // Get the current user ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User is not authenticated');
      }

      // If there's a local image path, upload it to Supabase Storage
      String? finalImageUrl = imageUrl;
      if (imageUrl != null && imageUrl.startsWith('/')) {
        final file = File(imageUrl);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageUrl)}';
        await _supabase.storage
            .from('images')
            .upload('destination/$fileName', file);

        finalImageUrl = _supabase.storage
            .from('images')
            .getPublicUrl('destination/$fileName');
      }

      // Insert the destination data into Supabase
      await _supabase.from('destination').insert({
        'name': name,
        'category_id': categoryId,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'rating_count': 0, // Initial rating count
        'image_url': finalImageUrl,
        'added_by': userId,
        'type': 'added_by_user', // Set type to added_by_user
      });

      return true;
    } catch (e) {
      throw Exception('Failed to add destination: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _supabase
          .from('category')
          .select('id, name, created_at')
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }
}
