import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rivil/core/services/media_permission_service.dart';
import 'package:rivil/features/auth/data/models/user_profile_model.dart';
import 'package:rivil/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:rivil/widgets/custom_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  UserProfileModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
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
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() {
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Informasi Pribadi',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileAvatar(context),
                      const SizedBox(height: 20),
                      Text(
                        'Informasi Dasar',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoItem(
                        context: context,
                        label: 'Nama Lengkap',
                        value: _userProfile?.fullName ?? 'Belum diisi',
                        icon: Icons.person_outline_rounded,
                      ),
                      _buildInfoItem(
                        context: context,
                        label: 'Username',
                        value: _userProfile?.username != null
                            ? '@${_userProfile!.username}'
                            : 'Belum diisi',
                        icon: Icons.alternate_email_rounded,
                      ),
                      _buildInfoItem(
                        context: context,
                        label: 'Email',
                        value: _userProfile?.email ?? 'Belum diisi',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Kontak',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoItem(
                        context: context,
                        label: 'Nomor Telepon',
                        value: _userProfile?.phoneNumber ?? 'Belum diisi',
                        icon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Alamat',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoItem(
                        context: context,
                        label: 'Alamat Lengkap',
                        value: _userProfile?.address ?? 'Belum diisi',
                        icon: Icons.location_on_outlined,
                      ),
                      _buildInfoItem(
                        context: context,
                        label: 'Kota',
                        value: _userProfile?.city ?? 'Belum diisi',
                        icon: Icons.location_city_outlined,
                      ),
                      _buildInfoItem(
                        context: context,
                        label: 'Kode Pos',
                        value: _userProfile?.postalCode ?? 'Belum diisi',
                        icon: Icons.markunread_mailbox_outlined,
                      ),
                      const SizedBox(height: 20),
                      _buildEditButton(context),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    String? avatarUrl = _userProfile?.avatarUrl;

    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl) as ImageProvider
                  : const AssetImage('assets/images/avatar_fallback.png'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _updateAvatar(context);
            },
            icon: Icon(
              Icons.photo_camera_outlined,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              'Ubah Foto',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAvatar(BuildContext context) async {
    final mediaPermissionService = MediaPermissionService();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.pop(context);
                final isGranted =
                    await mediaPermissionService.requestCameraPermission();

                if (isGranted) {
                  _pickImage(ImageSource.camera);
                } else {
                  final isPermanentlyDenied =
                      await mediaPermissionService.isCameraPermanentlyDenied();
                  if (isPermanentlyDenied && mounted) {
                    _showPermissionDeniedDialog(
                      context,
                      'Akses Kamera',
                      'Untuk mengambil foto profil, Anda perlu memberikan izin akses kamera di pengaturan aplikasi.',
                      Permission.camera,
                    );
                  } else if (mounted) {
                    CustomSnackbar.show(
                      context: context,
                      message: 'Akses kamera diperlukan untuk mengambil foto',
                      type: SnackbarType.warning,
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final isGranted =
                    await mediaPermissionService.requestGalleryPermission();

                if (isGranted) {
                  _pickImage(ImageSource.gallery);
                } else {
                  final isPermanentlyDenied =
                      await mediaPermissionService.isGalleryPermanentlyDenied();
                  if (isPermanentlyDenied && mounted) {
                    _showPermissionDeniedDialog(
                      context,
                      'Akses Galeri',
                      'Untuk memilih foto profil, Anda perlu memberikan izin akses galeri di pengaturan aplikasi.',
                      Permission.photos,
                    );
                  } else if (mounted) {
                    CustomSnackbar.show(
                      context: context,
                      message: 'Akses galeri diperlukan untuk memilih foto',
                      type: SnackbarType.warning,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
    String message,
    Permission permission,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Izin $permissionName Diperlukan'),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
      });

      // Get the original file and its size
      final File originalFile = File(pickedFile.path);
      final int originalSize = await originalFile.length();
      debugPrint('Original image size: ${originalSize / 1024}KB');

      // Maximum size in bytes (128KB)
      const maxSizeInBytes = 128 * 1024;

      // If the image is already under the size limit, use it as is
      if (originalSize <= maxSizeInBytes) {
        await _uploadAndUpdateProfile(originalFile);
        return;
      }

      try {
        // Create a temporary directory for the compressed file
        final tempDir = await getTemporaryDirectory();
        final targetPath = path.join(
          tempDir.path,
          'compressed_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}',
        );

        // Simpler approach to compression that works better across platforms
        final result = await FlutterImageCompress.compressAndGetFile(
          originalFile.path,
          targetPath,
          quality: 70,
          // Remove format parameter to let the plugin determine format based on extension
        );

        if (result != null) {
          final compressedSize = await result.length();
          debugPrint('Compressed image size: ${compressedSize / 1024}KB');

          if (compressedSize <= maxSizeInBytes) {
            await _uploadAndUpdateProfile(File(result.path));
          } else {
            // Try one more compression with lower quality
            final secondTargetPath = path.join(
              tempDir.path,
              'compressed_2_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}',
            );

            final secondResult = await FlutterImageCompress.compressAndGetFile(
              result.path,
              secondTargetPath,
              quality: 50,
              // Remove format parameter to let the plugin determine format based on extension
            );

            if (secondResult != null) {
              final finalSize = await secondResult.length();
              debugPrint('Final compressed size: ${finalSize / 1024}KB');
              await _uploadAndUpdateProfile(File(secondResult.path));
            }
          }
        } else {
          // If compression failed, try to upload the original
          await _uploadAndUpdateProfile(originalFile);
        }
      } catch (compressError) {
        debugPrint('Error during compression: $compressError');
        // Fallback to original file if compression fails
        await _uploadAndUpdateProfile(originalFile);
      }
    } catch (e) {
      debugPrint('Error picking/compressing image: $e');
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'Gagal memperbarui foto profil: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadAndUpdateProfile(File imageFile) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Delete old avatar if exists
      await _deleteOldAvatar();

      // Upload image to Supabase Storage
      final fileExt = path.extension(imageFile.path);
      final fileName =
          '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'avatars/$fileName';

      await Supabase.instance.client.storage
          .from('images')
          .upload(filePath, imageFile);

      // Get the public URL
      final imageUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(filePath);

      // Update user profile with new avatar URL
      await Supabase.instance.client
          .from('user_profile')
          .update({'avatar_url': imageUrl}).eq('user_id', currentUser.id);

      // Reload profile data
      await _loadUserProfile();

      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'Foto profil berhasil diperbarui',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<void> _deleteOldAvatar() async {
    try {
      // Check if user already has an avatar
      if (_userProfile?.avatarUrl == null || _userProfile!.avatarUrl!.isEmpty) {
        return;
      }

      final avatarUrl = _userProfile!.avatarUrl!;

      // Extract the file path from the URL
      // https://[project-ref].supabase.co/storage/v1/object/public/images/avatars/filename.jpg

      // Parse the URL to extract the file path
      Uri uri = Uri.parse(avatarUrl);

      // extract just the avatars/filename.jpg part
      final pathSegments = uri.path.split('/');
      int imagesIndex = pathSegments.indexOf('images');

      if (imagesIndex >= 0 && imagesIndex < pathSegments.length - 1) {
        final storagePath = pathSegments.sublist(imagesIndex + 1).join('/');

        // Delete the file from storage
        await Supabase.instance.client.storage
            .from('images')
            .remove([storagePath]);
        debugPrint('Successfully deleted old avatar: $storagePath');
      }
    } catch (e) {
      // Just log the error but continue with the upload process
      debugPrint('Error deleting old avatar: $e');
    }
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          _showEditProfileDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Edit Profil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    if (_userProfile == null) {
      CustomSnackbar.show(
        context: context,
        message: 'Tidak dapat memuat data profil',
        type: SnackbarType.error,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userProfile: _userProfile!),
      ),
    ).then((result) {
      if (result == true) {
        // Reload profile data if edit was successful
        _loadUserProfile();
      }
    });
  }
}
