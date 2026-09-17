import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../models/status_item.dart';
import 'media_gallery_service.dart';
import 'settings_service.dart';
import 'status_folder_service.dart';

class StatusService {
  final SettingsService _settingsService;
  final StatusFolderService _folderService;

  StatusService(this._settingsService, this._folderService);

  static const _picturesSave =
      '/storage/emulated/0/Pictures/${AppConstants.saveFolderName}';
  static const _moviesSave =
      '/storage/emulated/0/Movies/${AppConstants.saveFolderName}';
  static const _legacyDownloadSave =
      '/storage/emulated/0/Download/${AppConstants.saveFolderName}';
  static const _legacyPicturesSave =
      '/storage/emulated/0/Pictures/${AppConstants.legacySaveFolderName}';
  static const _legacyMoviesSave =
      '/storage/emulated/0/Movies/${AppConstants.legacySaveFolderName}';
  static const _legacyOldDownloadSave =
      '/storage/emulated/0/Download/${AppConstants.legacySaveFolderName}';

  /// Primary folder shown in Settings (images live under Pictures).
  Future<String> getSaveDirectory() async {
    final savedPath = _settingsService.saveFolderPath;
    if (savedPath != null &&
        savedPath.isNotEmpty &&
        !savedPath.contains('/Android/data/')) {
      final dir = Directory(savedPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return savedPath;
    }

    final picturesDir = Directory(_picturesSave);
    if (picturesDir.existsSync() || await _tryCreateDir(picturesDir)) {
      await _settingsService.setSaveFolderPath(picturesDir.path);
      return picturesDir.path;
    }

    final downloadDir = Directory(_legacyDownloadSave);
    if (downloadDir.existsSync() || await _tryCreateDir(downloadDir)) {
      await _settingsService.setSaveFolderPath(downloadDir.path);
      return downloadDir.path;
    }

    final externalDir = await getExternalStorageDirectory();
    final fallback =
        Directory(p.join(externalDir!.path, AppConstants.saveFolderName));
    if (!fallback.existsSync()) {
      fallback.createSync(recursive: true);
    }
    await _settingsService.setSaveFolderPath(fallback.path);
    return fallback.path;
  }

  /// All public folders where saved statuses may live (new + legacy).
  Future<List<String>> _savedSearchDirectories() async {
    final dirs = <String>{
      _picturesSave,
      _moviesSave,
      _legacyDownloadSave,
      _legacyPicturesSave,
      _legacyMoviesSave,
      _legacyOldDownloadSave,
      await getSaveDirectory(),
    };
    return dirs.toList();
  }

  String _destDirFor(StatusItem item) {
    return item.isVideo ? _moviesSave : _picturesSave;
  }

  Future<bool> _tryCreateDir(Directory dir) async {
    try {
      dir.createSync(recursive: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns every status cache folder on the device that exists and can be
  /// listed without throwing.
  ///
  /// NOTE: a folder passing this check does NOT mean it is genuinely readable.
  /// Under scoped storage (Android 11+) a blocked directory frequently reports
  /// `existsSync() == true` and then returns an EMPTY listing instead of
  /// throwing. Callers must therefore judge access on whether media actually
  /// came back — see [_readDirectStatuses] — never on this list being
  /// non-empty.
  List<String> findStatusDirectories() {
    final found = <String>[];
    for (final path in AppConstants.statusCachePaths) {
      try {
        final dir = Directory(path);
        if (dir.existsSync()) {
          // Confirm we can actually list it (permission check).
          dir.listSync(followLinks: false);
          found.add(path);
          if (kDebugMode) {
            debugPrint('Status folder listable: $path');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Status folder blocked/unreadable: $path ($e)');
        }
      }
    }
    return found;
  }

  /// Media obtained by reading the status folders directly. Empty means direct
  /// access is unavailable OR there is genuinely nothing to show; either way
  /// the folder grant is the next thing to try.
  List<StatusItem> _readDirectStatuses() {
    final items = _readFromDirectories(findStatusDirectories());
    if (kDebugMode) {
      debugPrint('Direct status read produced ${items.length} item(s)');
    }
    return items;
  }

  /// True when statuses are unreachable both directly and via a folder grant,
  /// so the UI should ask the user to pick the status folder.
  Future<bool> needsFolderAccess() async {
    // A grant already exists — never prompt again.
    if (await _folderService.hasAccess()) return false;

    // Only skip the prompt if direct reads actually yield media. Treating a
    // silently-empty listing as "access works" is what previously hid the
    // Status tab behind a permanently empty grid.
    return _readDirectStatuses().isEmpty;
  }

  /// Direct reads work on some devices; where scoped storage blocks them the
  /// user's one-time folder grant supplies the same media via cached copies.
  Future<List<StatusItem>> _loadAllStatuses() async {
    final direct = _readDirectStatuses();
    if (direct.isNotEmpty) return direct;

    if (await _folderService.hasAccess()) {
      final synced = await _folderService.syncStatuses();
      if (kDebugMode) {
        debugPrint('Folder-grant sync produced ${synced.length} item(s)');
      }
      return synced;
    }

    return direct;
  }

  List<StatusItem> _readFromDirectories(List<String> statusDirs) {
    final items = <StatusItem>[];
    final seenKeys = <String>{};

    for (final statusDir in statusDirs) {
      try {
        final dir = Directory(statusDir);
        final files = dir.listSync(followLinks: false).whereType<File>();

        for (final file in files) {
          final name = p.basename(file.path);
          final ext = p.extension(file.path).toLowerCase();

          // Skip hidden / system files (.nomedia, temp), keep media.
          if (name == '.nomedia' || name.startsWith('._')) continue;
          final isVideo = AppConstants.videoExtensions.contains(ext);
          if (!isVideo && !AppConstants.imageExtensions.contains(ext)) continue;

          // Avoid duplicates across multiple status folders.
          if (!seenKeys.add('$name-${file.lengthSync()}')) continue;

          items.add(StatusItem(
            path: file.path,
            name: name,
            type: isVideo ? MediaType.video : MediaType.image,
            modified: file.lastModifiedSync(),
          ));
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed listing $statusDir: $e');
        }
      }
    }

    return items;
  }

  Future<List<StatusItem>> getStatuses({required bool videos}) async {
    final items = (await _loadAllStatuses())
        .where((item) => item.isVideo == videos)
        .toList();
    items.sort((a, b) => b.modified.compareTo(a.modified));
    return items;
  }

  Future<List<StatusItem>> getSavedStatuses({required bool videos}) async {
    final extensions =
        videos ? AppConstants.videoExtensions : AppConstants.imageExtensions;
    final items = <StatusItem>[];
    final seenNames = <String>{};

    for (final saveDir in await _savedSearchDirectories()) {
      final dir = Directory(saveDir);
      if (!dir.existsSync()) continue;

      try {
        final files = dir
            .listSync()
            .whereType<File>()
            .where((file) {
              final ext = p.extension(file.path).toLowerCase();
              return extensions.contains(ext);
            })
            .toList();

        for (final file in files) {
          final name = p.basename(file.path);
          if (seenNames.contains(name)) continue;
          seenNames.add(name);

          final ext = p.extension(file.path).toLowerCase();
          items.add(StatusItem(
            path: file.path,
            name: name,
            type: AppConstants.videoExtensions.contains(ext)
                ? MediaType.video
                : MediaType.image,
            modified: file.lastModifiedSync(),
          ));
        }
      } catch (_) {}
    }

    items.sort((a, b) => b.modified.compareTo(a.modified));
    return items;
  }

  Future<bool> isAlreadySaved(StatusItem item) async {
    for (final saveDir in await _savedSearchDirectories()) {
      if (File(p.join(saveDir, item.name)).existsSync()) {
        return true;
      }
    }
    return false;
  }

  Future<String?> saveStatus(StatusItem item) async {
    try {
      // Already on disk — re-scan so Gallery picks it up if it missed it before.
      for (final saveDir in await _savedSearchDirectories()) {
        final existing = File(p.join(saveDir, item.name));
        if (existing.existsSync()) {
          await MediaGalleryService.scanFile(existing.path);
          return existing.path;
        }
      }

      // Prefer MediaStore so Gallery apps index the file immediately.
      final galleryPath = await MediaGalleryService.saveToGallery(
        sourcePath: item.path,
        fileName: item.name,
        isVideo: item.isVideo,
      );
      if (galleryPath != null && galleryPath.isNotEmpty) {
        await _settingsService.setSaveFolderPath(
          item.isVideo ? _moviesSave : _picturesSave,
        );
        return galleryPath;
      }

      // Fallback: copy into a public folder, then ask MediaStore to scan it.
      final saveDir = _destDirFor(item);
      final dir = Directory(saveDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final destPath = p.join(saveDir, item.name);
      await File(item.path).copy(destPath);
      await MediaGalleryService.scanFile(destPath);
      await _settingsService.setSaveFolderPath(saveDir);
      return destPath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('saveStatus failed: $e');
      }
      return null;
    }
  }

  Future<void> autoSaveNewStatuses() async {
    if (!_settingsService.autoSave) return;

    for (final item in await _loadAllStatuses()) {
      if (!await isAlreadySaved(item)) {
        await saveStatus(item);
      }
    }
  }
}
