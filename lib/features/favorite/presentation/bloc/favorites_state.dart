import 'package:equatable/equatable.dart';
import 'package:rivil/features/favorite/domain/model/favorite_destination.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteDestination> favorites;
  final List<FavoriteDestination> filteredFavorites;

  FavoritesLoaded({
    required this.favorites,
    List<FavoriteDestination>? filteredFavorites,
  }) : filteredFavorites = filteredFavorites ?? favorites;

  @override
  List<Object> get props => [favorites, filteredFavorites];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object> get props => [message];
}

class FavoriteAdded extends FavoritesState {
  final FavoriteDestination destination;

  const FavoriteAdded(this.destination);

  @override
  List<Object> get props => [destination];
}

class FavoriteRemoved extends FavoritesState {
  final String destinationName;

  const FavoriteRemoved(this.destinationName);

  @override
  List<Object> get props => [destinationName];
}

class FavoriteCheckResult extends FavoritesState {
  final bool isFavorite;
  final int destinationId;

  const FavoriteCheckResult({
    required this.isFavorite,
    required this.destinationId,
  });

  @override
  List<Object> get props => [isFavorite, destinationId];
}
