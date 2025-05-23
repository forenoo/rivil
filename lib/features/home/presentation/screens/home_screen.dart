import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rivil/app.dart';
import 'package:rivil/core/config/app_colors.dart';
import 'package:rivil/core/services/location_service.dart';
import 'package:rivil/features/auth/data/models/user_profile_model.dart';
import 'package:rivil/features/exploration/presentation/screens/destination_detail_screen.dart';
import 'package:rivil/features/home/presentation/bloc/destination_bloc.dart';
import 'package:rivil/features/home/presentation/widgets/home_skeleton_loader.dart';
import 'package:rivil/features/trip_planning/presentation/screens/trip_planner_screen.dart';
import 'package:rivil/widgets/custom_snackbar.dart';
import 'package:rivil/widgets/slide_page_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  UserProfileModel? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();

    // Load all data and request permissions sequentially for better initial experience
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Load destinations and user data in parallel
    await Future.wait([
      () async {
        // Load destinations first
        context.read<DestinationBloc>().add(LoadDestinations());
      }(),
      _loadUserProfile(),
      _loadFavorites(),
    ]);

    // After initial data is loaded, request location and update nearby destinations
    _requestLocationPermission();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final response = await Supabase.instance.client
            .from('user_profile')
            .select()
            .eq('user_id', currentUser.id)
            .single();

        if (mounted) {
          setState(() {
            _userProfile = UserProfileModel.fromJson(response);
            _isLoadingProfile = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    bool hasPermission = await _locationService.requestLocationPermission();

    if (hasPermission) {
      Position? position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        if (context.read<DestinationBloc>().state is DestinationsLoaded) {
          context.read<DestinationBloc>().add(
                LoadNearbyDestinations(
                  latitude: position.latitude,
                  longitude: position.longitude,
                ),
              );
        } else {
          context.read<DestinationBloc>().add(LoadDestinations());
        }
      }
    }
  }

  bool _isDestinationFavorited(int destinationId) {
    final state = context.read<DestinationBloc>().state;
    if (state is DestinationsLoaded) {
      return state.favorites[destinationId] ?? false;
    }
    return false;
  }

  Future<void> _toggleFavorite(int destinationId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final isFavorited = _isDestinationFavorited(destinationId);

    context.read<DestinationBloc>().add(
          ToggleFavoriteEvent(
            destinationId: destinationId,
            isFavorite: !isFavorited,
          ),
        );

    try {
      if (isFavorited) {
        await Supabase.instance.client
            .from('favorite_destination')
            .delete()
            .eq('user_id', currentUser.id)
            .eq('destination_id', destinationId);
      } else {
        await Supabase.instance.client.from('favorite_destination').insert(
            {'user_id': currentUser.id, 'destination_id': destinationId});
      }
    } catch (e) {
      // If the database operation fails, revert the UI change
      context.read<DestinationBloc>().add(
            ToggleFavoriteEvent(
              destinationId: destinationId,
              isFavorite: isFavorited,
            ),
          );

      // Show error message if needed
      CustomSnackbar.show(
        context: context,
        message: 'Failed to update favorite status',
        type: SnackbarType.error,
      );
    }
  }

  // Load all user's favorites at once
  Future<void> _loadFavorites() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      final response = await Supabase.instance.client
          .from('favorite_destination')
          .select()
          .eq('user_id', currentUser.id);

      final Map<int, bool> favorites = {};
      for (var favorite in response) {
        favorites[favorite['destination_id']] = true;
      }

      // Update BLoC with all favorites
      context.read<DestinationBloc>().add(LoadFavoritesEvent(favorites));
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DestinationBloc, DestinationState>(
          builder: (context, state) {
            if (state is DestinationLoading) {
              // Use cached destinations while loading new data
              final DestinationsLoaded? cachedState = context
                      .read<DestinationBloc>()
                      .state is DestinationsLoaded
                  ? context.read<DestinationBloc>().state as DestinationsLoaded
                  : null;

              if (cachedState != null) {
                // Return the UI with cached data but show a loading indicator at the top
                return Stack(
                  children: [
                    _buildHomeContent(context, cachedState),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        backgroundColor: colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ],
                );
              }

              // If no cached data is available, show the skeleton loader
              return const HomeSkeletonLoader();
            }

            if (state is DestinationError) {
              return Center(
                child: Text('Error: ${state.message}'),
              );
            }

            if (state is DestinationsLoaded) {
              return _buildHomeContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, DestinationsLoaded state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        // Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.8),
                colorScheme.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoadingProfile
                            ? 'Memuat...'
                            : 'Halo, ${_userProfile?.fullName ?? _userProfile?.username ?? 'pengguna'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        'Mau berpetualang?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      mainNavigationKey.currentState?.navigateToTab(3);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: _userProfile?.avatarUrl != null &&
                                  _userProfile!.avatarUrl!.isNotEmpty
                              ? NetworkImage(_userProfile!.avatarUrl!)
                                  as ImageProvider
                              : const AssetImage(
                                  'assets/images/avatar_fallback.png',
                                ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        SlidePageRoute(
                          child: const TripPlannerScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Buat rencana perjalananmu',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Popular Destinations
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Destinasi Populer',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: state.popularDestinations.length,
            itemBuilder: (context, index) {
              final destination = state.popularDestinations[index];
              return _buildDestinationCard(
                context: context,
                destination: destination,
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Recommended For You
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.thumb_up_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Rekomendasi Untukmu',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: state.recommendedDestinations.length,
            itemBuilder: (context, index) {
              final destination = state.recommendedDestinations[index];
              return _buildDestinationCard(
                context: context,
                destination: destination,
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Nearby Destinations
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.near_me,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Destinasi Terdekat',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              state.nearbyDestinations.isEmpty
                  ? _buildEmptyNearbyState(context)
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.nearbyDestinations.length,
                      itemBuilder: (context, index) {
                        final destination = state.nearbyDestinations[index];
                        return _buildNearbyPlace(
                          context: context,
                          destination: destination,
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyNearbyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Lokasi tidak tersedia',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aktifkan lokasi untuk melihat destinasi terdekat',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _requestLocationPermission,
            icon: const Icon(Icons.location_on, size: 16),
            label: const Text('Aktifkan Lokasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
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
    final name = destination['name'] as String? ?? '';
    final location = destination['address'] as String? ?? '';
    final rating = destination['rating'] as double? ?? 0.0;
    final destinationId = destination['id'] as int;
    final imageUrl = destination['image_url'] as String?;
    final destinationType = destination['type'] as String? ?? 'added_by_google';

    // Determine which rating to display based on type
    bool isUserAdded = destinationType == 'added_by_user';
    double displayRating = rating;

    // For user-added destinations, we'll show app rating if available
    if (isUserAdded && destination['app_rating_average'] != null) {
      displayRating = destination['app_rating_average'] as double? ?? 0.0;
    }

    return GestureDetector(
      onTap: () {
        _navigateToDetail(destination);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 140,
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 140,
                            width: 200,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 140,
                          width: 200,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                ),
                // Favorite button
                Positioned(
                  top: 12,
                  right: 12,
                  child: BlocBuilder<DestinationBloc, DestinationState>(
                    buildWhen: (previous, current) {
                      if (previous is DestinationsLoaded &&
                          current is DestinationsLoaded) {
                        // Only rebuild if the favorite status for this destination has changed
                        return previous.favorites[destinationId] !=
                            current.favorites[destinationId];
                      }
                      return true;
                    },
                    builder: (context, state) {
                      final isFavorite = state is DestinationsLoaded
                          ? (state.favorites[destinationId] ?? false)
                          : false;

                      return GestureDetector(
                        onTap: () {
                          _toggleFavorite(destinationId);
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color:
                                isFavorite ? Colors.red : Colors.grey.shade700,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Rating
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: isUserAdded
                              ? Colors.amber.shade600
                              : colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayRating.toString(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyPlace({
    required BuildContext context,
    required Map<String, dynamic> destination,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = destination['name'] as String? ?? '';
    final location = destination['address'] as String? ?? '';
    final distance = '${destination['distance']} km';
    final imageUrl = destination['image_url'] as String?;
    final destinationType = destination['type'] as String? ?? 'added_by_google';

    // Determine which rating to display based on type
    bool isUserAdded = destinationType == 'added_by_user';
    double displayRating = destination['rating'] as double? ?? 0.0;

    // For user-added destinations, we'll show app rating if available
    if (isUserAdded && destination['app_rating_average'] != null) {
      displayRating = destination['app_rating_average'] as double? ?? 0.0;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _navigateToDetail(destination);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Place image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade300,
                                child:
                                    const Icon(Icons.image, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade300,
                              child:
                                  const Icon(Icons.image, color: Colors.grey),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Place info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
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
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_walk,
                                size: 12,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distance,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUserAdded
                                ? Colors.amber.withOpacity(0.1)
                                : colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: isUserAdded
                                    ? Colors.amber.shade700
                                    : colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                displayRating.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isUserAdded
                                          ? Colors.amber.shade700
                                          : colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> destination) {
    Navigator.push(
      context,
      SlidePageRoute(
        child: DestinationDetailScreen(
          destinationId: destination['id'],
        ),
      ),
    );
  }
}
