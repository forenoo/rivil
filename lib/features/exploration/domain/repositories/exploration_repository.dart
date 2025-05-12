abstract class ExplorationRepository {
  Future<List<Map<String, dynamic>>> getAllDestinations(
      {int page = 1, int pageSize = 10});
  Future<List<String>> getCategories();
  Future<List<Map<String, dynamic>>> searchDestinations(String query,
      {int page = 1, int pageSize = 10});
  Future<List<Map<String, dynamic>>> filterDestinations({
    String? category,
    double? minRating,
    double? latitude,
    double? longitude,
    int page = 1,
    int pageSize = 10,
  });
}
