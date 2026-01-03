import 'dart:ui'; // 👈 for BackdropFilter
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
// Updated imports based on new project structure (RangeScan)
import '/Screens/auth/controller/auth_controller.dart';
import '/core/constant/app_colors.dart';

void showLogoutDialog(BuildContext context) {
  final theme = Theme.of(context);

  

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    // Localization removed
    barrierLabel: 'Log Out', 
    pageBuilder: (_, __, ___) => const SizedBox(),
    transitionBuilder: (context, animation, secondaryAnimation, _) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
          ),
          child: Dialog(
            backgroundColor: Colors.transparent, // 👈 transparent
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 👈 blur effect
                child: Container(
                  height: 250,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: BoxDecoration(
                    // FORCING DARK THEME LOOK (Transparent Black/Dark Gray)
                    color: Colors.black.withOpacity(0.6), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: GetBuilder<AuthController>(builder: (controller) {
                    return Column(
                      
                      children: [
                        // Floating logout icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              // FORCING DARK THEME LOOK (Subtle light color on dark surface)
                              color: Colors.white.withOpacity(0.15), 
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  // Using dark shadow regardless of system theme
                                  color: Colors.black26, 
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Icon(
                              EneftyIcons.logout_2_outline,
                              size: 29,
                              color: Colors.redAccent,
                            ),
                          )
                              .animate()
                              .slideX(begin: -1.5, duration: 700.ms, curve: Curves.easeOutBack)
                              .then(delay: 200.ms),
                        ),

                        // Dialog content
                        const SizedBox(height: 16),
                        Text(
                          // Localization removed
                          'Are you sure?', 
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Ensure text is white for contrast
                          ),
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          // Localization removed
                          'Do you really want to log out?', 
                          style: theme.textTheme.bodyMedium?.copyWith(
                            // Ensure text is light for contrast on dark background
                            color: Colors.white.withOpacity(0.9), 
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.5),
                        
                        const SizedBox(height: 24),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                // Localization removed
                                'Cancel', 
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70, // Ensure button text is visible
                                ),
                              ),
                            ).animate().fadeIn(delay: 200.ms),
                            
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                controller.logout();
                              },
                              style: ElevatedButton.styleFrom(
                                // Updated to AppColors.primary based on context
                                backgroundColor: AppColors.primary, 
                              ),
                              child: const Text(
                                // Localization removed
                                'Log Out', 
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ).animate().fadeIn(delay: 250.ms).scale(),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
  );
}
