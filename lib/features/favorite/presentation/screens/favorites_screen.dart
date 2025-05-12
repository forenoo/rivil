import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rivil/core/config/app_colors.dart';
import 'package:rivil/features/exploration/presentation/screens/destination_detail_screen.dart';
import 'package:rivil/features/favorite/domain/model/favorite_destination.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_bloc.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_event.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_state.dart';
import 'package:rivil/features/favorite/presentation/widgets/empty_favorites.dart';
import 'package:rivil/features/favorite/presentation/widgets/favorite_destination_card.dart';

enum SortCategory {
  name,
  rating,
  price,
  distance,
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<FavoriteDestination> _visibleItems = [];
  bool _isGridView = true;
  SortCategory _currentSortCategory = SortCategory.name;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    context.read<FavoritesBloc>().add(LoadFavorites());
  }

  void _navigateToDetail(Map<String, dynamic> destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationDetailScreen(
          destination: destination,
        ),
      ),
    );
  }

  void _showSortOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  Widget _buildSortBottomSheet() {
    final theme = Theme.of(context);

    // Create local variables to track selection without immediately applying
    SortCategory selectedCategory = _currentSortCategory;
    bool selectedAscending = _isAscending;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Urutkan Berdasarkan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              _buildSortCategoryRow(
                title: 'Nama',
                icon: Icons.sort_by_alpha,
                category: SortCategory.name,
                selectedCategory: selectedCategory,
                isAscending: selectedCategory == SortCategory.name
                    ? selectedAscending
                    : true,
                ascendingText: 'A-Z',
                descendingText: 'Z-A',
                onCategorySelected: () {
                  setSheetState(() {
                    selectedCategory = SortCategory.name;
                  });
                },
                onDirectionChanged: (isAsc) {
                  setSheetState(() {
                    selectedAscending = isAsc;
                  });
                },
              ),
              _buildSortCategoryRow(
                title: 'Rating',
                icon: Icons.star,
                category: SortCategory.rating,
                selectedCategory: selectedCategory,
                isAscending: selectedCategory == SortCategory.rating
                    ? selectedAscending
                    : false,
                ascendingText: 'Terendah',
                descendingText: 'Tertinggi',
                onCategorySelected: () {
                  setSheetState(() {
                    selectedCategory = SortCategory.rating;
                  });
                },
                onDirectionChanged: (isAsc) {
                  setSheetState(() {
                    selectedAscending = isAsc;
                  });
                },
              ),
              _buildSortCategoryRow(
                title: 'Harga',
                icon: Icons.attach_money,
                category: SortCategory.price,
                selectedCategory: selectedCategory,
                isAscending: selectedCategory == SortCategory.price
                    ? selectedAscending
                    : true,
                ascendingText: 'Termurah',
                descendingText: 'Termahal',
                onCategorySelected: () {
                  setSheetState(() {
                    selectedCategory = SortCategory.price;
                  });
                },
                onDirectionChanged: (isAsc) {
                  setSheetState(() {
                    selectedAscending = isAsc;
                  });
                },
              ),
              _buildSortCategoryRow(
                title: 'Jarak',
                icon: Icons.place,
                category: SortCategory.distance,
                selectedCategory: selectedCategory,
                isAscending: selectedCategory == SortCategory.distance
                    ? selectedAscending
                    : true,
                ascendingText: 'Terdekat',
                descendingText: 'Terjauh',
                onCategorySelected: () {
                  setSheetState(() {
                    selectedCategory = SortCategory.distance;
                  });
                },
                onDirectionChanged: (isAsc) {
                  setSheetState(() {
                    selectedAscending = isAsc;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentSortCategory = selectedCategory;
                      _isAscending = selectedAscending;
                    });
                    Navigator.pop(context);
                    _sortFavorites();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortCategoryRow({
    required String title,
    required IconData icon,
    required SortCategory category,
    required SortCategory selectedCategory,
    required bool isAscending,
    required String ascendingText,
    required String descendingText,
    required VoidCallback onCategorySelected,
    required Function(bool) onDirectionChanged,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Category selection
          Expanded(
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: onCategorySelected,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected ? AppColors.primary : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Direction buttons (only visible for selected category)
          if (isSelected)
            Row(
              children: [
                _buildDirectionButton(
                  isActive: isAscending,
                  text: ascendingText,
                  icon: Icons.arrow_upward,
                  onTap: () => onDirectionChanged(true),
                ),
                const SizedBox(width: 8),
                _buildDirectionButton(
                  isActive: !isAscending,
                  text: descendingText,
                  icon: Icons.arrow_downward,
                  onTap: () => onDirectionChanged(false),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton({
    required bool isActive,
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.jordyBlue100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withOpacity(0.3)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.primary : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _sortFavorites() {
    // Sort based on category and direction
    switch (_currentSortCategory) {
      case SortCategory.name:
        if (_isAscending) {
          _visibleItems.sort((a, b) => a.name.compareTo(b.name));
        } else {
          _visibleItems.sort((a, b) => b.name.compareTo(a.name));
        }
        break;
      case SortCategory.rating:
        if (_isAscending) {
          _visibleItems.sort((a, b) => a.rating.compareTo(b.rating));
        } else {
          _visibleItems.sort((a, b) => b.rating.compareTo(a.rating));
        }
        break;
      case SortCategory.price:
        if (_isAscending) {
          _visibleItems.sort((a, b) => a.price.compareTo(b.price));
        } else {
          _visibleItems.sort((a, b) => b.price.compareTo(a.price));
        }
        break;
      case SortCategory.distance:
        if (_isAscending) {
          _visibleItems.sort((a, b) => a.distance.compareTo(b.distance));
        } else {
          _visibleItems.sort((a, b) => b.distance.compareTo(a.distance));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: BlocBuilder<FavoritesBloc, FavoritesState>(
                builder: (context, state) {
                  if (state is FavoritesLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is FavoritesLoaded) {
                    if (state.favorites.isEmpty) {
                      return EmptyFavorites(
                        onExplore: () {
                          // Navigate to exploration screen
                        },
                      );
                    }

                    _visibleItems.clear();
                    _visibleItems.addAll(state.favorites);
                    _sortFavorites();

                    return _isGridView
                        ? _buildGridView(theme)
                        : _buildListView(theme);
                  }

                  if (state is FavoritesError) {
                    return Center(
                      child: Text(
                        'Terjadi kesalahan saat memuat favorit',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                    hintText: 'Cari destinasi favoritmu...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (query) {
                    // Filter favorites
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortOptionsBottomSheet,
                  color: AppColors.primary,
                  tooltip: 'Urutkan',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  color: AppColors.primary,
                  tooltip: _isGridView ? 'Tampilan list' : 'Tampilan grid',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _visibleItems.length,
      itemBuilder: (context, index) {
        final destination = _visibleItems[index];
        return FavoriteDestinationCard(
          destination: destination,
          onTap: () => _navigateToDetail(destination.toMap()),
          onFavoriteToggle: () {
            context.read<FavoritesBloc>().add(
                  RemoveFromFavorites(destination.name),
                );
          },
        );
      },
    );
  }

  Widget _buildListView(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _visibleItems.length,
      itemBuilder: (context, index) {
        final destination = _visibleItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToDetail(destination.toMap()),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        destination.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  destination.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    fontSize: 17,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  context.read<FavoritesBloc>().add(
                                        RemoveFromFavorites(destination.name),
                                      );
                                },
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  destination.location,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.jordyBlue100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  destination.category,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                destination.rating.toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rp${destination.price.toInt()}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
