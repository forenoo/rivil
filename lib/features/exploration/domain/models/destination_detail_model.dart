import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rivil/features/exploration/domain/models/destination_type.dart';

class DestinationDetailModel {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final String? imageUrl;
  final double rating;
  final int ratingCount;
  final double? latitude;
  final double? longitude;
  final String? category;
  final int? categoryId;
  final double? appRatingAverage;
  final int appRatingCount;
  final double? distanceInKm;
  final Set<Marker> mapMarkers;
  final bool isFavorite;
  final DestinationType type;

  DestinationDetailModel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.imageUrl,
    required this.rating,
    required this.ratingCount,
    this.latitude,
    this.longitude,
    this.category,
    this.categoryId,
    this.appRatingAverage = 0.0,
    this.appRatingCount = 0,
    this.distanceInKm,
    this.mapMarkers = const {},
    this.isFavorite = false,
    this.type = DestinationType.added_by_google,
  });

  // Create a model from a Map (typically from Supabase)
  factory DestinationDetailModel.fromMap(
    Map<String, dynamic> map, {
    bool isFavorite = false,
    double? distanceInKm,
    double? appRatingAverage,
    int? appRatingCount,
    Set<Marker>? mapMarkers,
  }) {
    // Safely extract latitude and longitude
    double? lat;
    double? lng;

    final latValue = map['latitude'];
    final lngValue = map['longitude'];

    // Handle different possible data types
    if (latValue is double) {
      lat = latValue;
    } else if (latValue is String) {
      lat = double.tryParse(latValue);
    }

    if (lngValue is double) {
      lng = lngValue;
    } else if (lngValue is String) {
      lng = double.tryParse(lngValue);
    }

    final rawRating = map['rating'];
    final rating = rawRating is double
        ? rawRating
        : (rawRating is int
            ? rawRating.toDouble()
            : (rawRating is String ? double.tryParse(rawRating) ?? 0.0 : 0.0));

    final rawRatingCount = map['rating_count'];
    final ratingCount = rawRatingCount is int
        ? rawRatingCount
        : (rawRatingCount is String ? int.tryParse(rawRatingCount) ?? 0 : 0);

    // Determine destination type
    DestinationType destinationType = DestinationType.added_by_google;
    if (map['type'] != null) {
      if (map['type'] == 'added_by_user') {
        destinationType = DestinationType.added_by_user;
      }
    }

    return DestinationDetailModel(
      id: map['id'] as int,
      name: map['name'] as String? ?? 'Unnamed Destination',
      description: map['description'] as String?,
      address: map['address'] as String?,
      imageUrl: map['image_url'] as String? ?? map['imageUrl'] as String?,
      rating: rating,
      ratingCount: ratingCount,
      latitude: lat,
      longitude: lng,
      category: map['category'] as String?,
      categoryId: map['category_id'] as int?,
      appRatingAverage: appRatingAverage ?? 0.0,
      appRatingCount: appRatingCount ?? 0,
      distanceInKm: distanceInKm,
      mapMarkers: mapMarkers ?? {},
      isFavorite: isFavorite,
      type: destinationType,
    );
  }

  // Convert model to Map (useful for serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'image_url': imageUrl,
      'rating': rating,
      'rating_count': ratingCount,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'category_id': categoryId,
      'type': type == DestinationType.added_by_user
          ? 'added_by_user'
          : 'added_by_google',
    };
  }

  // Create a copy of the model with updated values
  DestinationDetailModel copyWith({
    int? id,
    String? name,
    String? description,
    String? address,
    String? imageUrl,
    double? rating,
    int? ratingCount,
    double? latitude,
    double? longitude,
    String? category,
    int? categoryId,
    double? appRatingAverage,
    int? appRatingCount,
    double? distanceInKm,
    Set<Marker>? mapMarkers,
    bool? isFavorite,
    DestinationType? type,
  }) {
    return DestinationDetailModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      appRatingAverage: appRatingAverage ?? this.appRatingAverage,
      appRatingCount: appRatingCount ?? this.appRatingCount,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      mapMarkers: mapMarkers ?? this.mapMarkers,
      isFavorite: isFavorite ?? this.isFavorite,
      type: type ?? this.type,
    );
  }
}
