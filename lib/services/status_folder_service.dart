import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/status_item.dart';

enum FolderAccessResult { granted, cancelled, wrongFolder, unavailable }

/// One-time folder grant on the messaging app's status folder, used when the
/// app cannot read that folder directly. Documents are copied into the app
/// cache by the platform side, so callers still get plain file paths.
class StatusFolderService {
  static const _channel = MethodChannel(
    'com.statusdownloader.download.videoimagesaver/saf',
  );

  Future<bool> hasAccess() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('hasAccess') ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StatusFolderService.hasAccess failed: $e');
      }
      return false;
    }
  }

  Future<FolderAccessResult> requestAccess({bool business = false}) async {
    if (!Platform.isAndroid) return FolderAccessResult.unavailable;
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'requestAccess',
        {'business': business},
      );
      if (response?['granted'] == true) return FolderAccessResult.granted;

      return switch (response?['reason']) {
        'wrong_folder' => FolderAccessResult.wrongFolder,
        'cancelled' => FolderAccessResult.cancelled,
        _ => FolderAccessResult.unavailable,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StatusFolderService.requestAccess failed: $e');
      }
      return FolderAccessResult.unavailable;
    }
  }

  Future<List<StatusItem>> syncStatuses() async {
    if (!Platform.isAndroid) return [];
    try {
      final response = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'syncStatuses',
      );
      if (response == null) return [];

      return response.map((entry) {
        final isVideo = entry['isVideo'] == true;
        return StatusItem(
          path: entry['path'] as String,
          name: entry['name'] as String,
          type: isVideo ? MediaType.video : MediaType.image,
          modified: DateTime.fromMillisecondsSinceEpoch(
            entry['lastModified'] as int,
          ),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StatusFolderService.syncStatuses failed: $e');
      }
      return [];
    }
  }

  Future<void> releaseAccess() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('releaseAccess');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StatusFolderService.releaseAccess failed: $e');
      }
    }
  }
}
