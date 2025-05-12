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
}
