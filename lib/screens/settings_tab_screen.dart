import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/status_service.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/usage_guide_dialog.dart';

class SettingsTabScreen extends StatefulWidget {
  final SettingsService settingsService;
  final StatusService statusService;
  final VoidCallback onShareApp;
  final VoidCallback onSendFeedback;

  const SettingsTabScreen({
    super.key,
    required this.settingsService,
    required this.statusService,
    required this.onShareApp,
    required this.onSendFeedback,
  });

  @override
  State<SettingsTabScreen> createState() => _SettingsTabScreenState();
}

class _SettingsTabScreenState extends State<SettingsTabScreen> {
  bool _autoSave = false;
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

    if (mounted) {
      setState(() {
        _autoSave = widget.settingsService.autoSave;
        _saveFolderPath = savePath;
        _version = version.version;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAppBar(
          onShareApp: widget.onShareApp,
          onSendFeedback: widget.onSendFeedback,
        ),
        Expanded(
          child: ListView(
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
                  onChanged: (value) async {
                    await widget.settingsService.setAutoSave(value);
                    setState(() => _autoSave = value);
                    if (value) {
                      await widget.statusService.autoSaveNewStatuses();
                    }
                  },
                ),
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
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
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
          trailing: trailing,
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}
