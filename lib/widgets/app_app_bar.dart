import 'package:flutter/material.dart';
import '../core/constants.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onShareApp;
  final VoidCallback? onSendFeedback;

  const AppAppBar({
    super.key,
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
      title: const Text(
        AppConstants.appName,
        style: TextStyle(
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
