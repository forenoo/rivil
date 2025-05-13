import 'package:rivil/features/trip_planning/domain/models/trip_plan.dart';
import 'package:rivil/features/trip_planning/domain/repositories/trip_repository.dart';
import 'package:rivil/features/trip_planning/data/services/trip_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripRepositoryImpl implements TripRepository {
  final SupabaseClient _supabase;
  late TripStorageService _storageService;

  TripRepositoryImpl(this._supabase) {
    _storageService = TripStorageService(_supabase);
  }

  @override
  Future<int> saveTrip(TripPlan tripPlan) async {
    return await _storageService.saveTripPlan(tripPlan);
  }

  @override
  Future<List<Map<String, dynamic>>> getUserTrips() async {
    return await _storageService.getUserTrips();
  }

  @override
  Future<Map<String, dynamic>> getTripDetails(int tripId) async {
    return await _storageService.getTripDetails(tripId);
  }

  @override
  Future<void> deleteTrip(int tripId) async {
    await _storageService.deleteTripPlan(tripId);
  }
}
