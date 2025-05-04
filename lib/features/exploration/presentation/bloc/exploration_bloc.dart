import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rivil/core/constants/destination_mock.dart';

// Events
abstract class ExplorationEvent extends Equatable {
  const ExplorationEvent();

  @override
  List<Object?> get props => [];
}

class SearchDestinationsEvent extends ExplorationEvent {
  final String query;

  const SearchDestinationsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterDestinationsEvent extends ExplorationEvent {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? maxDistance;
  final double? minRating;
  final List<String>? facilities;

  const FilterDestinationsEvent({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.maxDistance,
    this.minRating,
    this.facilities,
  });

  @override
  List<Object?> get props => [
        category,
        minPrice,
        maxPrice,
        maxDistance,
        minRating,
        facilities,
      ];
}

class SortDestinationsEvent extends ExplorationEvent {
  final SortOption sortOption;

  const SortDestinationsEvent(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
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

class ExplorationLoaded extends ExplorationState {
  final List<Map<String, dynamic>> destinations;
  final String searchQuery;
  final String? selectedCategory;
  final SortOption? activeSortOption;
  final double? minPrice;
  final double? maxPrice;
  final double? maxDistance;
  final double? minRating;
  final List<String>? selectedFacilities;

  const ExplorationLoaded({
    required this.destinations,
    this.searchQuery = '',
    this.selectedCategory,
    this.activeSortOption,
    this.minPrice,
    this.maxPrice,
    this.maxDistance,
    this.minRating,
    this.selectedFacilities,
  });

  @override
  List<Object?> get props => [
        destinations,
        searchQuery,
        selectedCategory,
        activeSortOption,
        minPrice,
        maxPrice,
        maxDistance,
        minRating,
        selectedFacilities,
      ];

  ExplorationLoaded copyWith({
    List<Map<String, dynamic>>? destinations,
    String? searchQuery,
    String? selectedCategory,
    SortOption? activeSortOption,
    double? minPrice,
    double? maxPrice,
    double? maxDistance,
    double? minRating,
    List<String>? selectedFacilities,
  }) {
    return ExplorationLoaded(
      destinations: destinations ?? this.destinations,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      activeSortOption: activeSortOption ?? this.activeSortOption,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      maxDistance: maxDistance ?? this.maxDistance,
      minRating: minRating ?? this.minRating,
      selectedFacilities: selectedFacilities ?? this.selectedFacilities,
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
  final List<Map<String, dynamic>> _allDestinations = allDestinations;

  ExplorationBloc() : super(ExplorationInitial()) {
    on<SearchDestinationsEvent>(_onSearchDestinations);
    on<FilterDestinationsEvent>(_onFilterDestinations);
    on<SortDestinationsEvent>(_onSortDestinations);

    add(const FilterDestinationsEvent());
  }

  void _onSearchDestinations(
    SearchDestinationsEvent event,
    Emitter<ExplorationState> emit,
  ) {
    if (state is ExplorationLoaded) {
      final currentState = state as ExplorationLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(currentState.copyWith(
          searchQuery: query,
          destinations: _filterAndSortDestinations(
            _allDestinations,
            category: currentState.selectedCategory,
            minPrice: currentState.minPrice,
            maxPrice: currentState.maxPrice,
            maxDistance: currentState.maxDistance,
            minRating: currentState.minRating,
            facilities: currentState.selectedFacilities,
            sortOption: currentState.activeSortOption,
          ),
        ));
      } else {
        final filteredDestinations = _allDestinations.where((destination) {
          final name = destination['name'] as String;
          final location = destination['location'] as String;
          return name.toLowerCase().contains(query) ||
              location.toLowerCase().contains(query);
        }).toList();

        emit(currentState.copyWith(
          searchQuery: query,
          destinations: _filterAndSortDestinations(
            filteredDestinations,
            category: currentState.selectedCategory,
            minPrice: currentState.minPrice,
            maxPrice: currentState.maxPrice,
            maxDistance: currentState.maxDistance,
            minRating: currentState.minRating,
            facilities: currentState.selectedFacilities,
            sortOption: currentState.activeSortOption,
          ),
        ));
      }
    }
  }

  void _onFilterDestinations(
    FilterDestinationsEvent event,
    Emitter<ExplorationState> emit,
  ) {
    if (state is ExplorationInitial || state is ExplorationLoaded) {
      final currentState = state is ExplorationLoaded
          ? state as ExplorationLoaded
          : ExplorationLoaded(destinations: _allDestinations);

      final String? newCategory = event.category;

      emit(currentState.copyWith(
        selectedCategory: newCategory,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        maxDistance: event.maxDistance,
        minRating: event.minRating,
        selectedFacilities: event.facilities,
        destinations: _filterAndSortDestinations(
          _allDestinations,
          searchQuery: currentState.searchQuery,
          category: newCategory,
          minPrice: event.minPrice ?? currentState.minPrice,
          maxPrice: event.maxPrice ?? currentState.maxPrice,
          maxDistance: event.maxDistance ?? currentState.maxDistance,
          minRating: event.minRating ?? currentState.minRating,
          facilities: event.facilities ?? currentState.selectedFacilities,
          sortOption: currentState.activeSortOption,
        ),
      ));
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

      switch (event.sortOption) {
        case SortOption.priceAsc:
          sortedDestinations
              .sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
          break;
        case SortOption.priceDesc:
          sortedDestinations
              .sort((a, b) => (b['price'] as int).compareTo(a['price'] as int));
          break;
        case SortOption.ratingDesc:
          sortedDestinations.sort((a, b) =>
              (b['rating'] as double).compareTo(a['rating'] as double));
          break;
        case SortOption.distanceAsc:
          sortedDestinations.sort((a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double));
          break;
      }

      emit(currentState.copyWith(
        destinations: sortedDestinations,
        activeSortOption: event.sortOption,
      ));
    }
  }

  List<Map<String, dynamic>> _filterAndSortDestinations(
    List<Map<String, dynamic>> destinations, {
    String? searchQuery,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? maxDistance,
    double? minRating,
    List<String>? facilities,
    SortOption? sortOption,
  }) {
    // Filter by search query
    List<Map<String, dynamic>> result = destinations;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((destination) {
        final name = destination['name'] as String;
        final location = destination['location'] as String;
        return name.toLowerCase().contains(query) ||
            location.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by category
    if (category != null) {
      result = result.where((destination) {
        return destination['category'] == category;
      }).toList();
    }

    // Filter by price range
    if (minPrice != null) {
      result = result.where((destination) {
        final price = destination['price'] as int;
        return price >= minPrice;
      }).toList();
    }

    if (maxPrice != null) {
      result = result.where((destination) {
        final price = destination['price'] as int;
        return price <= maxPrice;
      }).toList();
    }

    // Filter by distance
    if (maxDistance != null) {
      result = result.where((destination) {
        final distance = destination['distance'] as double;
        return distance <= maxDistance;
      }).toList();
    }

    // Filter by rating
    if (minRating != null) {
      result = result.where((destination) {
        final rating = destination['rating'] as double;
        return rating >= minRating;
      }).toList();
    }

    // Filter by facilities
    if (facilities != null && facilities.isNotEmpty) {
      result = result.where((destination) {
        final destinationFacilities = destination['facilities'] as List<String>;
        for (final facility in facilities) {
          if (!destinationFacilities.contains(facility)) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    // Sort destinations
    if (sortOption != null) {
      switch (sortOption) {
        case SortOption.priceAsc:
          result
              .sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
          break;
        case SortOption.priceDesc:
          result
              .sort((a, b) => (b['price'] as int).compareTo(a['price'] as int));
          break;
        case SortOption.ratingDesc:
          result.sort((a, b) =>
              (b['rating'] as double).compareTo(a['rating'] as double));
          break;
        case SortOption.distanceAsc:
          result.sort((a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double));
          break;
      }
    }

    return result;
  }
}
