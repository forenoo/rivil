import 'package:rivil/core/constants/destination_mock.dart';
import 'package:rivil/features/favorite/domain/model/favorite_destination.dart';
import 'package:rivil/features/favorite/domain/repository/favorite_repository.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  // In-memory cache for favorites in this mock implementation
  final List<FavoriteDestination> _favorites = [];

  FavoriteRepositoryImpl() {
    // Initialize with mock data
    _loadInitialFavorites();
  }

  void _loadInitialFavorites() {
    final favoritesFromMock = allDestinations
        .where((dest) => dest['isFavorite'] == true)
        .map((map) => FavoriteDestination.fromMap(map))
        .toList();

    _favorites.addAll(favoritesFromMock);
  }

  @override
  Future<List<FavoriteDestination>> getFavoriteDestinations() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _favorites;
  }

  @override
  Future<void> addFavoriteDestination(FavoriteDestination destination) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Check if already exists
    if (_favorites.any((fav) => fav.name == destination.name)) {
      return;
    }

    _favorites.add(destination);
  }

  @override
  Future<void> removeFavoriteDestination(String destinationName) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    _favorites.removeWhere((fav) => fav.name == destinationName);
  }

  @override
  Future<bool> isFavorite(String destinationName) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    return _favorites.any((fav) => fav.name == destinationName);
  }
}
