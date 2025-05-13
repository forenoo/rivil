import 'package:flutter/material.dart';

class TripPlan {
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final int numberOfDays;
  final String? numberOfPeople;
  final String? budget;
  final List<String> preferences;
  final String summary;
  final List<TripDay> days;
  final List<Destination> highlights;
  final List<Recommendation> recommendations;

  TripPlan({
    required this.title,
    this.startDate,
    this.endDate,
    required this.numberOfDays,
    this.numberOfPeople,
    this.budget,
    required this.preferences,
    required this.summary,
    required this.days,
    required this.highlights,
    required this.recommendations,
  });

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    List<TripDay> parseDays(List daysList) {
      return daysList.map((day) {
        return TripDay(
          day: day['day'] as String,
          date: day['date'] != null
              ? DateTime.parse(day['date'] as String)
              : null,
          activities: (day['activities'] as List)
              .map((activity) => Activity(
                    time: activity['time'] as String,
                    title: activity['title'] as String,
                    description: activity['description'] as String,
                    location: activity['location'] as String,
                  ))
              .toList(),
        );
      }).toList();
    }

    List<Destination> parseHighlights(List highlightsList) {
      return highlightsList.map((highlight) {
        final String name = highlight['name'] as String;

        // Only use the name for image mapping, ignore any imageUrl from JSON
        final String finalImageUrl = _getImageUrlForDestination(name, '');

        return Destination(
          name: name,
          description: highlight['description'] as String? ?? '',
          rating: (highlight['rating'] is int)
              ? (highlight['rating'] as int).toDouble()
              : (highlight['rating'] as num?)?.toDouble() ?? 4.5,
          imageUrl: finalImageUrl,
        );
      }).toList();
    }

    List<Recommendation> parseRecommendations(List recommendationsList) {
      return recommendationsList.map((recommendation) {
        IconData iconData = Icons.lightbulb_outline;

        // Parse icon type
        if (recommendation['iconType'] != null) {
          switch (recommendation['iconType'] as String) {
            case 'beach_access':
              iconData = Icons.beach_access;
              break;
            case 'restaurant':
              iconData = Icons.restaurant;
              break;
            case 'hiking':
              iconData = Icons.hiking;
              break;
            case 'attach_money':
              iconData = Icons.attach_money_outlined;
              break;
            case 'language':
              iconData = Icons.language;
              break;
            case 'camera':
              iconData = Icons.camera_alt;
              break;
            case 'local_taxi':
              iconData = Icons.local_taxi;
              break;
            default:
              iconData = Icons.lightbulb_outline;
          }
        }

        return Recommendation(
          title: recommendation['title'] as String,
          description: recommendation['description'] as String,
          icon: iconData,
        );
      }).toList();
    }

    // Safely convert fields with potential type issues
    String? convertToStringOrNull(dynamic value) {
      if (value == null) return null;
      return value is String ? value : value.toString();
    }

    int convertToInt(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 1;
      }
      return 1; // Default fallback
    }

    return TripPlan(
      title: json['title'] as String? ?? 'Trip Plan',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      numberOfDays:
          convertToInt(json['numberOfDays'] ?? json['days']?.length ?? 1),
      numberOfPeople: convertToStringOrNull(json['numberOfPeople']),
      budget: convertToStringOrNull(json['budget']),
      preferences: List<String>.from((json['preferences'] as List? ?? [])
          .map((item) => item is String ? item : item.toString())),
      summary: json['summary'] as String? ?? 'No summary provided',
      days: parseDays(json['days'] as List? ?? []),
      highlights: parseHighlights(json['highlights'] as List? ?? []),
      recommendations:
          parseRecommendations(json['recommendations'] as List? ?? []),
    );
  }

  // Helper function to map destination names to appropriate images
  static String _getImageUrlForDestination(
      String destinationName, String unused) {
    // Convert to lowercase for case-insensitive matching
    final nameLower = destinationName.toLowerCase();

    // Map of category keywords to image assets
    final Map<String, String> categoryImageMap = {
      // Beaches
      'pantai': 'assets/images/destinations/pantai.jpg',
      'beach': 'assets/images/destinations/pantai.jpg',
      'laut': 'assets/images/destinations/pantai.jpg',
      'pulau': 'assets/images/destinations/pantai.jpg',
      'teluk': 'assets/images/destinations/pantai.jpg',
      'island': 'assets/images/destinations/pantai.jpg',
      'bay': 'assets/images/destinations/pantai.jpg',
      'sea': 'assets/images/destinations/pantai.jpg',
      'balekambang': 'assets/images/destinations/pantai.jpg',
      'sempu': 'assets/images/destinations/pantai.jpg',
      'segara': 'assets/images/destinations/pantai.jpg',

      // Mountains
      'gunung': 'assets/images/destinations/gunung.jpg',
      'mountain': 'assets/images/destinations/gunung.jpg',
      'highland': 'assets/images/destinations/gunung.jpg',
      'hill': 'assets/images/destinations/gunung.jpg',
      'bukit': 'assets/images/destinations/gunung.jpg',

      // Waterfalls
      'air terjun': 'assets/images/destinations/air_terjun.jpg',
      'waterfall': 'assets/images/destinations/air_terjun.jpg',
      'curug': 'assets/images/destinations/air_terjun.jpg',
      'coban': 'assets/images/destinations/air_terjun.jpg',

      // Lakes
      'danau': 'assets/images/destinations/danau.jpg',
      'lake': 'assets/images/destinations/danau.jpg',
      'laguna': 'assets/images/destinations/danau.jpg',
      'lagoon': 'assets/images/destinations/danau.jpg',
      'ranu': 'assets/images/destinations/danau.jpg',
      'telaga': 'assets/images/destinations/danau.jpg',

      // Caves
      'goa': 'assets/images/destinations/goa.jpg',
      'cave': 'assets/images/destinations/goa.jpg',
      'gua': 'assets/images/destinations/goa.jpg',

      // Cities
      'kota': 'assets/images/destinations/kota.jpg',
      'city': 'assets/images/destinations/kota.jpg',
      'town': 'assets/images/destinations/kota.jpg',
      'alun': 'assets/images/destinations/kota.jpg',
      'square': 'assets/images/destinations/kota.jpg',

      // Parks
      'taman': 'assets/images/destinations/taman.jpg',
      'park': 'assets/images/destinations/taman.jpg',
      'kebun': 'assets/images/destinations/taman.jpg',
      'garden': 'assets/images/destinations/taman.jpg',
      'rekreasi': 'assets/images/destinations/taman.jpg',

      // Culinary
      'kuliner': 'assets/images/destinations/kuliner.jpg',
      'food': 'assets/images/destinations/kuliner.jpg',
      'makanan': 'assets/images/destinations/kuliner.jpg',
      'resto': 'assets/images/destinations/kuliner.jpg',
      'restaurant': 'assets/images/destinations/kuliner.jpg',
      'pasar': 'assets/images/destinations/kuliner.jpg',
      'market': 'assets/images/destinations/kuliner.jpg',

      // Rice fields and agriculture
      'sawah':
          'assets/images/destinations/gunung.jpg', // Use mountain/nature image for rice fields
      'tegalalang': 'assets/images/destinations/gunung.jpg',
      'terasering': 'assets/images/destinations/gunung.jpg',
      'rice terrace': 'assets/images/destinations/gunung.jpg',
      'rice field': 'assets/images/destinations/gunung.jpg',
      'pertanian': 'assets/images/destinations/gunung.jpg',
      'perkebunan': 'assets/images/destinations/taman.jpg',
      'plantation': 'assets/images/destinations/taman.jpg',

      // Historical
      'sejarah': 'assets/images/destinations/sejarah.jpg',
      'history': 'assets/images/destinations/sejarah.jpg',
      'historic': 'assets/images/destinations/sejarah.jpg',
      'heritage': 'assets/images/destinations/sejarah.jpg',
      'peninggalan': 'assets/images/destinations/sejarah.jpg',
      'monumen': 'assets/images/destinations/sejarah.jpg',
      'monument': 'assets/images/destinations/sejarah.jpg',
      'istana': 'assets/images/destinations/sejarah.jpg',
      'palace': 'assets/images/destinations/sejarah.jpg',

      // Temples
      'candi': 'assets/images/destinations/candi.jpg',
      'temple': 'assets/images/destinations/candi.jpg',
      'pura': 'assets/images/destinations/candi.jpg',

      // Museums
      'museum': 'assets/images/destinations/museum.jpg',
      'gallery': 'assets/images/destinations/museum.jpg',
      'galeri': 'assets/images/destinations/museum.jpg',

      // Specific locations
      'bali': 'assets/images/destinations/bali.jpg',
      'bromo': 'assets/images/destinations/bromo.jpg',
      'semeru': 'assets/images/destinations/bromo.jpg',
      'lombok': 'assets/images/destinations/lombok.jpg',
      'raja ampat': 'assets/images/destinations/raja_ampat.jpg',
      'borobudur': 'assets/images/destinations/borobudur.jpg',
      'prambanan': 'assets/images/destinations/prambanan.jpg',
      'yogyakarta': 'assets/images/destinations/yogyakarta.jpg',
      'jogja': 'assets/images/destinations/yogyakarta.jpg',
      'bandung': 'assets/images/destinations/bandung.jpg',
      'jakarta': 'assets/images/destinations/jakarta.jpg',
      'ubud': 'assets/images/destinations/ubud.jpg',
      'komodo': 'assets/images/destinations/komodo.jpg',
      'dieng': 'assets/images/destinations/dieng.jpg',
      'malang': 'assets/images/destinations/malang.jpg',
      'batu': 'assets/images/destinations/malang.jpg',
      'kawah': 'assets/images/destinations/kawah.jpg',
      'crater': 'assets/images/destinations/kawah.jpg',
      'lembang': 'assets/images/destinations/lembang.jpg',
    };

    // Check if destination name contains any keywords
    for (final entry in categoryImageMap.entries) {
      if (nameLower.contains(entry.key)) {
        // Found a match
        return entry.value;
      }
    }

    // If we get here, no match was found - log for debugging
    print(
        'No image match found for destination: $destinationName, using fallback image');

    // Default fallback
    return 'assets/images/kotamalangplaceholder.jpg';
  }
}

class TripDay {
  final String day;
  final DateTime? date;
  final List<Activity> activities;

  TripDay({
    required this.day,
    this.date,
    required this.activities,
  });
}

class Activity {
  final String time;
  final String title;
  final String description;
  final String location;

  Activity({
    required this.time,
    required this.title,
    required this.description,
    required this.location,
  });
}

class Destination {
  final String name;
  final String description;
  final String imageUrl;
  final double rating;

  Destination({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
  });
}

class Recommendation {
  final String title;
  final String description;
  final IconData icon;

  Recommendation({
    required this.title,
    required this.description,
    required this.icon,
  });
}
