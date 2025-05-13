import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/trip_request.dart';
import '../../domain/models/trip_plan.dart';
import '../../data/services/trip_planning_service.dart';

// Events
abstract class TripPlanningEvent {}

class GenerateTripPlanEvent extends TripPlanningEvent {
  final TripRequest request;

  GenerateTripPlanEvent(this.request);
}

// States
abstract class TripPlanningState {}

class TripPlanningInitial extends TripPlanningState {}

class TripPlanningLoading extends TripPlanningState {}

class TripPlanningSuccess extends TripPlanningState {
  final TripPlan tripPlan;

  TripPlanningSuccess(this.tripPlan);
}

class TripPlanningFailure extends TripPlanningState {
  final String error;

  TripPlanningFailure(this.error);
}

// BLoC
class TripPlanningBloc extends Bloc<TripPlanningEvent, TripPlanningState> {
  final TripPlanningService _service;

  TripPlanningBloc(this._service) : super(TripPlanningInitial()) {
    on<GenerateTripPlanEvent>(_onGenerateTripPlan);
  }

  Future<void> _onGenerateTripPlan(
    GenerateTripPlanEvent event,
    Emitter<TripPlanningState> emit,
  ) async {
    emit(TripPlanningLoading());

    try {
      final tripPlan = await _service.generateTripPlan(event.request);
      emit(TripPlanningSuccess(tripPlan));
    } catch (e) {
      emit(TripPlanningFailure(e.toString()));
    }
  }
}
