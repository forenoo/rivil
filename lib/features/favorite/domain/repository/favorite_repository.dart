import 'package:rivil/features/favorite/domain/model/favorite_destination.dart';

abstract class FavoriteRepository {
  Future<List<FavoriteDestination>> getFavoriteDestinations();
  Future<void> addFavoriteDestination(int destinationId);
  Future<void> removeFavoriteDestination(int destinationId);
  Future<bool> isFavorite(int destinationId);
}
