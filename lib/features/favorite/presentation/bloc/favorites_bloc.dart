import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rivil/features/favorite/domain/model/favorite_destination.dart';
import 'package:rivil/features/favorite/domain/repository/favorite_repository.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_event.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoriteRepository _repository;
  List<FavoriteDestination> _allFavorites = [];

  FavoritesBloc({required FavoriteRepository repository})
      : _repository = repository,
        super(FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<SearchFavorites>(_onSearchFavorites);
    on<CheckIsFavorite>(_onCheckIsFavorite);
    on<UpdateFavoritesDistances>(_onUpdateFavoritesDistances);
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    try {
      _allFavorites = await _repository.getFavoriteDestinations();
      emit(FavoritesLoaded(favorites: _allFavorites));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _repository.addFavoriteDestination(event.destinationId);
      add(LoadFavorites()); // Reload the favorites
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _repository.removeFavoriteDestination(event.destinationId);

      if (state is FavoritesLoaded) {
        _allFavorites
            .removeWhere((item) => item.destinationId == event.destinationId);
        emit(FavoritesLoaded(favorites: _allFavorites));
      }
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onSearchFavorites(
    SearchFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state is FavoritesLoaded) {
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(FavoritesLoaded(favorites: _allFavorites));
        return;
      }

      final filtered = _allFavorites.where((destination) {
        return destination.name.toLowerCase().contains(query) ||
            destination.location.toLowerCase().contains(query) ||
            destination.category.toLowerCase().contains(query);
      }).toList();

      emit(FavoritesLoaded(
        favorites: _allFavorites,
        filteredFavorites: filtered,
      ));
    }
  }

  Future<void> _onCheckIsFavorite(
    CheckIsFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final isFavorite = await _repository.isFavorite(event.destinationId);
      emit(FavoriteCheckResult(
        isFavorite: isFavorite,
        destinationId: event.destinationId,
      ));
    } catch (e) {
      // Just return false without emitting error
      emit(FavoriteCheckResult(
        isFavorite: false,
        destinationId: event.destinationId,
      ));
    }
  }

  Future<void> _onUpdateFavoritesDistances(
    UpdateFavoritesDistances event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state is! FavoritesLoaded) return;

    try {
      // Get updated favorites with new distances without showing loading state
      final updatedFavorites = await _repository.getFavoriteDestinations();
      _allFavorites = updatedFavorites;

      // Keep the current state but with updated distances
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        emit(FavoritesLoaded(
          favorites: updatedFavorites,
          filteredFavorites: currentState.filteredFavorites.isNotEmpty
              ? _filterFavorites(
                  currentState.filteredFavorites, updatedFavorites)
              : updatedFavorites,
        ));
      }
    } catch (e) {
      // Don't emit error, just keep current state
      print('Error updating distances: $e');
    }
  }

  List<FavoriteDestination> _filterFavorites(
    List<FavoriteDestination> currentFiltered,
    List<FavoriteDestination> allUpdated,
  ) {
    // Get destination IDs from current filtered list
    final filteredIds = currentFiltered.map((f) => f.destinationId).toSet();

    // Return updated favorites that match the filtered IDs
    return allUpdated
        .where((f) => filteredIds.contains(f.destinationId))
        .toList();
  }
}
