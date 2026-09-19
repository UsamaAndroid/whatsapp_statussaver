import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../services/interstitial_ad_service.dart';
import '../services/settings_service.dart';
import '../services/status_folder_service.dart';
import '../services/status_service.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/usage_guide_dialog.dart';

class SettingsTabScreen extends StatefulWidget {
  final SettingsService settingsService;
  final StatusService statusService;
  final VoidCallback onShareApp;
  final VoidCallback onSendFeedback;
  final bool showBackButton;

  const SettingsTabScreen({
    super.key,
    required this.settingsService,
    required this.statusService,
    required this.onShareApp,
    required this.onSendFeedback,
    this.showBackButton = false,
  });

  @override
  State<SettingsTabScreen> createState() => _SettingsTabScreenState();
}

class _SettingsTabScreenState extends State<SettingsTabScreen> {
  final StatusFolderService _folderService = StatusFolderService();

  bool _autoSave = false;
  bool _folderGranted = false;
  String _saveFolderPath = '';
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final version = await PackageInfo.fromPlatform();
    final savePath = await widget.statusService.getSaveDirectory();
    final folderGranted = await _folderService.hasAccess();

    if (mounted) {
      setState(() {
        _autoSave = widget.settingsService.autoSave;
        _folderGranted = folderGranted;
        _saveFolderPath = savePath;
        _version = version.version;
      });
    }
  }

  Future<void> _requestFolderAccess() async {
    final result = await _folderService.requestAccess();
    if (!mounted) return;

    if (result == FolderAccessResult.granted) {
      setState(() => _folderGranted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status folder access granted')),
      );
    } else if (result == FolderAccessResult.wrongFolder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That folder holds no statuses. Open the folder the picker starts '
            'in and tap "Use this folder".',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  /// Applies the Auto Save change first, then shows an interstitial. Doing it
  /// in that order means the setting is already persisted and reflected in the
  /// UI before the ad takes over the screen, so nothing is lost if the user
  /// dismisses the ad or backgrounds the app while it is up.
  Future<void> _onAutoSaveChanged(bool value) async {
    await widget.settingsService.setAutoSave(value);
    if (!mounted) return;
    setState(() => _autoSave = value);

    if (value) {
      await widget.statusService.autoSaveNewStatuses();
    }
    if (!mounted) return;

    await InterstitialAdService.instance.showThen(onContinue: () {});
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Settings',
        showBackButton: widget.showBackButton,
        onShareApp: widget.onShareApp,
        onSendFeedback: widget.onSendFeedback,
      ),
      bottomNavigationBar: const NativeAdWidget(),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Settings',
              style: TextStyle(
                color: AppConstants.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          _SettingsTile(
            title: 'How to use',
            subtitle: 'Know how to use this app to download statuses',
            onTap: () => UsageGuideDialog.show(context),
          ),
          _SettingsTile(
            title: 'Auto Save',
            subtitle: 'Automatically Save all New Statuses',
            trailing: Switch(
              value: _autoSave,
              onChanged: _onAutoSaveChanged,
            ),
          ),
          _SettingsTile(
            title: 'Status folder access',
            subtitle: _folderGranted
                ? 'Granted — tap to pick the folder again'
                : 'Only needed if your statuses do not show up',
            onTap: _requestFolderAccess,
          ),
          _SettingsTile(
            title: 'Save Statuses in Folder',
            subtitle: _saveFolderPath.isEmpty
                ? 'Loading...'
                : _saveFolderPath,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Save folder: $_saveFolderPath'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          _SettingsTile(
            title: 'Privacy policy',
            subtitle: 'Our Terms and conditions',
            onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
          ),
          _SettingsTile(
            title: 'Share with others',
            subtitle: 'Share this app with your beloved friends',
            onTap: widget.onShareApp,
          ),
          _SettingsTile(
            title: 'About',
            subtitle: 'Version: $_version',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Text(
              AppConstants.trademarkDisclaimer,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: trailing ??
              (onTap != null
                  ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
                  : null),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}
