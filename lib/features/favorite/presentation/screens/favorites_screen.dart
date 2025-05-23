import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rivil/app.dart';
import 'package:rivil/core/config/app_colors.dart';
import 'package:rivil/features/exploration/presentation/screens/destination_detail_screen.dart';
import 'package:rivil/features/favorite/domain/model/favorite_destination.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_bloc.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_event.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_state.dart';
import 'package:rivil/features/favorite/presentation/widgets/empty_favorites.dart';
import 'package:rivil/features/favorite/presentation/widgets/favorite_screen_skeleton.dart';
import 'package:rivil/widgets/slide_page_route.dart';

enum SortCategory {
  name,
  rating,
  distance,
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  SortCategory _currentSortCategory = SortCategory.name;
  bool _isAscending = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<FavoritesBloc>().add(LoadFavorites());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToDetail(Map<String, dynamic> destination) {
    Navigator.push(
      context,
      SlidePageRoute(
        child: DestinationDetailScreen(
          destinationId: destination['destination_id'],
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

    SortCategory selectedCategory = _currentSortCategory;
    bool selectedAscending = _isAscending;

    return SafeArea(
      child: StatefulBuilder(
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
                      // Reload the state to trigger sorting
                      context.read<FavoritesBloc>().add(LoadFavorites());
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
      ),
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

  List<FavoriteDestination> _sortFavorites(List<FavoriteDestination> items) {
    // Sort based on category and direction without setState
    List<FavoriteDestination> sortedItems = List.from(items);

    switch (_currentSortCategory) {
      case SortCategory.name:
        if (_isAscending) {
          sortedItems.sort((a, b) => a.name.compareTo(b.name));
        } else {
          sortedItems.sort((a, b) => b.name.compareTo(a.name));
        }
        break;
      case SortCategory.rating:
        if (_isAscending) {
          sortedItems.sort((a, b) => a.rating.compareTo(b.rating));
        } else {
          sortedItems.sort((a, b) => b.rating.compareTo(a.rating));
        }
        break;
      case SortCategory.distance:
        if (_isAscending) {
          sortedItems.sort((a, b) => a.distance.compareTo(b.distance));
        } else {
          sortedItems.sort((a, b) => b.distance.compareTo(a.distance));
        }
        break;
    }

    return sortedItems;
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
                    return const FavoriteScreenSkeleton();
                  }

                  if (state is FavoritesLoaded) {
                    if (state.favorites.isEmpty) {
                      return EmptyFavorites(
                        onExplore: () {
                          // Navigate to the exploration tab (index 1)
                          mainNavigationKey.currentState?.navigateToTab(1);
                        },
                      );
                    }

                    final itemsToDisplay = _searchQuery.isEmpty
                        ? state.favorites
                        : state.filteredFavorites;
                    final sortedItems = _sortFavorites(itemsToDisplay);

                    return _buildSingleColumnGridView(theme, sortedItems);
                  }

                  if (state is FavoritesError) {
                    return Center(
                      child: Text(
                        'Terjadi kesalahan saat memuat favorit: ${state.message}',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return const FavoriteScreenSkeleton();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                    filled: true,
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
                    setState(() {
                      _searchQuery = query;
                    });
                    context.read<FavoritesBloc>().add(SearchFavorites(query));
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleColumnGridView(
      ThemeData theme, List<FavoriteDestination> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final destination = items[index];
        return _buildFavoriteDestinationCard(context, destination);
      },
    );
  }

  Widget _buildFavoriteDestinationCard(
      BuildContext context, FavoriteDestination destination) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: destination.imageUrl.startsWith('http')
                    ? Image.network(
                        destination.imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Image.asset(
                        destination.imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () {
                      context.read<FavoritesBloc>().add(
                            RemoveFromFavorites(destination.destinationId),
                          );
                      // Reload favorites after removal
                      Future.delayed(const Duration(milliseconds: 300), () {
                        context.read<FavoritesBloc>().add(LoadFavorites());
                      });
                    },
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.near_me,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        destination.distance != null
                            ? '${destination.distance.toStringAsFixed(1)} km'
                            : 'Calculating...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: _getRatingIconColor(destination),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getRatingText(destination),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    destination.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        destination.location,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    _navigateToDetail(destination.toMap());
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingIconColor(FavoriteDestination destination) {
    // If you have a type field, adjust this logic accordingly
    // For now, use amber for all
    return Colors.amber.shade600;
  }

  String _getRatingText(FavoriteDestination destination) {
    // If you have app_rating_average, use it, else fallback to rating
    return destination.rating.toStringAsFixed(1);
  }
}
