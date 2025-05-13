import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rivil/features/trip_planning/domain/models/trip_plan.dart';
import 'package:rivil/features/trip_planning/domain/repositories/trip_repository.dart';

// Events
abstract class TripSaveEvent extends Equatable {
  const TripSaveEvent();

  @override
  List<Object?> get props => [];
}

class SaveTripEvent extends TripSaveEvent {
  final TripPlan tripPlan;

  const SaveTripEvent(this.tripPlan);

  @override
  List<Object?> get props => [tripPlan];
}

class GetUserTripsEvent extends TripSaveEvent {}

class GetTripDetailsEvent extends TripSaveEvent {
  final int tripId;

  const GetTripDetailsEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class DeleteTripEvent extends TripSaveEvent {
  final int tripId;

  const DeleteTripEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

// States
abstract class TripSaveState extends Equatable {
  const TripSaveState();

  @override
  List<Object?> get props => [];
}

class TripSaveInitial extends TripSaveState {}

class TripSaveLoading extends TripSaveState {}

class TripSaveSuccess extends TripSaveState {
  final int tripId;

  const TripSaveSuccess(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class UserTripsLoaded extends TripSaveState {
  final List<Map<String, dynamic>> trips;

  const UserTripsLoaded(this.trips);

  @override
  List<Object?> get props => [trips];
}

class TripDetailsLoaded extends TripSaveState {
  final Map<String, dynamic> tripDetails;

  const TripDetailsLoaded(this.tripDetails);

  @override
  List<Object?> get props => [tripDetails];
}

class TripSaveFailure extends TripSaveState {
  final String error;

  const TripSaveFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class TripDeleteSuccess extends TripSaveState {}

// BLoC
class TripSaveBloc extends Bloc<TripSaveEvent, TripSaveState> {
  final TripRepository _repository;

  TripSaveBloc(this._repository) : super(TripSaveInitial()) {
    on<SaveTripEvent>(_onSaveTrip);
    on<GetUserTripsEvent>(_onGetUserTrips);
    on<GetTripDetailsEvent>(_onGetTripDetails);
    on<DeleteTripEvent>(_onDeleteTrip);
  }

  Future<void> _onSaveTrip(
    SaveTripEvent event,
    Emitter<TripSaveState> emit,
  ) async {
    emit(TripSaveLoading());

    try {
      final tripId = await _repository.saveTrip(event.tripPlan);
      emit(TripSaveSuccess(tripId));
    } catch (e) {
      emit(TripSaveFailure(e.toString()));
    }
  }

  Future<void> _onGetUserTrips(
    GetUserTripsEvent event,
    Emitter<TripSaveState> emit,
  ) async {
    emit(TripSaveLoading());

    try {
      final trips = await _repository.getUserTrips();
      emit(UserTripsLoaded(trips));
    } catch (e) {
      emit(TripSaveFailure(e.toString()));
    }
  }

  Future<void> _onGetTripDetails(
    GetTripDetailsEvent event,
    Emitter<TripSaveState> emit,
  ) async {
    emit(TripSaveLoading());

    try {
      final tripDetails = await _repository.getTripDetails(event.tripId);
      emit(TripDetailsLoaded(tripDetails));
    } catch (e) {
      emit(TripSaveFailure(e.toString()));
    }
  }

  Future<void> _onDeleteTrip(
    DeleteTripEvent event,
    Emitter<TripSaveState> emit,
  ) async {
    emit(TripSaveLoading());

    try {
      await _repository.deleteTrip(event.tripId);
      emit(TripDeleteSuccess());
    } catch (e) {
      emit(TripSaveFailure(e.toString()));
    }
  }
}
