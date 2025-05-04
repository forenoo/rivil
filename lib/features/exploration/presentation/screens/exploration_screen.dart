import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rivil/core/config/app_colors.dart';
import 'package:rivil/features/exploration/presentation/bloc/exploration_bloc.dart';

class ExplorationScreen extends StatefulWidget {
  const ExplorationScreen({super.key});

  @override
  State<ExplorationScreen> createState() => _ExplorationScreenState();
}

class _ExplorationScreenState extends State<ExplorationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = [
    "Semua",
    "Pantai",
    "Gunung",
    "Air Terjun",
    "Danau",
    "Goa",
    "Hutan Wisata",
    "Kebun Raya",
    "Taman Nasional",
    "Agrowisata",
    "Pemandian Air Panas",
    "Bukit",
    "Museum",
    "Candi",
    "Taman Hiburan",
    "Taman Air",
    "Kebun Binatang",
    "Akuarium",
    "Outbound",
    "Wahana Permainan",
    "Pusat Olahraga",
    "Restoran",
    "Kafe",
    "Mall"
  ];

  // Filter values
  RangeValues _priceRange = const RangeValues(0, 1000000);
  double _maxDistance = 100;
  double _minRating = 0;
  List<String> _selectedFacilities = [];
  String? _selectedCategory;
  SortOption? _selectedSortOption;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Get the bloc instance before showing the bottom sheet
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
            _priceRange = RangeValues(
              state.minPrice ?? 0,
              state.maxPrice ?? 1000000,
            );
            _maxDistance = state.maxDistance ?? 100;
            _minRating = state.minRating ?? 0;
            _selectedFacilities = state.selectedFacilities?.toList() ?? [];
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
                              _priceRange = const RangeValues(0, 1000000);
                              _maxDistance = 100;
                              _minRating = 0;
                              _selectedFacilities = [];
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
                              "Harga Terendah",
                              SortOption.priceAsc,
                            ),
                            _buildSortChip(
                              context,
                              setState,
                              "Harga Tertinggi",
                              SortOption.priceDesc,
                            ),
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
                        Wrap(
                          spacing: 8,
                          children: _categories.map((category) {
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

                        // Price range
                        const Text(
                          'Kisaran Harga Tiket',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rp ${_priceRange.start.toInt()}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'Rp ${_priceRange.end.toInt()}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 1000000,
                          divisions: 20,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.jordyBlue200,
                          labels: RangeLabels(
                            'Rp ${_priceRange.start.toInt()}',
                            'Rp ${_priceRange.end.toInt()}',
                          ),
                          onChanged: (values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Maximum distance
                        const Text(
                          'Jarak Maksimum',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0 km',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${_maxDistance.toInt()} km',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _maxDistance,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.jordyBlue200,
                          label: '${_maxDistance.toInt()} km',
                          onChanged: (value) {
                            setState(() {
                              _maxDistance = value;
                            });
                          },
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
                            minPrice: _priceRange.start,
                            maxPrice: _priceRange.end,
                            maxDistance: _maxDistance,
                            minRating: _minRating,
                            facilities: _selectedFacilities.isNotEmpty
                                ? _selectedFacilities
                                : null,
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
    return BlocProvider(
      create: (_) => ExplorationBloc(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<ExplorationBloc, ExplorationState>(
          builder: (context, state) {
            return SafeArea(
              child: Column(
                children: [
                  // Top search bar
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
                                context.read<ExplorationBloc>().add(
                                      SearchDestinationsEvent(query),
                                    );
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
                    child: state is ExplorationLoaded
                        ? state.destinations.isEmpty
                            ? Center(
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
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.destinations.length,
                                itemBuilder: (context, index) {
                                  final destination = state.destinations[index];
                                  return _buildDestinationCard(
                                    context: context,
                                    destination: destination,
                                  );
                                },
                              )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
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
                child: Image.asset(
                  destination['imageUrl'] as String,
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
              // Favorite button
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    destination['isFavorite'] as bool
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: destination['isFavorite'] as bool
                        ? Colors.red
                        : Colors.grey.shade700,
                    size: 18,
                  ),
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
                        '${destination['distance']} km',
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
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${destination['rating']}',
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
              // Price
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
                    'Rp ${destination['price']}',
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
                    Text(
                      destination['location'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (destination['facilities'] as List<String>)
                      .take(3)
                      .map((facility) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        facility,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to detail page
                  },
                  style: ElevatedButton.styleFrom(
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
}
