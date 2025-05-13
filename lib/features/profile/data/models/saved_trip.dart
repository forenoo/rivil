import 'package:flutter/material.dart';

class SavedTrip {
  final int id;
  final String userId;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final int numberOfDays;
  final String? numberOfPeople;
  final String? budget;
  final String summary;
  final List<String> preferences;
  final List<SavedTripDay> days;
  final List<SavedDestination> highlights;
  final List<SavedRecommendation> recommendations;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedTrip({
    required this.id,
    required this.userId,
    required this.title,
    this.startDate,
    this.endDate,
    required this.numberOfDays,
    this.numberOfPeople,
    this.budget,
    required this.summary,
    required this.preferences,
    required this.days,
    required this.highlights,
    required this.recommendations,
    required this.createdAt,
    required this.updatedAt,
  });

  static Future<SavedTrip> fromDatabase({
    required Map<String, dynamic> tripData,
    required List<Map<String, dynamic>> preferencesData,
    required List<Map<String, dynamic>> daysData,
    required List<Map<String, dynamic>> activitiesData,
    required List<Map<String, dynamic>> highlightsData,
    required List<Map<String, dynamic>> recommendationsData,
  }) async {
    // Process preferences
    final preferences = preferencesData
        .where((pref) => pref['trip_id'] == tripData['id'])
        .map((pref) => pref['preference'] as String)
        .toList();

    // Process days and activities
    final days = <SavedTripDay>[];
    for (final dayData
        in daysData.where((day) => day['trip_id'] == tripData['id'])) {
      final dayActivities = activitiesData
          .where((activity) => activity['trip_day_id'] == dayData['id'])
          .map((activity) => SavedActivity(
                id: activity['id'],
                time: activity['time'],
                title: activity['title'],
                description: activity['description'],
                location: activity['location'],
                activityOrder: activity['activity_order'],
              ))
          .toList()
        ..sort((a, b) => a.activityOrder.compareTo(b.activityOrder));

      days.add(SavedTripDay(
        id: dayData['id'],
        dayTitle: dayData['day_title'],
        dayDate: dayData['day_date'] != null
            ? DateTime.parse(dayData['day_date'])
            : null,
        dayOrder: dayData['day_order'],
        activities: dayActivities,
      ));
    }
    // Sort days by order
    days.sort((a, b) => a.dayOrder.compareTo(b.dayOrder));

    // Process highlights
    final highlights = highlightsData
        .where((highlight) => highlight['trip_id'] == tripData['id'])
        .map((highlight) => SavedDestination(
              id: highlight['id'],
              name: highlight['name'],
              description: highlight['description'],
              rating: (highlight['rating'] as num).toDouble(),
              imageUrl: _getImageUrlForDestination(highlight['name']),
            ))
        .toList();

    // Process recommendations
    final recommendations = recommendationsData
        .where((rec) => rec['trip_id'] == tripData['id'])
        .map((rec) => SavedRecommendation(
              id: rec['id'],
              title: rec['title'],
              description: rec['description'],
              icon: _getIconForType(rec['icon_type']),
            ))
        .toList();

    return SavedTrip(
      id: tripData['id'],
      userId: tripData['user_id'],
      title: tripData['title'],
      startDate: tripData['start_date'] != null
          ? DateTime.parse(tripData['start_date'])
          : null,
      endDate: tripData['end_date'] != null
          ? DateTime.parse(tripData['end_date'])
          : null,
      numberOfDays: tripData['number_of_days'],
      numberOfPeople: tripData['number_of_people'],
      budget: tripData['budget'],
      summary: tripData['summary'],
      preferences: preferences,
      days: days,
      highlights: highlights,
      recommendations: recommendations,
      createdAt: DateTime.parse(tripData['created_at']),
      updatedAt: DateTime.parse(tripData['updated_at']),
    );
  }

  // Helper function to map destination names to appropriate images
  static String _getImageUrlForDestination(String destinationName) {
    // Convert to lowercase for case-insensitive matching
    final nameLower = destinationName.toLowerCase();

    // Map of category keywords to image assets
    final Map<String, String> categoryImageMap = {
      // Beaches
      'pantai': 'assets/images/destinations/pantai.jpg',
      'beach': 'assets/images/destinations/pantai.jpg',
      'laut': 'assets/images/destinations/pantai.jpg',
      'pulau': 'assets/images/destinations/pantai.jpg',

      // Mountains
      'gunung': 'assets/images/destinations/gunung.jpg',
      'mountain': 'assets/images/destinations/gunung.jpg',
      'bukit': 'assets/images/destinations/gunung.jpg',

      // Waterfalls
      'air terjun': 'assets/images/destinations/air_terjun.jpg',
      'waterfall': 'assets/images/destinations/air_terjun.jpg',

      // Cities
      'kota': 'assets/images/destinations/kota.jpg',
      'city': 'assets/images/destinations/kota.jpg',

      // Specific locations
      'bali': 'assets/images/destinations/bali.jpg',
      'bromo': 'assets/images/destinations/bromo.jpg',
      'malang': 'assets/images/destinations/malang.jpg',
    };

    // Check if destination name contains any keywords
    for (final entry in categoryImageMap.entries) {
      if (nameLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default fallback
    return 'assets/images/kotamalangplaceholder.jpg';
  }

  // Helper function to map icon type strings to IconData
  static IconData _getIconForType(String iconType) {
    switch (iconType) {
      case 'beach_access':
        return Icons.beach_access;
      case 'restaurant':
        return Icons.restaurant;
      case 'hiking':
        return Icons.hiking;
      case 'attach_money':
        return Icons.attach_money_outlined;
      case 'language':
        return Icons.language;
      case 'camera':
        return Icons.camera_alt;
      case 'local_taxi':
        return Icons.local_taxi;
      default:
        return Icons.lightbulb_outline;
    }
  }
}

class SavedTripDay {
  final int id;
  final String dayTitle;
  final DateTime? dayDate;
  final int dayOrder;
  final List<SavedActivity> activities;

  SavedTripDay({
    required this.id,
    required this.dayTitle,
    this.dayDate,
    required this.dayOrder,
    required this.activities,
  });
}

class SavedActivity {
  final int id;
  final String time;
  final String title;
  final String description;
  final String location;
  final int activityOrder;

  SavedActivity({
    required this.id,
    required this.time,
    required this.title,
    required this.description,
    required this.location,
    required this.activityOrder,
  });
}

class SavedDestination {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;

  SavedDestination({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
  });
}

class SavedRecommendation {
  final int id;
  final String title;
  final String description;
  final IconData icon;

  SavedRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
