import 'package:flutter/material.dart';
import 'package:rivil/features/exploration/domain/models/destination_detail_model.dart';
import 'package:rivil/features/exploration/domain/models/destination_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rivil/widgets/slide_page_route.dart';
import 'package:rivil/features/add_destination/presentation/screens/add_destination_screen.dart';
import 'package:rivil/features/exploration/presentation/screens/destination_detail_screen.dart';

class UserDestinationsScreen extends StatefulWidget {
  const UserDestinationsScreen({super.key});

  @override
  State<UserDestinationsScreen> createState() => _UserDestinationsScreenState();
}

class _UserDestinationsScreenState extends State<UserDestinationsScreen> {
  List<DestinationDetailModel> _destinations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserDestinations();
  }

  Future<void> _fetchUserDestinations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Anda perlu login untuk melihat destinasi Anda';
          _isLoading = false;
        });
        return;
      }

      // Fetch user's destinations
      final response = await Supabase.instance.client
          .from('destination')
          .select('*, categories:category_id(name)')
          .eq('added_by', user.id)
          .eq('type', 'added_by_user')
          .order('created_at', ascending: false);

      // Get destination IDs for fetching ratings
      final List<int> destinationIds =
          response.map<int>((item) => item['id'] as int).toList();

      // Fetch app ratings for these destinations
      Map<int, Map<String, dynamic>> appRatings = {};

      if (destinationIds.isNotEmpty) {
        // Fetch all ratings for the user's destinations
        final ratingsResponse = await Supabase.instance.client
            .from('destination_rating')
            .select('destination_id, rating')
            .filter('destination_id', 'in', '(${destinationIds.join(",")})');

        // Group ratings by destination
        final Map<int, List<dynamic>> ratingsByDestination = {};
        for (var rating in ratingsResponse) {
          final destId = rating['destination_id'] as int;
          ratingsByDestination[destId] ??= [];
          ratingsByDestination[destId]!.add(rating);
        }

        // Calculate average and count for each destination
        for (var destId in destinationIds) {
          final ratings = ratingsByDestination[destId] ?? [];
          final ratingSum = ratings.fold<int>(
              0, (sum, rating) => sum + (rating['rating'] as int? ?? 0));
          final average = ratings.isEmpty ? 0.0 : ratingSum / ratings.length;

          appRatings[destId] = {
            'average': average,
            'count': ratings.length,
          };
        }
      }

      // Create destination models with the correct data
      final destinations = response.map((data) {
        // Extract category name from the joined table
        final categoryName = data['categories'] != null
            ? data['categories']['name'] as String?
            : null;

        // Merge category name into the destination data
        final destinationData = Map<String, dynamic>.from(data);
        destinationData['category'] = categoryName;

        // Get app rating data for this destination
        final destId = data['id'] as int;
        final double appRatingAverage;
        final int appRatingCount;

        if (appRatings.containsKey(destId)) {
          appRatingAverage = appRatings[destId]!['average'];
          appRatingCount = appRatings[destId]!['count'];
        } else {
          appRatingAverage = 0.0;
          appRatingCount = 0;
        }

        // Create the model with app rating data
        return DestinationDetailModel.fromMap(
          destinationData,
          appRatingAverage: appRatingAverage,
          appRatingCount: appRatingCount,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _destinations = destinations as List<DestinationDetailModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat destinasi: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Destinasi Yang Anda Tambahkan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        foregroundColor: colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: _destinations.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddDestination,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchUserDestinations,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : _buildDestinationsList(context),
      ),
    );
  }

  void _navigateToAddDestination() {
    // Navigate to add destination screen
    Navigator.push(
      context,
      SlidePageRoute(
        child: const AddDestinationScreen(),
      ),
    ).then((_) => _fetchUserDestinations());
  }

  Widget _buildDestinationsList(BuildContext context) {
    if (_destinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place_outlined,
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada destinasi tersimpan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan tempat menarik yang Anda temukan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddDestination,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Destinasi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUserDestinations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _destinations.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final destination = _destinations[index];
          return _buildDestinationCard(
            context: context,
            destination: destination,
          );
        },
      ),
    );
  }

  // Helper method to get rating color based on destination type
  Color _getRatingIconColor(DestinationDetailModel destination) {
    return destination.type == DestinationType.added_by_user
        ? Colors.amber.shade600
        : Theme.of(context).colorScheme.primary;
  }

  // Helper method to get the appropriate rating text based on destination type
  String _getRatingText(DestinationDetailModel destination) {
    if (destination.type == DestinationType.added_by_user) {
      final rating = destination.appRatingAverage ?? 0.0;
      return rating.toStringAsFixed(1);
    } else {
      return destination.rating.toStringAsFixed(1);
    }
  }

  // Helper method to get the appropriate rating count based on destination type
  int _getRatingCount(DestinationDetailModel destination) {
    return destination.type == DestinationType.added_by_user
        ? destination.appRatingCount
        : destination.ratingCount;
  }

  Widget _buildDestinationCard({
    required BuildContext context,
    required DestinationDetailModel destination,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fallbackImage = 'assets/images/avatar_fallback.png';

    // Rating properties
    final ratingColor = _getRatingIconColor(destination);
    final ratingText = _getRatingText(destination);
    final ratingCount = _getRatingCount(destination);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              SlidePageRoute(
                child: DestinationDetailScreen(
                  destinationId: destination.id,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination image
              _buildDestinationImage(destination, fallbackImage),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    _buildCategoryBadge(destination, colorScheme),
                    const SizedBox(height: 8),
                    // Destination name
                    Text(
                      destination.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Location
                    _buildLocationInfo(destination, theme),
                    const SizedBox(height: 8),
                    // Rating
                    _buildRatingInfo(
                        ratingColor, ratingText, ratingCount, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for destination card components

  Widget _buildDestinationImage(
      DestinationDetailModel destination, String fallbackImage) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: destination.imageUrl != null && destination.imageUrl!.isNotEmpty
            ? Image.network(
                destination.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    fallbackImage,
                    fit: BoxFit.cover,
                  );
                },
              )
            : Image.asset(
                fallbackImage,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildCategoryBadge(
      DestinationDetailModel destination, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        destination.category ?? 'Lainnya',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildLocationInfo(
      DestinationDetailModel destination, ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.place_outlined,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            destination.address ?? 'Lokasi tidak tersedia',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingInfo(
      Color ratingColor, String ratingText, int ratingCount, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: ratingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 16,
            color: ratingColor,
          ),
          const SizedBox(width: 4),
          Text(
            ratingText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: ratingColor,
            ),
          ),
          if (ratingCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '($ratingCount)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ratingColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
