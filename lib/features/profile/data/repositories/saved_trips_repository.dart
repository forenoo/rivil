import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rivil/features/profile/data/models/saved_trip.dart';

class SavedTripsRepository {
  final SupabaseClient _supabaseClient;

  SavedTripsRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<List<SavedTrip>> getSavedTrips() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch trips
      final tripsResponse = await _supabaseClient
          .from('trips')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (tripsResponse.isEmpty) {
        return [];
      }

      // Fetch all related data in parallel
      final futures = await Future.wait([
        _supabaseClient.from('trip_preferences').select(),
        _supabaseClient.from('trip_days').select().order('day_order'),
        _supabaseClient
            .from('trip_activities')
            .select()
            .order('activity_order'),
        _supabaseClient.from('trip_highlights').select(),
        _supabaseClient.from('trip_recommendations').select(),
      ]);

      final List<Map<String, dynamic>> preferencesData =
          List<Map<String, dynamic>>.from(futures[0]);
      final List<Map<String, dynamic>> daysData =
          List<Map<String, dynamic>>.from(futures[1]);
      final List<Map<String, dynamic>> activitiesData =
          List<Map<String, dynamic>>.from(futures[2]);
      final List<Map<String, dynamic>> highlightsData =
          List<Map<String, dynamic>>.from(futures[3]);
      final List<Map<String, dynamic>> recommendationsData =
          List<Map<String, dynamic>>.from(futures[4]);

      // Convert to SavedTrip objects
      final List<SavedTrip> savedTrips = [];
      for (final tripData in tripsResponse) {
        final savedTrip = await SavedTrip.fromDatabase(
          tripData: tripData,
          preferencesData: preferencesData,
          daysData: daysData,
          activitiesData: activitiesData,
          highlightsData: highlightsData,
          recommendationsData: recommendationsData,
        );
        savedTrips.add(savedTrip);
      }

      return savedTrips;
    } catch (e) {
      throw Exception('Failed to fetch saved trips: $e');
    }
  }

  Future<SavedTrip> getSavedTripById(int tripId) async {
    try {
      // Fetch the specific trip
      final tripResponse = await _supabaseClient
          .from('trips')
          .select()
          .eq('id', tripId)
          .single();

      // Fetch all related data in parallel
      final futures = await Future.wait([
        _supabaseClient.from('trip_preferences').select().eq('trip_id', tripId),
        _supabaseClient
            .from('trip_days')
            .select()
            .eq('trip_id', tripId)
            .order('day_order'),
        _supabaseClient
            .from('trip_activities')
            .select()
            .order('activity_order'),
        _supabaseClient.from('trip_highlights').select().eq('trip_id', tripId),
        _supabaseClient
            .from('trip_recommendations')
            .select()
            .eq('trip_id', tripId),
      ]);

      final List<Map<String, dynamic>> preferencesData =
          List<Map<String, dynamic>>.from(futures[0]);
      final List<Map<String, dynamic>> daysData =
          List<Map<String, dynamic>>.from(futures[1]);
      final List<Map<String, dynamic>> activitiesData =
          List<Map<String, dynamic>>.from(futures[2]);
      final List<Map<String, dynamic>> highlightsData =
          List<Map<String, dynamic>>.from(futures[3]);
      final List<Map<String, dynamic>> recommendationsData =
          List<Map<String, dynamic>>.from(futures[4]);

      // Convert to SavedTrip object
      return await SavedTrip.fromDatabase(
        tripData: tripResponse,
        preferencesData: preferencesData,
        daysData: daysData,
        activitiesData: activitiesData,
        highlightsData: highlightsData,
        recommendationsData: recommendationsData,
      );
    } catch (e) {
      throw Exception('Failed to fetch saved trip: $e');
    }
  }

  Future<void> deleteSavedTrip(int tripId) async {
    try {
      // Delete the trip (cascade will handle related records)
      await _supabaseClient.from('trips').delete().eq('id', tripId);
    } catch (e) {
      throw Exception('Failed to delete saved trip: $e');
    }
  }
}
