abstract class DestinationAddRepository {
  Future<bool> addDestination({
    required String name,
    required int categoryId,
    required String description,
    required String address,
    required String latitude,
    required String longitude,
    required double rating,
    String? imageUrl,
  });

  Future<List<Map<String, dynamic>>> getCategories();
}
