import 'package:permission_handler/permission_handler.dart';

class MediaPermissionService {
  static final MediaPermissionService _instance =
      MediaPermissionService._internal();

  factory MediaPermissionService() => _instance;

  MediaPermissionService._internal();

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request gallery permission
  Future<bool> requestGalleryPermission() async {
    // For Android 13 and above, we need to request READ_MEDIA_IMAGES
    // For older versions, we need READ_EXTERNAL_STORAGE
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Check if camera permission is permanently denied
  Future<bool> isCameraPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  /// Check if gallery permission is permanently denied
  Future<bool> isGalleryPermanentlyDenied() async {
    final status = await Permission.photos.status;
    return status.isPermanentlyDenied;
  }
}
