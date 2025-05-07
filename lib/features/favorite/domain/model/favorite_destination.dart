class FavoriteDestination {
  final String name;
  final String location;
  final double rating;
  final String imageUrl;
  final String category;
  final double price;
  final List<String> facilities;
  final double distance;
  final bool isFavorite;

  FavoriteDestination({
    required this.name,
    required this.location,
    required this.rating,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.facilities,
    required this.distance,
    this.isFavorite = true,
  });

  factory FavoriteDestination.fromMap(Map<String, dynamic> map) {
    return FavoriteDestination(
      name: map['name'] as String,
      location: map['location'] as String,
      rating: (map['rating'] is int)
          ? (map['rating'] as int).toDouble()
          : map['rating'] as double,
      imageUrl: map['imageUrl'] as String,
      category: map['category'] as String,
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : map['price'] as double,
      facilities: List<String>.from(map['facilities'] as List),
      distance: (map['distance'] is int)
          ? (map['distance'] as int).toDouble()
          : map['distance'] as double,
      isFavorite: map['isFavorite'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'rating': rating,
      'imageUrl': imageUrl,
      'category': category,
      'price': price,
      'facilities': facilities,
      'distance': distance,
      'isFavorite': isFavorite,
    };
  }
}
