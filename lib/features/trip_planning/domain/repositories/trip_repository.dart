import 'package:rivil/features/trip_planning/domain/models/trip_plan.dart';

abstract class TripRepository {
  Future<int> saveTrip(TripPlan tripPlan);
  Future<List<Map<String, dynamic>>> getUserTrips();
  Future<Map<String, dynamic>> getTripDetails(int tripId);
  Future<void> deleteTrip(int tripId);
}
