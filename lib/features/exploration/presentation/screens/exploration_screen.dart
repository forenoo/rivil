import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rivil/core/config/app_colors.dart';
import 'package:rivil/features/exploration/presentation/bloc/exploration_bloc.dart';
import 'package:rivil/features/exploration/presentation/screens/destination_detail_screen.dart';
import 'package:rivil/features/exploration/presentation/widgets/exploration_screen_skeleton.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rivil/widgets/slide_page_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rivil/core/services/location_service.dart';
import 'dart:async';

class ExplorationScreen extends StatefulWidget {
  const ExplorationScreen({super.key});

  @override
  State<ExplorationScreen> createState() => _ExplorationScreenState();
}

class _ExplorationScreenState extends State<ExplorationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ExplorationBloc _explorationBloc;
  StreamSubscription? _blocSubscription;

  // Filter values
  double _minRating = 0;
  String? _selectedCategory;
  SortOption? _selectedSortOption;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize favorites after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Initializing favorites and distances after frame');
      _initializeFavorites();

      // Don't calculate distances immediately - set up a listener instead
      // to wait for ExplorationLoaded state
    });

    // Set up a listener for state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<ExplorationBloc>();
      _blocSubscription = bloc.stream.listen((state) {
        if (state is ExplorationLoaded) {
          print('ExplorationLoaded state detected - calculating distances');
          _recalculateDistances();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the bloc from the context once it's available
    _explorationBloc = context.read<ExplorationBloc>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _blocSubscription?.cancel();
    super.dispose();
  }

  // Method to initialize favorites in the bloc
  Future<void> _initializeFavorites() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      // Fetch all favorites for the current user
      final response = await Supabase.instance.client
          .from('favorite_destination')
          .select('destination_id')
          .eq('user_id', currentUser.id);

      // Create a map of destination_id -> true for all favorited destinations
      final Map<int, bool> favorites = {};
      for (var item in response) {
        final destinationId = item['destination_id'] as int;
        favorites[destinationId] = true;
      }

      // Update the bloc with initial favorites
      if (_explorationBloc.state is ExplorationLoaded) {
        _explorationBloc.add(LoadFavoritesEvent(favorites));
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Method to recalculate distances for all visible destinations
  Future<void> _recalculateDistances() async {
    if (_explorationBloc.state is! ExplorationLoaded) {
      print('Distance not recalculated: state is not ExplorationLoaded');
      return;
    }

    try {
      final locationService = LocationService();
      final hasPermission = await locationService.requestLocationPermission();

      if (!hasPermission) {
        print('Distance not recalculated: no location permission');
        return;
      }

      final serviceEnabled = await locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Distance not recalculated: location service not enabled');
        return;
      }

      final position = await locationService.getCurrentPosition();
      if (position == null) {
        print('Distance not recalculated: could not get current position');
        return;
      }

      print(
          'Adding UpdateDistancesEvent with lat: ${position.latitude}, lng: ${position.longitude}');
      _explorationBloc.add(UpdateDistancesEvent(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (e) {
      print('Error recalculating distances: $e');
    }
  }

  void _onScroll() {
    if (_isBottom) {
      _explorationBloc.add(const LoadMoreDestinationsEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  void _showFilterBottomSheet(BuildContext context) {
    final explorationBloc = context.read<ExplorationBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(context, explorationBloc),
    );
  }

  Widget _buildFilterBottomSheet(
      BuildContext context, ExplorationBloc explorationBloc) {
    return BlocProvider.value(
      value: explorationBloc,
      child: BlocBuilder<ExplorationBloc, ExplorationState>(
        builder: (context, state) {
          if (state is ExplorationLoaded) {
            // Initialize filter values from state
            _minRating = state.minRating ?? 0;
            _selectedCategory = state.selectedCategory;
          }

          return StatefulBuilder(builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _minRating = 0;
                              _selectedCategory = null;
                              _selectedSortOption = null;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Sort options
                        const Text(
                          'Urutkan Berdasarkan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildSortChip(
                              context,
                              setState,
                              "Rating Tertinggi",
                              SortOption.ratingDesc,
                            ),
                            _buildSortChip(
                              context,
                              setState,
                              "Jarak Terdekat",
                              SortOption.distanceAsc,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Category filter
                        const Text(
                          'Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (state is ExplorationLoaded)
                          Wrap(
                            spacing: 8,
                            children: state.categories.map((category) {
                              final isSelected = (category == 'Semua' &&
                                      _selectedCategory == null) ||
                                  category == _selectedCategory;

                              return FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade400,
                                ),
                                backgroundColor: Colors.grey.shade50,
                                selectedColor: AppColors.jordyBlue200,
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade800,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategory =
                                          category == 'Semua' ? null : category;
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 20),

                        // Minimum rating
                        const Text(
                          'Rating Minimum',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 18,
                                  color: Colors.amber.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_minRating.toInt()}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 18,
                                  color: Colors.amber.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '5',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Slider(
                          value: _minRating,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.jordyBlue200,
                          label: '${_minRating.toInt()}',
                          onChanged: (value) {
                            setState(() {
                              _minRating = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Apply button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        explorationBloc.add(
                          FilterDestinationsEvent(
                            minRating: _minRating,
                            category: _selectedCategory,
                          ),
                        );

                        // Apply sorting if selected
                        if (_selectedSortOption != null) {
                          explorationBloc.add(
                            SortDestinationsEvent(_selectedSortOption!),
                          );
                        }

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    StateSetter setState,
    String label,
    SortOption option,
  ) {
    final isSelected = _selectedSortOption == option;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade400,
      ),
      backgroundColor: Colors.grey.shade50,
      selectedColor: AppColors.jordyBlue200,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedSortOption = selected ? option : null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ExplorationBloc, ExplorationState>(
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (query) {
                              context
                                  .read<ExplorationBloc>()
                                  .add(SearchDestinationsEvent(query));
                            },
                            decoration: InputDecoration(
                              fillColor: Colors.grey.shade100,
                              hintText: 'Cari destinasi wisata...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
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
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => _showFilterBottomSheet(context),
                          icon: Icon(
                            Icons.filter_alt,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildContent(state, context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ExplorationState state, BuildContext context) {
    if (state is ExplorationLoading) {
      return const ExplorationScreenSkeleton();
    } else if (state is ExplorationLoaded || state is ExplorationLoadingMore) {
      final destinations = state is ExplorationLoaded
          ? state.destinations
          : (state as ExplorationLoadingMore).currentDestinations;

      if (destinations.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        itemCount:
            destinations.length + (state is ExplorationLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == destinations.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final destination = destinations[index];
          return _buildDestinationCard(
            context: context,
            destination: destination,
          );
        },
      );
    } else if (state is ExplorationError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context
                    .read<ExplorationBloc>()
                    .add(const LoadExplorationEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    } else {
      return const ExplorationScreenSkeleton();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada destinasi yang ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter pencarian Anda',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard({
    required BuildContext context,
    required Map<String, dynamic> destination,
  }) {
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
          // Destination image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: destination['image_url'].toString().startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: destination['image_url'] as String,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Image.asset(
                        destination['image_url'] as String,
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
                child: BlocBuilder<ExplorationBloc, ExplorationState>(
                  buildWhen: (previous, current) {
                    if (current is ExplorationLoaded &&
                        previous is ExplorationLoaded) {
                      // Only rebuild this widget when favorites change for this destination
                      return current.favorites[destination['id']] !=
                          previous.favorites[destination['id']];
                    }
                    return false;
                  },
                  builder: (context, state) {
                    bool isFavorite = false;

                    if (state is ExplorationLoaded) {
                      isFavorite = state.favorites[destination['id']] ?? false;
                    }

                    return GestureDetector(
                      onTap: () async {
                        await _toggleFavorite(destination['id'] as int);
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey.shade700,
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Distance
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
                        destination['distance'] != null
                            ? '${((destination['distance'] as num).toDouble()).toStringAsFixed(1)} km'
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
              // Rating
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
              // Category badge
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
                    destination['category'] as String,
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
                  destination['name'] as String,
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
                        destination['address'] != null
                            ? destination['address'] as String
                            : 'No location data',
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
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        child: DestinationDetailScreen(
                          destinationId: destination['id'] as int,
                        ),
                      ),
                    );
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
                        fontWeight: FontWeight.bold,
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

  // Method to toggle favorite status for a destination
  Future<void> _toggleFavorite(int destinationId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    // Get current favorite status from bloc
    bool isFavorited = false;
    if (_explorationBloc.state is ExplorationLoaded) {
      final state = _explorationBloc.state as ExplorationLoaded;
      isFavorited = state.favorites[destinationId] ?? false;
    }

    if (isFavorited) {
      // Delete the favorite entry
      await Supabase.instance.client
          .from('favorite_destination')
          .delete()
          .eq('user_id', currentUser.id)
          .eq('destination_id', destinationId);

      // Update bloc state
      _explorationBloc.add(ToggleFavoriteEvent(
        destinationId: destinationId,
        isFavorite: false,
      ));
    } else {
      // Create a new favorite entry
      await Supabase.instance.client
          .from('favorite_destination')
          .insert({'user_id': currentUser.id, 'destination_id': destinationId});

      // Update bloc state
      _explorationBloc.add(ToggleFavoriteEvent(
        destinationId: destinationId,
        isFavorite: true,
      ));
    }
  }

  Color _getRatingIconColor(Map<String, dynamic> destination) {
    final destinationType = destination['type'] as String? ?? 'added_by_google';

    // Use amber color for user-added destinations, primary color for Google destinations
    if (destinationType == 'added_by_user') {
      return Colors.amber.shade600;
    } else {
      return AppColors.primary;
    }
  }

  String _getRatingText(Map<String, dynamic> destination) {
    final destinationType = destination['type'] as String? ?? 'added_by_google';

    // For user-added destinations, show app rating if available
    if (destinationType == 'added_by_user' &&
        destination['app_rating_average'] != null) {
      final appRating = destination['app_rating_average'] as double?;
      return appRating != null ? appRating.toStringAsFixed(1) : '0.0';
    }
    // Otherwise show Google rating
    else {
      final rating = (destination['rating'] as num?)?.toDouble() ?? 0.0;
      return rating.toStringAsFixed(1);
    }
  }
}
