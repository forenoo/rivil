import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rivil/core/config/app_colors.dart';
import 'package:rivil/widgets/custom_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rivil/features/exploration/data/services/destination_service.dart';
import 'package:rivil/features/exploration/domain/models/destination_detail_model.dart';
import 'package:rivil/features/exploration/domain/models/destination_comment_model.dart';
import 'package:rivil/features/exploration/domain/models/destination_rating_model.dart';
import 'package:rivil/features/exploration/domain/models/destination_type.dart';
import 'package:rivil/features/exploration/presentation/widgets/destination_detail_skeleton.dart';
import 'package:shimmer/shimmer.dart';

class DestinationDetailScreen extends StatefulWidget {
  // Allow navigation by either providing a full destination object or just the ID
  final Map<String, dynamic>? destination;
  final int? destinationId;

  const DestinationDetailScreen({
    super.key,
    this.destination,
    this.destinationId,
  }) : assert(destination != null || destinationId != null,
            'Either destination or destinationId must be provided');

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  // Service instance
  final DestinationService _destinationService = DestinationService();

  // State variables
  bool _isLoading = true;
  bool _isLoadingImage = true;

  // Destination data
  late DestinationDetailModel _destination;

  // Favorite status
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

  // Comments
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  List<DestinationCommentModel> _comments = [];
  bool _isLoadingComments = true;

  // Rating related state variables
  bool _isLoadingUserRating = true;
  bool _isSubmittingRating = false;
  DestinationRatingModel? _userRating;
  DestinationRatingModel?
      _originalUserRating; // Store the original rating when editing
  int _selectedRating = 0;

  // Pagination variables for comments
  int _commentsPage = 1;
  bool _isLoadingMoreComments = false;
  bool _hasMoreComments = true;
  final int _commentsPerPage = 5;

  // Additional tracking
  late int _destinationId;

  @override
  void initState() {
    super.initState();

    // Determine destination ID from either the passed destination or the ID parameter
    _destinationId = widget.destinationId ??
        (widget.destination != null ? widget.destination!['id'] as int : 0);

    // If we already have destination data, initialize with it while loading full data
    if (widget.destination != null) {
      _destination = DestinationDetailModel.fromMap(widget.destination!);
      _isLoadingImage = false;
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // If we don't have destination data yet, or if we only have partial data
      if (widget.destination == null || widget.destinationId != null) {
        await _loadDestinationData();
      }

      await Future.wait([
        _loadFavoriteStatus(),
        _loadComments(page: 1),
        _loadUserRating(),
        _loadAppRating(),
        _calculateDistance(),
      ]);

      // Track this view in analytics
      if (_destination.categoryId != null) {
        _destinationService.trackDestinationView(
            _destinationId, _destination.categoryId!);
      }

      // Initialize map markers
      _initializeMapMarkers();
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load complete destination data by ID
  Future<void> _loadDestinationData() async {
    try {
      final data = await _destinationService.getDestinationById(_destinationId);

      if (mounted) {
        setState(() {
          _destination = DestinationDetailModel.fromMap(data);
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      print('Error loading destination data: $e');
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'Gagal memuat data destinasi',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFavorited =
          await _destinationService.isDestinationFavorited(_destinationId);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorited;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('Error loading favorite status: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final newStatus =
          await _destinationService.toggleFavorite(_destinationId);

      if (mounted) {
        setState(() {
          _isFavorite = newStatus;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });

        CustomSnackbar.show(
          context: context,
          message: 'Gagal mengubah status favorit',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _loadComments({int page = 1, bool loadMore = false}) async {
    try {
      if (page == 1 && !loadMore) {
        setState(() {
          _isLoadingComments = true;
          _comments = [];
          _commentsPage = 1;
          _hasMoreComments = true;
        });
      }

      final comments = await _destinationService.loadComments(
        destinationId: _destinationId,
        page: page,
        commentsPerPage: _commentsPerPage,
      );

      // If we received fewer comments than requested, there are no more to load
      final hasMoreComments = comments.length >= _commentsPerPage;

      // Convert the raw maps to model objects
      final commentModels =
          comments.map((c) => DestinationCommentModel.fromMap(c)).toList();

      if (mounted) {
        setState(() {
          if (loadMore) {
            // Append new comments to existing list
            _comments = [..._comments, ...commentModels];
          } else {
            _comments = commentModels;
          }
          _commentsPage = page;
          _isLoadingComments = false;
          _hasMoreComments = hasMoreComments;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
          if (page > 1) {
            _isLoadingMoreComments = false;
          }
        });
      }
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        CustomSnackbar.show(
          context: context,
          message: 'Silakan login untuk memberikan komentar',
          type: SnackbarType.warning,
        );
        setState(() {
          _isSubmittingComment = false;
        });
        return;
      }

      await _destinationService.submitComment(
        destinationId: _destinationId,
        comment: _commentController.text.trim(),
      );

      // Clear the input after successful submission
      _commentController.clear();

      CustomSnackbar.show(
        context: context,
        message: 'Berhasil menambahkan komentar',
        type: SnackbarType.success,
      );

      // Reset and reload comments from the first page
      await _loadComments(page: 1);
    } catch (e) {
      print('Error submitting comment: $e');
      CustomSnackbar.show(
        context: context,
        message: 'Gagal mengirim komentar',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  Future<void> _calculateDistance() async {
    try {
      final distanceInKm = await _destinationService.calculateDistance(
        destinationLat: _destination.latitude,
        destinationLng: _destination.longitude,
      );

      if (mounted) {
        setState(() {
          _destination = _destination.copyWith(distanceInKm: distanceInKm);
        });
      }
    } catch (e) {
      print('Error calculating distance: $e');
    }
  }

  void _initializeMapMarkers() {
    try {
      if (_destination.latitude != null && _destination.longitude != null) {
        final marker = Marker(
          markerId: MarkerId(_destinationId.toString()),
          position: LatLng(_destination.latitude!, _destination.longitude!),
          infoWindow: InfoWindow(
            title: _destination.name,
            snippet: _destination.address ?? 'Lokasi Destinasi',
          ),
        );

        setState(() {
          _destination = _destination.copyWith(
            mapMarkers: {marker},
          );
        });
      }
    } catch (e) {
      print('Error initializing map markers: $e');
    }
  }

  Future<void> _loadUserRating() async {
    try {
      final userRatingData =
          await _destinationService.loadUserRating(_destinationId);

      if (mounted) {
        setState(() {
          if (userRatingData != null) {
            _userRating = DestinationRatingModel.fromMap(userRatingData);
            _selectedRating = _userRating?.rating ?? 0;
          }
          _isLoadingUserRating = false;
        });
      }
    } catch (e) {
      print('Error loading user rating: $e');
      if (mounted) {
        setState(() {
          _isLoadingUserRating = false;
        });
      }
    }
  }

  Future<void> _loadAppRating() async {
    try {
      final appRating = await _destinationService.loadAppRating(_destinationId);

      if (mounted) {
        setState(() {
          _destination = _destination.copyWith(
            appRatingAverage: appRating['average'] as double,
            appRatingCount: appRating['count'] as int,
          );
        });
      }
    } catch (e) {
      print('Error loading app rating: $e');
    }
  }

  Future<void> _submitRating(int rating) async {
    if (_isSubmittingRating) return;

    setState(() {
      _isSubmittingRating = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        CustomSnackbar.show(
          context: context,
          message: 'Silakan login untuk memberikan rating',
          type: SnackbarType.warning,
        );
        setState(() {
          _isSubmittingRating = false;
        });
        return;
      }

      await _destinationService.submitRating(
        destinationId: _destinationId,
        rating: rating,
        ratingId: _userRating?.id,
      );

      // Refresh user rating and app rating
      await Future.wait([
        _loadUserRating(),
        _loadAppRating(),
      ]);

      CustomSnackbar.show(
        context: context,
        message: 'Rating berhasil disimpan',
        type: SnackbarType.success,
      );
    } catch (e) {
      print('Error submitting rating: $e');
      CustomSnackbar.show(
        context: context,
        message: 'Gagal menyimpan rating',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingRating = false;
        });
      }
    }
  }

  Future<void> _deleteRating() async {
    if (_userRating == null || _userRating?.id == null) return;

    setState(() {
      _isSubmittingRating = true;
    });

    try {
      await _destinationService.deleteRating(_userRating!.id!);

      if (mounted) {
        setState(() {
          _userRating = null;
          _selectedRating = 0;
          _isSubmittingRating = false;
        });
      }

      // Refresh app rating after deletion
      await _loadAppRating();

      CustomSnackbar.show(
        context: context,
        message: 'Rating berhasil dihapus',
        type: SnackbarType.success,
      );
    } catch (e) {
      print('Error deleting rating: $e');
      CustomSnackbar.show(
        context: context,
        message: 'Gagal menghapus rating',
        type: SnackbarType.error,
      );
      if (mounted) {
        setState(() {
          _isSubmittingRating = false;
        });
      }
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMoreComments || !_hasMoreComments) return;

    setState(() {
      _isLoadingMoreComments = true;
    });

    await _loadComments(page: _commentsPage + 1, loadMore: true);

    setState(() {
      _isLoadingMoreComments = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while initial data is loading
    if (_isLoading && widget.destination == null) {
      return const DestinationDetailSkeleton();
    }

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200 &&
              !_isLoadingMoreComments &&
              _hasMoreComments) {
            _loadMoreComments();
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDestinationTitle(context),
                    const SizedBox(height: 16),
                    _buildOverviewSection(context),
                    const SizedBox(height: 16),
                    _buildLocationMapSection(context),
                    const SizedBox(height: 16),
                    _buildRatingSection(context),
                    const SizedBox(height: 16),
                    _buildAddCommentSection(context),
                    const SizedBox(height: 16),
                    _buildReviewsSection(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      collapsedHeight: 70,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Hero image
            if (_isLoadingImage)
              Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Image.network(
                  _destination.imageUrl ?? 'https://via.placeholder.com/400',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child:
                        const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: const [0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isLoadingFavorite
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.black87,
                  ),
                  onPressed: _toggleFavorite,
                ),
        ),
      ],
    );
  }

  Widget _buildDestinationTitle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _destination.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _destination.address ?? 'Kota Malang, Jawa Timur',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Google rating - only show if the destination type is added_by_google
            if (_destination.type != DestinationType.added_by_user)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/vectors/google.svg',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _destination.rating.toString(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _destination.ratingCount > 0
                          ? '(${_destination.ratingCount})'
                          : '(No ratings yet)',
                      style: TextStyle(
                        color: colorScheme.primary.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (_destination.type != DestinationType.added_by_user)
              const SizedBox(width: 8),

            // App rating
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _destination.appRatingCount > 0
                        ? (_destination.appRatingAverage ?? 0.0)
                            .toStringAsFixed(1)
                        : '0.0',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${_destination.appRatingCount})',
                    style: TextStyle(
                      color: Colors.amber.shade700.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Distance info
            if (_destination.distanceInKm != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_destination.distanceInKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    final description = _destination.description ??
        'Tidak ada deskripsi yang tersedia untuk destinasi ini.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationMapSection(BuildContext context) {
    // Default position if coordinates are not available
    final defaultLat =
        -7.9666; // Default to Malang, Indonesia if no coordinates
    final defaultLng = 112.6326;

    final initialCameraPosition = CameraPosition(
      target: LatLng(
        _destination.latitude ?? defaultLat,
        _destination.longitude ?? defaultLng,
      ),
      zoom: 14.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokasi',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child:
              (_destination.latitude == null || _destination.longitude == null)
                  ? Center(
                      child: Text(
                        'Lokasi tidak tersedia',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: initialCameraPosition,
                        markers: _destination.mapMarkers,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        onMapCreated: (controller) {},
                      ),
                    ),
        ),
        if (_destination.latitude != null && _destination.longitude != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Buka di Google Maps'),
                  onPressed: () async {
                    final url =
                        'https://www.google.com/maps/dir/?api=1&destination=${_destination.latitude},${_destination.longitude}';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) {
                        CustomSnackbar.show(
                          context: context,
                          message: 'Tidak dapat membuka Google Maps',
                          type: SnackbarType.error,
                        );
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Komentar',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _isLoadingComments && _commentsPage == 1
            ? _buildCommentsSkeletonSection()
            : _comments.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada komentar',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : Column(
                    children: [
                      // Comments list
                      ..._comments.map((comment) {
                        return _buildCommentCard(
                          context,
                          {
                            'name': comment.authorName,
                            'photo': comment.authorAvatarUrl ?? '',
                            'date': comment.formattedDate(),
                            'comment': comment.comment,
                          },
                        );
                      }).toList(),

                      // Loading indicator
                      if (_hasMoreComments)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: _isLoadingMoreComments
                                ? _buildLoadMoreSkeleton()
                                : const SizedBox(height: 30),
                          ),
                        ),
                    ],
                  ),
      ],
    );
  }

  Widget _buildCommentsSkeletonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username
                            Container(
                              width: 120,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Date
                            Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Comment text
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(BuildContext context, Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(comment['photo'] as String),
                radius: 20,
                onBackgroundImageError: (_, __) {},
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment['date'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment['comment'] as String,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCommentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tambahkan Komentar',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Bagikan pengalaman Anda...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmittingComment ? null : _submitComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmittingComment
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Kirim Komentar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beri Rating',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _isLoadingUserRating
            ? _buildRatingSkeletonSection(context)
            : _userRating != null
                ? _buildUserRatingView(context)
                : _buildRatingInput(context),
      ],
    );
  }

  Widget _buildRatingSkeletonSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating title
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRatingView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Anda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < (_userRating?.rating ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmittingRating
                        ? null
                        : () {
                            setState(() {
                              // Save original user rating before editing
                              _originalUserRating = _userRating;
                              _selectedRating = _userRating?.rating ?? 0;
                              _userRating = null;
                            });
                          },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmittingRating ? null : _deleteRating,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _isSubmittingRating
              ? const CircularProgressIndicator()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedRating = index + 1;
                        });
                        _showRatingConfirmationDialog(context, index + 1);
                      },
                      icon: Icon(
                        index < _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      constraints: const BoxConstraints(),
                      splashRadius: 24,
                    );
                  }),
                ),
          const SizedBox(height: 8),
          Text(
            'Tap bintang untuk memberi rating',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),

          // Add a cancel button if we're in edit mode
          if (_originalUserRating != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    // Restore original rating and exit edit mode
                    _userRating = _originalUserRating;
                    _selectedRating = _userRating?.rating ?? 0;
                    _originalUserRating = null;
                  });
                },
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Batal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey.shade400),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRatingConfirmationDialog(
      BuildContext context, int rating) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Rating'),
          content: Text(
              'Apakah Anda yakin ingin memberikan rating $rating bintang?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                setState(() {
                  if (_originalUserRating != null) {
                    // Restore original user rating if we were editing
                    _userRating = _originalUserRating;
                    _selectedRating = _userRating?.rating ?? 0;
                    _originalUserRating = null;
                  } else {
                    // If this is a new rating, just reset the selected rating
                    _selectedRating = 0;
                  }
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ya'),
              onPressed: () {
                Navigator.of(context).pop();
                _submitRating(rating);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadMoreSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 150,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
