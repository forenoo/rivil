import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rivil/core/services/location_service.dart';
import 'package:rivil/features/home/domain/repository/destination_repository.dart';

// Events
abstract class DestinationEvent extends Equatable {
  const DestinationEvent();

  @override
  List<Object?> get props => [];
}

class LoadDestinations extends DestinationEvent {}

class LoadPopularDestinations extends DestinationEvent {}

class LoadRecommendedDestinations extends DestinationEvent {}

class LoadNearbyDestinations extends DestinationEvent {
  final double? latitude;
  final double? longitude;

  const LoadNearbyDestinations({this.latitude, this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class ToggleFavoriteEvent extends DestinationEvent {
  final int destinationId;
  final bool isFavorite;

  const ToggleFavoriteEvent({
    required this.destinationId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [destinationId, isFavorite];
}

class LoadFavoritesEvent extends DestinationEvent {
  final Map<int, bool> favorites;

  const LoadFavoritesEvent(this.favorites);

  @override
  List<Object?> get props => [favorites];
}

// States
abstract class DestinationState extends Equatable {
  const DestinationState();

  @override
  List<Object?> get props => [];
}

class DestinationInitial extends DestinationState {}

class DestinationLoading extends DestinationState {}

class DestinationsLoaded extends DestinationState {
  final List<Map<String, dynamic>> destinations;
  final List<Map<String, dynamic>> popularDestinations;
  final List<Map<String, dynamic>> recommendedDestinations;
  final List<Map<String, dynamic>> nearbyDestinations;
  final Map<int, bool> favorites;

  const DestinationsLoaded({
    required this.destinations,
    required this.popularDestinations,
    required this.recommendedDestinations,
    required this.nearbyDestinations,
    this.favorites = const {},
  });

  @override
  List<Object?> get props => [
        destinations,
        popularDestinations,
        recommendedDestinations,
        nearbyDestinations,
        favorites,
      ];

  DestinationsLoaded copyWith({
    List<Map<String, dynamic>>? destinations,
    List<Map<String, dynamic>>? popularDestinations,
    List<Map<String, dynamic>>? recommendedDestinations,
    List<Map<String, dynamic>>? nearbyDestinations,
    Map<int, bool>? favorites,
  }) {
    return DestinationsLoaded(
      destinations: destinations ?? this.destinations,
      popularDestinations: popularDestinations ?? this.popularDestinations,
      recommendedDestinations:
          recommendedDestinations ?? this.recommendedDestinations,
      nearbyDestinations: nearbyDestinations ?? this.nearbyDestinations,
      favorites: favorites ?? this.favorites,
    );
  }
}

class DestinationError extends DestinationState {
  final String message;

  const DestinationError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class DestinationBloc extends Bloc<DestinationEvent, DestinationState> {
  final DestinationRepository _destinationRepository;
  final LocationService _locationService = LocationService();

  DestinationBloc(this._destinationRepository) : super(DestinationInitial()) {
    on<LoadDestinations>(_onLoadDestinations);
    on<LoadPopularDestinations>(_onLoadPopularDestinations);
    on<LoadRecommendedDestinations>(_onLoadRecommendedDestinations);
    on<LoadNearbyDestinations>(_onLoadNearbyDestinations);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<LoadFavoritesEvent>(_onLoadFavorites);
  }

  Future<void> _onLoadDestinations(
    LoadDestinations event,
    Emitter<DestinationState> emit,
  ) async {
    emit(DestinationLoading());
    try {
      // Use Future.wait to load all data in parallel instead of sequentially
      final position = await _locationService.getCurrentPosition();

      final results = await Future.wait([
        _destinationRepository.getDestinations(),
        _destinationRepository.getPopularDestinations(),
        _destinationRepository.getRecommendedDestinations(),
        _destinationRepository.getNearbyDestinations(
          latitude: position?.latitude,
          longitude: position?.longitude,
        ),
      ]);

      emit(DestinationsLoaded(
        destinations: results[0],
        popularDestinations: results[1],
        recommendedDestinations: results[2],
        nearbyDestinations: results[3],
        favorites: {}, // Initialize with empty favorites map
      ));
    } catch (e) {
      emit(DestinationError(e.toString()));
    }
  }

  Future<void> _onLoadPopularDestinations(
    LoadPopularDestinations event,
    Emitter<DestinationState> emit,
  ) async {
    if (state is DestinationsLoaded) {
      try {
        final popularDestinations =
            await _destinationRepository.getPopularDestinations();
        emit((state as DestinationsLoaded).copyWith(
          popularDestinations: popularDestinations,
        ));
      } catch (e) {
        emit(DestinationError(e.toString()));
      }
    }
  }

  Future<void> _onLoadRecommendedDestinations(
    LoadRecommendedDestinations event,
    Emitter<DestinationState> emit,
  ) async {
    if (state is DestinationsLoaded) {
      try {
        final recommendedDestinations =
            await _destinationRepository.getRecommendedDestinations();
        emit((state as DestinationsLoaded).copyWith(
          recommendedDestinations: recommendedDestinations,
        ));
      } catch (e) {
        emit(DestinationError(e.toString()));
      }
    }
  }

  Future<void> _onLoadNearbyDestinations(
    LoadNearbyDestinations event,
    Emitter<DestinationState> emit,
  ) async {
    try {
      double? latitude = event.latitude;
      double? longitude = event.longitude;

      // If location not provided, try to get current location
      if (latitude == null || longitude == null) {
        Position? position = await _locationService.getCurrentPosition();
        latitude = position?.latitude;
        longitude = position?.longitude;
      }

      final nearbyDestinations =
          await _destinationRepository.getNearbyDestinations(
        latitude: latitude,
        longitude: longitude,
      );

      if (state is DestinationsLoaded) {
        // Update the existing state with new nearby destinations
        emit((state as DestinationsLoaded).copyWith(
          nearbyDestinations: nearbyDestinations,
        ));
      } else if (state is DestinationLoading) {
        // We're still loading other data, but we'll let that complete
        // The LoadDestinations handler will incorporate our results
      }
    } catch (e) {
      // Only emit error if we're in the loaded state
      if (state is DestinationsLoaded) {
        emit(DestinationError(e.toString()));
      }
    }
  }

  void _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<DestinationState> emit,
  ) {
    if (state is DestinationsLoaded) {
      final currentState = state as DestinationsLoaded;

      // Create a new map with the updated favorite status
      final newFavorites = Map<int, bool>.from(currentState.favorites);
      newFavorites[event.destinationId] = event.isFavorite;

      emit(currentState.copyWith(favorites: newFavorites));
    }
  }

  void _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<DestinationState> emit,
  ) {
    if (state is DestinationsLoaded) {
      final currentState = state as DestinationsLoaded;
      emit(currentState.copyWith(favorites: event.favorites));
    }
  }
}
