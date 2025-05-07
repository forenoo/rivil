import 'package:rivil/features/favorite/domain/model/favorite_destination.dart';

abstract class FavoriteRepository {
  Future<List<FavoriteDestination>> getFavoriteDestinations();
  Future<void> addFavoriteDestination(FavoriteDestination destination);
  Future<void> removeFavoriteDestination(String destinationName);
  Future<bool> isFavorite(String destinationName);
}
