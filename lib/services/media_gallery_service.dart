import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Saves media into public Pictures/Movies so Gallery apps can see it,
/// and triggers a MediaStore scan when needed.
class MediaGalleryService {
  MediaGalleryService._();

  static const _channel = MethodChannel(
    'com.statusdownloader.download.videoimagesaver/media',
  );

  /// Writes [sourcePath] into MediaStore (Pictures or Movies / StatusSaver).
  /// Returns the absolute path of the saved file, or null on failure.
  static Future<String?> saveToGallery({
    required String sourcePath,
    required String fileName,
    required bool isVideo,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      final path = await _channel.invokeMethod<String>('saveToGallery', {
        'sourcePath': sourcePath,
        'fileName': fileName,
        'isVideo': isVideo,
      });
      return path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaGalleryService.saveToGallery failed: $e');
      }
      return null;
    }
  }

  /// Asks Android to index an existing file so Gallery can show it.
  static Future<void> scanFile(String path) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<String>('scanFile', {'path': path});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaGalleryService.scanFile failed: $e');
      }
    }
  }
}
