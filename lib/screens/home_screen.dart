import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../services/interstitial_ad_service.dart';
import '../services/permission_service.dart';
import '../services/settings_service.dart';
import '../services/status_service.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/usage_guide_dialog.dart';
import 'direct_chat_tab_screen.dart';
import 'saved_tab_screen.dart';
import 'settings_tab_screen.dart';
import 'status_tab_screen.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settingsService;
  final StatusService statusService;
  final PermissionService permissionService;

  const HomeScreen({
    super.key,
    required this.settingsService,
    required this.statusService,
    required this.permissionService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await widget.permissionService.requestMediaPermission();

    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    if (mounted) {
      await widget.permissionService.requestNotificationPermission();
    }

    await widget.statusService.autoSaveNewStatuses();

    if (!widget.settingsService.guideShown && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UsageGuideDialog.show(context);
        widget.settingsService.setGuideShown(true);
      });
    }
  }

  void _shareApp() {
    Share.share(AppConstants.shareMessage);
  }

  Future<void> _sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'zargarapps6@gmail.com',
      queryParameters: {
        'subject': '${AppConstants.appName} Feedback',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Shows an interstitial (when one is ready) and then opens [page]. If no
  /// ad is loaded the navigation happens immediately — the user never waits
  /// on an ad.
  void _openPageAfterAd(Widget page) {
    InterstitialAdService.instance.showThen(
      onContinue: () {
        if (mounted) _openPage(page);
      },
    );
  }

  void _openStatus() {
    _openPage(
      StatusTabScreen(
        statusService: widget.statusService,
        onShareApp: _shareApp,
        onSendFeedback: _sendFeedback,
        showBackButton: true,
      ),
    );
  }

  void _openSaved() {
    _openPageAfterAd(
      SavedTabScreen(
        statusService: widget.statusService,
        onShareApp: _shareApp,
        onSendFeedback: _sendFeedback,
        showBackButton: true,
      ),
    );
  }

  void _openChat() {
    _openPageAfterAd(
      DirectChatTabScreen(
        onShareApp: _shareApp,
        onSendFeedback: _sendFeedback,
        showBackButton: true,
      ),
    );
  }

  void _openSettings() {
    _openPageAfterAd(
      SettingsTabScreen(
        settingsService: widget.settingsService,
        statusService: widget.statusService,
        onShareApp: _shareApp,
        onSendFeedback: _sendFeedback,
        showBackButton: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        onShareApp: _shareApp,
        onSendFeedback: _sendFeedback,
      ),
      // Pinned to the bottom; the body is laid out above it, so the menu
      // grid is never overlapped by the ad.
      bottomNavigationBar: const NativeAdWidget(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What do you want to do?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a section below',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.05,
                  children: [
                    _HomeMenuButton(
                      icon: Icons.radio_button_checked_outlined,
                      label: 'New Status',
                      subtitle: 'View & save statuses',
                      onTap: _openStatus,
                    ),
                    _HomeMenuButton(
                      icon: Icons.image_outlined,
                      label: 'Saved',
                      subtitle: 'Your saved media',
                      onTap: _openSaved,
                    ),
                    _HomeMenuButton(
                      icon: Icons.chat_outlined,
                      label: 'Chat',
                      subtitle: 'Message without saving',
                      onTap: _openChat,
                    ),
                    _HomeMenuButton(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      subtitle: 'App preferences',
                      onTap: _openSettings,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeMenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppConstants.primaryGreen.withOpacity(0.25),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: AppConstants.primaryGreen,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.darkGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
