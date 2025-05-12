import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rivil/features/exploration/domain/repositories/exploration_repository.dart';

// Events
abstract class ExplorationEvent extends Equatable {
  const ExplorationEvent();

  @override
  List<Object?> get props => [];
}

class LoadExplorationEvent extends ExplorationEvent {
  const LoadExplorationEvent();
}

class LoadMoreDestinationsEvent extends ExplorationEvent {
  const LoadMoreDestinationsEvent();
}

class LoadCategoriesEvent extends ExplorationEvent {
  const LoadCategoriesEvent();
}

class SearchDestinationsEvent extends ExplorationEvent {
  final String query;

  const SearchDestinationsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterDestinationsEvent extends ExplorationEvent {
  final String? category;
  final double? minRating;

  const FilterDestinationsEvent({
    this.category,
    this.minRating,
  });

  @override
  List<Object?> get props => [
        category,
        minRating,
      ];
}

class SortDestinationsEvent extends ExplorationEvent {
  final SortOption sortOption;

  const SortDestinationsEvent(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}

class ToggleFavoriteEvent extends ExplorationEvent {
  final int destinationId;
  final bool isFavorite;

  const ToggleFavoriteEvent({
    required this.destinationId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [destinationId, isFavorite];
}

class LoadFavoritesEvent extends ExplorationEvent {
  final Map<int, bool> favorites;

  const LoadFavoritesEvent(this.favorites);

  @override
  List<Object?> get props => [favorites];
}

class UpdateDistancesEvent extends ExplorationEvent {
  final double latitude;
  final double longitude;

  const UpdateDistancesEvent({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

enum SortOption {
  priceAsc,
  priceDesc,
  ratingDesc,
  distanceAsc,
}

// States
abstract class ExplorationState extends Equatable {
  const ExplorationState();

  @override
  List<Object?> get props => [];
}

class ExplorationInitial extends ExplorationState {}

class ExplorationLoading extends ExplorationState {}

class ExplorationLoadingMore extends ExplorationState {
  final List<Map<String, dynamic>> currentDestinations;
  final List<String> categories;
  final String searchQuery;
  final String? selectedCategory;
  final SortOption? activeSortOption;
  final double? minRating;
  final int currentPage;
  final Map<int, bool> favorites;

  const ExplorationLoadingMore({
    required this.currentDestinations,
    required this.categories,
    required this.currentPage,
    this.searchQuery = '',
    this.selectedCategory,
    this.activeSortOption,
    this.minRating,
    this.favorites = const {},
  });

  @override
  List<Object?> get props => [
        currentDestinations,
        categories,
        searchQuery,
        selectedCategory,
        activeSortOption,
        minRating,
        currentPage,
        favorites,
      ];
}

class CategoriesLoaded extends ExplorationState {
  final List<String> categories;

  const CategoriesLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class ExplorationLoaded extends ExplorationState {
  final List<Map<String, dynamic>> destinations;
  final List<String> categories;
  final String searchQuery;
  final String? selectedCategory;
  final SortOption? activeSortOption;
  final double? minRating;
  final int currentPage;
  final bool hasReachedMax;
  final Map<int, bool> favorites;

  const ExplorationLoaded({
    required this.destinations,
    required this.categories,
    required this.currentPage,
    this.searchQuery = '',
    this.selectedCategory,
    this.activeSortOption,
    this.minRating,
    this.hasReachedMax = false,
    this.favorites = const {},
  });

  @override
  List<Object?> get props => [
        destinations,
        categories,
        searchQuery,
        selectedCategory,
        activeSortOption,
        minRating,
        currentPage,
        hasReachedMax,
        favorites,
      ];

  ExplorationLoaded copyWith({
    List<Map<String, dynamic>>? destinations,
    List<String>? categories,
    String? searchQuery,
    String? selectedCategory,
    SortOption? activeSortOption,
    double? minRating,
    int? currentPage,
    bool? hasReachedMax,
    Map<int, bool>? favorites,
  }) {
    return ExplorationLoaded(
      destinations: destinations ?? this.destinations,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      activeSortOption: activeSortOption ?? this.activeSortOption,
      minRating: minRating ?? this.minRating,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      favorites: favorites ?? this.favorites,
    );
  }
}

class ExplorationError extends ExplorationState {
  final String message;

  const ExplorationError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ExplorationBloc extends Bloc<ExplorationEvent, ExplorationState> {
  final ExplorationRepository _repository;
  List<String> _allCategories = ["Semua"];
  Position? _userPosition;
  static const int _pageSize = 10;

  ExplorationBloc(this._repository) : super(ExplorationInitial()) {
    on<LoadExplorationEvent>(_onLoadExploration);
    on<LoadMoreDestinationsEvent>(_onLoadMoreDestinations);
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<SearchDestinationsEvent>(_onSearchDestinations);
    on<FilterDestinationsEvent>(_onFilterDestinations);
    on<SortDestinationsEvent>(_onSortDestinations);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<LoadFavoritesEvent>(_onLoadFavorites);
    on<UpdateDistancesEvent>(_onUpdateDistances);

    // Initialize by loading data
    add(const LoadCategoriesEvent());
    add(const LoadExplorationEvent());
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      _userPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  void _onLoadExploration(
    LoadExplorationEvent event,
    Emitter<ExplorationState> emit,
  ) async {
    emit(ExplorationLoading());
    try {
      final destinations = await _repository.getAllDestinations(
        page: 1,
        pageSize: _pageSize,
      );

      if (state is CategoriesLoaded) {
        final categoriesState = state as CategoriesLoaded;
        emit(ExplorationLoaded(
          destinations: destinations,
          categories: categoriesState.categories,
          currentPage: 1,
          hasReachedMax: destinations.length < _pageSize,
          favorites: {},
        ));
      } else {
        // If categories not loaded yet, use the ones from repo
        emit(ExplorationLoaded(
          destinations: destinations,
          categories: _allCategories,
          currentPage: 1,
          hasReachedMax: destinations.length < _pageSize,
          favorites: {},
        ));
      }
    } catch (e) {
      emit(ExplorationError('Failed to load destinations: $e'));
    }
  }

  void _onLoadMoreDestinations(
    LoadMoreDestinationsEvent event,
    Emitter<ExplorationState> emit,
  ) async {
    if (state is ExplorationLoaded) {
      final currentState = state as ExplorationLoaded;

      if (currentState.hasReachedMax) return;

      try {
        emit(ExplorationLoadingMore(
          currentDestinations: currentState.destinations,
          categories: currentState.categories,
          currentPage: currentState.currentPage,
          searchQuery: currentState.searchQuery,
          selectedCategory: currentState.selectedCategory,
          minRating: currentState.minRating,
          activeSortOption: currentState.activeSortOption,
          favorites: currentState.favorites,
        ));

        final nextPage = currentState.currentPage + 1;
        List<Map<String, dynamic>> newDestinations = [];

        if (currentState.searchQuery.isNotEmpty) {
          // If search is active
          newDestinations = await _repository.searchDestinations(
            currentState.searchQuery,
            page: nextPage,
            pageSize: _pageSize,
          );
        } else if (currentState.selectedCategory != null ||
            (currentState.minRating != null && currentState.minRating! > 0)) {
          // If filters are active
          newDestinations = await _repository.filterDestinations(
            category: currentState.selectedCategory == "Semua"
                ? null
                : currentState.selectedCategory,
            minRating: currentState.minRating,
            latitude: _userPosition?.latitude,
            longitude: _userPosition?.longitude,
            page: nextPage,
            pageSize: _pageSize,
          );
        } else {
          // Just load next page
          newDestinations = await _repository.getAllDestinations(
            page: nextPage,
            pageSize: _pageSize,
          );
        }

        // Calculate distances for new destinations
        final processedDestinations = await _processDestinations(
          newDestinations,
          sortOption: currentState.activeSortOption,
        );

        // Check if we need to sort the combined results
        List<Map<String, dynamic>> combinedDestinations = [
          ...currentState.destinations,
          ...processedDestinations,
        ];

        if (currentState.activeSortOption != null) {
          _sortDestinations(
              combinedDestinations, currentState.activeSortOption!);
        }

        emit(currentState.copyWith(
          destinations: combinedDestinations,
          currentPage: nextPage,
          hasReachedMax: newDestinations.length < _pageSize,
          favorites: currentState.favorites,
        ));
      } catch (e) {
        emit(ExplorationError('Failed to load more destinations: $e'));
      }
    }
  }

  void _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<ExplorationState> emit,
  ) async {
    try {
      final categories = await _repository.getCategories();
      // Add "Semua" (All) as the first option
      _allCategories = ["Semua", ...categories];

      if (state is ExplorationLoaded) {
        final currentState = state as ExplorationLoaded;
        emit(currentState.copyWith(categories: _allCategories));
      } else {
        emit(CategoriesLoaded(categories: _allCategories));
      }
    } catch (e) {
      emit(ExplorationError('Failed to load categories: $e'));
    }
  }

  void _onSearchDestinations(
    SearchDestinationsEvent event,
    Emitter<ExplorationState> emit,
  ) async {
    if (state is ExplorationLoaded) {
      final currentState = state as ExplorationLoaded;
      final query = event.query.toLowerCase();
      emit(ExplorationLoading());

      try {
        List<Map<String, dynamic>> searchResults;

        if (query.isEmpty) {
          // If query is empty, apply current filters to all destinations
          searchResults = await _repository.filterDestinations(
            category: currentState.selectedCategory == "Semua"
                ? null
                : currentState.selectedCategory,
            minRating: currentState.minRating,
            latitude: _userPosition?.latitude,
            longitude: _userPosition?.longitude,
            page: 1,
            pageSize: _pageSize,
          );
        } else {
          // Search with query
          searchResults = await _repository.searchDestinations(
            query,
            page: 1,
            pageSize: _pageSize,
          );
        }

        // Process destinations (calculate distances and sort)
        final processedDestinations = await _processDestinations(
          searchResults,
          sortOption: currentState.activeSortOption,
        );

        emit(currentState.copyWith(
          destinations: processedDestinations,
          searchQuery: query,
          currentPage: 1,
          hasReachedMax: searchResults.length < _pageSize,
          // Preserve favorites
          favorites: currentState.favorites,
        ));
      } catch (e) {
        emit(ExplorationError('Failed to search destinations: $e'));
      }
    }
  }

  void _onFilterDestinations(
    FilterDestinationsEvent event,
    Emitter<ExplorationState> emit,
  ) async {
    if (state is ExplorationLoaded) {
      final currentState = state as ExplorationLoaded;
      emit(ExplorationLoading());

      try {
        final filteredDestinations = await _repository.filterDestinations(
          category: event.category == "Semua" ? null : event.category,
          minRating: event.minRating,
          latitude: _userPosition?.latitude,
          longitude: _userPosition?.longitude,
          page: 1,
          pageSize: _pageSize,
        );

        // Process destinations (calculate distances and sort)
        final processedDestinations = await _processDestinations(
          filteredDestinations,
          sortOption: currentState.activeSortOption,
        );

        emit(currentState.copyWith(
          destinations: processedDestinations,
          selectedCategory: event.category,
          minRating: event.minRating,
          currentPage: 1,
          hasReachedMax: filteredDestinations.length < _pageSize,
          // Clear search when filtering
          searchQuery: '',
          // Preserve favorites
          favorites: currentState.favorites,
        ));
      } catch (e) {
        emit(ExplorationError('Failed to filter destinations: $e'));
      }
    }
  }

  void _onSortDestinations(
    SortDestinationsEvent event,
    Emitter<ExplorationState> emit,
  ) {
    if (state is ExplorationLoaded) {
      final currentState = state as ExplorationLoaded;
      final sortedDestinations =
          List<Map<String, dynamic>>.from(currentState.destinations);

      _sortDestinations(sortedDestinations, event.sortOption);

      emit(currentState.copyWith(
        destinations: sortedDestinations,
        activeSortOption: event.sortOption,
        // Preserve favorites
        favorites: currentState.favorites,
      ));
    }
  }

  void _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<ExplorationState> emit,
  ) {
    if (state is ExplorationLoaded) {
      final currentState = state as ExplorationLoaded;

      // Create a new map with the updated favorite status
      final newFavorites = Map<int, bool>.from(currentState.favorites);
      newFavorites[event.destinationId] = event.isFavorite;

      emit(currentState.copyWith(favorites: newFavorites));
    }
  }

  void _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<ExplorationState> emit,
  ) {
    if (state is ExplorationLoaded) {
      final currentState = state as ExplorationLoaded;
      emit(currentState.copyWith(favorites: event.favorites));
    }
  }

  // Add handler for updating distances
  void _onUpdateDistances(
    UpdateDistancesEvent event,
    Emitter<ExplorationState> emit,
  ) {
    if (state is ExplorationLoaded) {
      final currentState = state as ExplorationLoaded;

      // Update user position
      _userPosition = Position(
        latitude: event.latitude,
        longitude: event.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      // Recalculate distances for all destinations
      List<Map<String, dynamic>> updatedDestinations =
          currentState.destinations.map((destination) {
        // Clone the destination
        final updatedDestination = Map<String, dynamic>.from(destination);

        // Extract destination coordinates
        double? destLat;
        double? destLng;

        final latValue = destination['latitude'];
        final lngValue = destination['longitude'];

        // Handle different possible data types
        if (latValue is double) {
          destLat = latValue;
        } else if (latValue is String) {
          destLat = double.tryParse(latValue);
        }

        if (lngValue is double) {
          destLng = lngValue;
        } else if (lngValue is String) {
          destLng = double.tryParse(lngValue);
        }

        // Calculate distance if coordinates are valid
        if (destLat != null && destLng != null) {
          final distanceInMeters = Geolocator.distanceBetween(
            event.latitude,
            event.longitude,
            destLat,
            destLng,
          );
          updatedDestination['distance'] = distanceInMeters / 1000;
        }

        return updatedDestination;
      }).toList();

      // Sort if needed
      if (currentState.activeSortOption == SortOption.distanceAsc) {
        _sortDestinations(updatedDestinations, SortOption.distanceAsc);
      }

      // Emit updated state
      emit(currentState.copyWith(
        destinations: updatedDestinations,
      ));
    }
  }

  // Helper method to sort destinations
  void _sortDestinations(
      List<Map<String, dynamic>> destinations, SortOption sortOption) {
    switch (sortOption) {
      case SortOption.ratingDesc:
        destinations.sort(
            (a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case SortOption.distanceAsc:
        destinations.sort((a, b) {
          final aDistance = (a['distance'] as num?)?.toDouble() ?? 0.0;
          final bDistance = (b['distance'] as num?)?.toDouble() ?? 0.0;
          return aDistance.compareTo(bDistance);
        });
        break;
      // We don't have price in our model anymore, so these options just maintain structure
      case SortOption.priceAsc:
      case SortOption.priceDesc:
        // No-op as price is not available
        break;
    }
  }

  Future<List<Map<String, dynamic>>> _processDestinations(
    List<Map<String, dynamic>> destinations, {
    SortOption? sortOption,
  }) async {
    final result = List<Map<String, dynamic>>.from(destinations);

    // Calculate distances if we have user's location
    if (_userPosition != null) {
      for (var destination in result) {
        final destLatStr = destination['latitude'] as String?;
        final destLonStr = destination['longitude'] as String?;

        final destLat = destLatStr != null && destLatStr.isNotEmpty
            ? double.tryParse(destLatStr) ?? 0.0
            : 0.0;
        final destLon = destLonStr != null && destLonStr.isNotEmpty
            ? double.tryParse(destLonStr) ?? 0.0
            : 0.0;

        final distance = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              destLat,
              destLon,
            ) /
            1000;

        print('Calculated distance: $distance km');

        destination['distance'] = distance; // Convert to km
      }
    } else {
      // Add placeholder distance if location not available
      for (var destination in result) {
        destination['distance'] = 0.0;
      }
    }

    // Apply sort if specified
    if (sortOption != null) {
      _sortDestinations(result, sortOption);
    }

    return result;
  }
}
