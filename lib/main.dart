import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// TODO(next release): re-enable AdMob
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'services/settings_service.dart';
import 'services/status_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase + background handler MUST be ready before runApp.
  try {
    await NotificationService.instance.initFirebase();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Firebase init failed: $e\n$st');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(prefs);
  final statusService = StatusService(settingsService);
  final permissionService = PermissionService();

  runApp(StatusSaverApp(
    settingsService: settingsService,
    statusService: statusService,
    permissionService: permissionService,
  ));

  // Permissions, listeners, token — after first frame.
  _initServicesInBackground();
}

Future<void> _initServicesInBackground() async {
  try {
    await NotificationService.instance.init();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('NotificationService init failed: $e\n$st');
    }
  }

  // TODO(next release): re-enable AdMob
  // try {
  //   await MobileAds.instance.initialize();
  // } catch (e, st) {
  //   if (kDebugMode) {
  //     debugPrint('MobileAds init failed: $e\n$st');
  //   }
  // }
}

class StatusSaverApp extends StatefulWidget {
  final SettingsService settingsService;
  final StatusService statusService;
  final PermissionService permissionService;

  const StatusSaverApp({
    super.key,
    required this.settingsService,
    required this.statusService,
    required this.permissionService,
  });

  @override
  State<StatusSaverApp> createState() => _StatusSaverAppState();
}

class _StatusSaverAppState extends State<StatusSaverApp> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Status Saver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _showSplash
          ? SplashScreen(onComplete: _onSplashComplete)
          : HomeScreen(
              settingsService: widget.settingsService,
              statusService: widget.statusService,
              permissionService: widget.permissionService,
            ),
    );
  }
}
