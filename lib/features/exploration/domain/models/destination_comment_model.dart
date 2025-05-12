class DestinationCommentModel {
  final int id;
  final String userId;
  final int destinationId;
  final String comment;
  final DateTime createdAt;
  final String authorName;
  final String? authorAvatarUrl;

  DestinationCommentModel({
    required this.id,
    required this.userId,
    required this.destinationId,
    required this.comment,
    required this.createdAt,
    required this.authorName,
    this.authorAvatarUrl,
  });

  factory DestinationCommentModel.fromMap(Map<String, dynamic> map) {
    // Extract user data from the nested structure
    final userData = map['user_data'];
    Map<String, dynamic>? profileData;

    if (userData != null && userData is Map<String, dynamic>) {
      profileData = userData['profile_data'] as Map<String, dynamic>?;
    }

    final userName = profileData?['name'] as String? ?? 'Anonymous';
    final photoUrl = profileData?['avatar_url'] as String? ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}';

    return DestinationCommentModel(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      destinationId: map['destination_id'] as int,
      comment: map['comment'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      authorName: userName,
      authorAvatarUrl: photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'destination_id': destinationId,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper method to format the date
  String formattedDate() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }
}
