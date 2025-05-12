abstract class FavoritesEvent {}

class LoadFavorites extends FavoritesEvent {}

class AddToFavorites extends FavoritesEvent {
  final int destinationId;

  AddToFavorites(this.destinationId);
}

class RemoveFromFavorites extends FavoritesEvent {
  final int destinationId;

  RemoveFromFavorites(this.destinationId);
}

class SearchFavorites extends FavoritesEvent {
  final String query;

  SearchFavorites(this.query);
}

class CheckIsFavorite extends FavoritesEvent {
  final int destinationId;

  CheckIsFavorite(this.destinationId);
}
