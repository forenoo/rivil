import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rivil/features/home/domain/entities/category.dart';

// Events
abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object> get props => [];
}

class CategorySelected extends CategoryEvent {
  final String categoryId;

  const CategorySelected(this.categoryId);

  @override
  List<Object> get props => [categoryId];
}

class CategoriesLoaded extends CategoryEvent {}

// States
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoriesLoadedState extends CategoryState {
  final List<Category> categories;
  final String selectedCategoryId;

  const CategoriesLoadedState({
    required this.categories,
    required this.selectedCategoryId,
  });

  @override
  List<Object> get props => [categories, selectedCategoryId];

  CategoriesLoadedState copyWith({
    List<Category>? categories,
    String? selectedCategoryId,
  }) {
    return CategoriesLoadedState(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryInitial()) {
    on<CategoriesLoaded>(_onCategoriesLoaded);
    on<CategorySelected>(_onCategorySelected);
  }

  void _onCategoriesLoaded(
    CategoriesLoaded event,
    Emitter<CategoryState> emit,
  ) {
    emit(CategoryLoading());

    // Predefined categories
    final categories = [
      const Category(id: 'pantai', name: 'Pantai', icon: Icons.beach_access),
      const Category(id: 'gunung', name: 'Gunung', icon: Icons.landscape),
      const Category(
          id: 'air_terjun', name: 'Air Terjun', icon: Icons.water_drop),
      const Category(id: 'danau', name: 'Danau', icon: Icons.water),
      const Category(id: 'goa', name: 'Goa', icon: Icons.terrain),
      const Category(
          id: 'hutan_wisata', name: 'Hutan Wisata', icon: Icons.forest),
      const Category(id: 'kebun_raya', name: 'Kebun Raya', icon: Icons.park),
      const Category(
          id: 'taman_nasional', name: 'Taman Nasional', icon: Icons.nature),
      const Category(
          id: 'agrowisata', name: 'Agrowisata', icon: Icons.agriculture),
      const Category(
          id: 'pemandian_air_panas',
          name: 'Pemandian Air Panas',
          icon: Icons.hot_tub),
      const Category(id: 'bukit', name: 'Bukit', icon: Icons.terrain),
      const Category(id: 'museum', name: 'Museum', icon: Icons.museum),
      const Category(id: 'candi', name: 'Candi', icon: Icons.account_balance),
      const Category(
          id: 'taman_hiburan', name: 'Taman Hiburan', icon: Icons.attractions),
      const Category(id: 'taman_air', name: 'Taman Air', icon: Icons.pool),
      const Category(
          id: 'kebun_binatang', name: 'Kebun Binatang', icon: Icons.pets),
      const Category(id: 'aquarium', name: 'Akuarium', icon: Icons.water),
      const Category(id: 'outbound', name: 'Outbound', icon: Icons.hiking),
      const Category(
          id: 'wahana_permainan', name: 'Wahana Permainan', icon: Icons.games),
      const Category(
          id: 'pusat_olahraga', name: 'Pusat Olahraga', icon: Icons.sports),
      const Category(
          id: 'restaurant', name: 'Restoran', icon: Icons.restaurant),
      const Category(id: 'cafe', name: 'Kafe', icon: Icons.coffee),
      const Category(id: 'mall', name: 'Mall', icon: Icons.storefront),
    ];

    // Default selected category is pantai
    emit(CategoriesLoadedState(
      categories: categories,
      selectedCategoryId: 'pantai',
    ));
  }

  void _onCategorySelected(
    CategorySelected event,
    Emitter<CategoryState> emit,
  ) {
    if (state is CategoriesLoadedState) {
      final currentState = state as CategoriesLoadedState;
      emit(currentState.copyWith(
        selectedCategoryId: event.categoryId,
      ));
    }
  }
}
