import 'package:permission_handler/permission_handler.dart';

import '../domain/notification_permission_status.dart';

class NotificationPermissions {
  /// Requests notification permission from the OS.
  /// On Android 13+, shows the POST_NOTIFICATIONS dialog.
  /// On iOS, requests provisional authorization.
  Future<NotificationPermissionStatus> requestPermission() async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      return NotificationPermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      return NotificationPermissionStatus.permanentlyDenied;
    } else {
      return NotificationPermissionStatus.denied;
    }
  }

  /// Checks the current notification permission status.
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return NotificationPermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      return NotificationPermissionStatus.permanentlyDenied;
    } else {
      return NotificationPermissionStatus.denied;
    }
  }

  /// Returns true if notification permission is granted.
  Future<bool> get isGranted async {
    final status = await getPermissionStatus();
    return status == NotificationPermissionStatus.granted;
  }
}
