import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestFilePermissions() async {
    // Check Android version for Scoped Storage
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    } else if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    } else if (await Permission.storage.isGranted) {
      return true;
    }

    // Redirect to app settings if permissions are permanently denied
    if (await Permission.manageExternalStorage.isPermanentlyDenied ||
        await Permission.storage.isPermanentlyDenied) {
      openAppSettings();
    }

    return false; // Return false if permissions are not granted
  }
}
