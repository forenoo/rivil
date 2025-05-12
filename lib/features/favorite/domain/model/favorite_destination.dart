class FavoriteDestination {
  final int id;
  final int destinationId;
  final String name;
  final String imageUrl;
  final String location;
  final String category;
  final double rating;
  final double distance;

  FavoriteDestination({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.imageUrl,
    required this.location,
    required this.category,
    required this.rating,
    this.distance = 0.0,
  });

  factory FavoriteDestination.fromMap(Map<String, dynamic> map) {
    return FavoriteDestination(
      id: map['id'],
      destinationId: map['destination_id'],
      name: map['name'] ?? '',
      imageUrl: map['image_url'] ?? '',
      location: map['address'] ?? '',
      category: map['category_name'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
      distance: map['distance']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destination_id': destinationId,
      'name': name,
      'image_url': imageUrl,
      'address': location,
      'category_name': category,
      'rating': rating,
      'distance': distance,
    };
  }
}
