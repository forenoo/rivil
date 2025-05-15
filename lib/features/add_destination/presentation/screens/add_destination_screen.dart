import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rivil/features/add_destination/domain/repository/destination_add_repository.dart';
import 'package:rivil/features/add_destination/data/repositories/destination_add_repository_impl.dart';
import 'package:rivil/features/add_destination/presentation/bloc/add_destination_bloc.dart';
import 'package:rivil/features/add_destination/presentation/widgets/map_location_picker.dart';
import 'package:rivil/features/add_destination/presentation/widgets/add_destination_skeleton_screen.dart';
import 'package:rivil/widgets/custom_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

class AddDestinationScreen extends StatefulWidget {
  const AddDestinationScreen({super.key});

  @override
  State<AddDestinationScreen> createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<AddDestinationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedImagePath;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _gmapsLinkController = TextEditingController();
  int? _selectedCategoryId;
  final double _rating = 0.0;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _gmapsLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepositoryProvider<DestinationAddRepository>(
      create: (context) =>
          DestinationAddRepositoryImpl(Supabase.instance.client),
      child: BlocProvider(
        create: (context) {
          final bloc = AddDestinationBloc(
            context.read<DestinationAddRepository>(),
          );
          // Fetch categories when the bloc is created
          bloc.add(FetchCategoriesEvent());
          return bloc;
        },
        child: BlocConsumer<AddDestinationBloc, AddDestinationState>(
          listener: (context, state) {
            if (state is AddDestinationSuccess) {
              _showSuccessToast(context);
              Navigator.pop(context);
            } else if (state is AddDestinationFailure) {
              _showErrorToast(context, state.error);
            } else if (state is CategoriesLoadFailure) {
              _showErrorToast(context, state.error);
            }
          },
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Tambah Destinasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: Stack(
                children: [
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Picker
                            _buildImagePicker(),

                            // Content Container
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Basic Information Section
                                  _buildSectionTitle('Informasi Dasar'),
                                  const SizedBox(height: 10),

                                  // Name Field
                                  _buildInputField(
                                    controller: _nameController,
                                    label: 'Nama',
                                    placeholder: 'Masukkan nama destinasi',
                                    icon: CupertinoIcons.placemark,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Mohon masukkan nama destinasi'
                                        : null,
                                  ),

                                  _buildInputField(
                                    controller: _gmapsLinkController,
                                    label: 'Link Google Maps',
                                    placeholder: 'Masukkan Link Google Maps',
                                    icon: CupertinoIcons.placemark,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Mohon masukkan Link Google Maps'
                                        : null,
                                  ),

                                  // Category Selector
                                  _buildCategorySelector(state),

                                  // Description Field
                                  _buildInputField(
                                    controller: _descriptionController,
                                    label: 'Deskripsi',
                                    placeholder:
                                        'Jelaskan tentang destinasi ini',
                                    icon: CupertinoIcons.text_alignleft,
                                    maxLines: 3,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Mohon masukkan deskripsi'
                                        : null,
                                  ),

                                  _buildSectionTitle('Lokasi'),
                                  const SizedBox(height: 10),

                                  // Address Field
                                  _buildInputField(
                                    controller: _addressController,
                                    label: 'Alamat',
                                    placeholder: 'Masukkan alamat lengkap',
                                    icon: CupertinoIcons.location,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Mohon masukkan alamat'
                                        : null,
                                  ),

                                  // Map Location Picker
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4, bottom: 2),
                                    child: Text(
                                      'Pilih Lokasi',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 260,
                                    margin: const EdgeInsets.only(
                                        top: 6, bottom: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          offset: const Offset(0, 2),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: MapLocationPicker(
                                      onLocationSelected: (LatLng location) {
                                        setState(() {
                                          _latitudeController.text =
                                              location.latitude.toString();
                                          _longitudeController.text =
                                              location.longitude.toString();
                                        });
                                      },
                                    ),
                                  ),

                                  // Submit Button
                                  _buildSubmitButton(context, state),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Loading overlay
                  if (state is AddDestinationLoading ||
                      state is CategoriesLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white,
                        child: const AddDestinationSkeletonScreen(),
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

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        color: _selectedImagePath != null ? Colors.black : Colors.grey[100],
        child: _selectedImagePath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(_selectedImagePath!),
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.camera,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.photo_camera,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambah Foto',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.grey[500], size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
            ),
            style: const TextStyle(fontSize: 14),
            maxLines: maxLines,
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(AddDestinationState state) {
    // Get categories from state if available
    List<Map<String, dynamic>> categories = [];
    if (state is CategoriesLoaded) {
      categories = state.categories;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            icon: Container(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                CupertinoIcons.chevron_down,
                color: Colors.grey[700],
                size: 12,
              ),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 10, right: 6),
                child: Icon(
                  CupertinoIcons.tag,
                  color: Colors.grey[600],
                  size: 18,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 300,
            borderRadius: BorderRadius.circular(10),
            itemHeight: 48,
            items: categories.map((category) {
              return DropdownMenuItem<int>(
                value: category['id'] as int,
                child: Text(
                  category['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Mohon pilih kategori';
              }
              return null;
            },
            hint: Text(
              'Pilih kategori',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, AddDestinationState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state is AddDestinationLoading
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  context.read<AddDestinationBloc>().add(
                        SubmitDestinationEvent(
                          name: _nameController.text,
                          categoryId: _selectedCategoryId!,
                          description: _descriptionController.text,
                          address: _addressController.text,
                          latitude: _latitudeController.text,
                          longitude: _longitudeController.text,
                          rating: _rating,
                          imagePath: _selectedImagePath,
                        ),
                      );
                }
              },
        child: state is AddDestinationLoading
            ? Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.5),
                highlightColor: Colors.white,
                child: const Text(
                  'Menambahkan...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              )
            : const Text(
                'Tambahkan Destinasi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  void _showSuccessToast(BuildContext context) {
    CustomSnackbar.show(
      context: context,
      message: 'Berhasil menambahkan destinasi',
      type: SnackbarType.success,
    );
  }

  void _showErrorToast(BuildContext context, String error) {
    CustomSnackbar.show(
      context: context,
      message: error,
      type: SnackbarType.error,
    );
  }
}
