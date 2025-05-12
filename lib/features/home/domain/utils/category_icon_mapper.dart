import 'package:flutter/material.dart';

class CategoryIconMapper {
  static IconData getIconForCategory(String categoryName) {
    // Convert to lowercase for case-insensitive matching
    final name = categoryName.toLowerCase();

    // Map of keywords to icons
    final iconMap = {
      'pantai': Icons.beach_access,
      'beach': Icons.beach_access,
      'gunung': Icons.landscape,
      'mountain': Icons.landscape,
      'air terjun': Icons.water_drop,
      'waterfall': Icons.water_drop,
      'danau': Icons.water,
      'lake': Icons.water,
      'goa': Icons.terrain,
      'cave': Icons.terrain,
      'hutan': Icons.forest,
      'forest': Icons.forest,
      'kebun raya': Icons.park,
      'botanical': Icons.park,
      'taman nasional': Icons.nature,
      'national park': Icons.nature,
      'agrowisata': Icons.agriculture,
      'agro': Icons.agriculture,
      'air panas': Icons.hot_tub,
      'hot spring': Icons.hot_tub,
      'bukit': Icons.terrain,
      'hill': Icons.terrain,
      'museum': Icons.museum,
      'candi': Icons.account_balance,
      'temple': Icons.account_balance,
      'hiburan': Icons.attractions,
      'entertainment': Icons.attractions,
      'taman air': Icons.pool,
      'water park': Icons.pool,
      'kebun binatang': Icons.pets,
      'zoo': Icons.pets,
      'aquarium': Icons.water,
      'outbound': Icons.hiking,
      'wahana': Icons.games,
      'permainan': Icons.games,
      'olahraga': Icons.sports,
      'sport': Icons.sports,
      'restoran': Icons.restaurant,
      'restaurant': Icons.restaurant,
      'cafe': Icons.coffee,
      'mall': Icons.storefront,
      'shopping': Icons.storefront,
      'pemandian': Icons.pool,
      'swimming': Icons.pool,
      'taman': Icons.park,
      'park': Icons.park,
      'wisata': Icons.travel_explore,
      'tourism': Icons.travel_explore,
      'budaya': Icons.account_balance,
      'culture': Icons.account_balance,
      'sejarah': Icons.history,
      'history': Icons.history,
      'alam': Icons.nature,
      'nature': Icons.nature,
    };

    // Try to find an exact match first
    if (iconMap.containsKey(name)) {
      return iconMap[name]!;
    }

    // If no exact match, try to find a partial match
    for (final entry in iconMap.entries) {
      if (name.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default icon if no match is found
    return Icons.place;
  }
}
