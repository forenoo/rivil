class DestinationRatingModel {
  final int? id;
  final String userId;
  final int destinationId;
  final int rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DestinationRatingModel({
    this.id,
    required this.userId,
    required this.destinationId,
    required this.rating,
    this.createdAt,
    this.updatedAt,
  });

  factory DestinationRatingModel.fromMap(Map<String, dynamic> map) {
    return DestinationRatingModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      destinationId: map['destination_id'] as int,
      rating: map['rating'] as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'destination_id': destinationId,
      'rating': rating,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  DestinationRatingModel copyWith({
    int? id,
    String? userId,
    int? destinationId,
    int? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DestinationRatingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destinationId: destinationId ?? this.destinationId,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
