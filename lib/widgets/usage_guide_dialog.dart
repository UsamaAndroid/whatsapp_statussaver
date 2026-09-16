import 'package:flutter/material.dart';
import '../core/constants.dart';

class UsageGuideDialog extends StatelessWidget {
  const UsageGuideDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const UsageGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Usage Guide',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _GuideStep(
                stepNumber: 1,
                icon: Icons.chat,
                iconColor: AppConstants.primaryGreen,
                title: 'Open the updates tab',
                description:
                    'Open your messaging app and go to the Updates / Status tab.',
              ),
              const SizedBox(height: 16),
              _GuideStep(
                stepNumber: 2,
                icon: Icons.play_circle_outline,
                iconColor: AppConstants.primaryGreen,
                title: 'Watch the full status',
                description:
                    'View the status completely so it becomes available to save.',
              ),
              const SizedBox(height: 16),
              _GuideStep(
                stepNumber: 3,
                icon: Icons.download,
                iconColor: AppConstants.primaryGreen,
                title: 'Save in Status Saver',
                description:
                    'Return here and tap the download button to save statuses.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'GOT IT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final int stepNumber;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _GuideStep({
    required this.stepNumber,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$stepNumber. $title',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
