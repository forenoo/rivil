import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rivil/core/config/app_colors.dart';
import 'package:rivil/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rivil/features/home/presentation/bloc/category_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
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
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  String name = 'pengguna';
                  String? avatarUrl;
                  if (state is AuthAuthenticated) {
                    name = state.user.name ?? 'pengguna';
                    avatarUrl = state.user.avatarUrl;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $name',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                'Mau berkeliling?',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              // Profile actions
                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                    MediaQuery.of(context).size.width,
                                    80,
                                    0,
                                    0),
                                items: [
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.logout, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Logout',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      context
                                          .read<AuthBloc>()
                                          .add(SignOutEvent());
                                    },
                                  ),
                                ],
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              );
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
                                  image: avatarUrl != null &&
                                          avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl) as ImageProvider
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
                              // Handle AI trip planner
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
                                    style: theme.textTheme.titleSmall?.copyWith(
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
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Category
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state is CategoriesLoadedState) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: state.categories.map((category) {
                          return _buildCategoryButton(
                            context: context,
                            icon: category.icon,
                            label: category.name,
                            categoryId: category.id,
                            isSelected: category.id == state.selectedCategoryId,
                          );
                        }).toList(),
                      ),
                    );
                  }

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Popular Destinations
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Destinasi Populer',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to see all destinations
                    },
                    child: Text(
                      'Lihat semua',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                children: [
                  _buildDestinationCard(
                    context: context,
                    name: 'Gunung Bromo',
                    location: 'Malang, Indonesia',
                    rating: 4.8,
                    imageUrl: 'assets/images/bromo.jpg',
                    isFavorite: true,
                  ),
                  _buildDestinationCard(
                    context: context,
                    name: 'Coban Rondo',
                    location: 'Malang, Indonesia',
                    rating: 4.5,
                    imageUrl: 'assets/images/coban_rondo.jpg',
                  ),
                  _buildDestinationCard(
                    context: context,
                    name: 'Jatim Park',
                    location: 'Malang, Indonesia',
                    rating: 4.6,
                    imageUrl: 'assets/images/jatim_park.jpg',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recommended For You
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.recommend,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rekomendasi Untukmu',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to see all recommended destinations
                    },
                    child: Text(
                      'Lihat semua',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                children: [
                  _buildDestinationCard(
                    context: context,
                    name: 'Pantai Malang Selatan',
                    location: 'Malang, Indonesia',
                    rating: 4.7,
                    imageUrl: 'assets/images/malang_beach.jpg',
                    isFavorite: false,
                  ),
                  _buildDestinationCard(
                    context: context,
                    name: 'Museum Angkut',
                    location: 'Batu, Indonesia',
                    rating: 4.6,
                    imageUrl: 'assets/images/museum_angkut.jpg',
                    isFavorite: true,
                  ),
                  _buildDestinationCard(
                    context: context,
                    name: 'Taman Safari',
                    location: 'Prigen, Indonesia',
                    rating: 4.5,
                    imageUrl: 'assets/images/taman_safari.jpg',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.near_me,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Destinasi Terdekat',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to see all destinations
                        },
                        child: Text(
                          'Lihat semua',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildNearbyPlace(
                    context: context,
                    name: 'Kebun Binatang Batu',
                    location: 'Batu, Indonesia',
                    distance: '3.5 km',
                    imageUrl: 'assets/images/batu_zoo.jpg',
                  ),
                  _buildNearbyPlace(
                    context: context,
                    name: 'Jatim Park 2',
                    location: 'Batu, Indonesia',
                    distance: '4.2 km',
                    imageUrl: 'assets/images/jatim_park2.jpg',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String categoryId,
    bool isSelected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: isSelected ? colorScheme.primary : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: () {
            // Select category using BLoC
            context.read<CategoryBloc>().add(CategorySelected(categoryId));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationCard({
    required BuildContext context,
    required String name,
    required String location,
    required double rating,
    required String imageUrl,
    bool isFavorite = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
                child: Image.asset(
                  imageUrl,
                  height: 140,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 140,
                    width: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              // Favorite button
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey.shade700,
                    size: 16,
                  ),
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
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _buildNearbyPlace({
    required BuildContext context,
    required String name,
    required String location,
    required String distance,
    required String imageUrl,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to place details
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Place info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade700,
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
}
