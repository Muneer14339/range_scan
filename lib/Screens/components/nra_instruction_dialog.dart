import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/core/constant/app_colors.dart';

Widget buildBulletPoint(String text) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class CustomDialog extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final BoxConstraints constraints;

  const CustomDialog({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF1A1A1A),
    this.borderRadius = 10,
    this.borderColor = AppColors.textPrimary,
    this.borderWidth = 2,
    this.constraints = const BoxConstraints(maxWidth: 450),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: borderColor, width: borderWidth),
          ),
          child: Container(
            // constraints: constraints,
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms) // Fades in smoothly
        .slide(
          begin: const Offset(0.1, 0.1),
          end: const Offset(0, 0),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}

class ActionButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  const ActionButton({super.key, required this.title, this.onTap, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: OutlinedButton(
            // Action for Cancel/Go Back
            onPressed:onCancel ?? () => Navigator.of(context).pop(null),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFF4CAF50,
              ), // Green for primary action
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class DialogHeaderWidget extends StatelessWidget {
  final String? title;
  const DialogHeaderWidget({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return // Header with warning icon
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              shape: BoxShape.circle,
            ),
            child: const Icon(EneftyIcons.danger_outline, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title ?? 'No holes detected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// --- Specific Dialog Implementations ---

/// Dialog for initial NRA Instructions with 'flutter_animate'.
class NRAInstructionsDialog extends StatelessWidget {
  final VoidCallback? onTap;
  const NRAInstructionsDialog({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Wrap the dialog content in an Animate widget
    final dialogContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DialogHeaderWidget(title: 'Important'),

        const SizedBox(height: 16),
        const Divider(color: Colors.white, thickness: 1),
        const SizedBox(height: 16),

        // Main description
        const Text(
          'NRA targets require BRIGHT background to scan properly.',
          style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 20),

        // You MUST section
        const Text(
          '✓ You MUST:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        buildBulletPoint('Remove target from range hanger'),
        buildBulletPoint('Hold against bright sky or light'),
        buildBulletPoint('Photograph with brightness maxed'),
        const SizedBox(height: 20),

        // Will NOT work section
        const Text(
          '✗ Will NOT work:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        buildBulletPoint('While hanging at shooting lane'),
        buildBulletPoint('Against dark walls'),
        buildBulletPoint('In dim/indoor lighting'),
        const SizedBox(height: 24),

        const Divider(color: Colors.white, thickness: 1),
        const SizedBox(height: 16),

        // Action buttons
        ActionButton(title: 'I understand', onTap: onTap),
      ],
    );

    return CustomDialog(child: dialogContent);
  }
}

/// Dialog displayed when no holes are detected. (No animation added here for focus, but can be done similarly)
class NoHolesDetectedDialog extends StatelessWidget {
  final VoidCallback? onRetake;
  final VoidCallback? onRetry;
  const NoHolesDetectedDialog({super.key, this.onRetake, this.onRetry});

  @override
  Widget build(BuildContext context) {
    // Reusing CustomDialog with specific styling changes
    return CustomDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      borderRadius: 4,
      borderColor: Colors.white,
      borderWidth: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogHeaderWidget(),
          const SizedBox(height: 16),

          // Main message
          const Text(
            'NRA targets need BRIGHT background.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Instructions section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.assignment, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Instructions:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          buildBulletPoint('Remove target from hanger'),
          buildBulletPoint('Hold against bright sky/light'),
          buildBulletPoint('Ensure good brightness behind it'),
          const SizedBox(height: 24),

          const Divider(color: Colors.white30, thickness: 1),
          const SizedBox(height: 16),

          // Action buttons (specific to this dialog)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetake, // Retake photo action
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text(
                    'Retake Photo',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:onRetry,
                    
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF2196F3,
                    ), // Blue for secondary action
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
