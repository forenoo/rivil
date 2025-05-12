import 'package:flutter/material.dart';
import 'package:rivil/core/config/app_colors.dart';
import 'package:rivil/widgets/custom_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rivil/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class DestinationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailScreen({
    super.key,
    required this.destination,
  });

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  String? _imageUrl;
  bool _isLoadingImage = true;
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;
  double? _distanceInKm;
  bool _isLoadingDistance = true;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _trackDestinationView();
    _calculateDistance();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadFavoriteStatus(),
      _loadDestinationImage(),
      _loadComments(),
    ]);
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFavorited =
          await _isDestinationFavorited(widget.destination['id'] as int);
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

  Future<void> _loadDestinationImage() async {
    try {
      final imageUrl = widget.destination['image_url'] as String?;
      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      print('Error loading destination image: $e');
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  Future<void> _trackDestinationView() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      await Supabase.instance.client
          .from('user_destination_interaction')
          .insert({
        'user_id': currentUser.id,
        'destination_id': widget.destination['id'],
        'type': 'view',
        'category_id': widget.destination['category_id'],
      });
    } catch (e) {
      print('Error tracking destination view: $e');
    }
  }

  Future<bool> _isDestinationFavorited(int destinationId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return false;

    final response = await Supabase.instance.client
        .from('favorite_destination')
        .select()
        .eq('user_id', currentUser.id)
        .eq('destination_id', destinationId)
        .limit(1);

    return response.isNotEmpty;
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      if (_isFavorite) {
        await Supabase.instance.client
            .from('favorite_destination')
            .delete()
            .eq('user_id', currentUser.id)
            .eq('destination_id', widget.destination['id']);
      } else {
        await Supabase.instance.client.from('favorite_destination').insert({
          'user_id': currentUser.id,
          'destination_id': widget.destination['id'],
        });
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      print('Loading comments for destination ID: ${widget.destination['id']}');

      final response = await Supabase.instance.client
          .from('destination_comment')
          .select()
          .eq('destination_id', widget.destination['id'])
          .order('created_at', ascending: false);

      final commentsWithUsers = await Future.wait(
          List<Map<String, dynamic>>.from(response).map((comment) async {
        try {
          final userId = comment['user_id'] as String?;
          if (userId == null) {
            return {...comment, 'user_data': null};
          }

          final currentUser = Supabase.instance.client.auth.currentUser;
          Map<String, dynamic>? userData;

          if (currentUser != null && currentUser.id == userId) {
            userData = {'raw_user_meta_data': currentUser.userMetadata ?? {}};
          } else {
            try {
              final profileData = await Supabase.instance.client
                  .from('user_profile')
                  .select()
                  .eq('id', userId)
                  .single();

              userData = {
                'raw_user_meta_data': {
                  'name': profileData['full_name'] ?? profileData['username'],
                  'avatar_url': profileData['avatar_url']
                }
              };
            } catch (e) {
              print('Error fetching profile data: $e');
            }
          }

          return {...comment, 'user_data': userData};
        } catch (e) {
          print('Error fetching user data: $e');
          return {...comment, 'user_data': null};
        }
      }));

      if (mounted) {
        setState(() {
          _comments = commentsWithUsers;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
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

      await Supabase.instance.client.from('destination_comment').insert({
        'user_id': currentUser.id,
        'destination_id': widget.destination['id'],
        'comment': _commentController.text.trim(),
      });

      // Clear the input after successful submission
      _commentController.clear();

      CustomSnackbar.show(
        context: context,
        message: 'Berhasil menambahkan komentar',
        type: SnackbarType.success,
      );

      // Reload comments to show the new one
      _loadComments();
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
      final hasPermission = await _locationService.requestLocationPermission();

      if (!hasPermission) {
        print('Location permission denied');
        if (mounted) {
          setState(() {
            _isLoadingDistance = false;
          });
        }
        return;
      }

      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services disabled');
        if (mounted) {
          setState(() {
            _isLoadingDistance = false;
          });
        }
        return;
      }

      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        print('Could not get current position');
        if (mounted) {
          setState(() {
            _isLoadingDistance = false;
          });
        }
        return;
      }

      if (mounted) {
        // Safely extract latitude and longitude, handling potential type issues
        double? destinationLat;
        double? destinationLng;

        final latValue = widget.destination['latitude'];
        final lngValue = widget.destination['longitude'];

        // Handle different possible data types
        if (latValue is double) {
          destinationLat = latValue;
        } else if (latValue is String) {
          destinationLat = double.tryParse(latValue);
        }

        if (lngValue is double) {
          destinationLng = lngValue;
        } else if (lngValue is String) {
          destinationLng = double.tryParse(lngValue);
        }

        if (destinationLat != null && destinationLng != null) {
          final distanceInMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            destinationLat,
            destinationLng,
          );

          setState(() {
            _distanceInKm = distanceInMeters / 1000;
            _isLoadingDistance = false;
          });
        } else {
          print(
              'Invalid destination coordinates: lat=$latValue, lng=$lngValue');
          setState(() {
            _isLoadingDistance = false;
          });
        }
      }
    } catch (e) {
      print('Error calculating distance: $e');
      if (mounted) {
        setState(() {
          _isLoadingDistance = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
              Image.network(
                _imageUrl ??
                    'https://picsum.photos/800/400?random=${widget.destination['id']}',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
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
    final rating = widget.destination['rating'] as double? ?? 0.0;
    final ratingCount = widget.destination['rating_count'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.destination['name'] as String,
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
                widget.destination['address'] as String? ??
                    'Lokasi tidak tersedia',
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
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${ratingCount.toString()})',
                    style: TextStyle(
                      color: colorScheme.primary.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_distanceInKm != null || _isLoadingDistance)
              const SizedBox(width: 8),
            if (_isLoadingDistance)
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
                      Icons.directions_walk,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              )
            else if (_distanceInKm != null)
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
                      Icons.directions_walk,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_distanceInKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: Colors.amber.shade700,
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
    final description = widget.destination['description'] as String? ??
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
        _isLoadingComments
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _comments.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada komentar',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : Column(
                    children: _comments.map((comment) {
                      // Debug the comment structure
                      print('Processing comment: $comment');

                      // Get user data
                      final userData = comment['user_data'];
                      Map<String, dynamic>? userMetaData;

                      if (userData != null &&
                          userData is Map<String, dynamic>) {
                        userMetaData = userData['raw_user_meta_data']
                            as Map<String, dynamic>?;
                      }

                      final userName =
                          userMetaData?['name'] as String? ?? 'Anonymous';
                      final photoUrl = userMetaData?['avatar_url'] as String? ??
                          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}';

                      final createdAt =
                          DateTime.parse(comment['created_at'] as String);
                      final formattedDate =
                          '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}';

                      return _buildCommentCard(
                        context,
                        {
                          'name': userName,
                          'photo': photoUrl,
                          'date': formattedDate,
                          'comment': comment['comment'] as String? ?? '',
                        },
                      );
                    }).toList(),
                  ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
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
}
