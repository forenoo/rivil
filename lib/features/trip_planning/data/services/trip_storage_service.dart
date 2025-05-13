import 'package:flutter/material.dart';
import 'package:rivil/features/trip_planning/domain/models/trip_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripStorageService {
  final SupabaseClient _supabase;

  TripStorageService(this._supabase);

  Future<int> saveTripPlan(TripPlan tripPlan) async {
    try {
      // Get current user ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 1. Insert trip and get the ID
      final tripResponse = await _supabase
          .from('trips')
          .insert({
            'user_id': userId,
            'title': tripPlan.title,
            'start_date': tripPlan.startDate?.toIso8601String(),
            'end_date': tripPlan.endDate?.toIso8601String(),
            'number_of_days': tripPlan.numberOfDays,
            'number_of_people': tripPlan.numberOfPeople,
            'budget': tripPlan.budget,
            'summary': tripPlan.summary,
          })
          .select('id')
          .single();

      final tripId = tripResponse['id'] as int;

      // 2. Insert preferences
      for (final preference in tripPlan.preferences) {
        await _supabase.from('trip_preferences').insert({
          'trip_id': tripId,
          'preference': preference,
        });
      }

      // 3. Insert days and activities
      for (int i = 0; i < tripPlan.days.length; i++) {
        final day = tripPlan.days[i];

        // Insert day
        final dayResponse = await _supabase
            .from('trip_days')
            .insert({
              'trip_id': tripId,
              'day_title': day.day,
              'day_date': day.date?.toIso8601String(),
              'day_order': i + 1,
            })
            .select('id')
            .single();

        final dayId = dayResponse['id'] as int;

        // Insert activities for this day
        for (int j = 0; j < day.activities.length; j++) {
          final activity = day.activities[j];
          await _supabase.from('trip_activities').insert({
            'trip_day_id': dayId,
            'time': activity.time,
            'title': activity.title,
            'description': activity.description,
            'location': activity.location,
            'activity_order': j + 1,
          });
        }
      }

      // 4. Insert highlights
      for (final highlight in tripPlan.highlights) {
        await _supabase.from('trip_highlights').insert({
          'trip_id': tripId,
          'name': highlight.name,
          'description': highlight.description,
          'rating': highlight.rating,
          'image_url': highlight.imageUrl,
        });
      }

      // 5. Insert recommendations
      for (final recommendation in tripPlan.recommendations) {
        String iconType = 'lightbulb_outline'; // Default

        // Map Flutter icon to string representation
        if (recommendation.icon == Icons.beach_access) {
          iconType = 'beach_access';
        } else if (recommendation.icon == Icons.restaurant) {
          iconType = 'restaurant';
        } else if (recommendation.icon == Icons.hiking) {
          iconType = 'hiking';
        } else if (recommendation.icon == Icons.attach_money_outlined) {
          iconType = 'attach_money';
        } else if (recommendation.icon == Icons.language) {
          iconType = 'language';
        } else if (recommendation.icon == Icons.camera_alt) {
          iconType = 'camera';
        } else if (recommendation.icon == Icons.local_taxi) {
          iconType = 'local_taxi';
        }

        await _supabase.from('trip_recommendations').insert({
          'trip_id': tripId,
          'title': recommendation.title,
          'description': recommendation.description,
          'icon_type': iconType,
        });
      }

      return tripId;
    } catch (e) {
      throw Exception('Failed to save trip plan: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserTrips() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('trips')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to get user trips: $e');
    }
  }

  Future<Map<String, dynamic>> getTripDetails(int tripId) async {
    try {
      // Get trip basic information
      final tripResponse =
          await _supabase.from('trips').select().eq('id', tripId).single();

      // Get preferences
      final preferencesResponse = await _supabase
          .from('trip_preferences')
          .select('preference')
          .eq('trip_id', tripId);

      final preferences = preferencesResponse
          .map((pref) => pref['preference'] as String)
          .toList();

      // Get days with activities
      final daysResponse = await _supabase
          .from('trip_days')
          .select()
          .eq('trip_id', tripId)
          .order('day_order');

      final days = [];
      for (final dayData in daysResponse) {
        final dayId = dayData['id'] as int;

        // Get activities for this day
        final activitiesResponse = await _supabase
            .from('trip_activities')
            .select()
            .eq('trip_day_id', dayId)
            .order('activity_order');

        // Add day with its activities
        days.add({
          ...dayData,
          'activities': activitiesResponse,
        });
      }

      // Get highlights
      final highlightsResponse = await _supabase
          .from('trip_highlights')
          .select()
          .eq('trip_id', tripId);

      // Get recommendations
      final recommendationsResponse = await _supabase
          .from('trip_recommendations')
          .select()
          .eq('trip_id', tripId);

      // Combine all data
      return {
        ...tripResponse,
        'preferences': preferences,
        'days': days,
        'highlights': highlightsResponse,
        'recommendations': recommendationsResponse,
      };
    } catch (e) {
      throw Exception('Failed to get trip details: $e');
    }
  }

  Future<void> deleteTripPlan(int tripId) async {
    try {
      // Due to cascade delete constraints, we only need to delete the trip
      await _supabase.from('trips').delete().eq('id', tripId);
    } catch (e) {
      throw Exception('Failed to delete trip plan: $e');
    }
  }
}
