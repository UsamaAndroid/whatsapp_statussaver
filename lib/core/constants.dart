import 'package:flutter/material.dart';

class AppConstants {
  static const Color primaryGreen = Color(0xFF7BC142);
  static const Color darkGreen = Color(0xFF1E4620);
  static const Color inactiveGrey = Color(0xFF9E9E9E);

  static const String appName = 'Status Saver';
  static const String saveFolderName = 'StatusSaver';
  /// Older installs may still have files under this folder name.
  static const String legacySaveFolderName = 'WAStatusSaver';

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.statusdownloader.download.videoimagesaver';

  static const String shareMessage =
      'Download $appName — save and manage statuses easily!\n$playStoreUrl';

  /// Required by Play trademark / impersonation policies.
  static const String trademarkDisclaimer =
      'Status Saver is an independent app and is not affiliated with, '
      'endorsed by, or connected to WhatsApp, Meta, or any related company. '
      'All trademarks belong to their respective owners.';

  /// Common status cache locations used by messaging apps on device storage.
  static const List<String> statusCachePaths = [
    // Messaging app (Android 11+ scoped media path)
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    // Legacy path
    '/storage/emulated/0/WhatsApp/Media/.Statuses',
    // Business app (Android 11+)
    '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
    // Business legacy
    '/storage/emulated/0/WhatsApp Business/Media/.Statuses',
    // Some OEM / dual-app variants
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/Statuses',
    '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/Statuses',
    '/sdcard/WhatsApp/Media/.Statuses',
    '/sdcard/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    '/sdcard/WhatsApp Business/Media/.Statuses',
    '/sdcard/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
  ];

  static const List<String> imageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
  ];
  static const List<String> videoExtensions = [
    '.mp4',
    '.3gp',
    '.mkv',
    '.avi',
    '.mov',
  ];

  static const String privacyPolicyUrl =
      'https://docs.google.com/document/d/e/2PACX-1vRWApv9V1MiqjwmQusRYkBv4jO25mZTHh29PC7-YXeWchjRm10K1nCyJFav5liaL9d9en9oIZFDMtPS/pub';

  /// TODO(next release): replace with real AdMob IDs and re-enable ads
  // static const String admobAppId =
  //     'ca-app-pub-3940256099942544~3347511713';
  // static const String bannerAdUnitId =
  //     'ca-app-pub-3940256099942544/6300978111';
}
