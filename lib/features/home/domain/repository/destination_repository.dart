abstract class DestinationRepository {
  Future<List<Map<String, dynamic>>> getDestinations();
  Future<List<Map<String, dynamic>>> getPopularDestinations();
  Future<List<Map<String, dynamic>>> getRecommendedDestinations();
  Future<List<Map<String, dynamic>>> getNearbyDestinations(
      {double? latitude,
      double? longitude,
      double maxDistanceKm = 50,
      int limit = 10});
}
