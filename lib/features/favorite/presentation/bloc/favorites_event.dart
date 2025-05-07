import 'package:equatable/equatable.dart';
import 'package:rivil/features/favorite/domain/model/favorite_destination.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object> get props => [];
}

class LoadFavorites extends FavoritesEvent {}

class AddToFavorites extends FavoritesEvent {
  final FavoriteDestination destination;

  const AddToFavorites(this.destination);

  @override
  List<Object> get props => [destination];
}

class RemoveFromFavorites extends FavoritesEvent {
  final String destinationName;

  const RemoveFromFavorites(this.destinationName);

  @override
  List<Object> get props => [destinationName];
}

class CheckIsFavorite extends FavoritesEvent {
  final String destinationName;

  const CheckIsFavorite(this.destinationName);

  @override
  List<Object> get props => [destinationName];
}
