import 'package:flutter/material.dart';

class UserDestinationsScreen extends StatelessWidget {
  const UserDestinationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Destinasi Yang Anda Tambahkan',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
          onPressed: () => Navigator.pop(context),
          splashRadius: 20,
          padding: EdgeInsets.zero,
          color: colorScheme.primary,
        ),
      ),
      body: SafeArea(
        child: _buildDestinationsList(context),
      ),
    );
  }

  Widget _buildDestinationsList(BuildContext context) {
    // Mock data for destinations
    final destinations = [
      {
        'name': 'Pantai Kuta',
        'location': 'Bali, Indonesia',
        'image': 'assets/images/avatar_fallback.png',
        'rating': 4.8,
        'type': 'Pantai',
      },
      {
        'name': 'Gunung Bromo',
        'location': 'Jawa Timur, Indonesia',
        'image': 'assets/images/avatar_fallback.png',
        'rating': 4.9,
        'type': 'Gunung',
      },
      {
        'name': 'Candi Borobudur',
        'location': 'Jawa Tengah, Indonesia',
        'image': 'assets/images/avatar_fallback.png',
        'rating': 4.7,
        'type': 'Candi',
      },
    ];

    if (destinations.isEmpty) {
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
              'Jelajahi dan tambahkan destinasi favorit Anda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: destinations.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final destination = destinations[index];
        return _buildDestinationCard(
          context: context,
          name: destination['name'] as String,
          location: destination['location'] as String,
          image: destination['image'] as String,
          rating: destination['rating'] as double,
          type: destination['type'] as String,
        );
      },
    );
  }

  Widget _buildDestinationCard({
    required BuildContext context,
    required String name,
    required String location,
    required String image,
    required double rating,
    required String type,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            // Navigate to destination detail
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Destination name
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Rating
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
