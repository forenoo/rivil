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

  const DestinationsLoaded({
    required this.destinations,
    required this.popularDestinations,
    required this.recommendedDestinations,
    required this.nearbyDestinations,
  });

  @override
  List<Object?> get props => [
        destinations,
        popularDestinations,
        recommendedDestinations,
        nearbyDestinations,
      ];

  DestinationsLoaded copyWith({
    List<Map<String, dynamic>>? destinations,
    List<Map<String, dynamic>>? popularDestinations,
    List<Map<String, dynamic>>? recommendedDestinations,
    List<Map<String, dynamic>>? nearbyDestinations,
  }) {
    return DestinationsLoaded(
      destinations: destinations ?? this.destinations,
      popularDestinations: popularDestinations ?? this.popularDestinations,
      recommendedDestinations:
          recommendedDestinations ?? this.recommendedDestinations,
      nearbyDestinations: nearbyDestinations ?? this.nearbyDestinations,
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
  }

  Future<void> _onLoadDestinations(
    LoadDestinations event,
    Emitter<DestinationState> emit,
  ) async {
    emit(DestinationLoading());
    try {
      final destinations = await _destinationRepository.getDestinations();
      final popularDestinations =
          await _destinationRepository.getPopularDestinations();
      final recommendedDestinations =
          await _destinationRepository.getRecommendedDestinations();

      // Get user's current location for nearby destinations
      Position? position = await _locationService.getCurrentPosition();
      final nearbyDestinations =
          await _destinationRepository.getNearbyDestinations(
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      emit(DestinationsLoaded(
        destinations: destinations,
        popularDestinations: popularDestinations,
        recommendedDestinations: recommendedDestinations,
        nearbyDestinations: nearbyDestinations,
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
    if (state is DestinationsLoaded) {
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

        emit((state as DestinationsLoaded).copyWith(
          nearbyDestinations: nearbyDestinations,
        ));
      } catch (e) {
        emit(DestinationError(e.toString()));
      }
    }
  }
}
