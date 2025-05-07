import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rivil/features/favorite/domain/repository/favorite_repository.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_event.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoriteRepository _favoriteRepository;

  FavoritesBloc(this._favoriteRepository) : super(FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<CheckIsFavorite>(_onCheckIsFavorite);
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    try {
      final favorites = await _favoriteRepository.getFavoriteDestinations();
      emit(FavoritesLoaded(favorites));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _favoriteRepository.addFavoriteDestination(event.destination);
      emit(FavoriteAdded(event.destination));

      // Reload updated favorites
      add(LoadFavorites());
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _favoriteRepository
          .removeFavoriteDestination(event.destinationName);
      emit(FavoriteRemoved(event.destinationName));

      // Reload updated favorites
      add(LoadFavorites());
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onCheckIsFavorite(
    CheckIsFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final isFavorite =
          await _favoriteRepository.isFavorite(event.destinationName);
      emit(FavoriteCheckResult(
        isFavorite: isFavorite,
        destinationName: event.destinationName,
      ));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }
}
