import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rivil/features/profile/data/models/saved_trip.dart';
import 'package:rivil/features/profile/data/repositories/saved_trips_repository.dart';

// Events
abstract class SavedTripsEvent extends Equatable {
  const SavedTripsEvent();

  @override
  List<Object?> get props => [];
}

class FetchSavedTripsEvent extends SavedTripsEvent {
  const FetchSavedTripsEvent();
}

class FetchSavedTripDetailEvent extends SavedTripsEvent {
  final int tripId;

  const FetchSavedTripDetailEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class DeleteSavedTripEvent extends SavedTripsEvent {
  final int tripId;

  const DeleteSavedTripEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

// States
abstract class SavedTripsState extends Equatable {
  const SavedTripsState();

  @override
  List<Object?> get props => [];
}

class SavedTripsInitial extends SavedTripsState {}

class SavedTripsLoading extends SavedTripsState {}

class SavedTripsSuccess extends SavedTripsState {
  final List<SavedTrip> trips;

  const SavedTripsSuccess(this.trips);

  @override
  List<Object?> get props => [trips];
}

class SavedTripDetailLoading extends SavedTripsState {}

class SavedTripDetailSuccess extends SavedTripsState {
  final SavedTrip trip;

  const SavedTripDetailSuccess(this.trip);

  @override
  List<Object?> get props => [trip];
}

class SavedTripsFailure extends SavedTripsState {
  final String error;

  const SavedTripsFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class SavedTripDeleteLoading extends SavedTripsState {}

class SavedTripDeleteSuccess extends SavedTripsState {}

// BLoC
class SavedTripsBloc extends Bloc<SavedTripsEvent, SavedTripsState> {
  final SavedTripsRepository repository;

  SavedTripsBloc({required this.repository}) : super(SavedTripsInitial()) {
    on<FetchSavedTripsEvent>(_onFetchSavedTrips);
    on<FetchSavedTripDetailEvent>(_onFetchSavedTripDetail);
    on<DeleteSavedTripEvent>(_onDeleteSavedTrip);
  }

  Future<void> _onFetchSavedTrips(
    FetchSavedTripsEvent event,
    Emitter<SavedTripsState> emit,
  ) async {
    emit(SavedTripsLoading());
    try {
      final trips = await repository.getSavedTrips();
      emit(SavedTripsSuccess(trips));
    } catch (e) {
      emit(SavedTripsFailure(e.toString()));
    }
  }

  Future<void> _onFetchSavedTripDetail(
    FetchSavedTripDetailEvent event,
    Emitter<SavedTripsState> emit,
  ) async {
    emit(SavedTripDetailLoading());
    try {
      final trip = await repository.getSavedTripById(event.tripId);
      emit(SavedTripDetailSuccess(trip));
    } catch (e) {
      emit(SavedTripsFailure(e.toString()));
    }
  }

  Future<void> _onDeleteSavedTrip(
    DeleteSavedTripEvent event,
    Emitter<SavedTripsState> emit,
  ) async {
    final currentState = state;
    emit(SavedTripDeleteLoading());
    try {
      await repository.deleteSavedTrip(event.tripId);
      emit(SavedTripDeleteSuccess());
      // Refetch the list after deletion
      add(const FetchSavedTripsEvent());
    } catch (e) {
      emit(SavedTripsFailure(e.toString()));
      // Restore previous state if deletion fails
      if (currentState is SavedTripsSuccess ||
          currentState is SavedTripDetailSuccess) {
        emit(currentState);
      }
    }
  }
}
