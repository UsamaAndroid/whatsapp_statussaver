import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestMediaPermission() async {
    if (!Platform.isAndroid) return true;

    if (await _isAndroid13OrAbove()) {
      final photos = await Permission.photos.request();
      final videos = await Permission.videos.request();
      return photos.isGranted || videos.isGranted;
    }

    return (await Permission.storage.request()).isGranted;
  }

  Future<bool> hasMediaPermission() async {
    if (!Platform.isAndroid) return true;

    if (await _isAndroid13OrAbove()) {
      return await Permission.photos.isGranted ||
          await Permission.videos.isGranted;
    }

    return await Permission.storage.isGranted;
  }

  Future<void> openSettings() => openAppSettings();

  Future<bool> _isAndroid13OrAbove() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt >= 33;
    } catch (_) {
      return true;
    }
  }

  /// Android 13+ shows the system notification permission dialog.
  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    return await Permission.notification.isGranted;
  }
}
