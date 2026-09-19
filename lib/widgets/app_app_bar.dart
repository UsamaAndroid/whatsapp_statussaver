import 'package:flutter/material.dart';
import '../core/constants.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Screen name shown in the bar. Defaults to the app name, which is what
  /// the home screen wants; every pushed screen should pass its own so the
  /// user can tell where they are.
  final String? title;
  final bool showBackButton;
  final VoidCallback? onShareApp;
  final VoidCallback? onSendFeedback;

  const AppAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.onShareApp,
    this.onSendFeedback,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppConstants.primaryGreen,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title ?? AppConstants.appName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.send_outlined),
          onPressed: onSendFeedback,
          tooltip: 'Send feedback',
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: onShareApp,
          tooltip: 'Share app',
        ),
      ],
    );
  }
}
