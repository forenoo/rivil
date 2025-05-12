import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rivil/features/add_destination/domain/repository/destination_add_repository.dart';

// Events
abstract class AddDestinationEvent extends Equatable {
  const AddDestinationEvent();

  @override
  List<Object?> get props => [];
}

class FetchCategoriesEvent extends AddDestinationEvent {}

class SubmitDestinationEvent extends AddDestinationEvent {
  final String name;
  final int categoryId;
  final String description;
  final String address;
  final String latitude;
  final String longitude;
  final double rating;
  final String? imagePath;

  const SubmitDestinationEvent({
    required this.name,
    required this.categoryId,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    this.imagePath,
  });

  @override
  List<Object?> get props => [
        name,
        categoryId,
        description,
        address,
        latitude,
        longitude,
        rating,
        imagePath
      ];
}

class ResetAddDestinationStateEvent extends AddDestinationEvent {}

// States
abstract class AddDestinationState extends Equatable {
  const AddDestinationState();

  @override
  List<Object?> get props => [];
}

class AddDestinationInitial extends AddDestinationState {}

class AddDestinationLoading extends AddDestinationState {}

class AddDestinationSuccess extends AddDestinationState {}

class AddDestinationFailure extends AddDestinationState {
  final String error;

  const AddDestinationFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class CategoriesLoading extends AddDestinationState {}

class CategoriesLoaded extends AddDestinationState {
  final List<Map<String, dynamic>> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class CategoriesLoadFailure extends AddDestinationState {
  final String error;

  const CategoriesLoadFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// Bloc
class AddDestinationBloc
    extends Bloc<AddDestinationEvent, AddDestinationState> {
  final DestinationAddRepository _repository;

  AddDestinationBloc(this._repository) : super(AddDestinationInitial()) {
    on<SubmitDestinationEvent>(_onSubmitDestination);
    on<ResetAddDestinationStateEvent>(_onResetState);
    on<FetchCategoriesEvent>(_onFetchCategories);
  }

  Future<void> _onFetchCategories(
    FetchCategoriesEvent event,
    Emitter<AddDestinationState> emit,
  ) async {
    emit(CategoriesLoading());

    try {
      final categories = await _repository.getCategories();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(CategoriesLoadFailure(e.toString()));
    }
  }

  Future<void> _onSubmitDestination(
    SubmitDestinationEvent event,
    Emitter<AddDestinationState> emit,
  ) async {
    emit(AddDestinationLoading());

    try {
      final success = await _repository.addDestination(
        name: event.name,
        categoryId: event.categoryId,
        description: event.description,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
        rating: event.rating,
        imageUrl: event.imagePath,
      );

      if (success) {
        emit(AddDestinationSuccess());
      } else {
        emit(const AddDestinationFailure('Failed to add destination'));
      }
    } catch (e) {
      emit(AddDestinationFailure(e.toString()));
    }
  }

  void _onResetState(
    ResetAddDestinationStateEvent event,
    Emitter<AddDestinationState> emit,
  ) {
    emit(AddDestinationInitial());
  }
}
