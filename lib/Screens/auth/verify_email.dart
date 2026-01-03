import 'dart:async';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Added for animation
import '/Screens/auth/controller/auth_controller.dart';
import '/core/constant/app_colors.dart';
import '/core/utils/app_spaces.dart';
import '/custom_widgets/app_buttons.dart';
import '/custom_widgets/main_base_scaffold.dart';
import '/routes/app_routes.dart';

class VerifyEmailScreen extends GetView<AuthController> {
  static const routeName = '/verify-email';
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? email = controller.firebaseAuth.currentUser?.email;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer.periodic(const Duration(seconds: 2), (timer) async {
        await controller.firebaseAuth.currentUser?.reload();
        final user = controller.firebaseAuth.currentUser;
        if (user != null && user.emailVerified) {
          timer.cancel();
          Get.offAndToNamed(AppRoutes.CONNECTION_SCREEN);
        }
      });
    });

    return MainBaseScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          50.heightBox,
          const Icon(
                EneftyIcons.message_outline,
                size: 80,
                color: AppColors.primary,
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                delay: 200.ms,
                duration: 500.ms,
                curve: Curves.easeOutBack,
                begin: Offset(1, 0.5),
              ),
          30.heightBox,
          if (email != null)
            Text(
                  'Verification link sent to:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                )
                // Animation 2: Text slides and fades in
                .animate()
                .fadeIn(duration: 500.ms, delay: 400.ms)
                .slideY(begin: 0.2),
          if (email != null) ...[
            8.heightBox,
            Text(
                  email,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
                // Animation 3: Email text slides and fades in
                .animate()
                .fadeIn(duration: 500.ms, delay: 500.ms)
                .slideY(begin: 0.2),
          ],
          20.heightBox,
          Text(
                'We have sent a verification link to your email address. '
                'Please check your inbox or spam folder and click the link to continue.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              )
              // Animation 4: Description text fades in
              .animate()
              .fadeIn(duration: 500.ms, delay: 600.ms),
          40.heightBox,

          // Resend email button
          AppAsyncLoadingButton(
                title: 'Resend Verification Email',
                onTap: () async {
                  await controller.resendVerificationEmail();
                },
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 800.ms)
              .scale(
                delay: 800.ms,
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),

          20.heightBox,

          // Manual check button (optional fallback)
          AppAsyncLoadingButton(
                title: 'I Verified, Continue',
                onTap: () async {
                  await controller.checkEmailVerified();
                },
              )
              // Animation 6: Continue button scales up
              .animate()
              .fadeIn(duration: 500.ms, delay: 900.ms)
              .scale(
                delay: 900.ms,
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),

          20.heightBox,

          AppCommonButton(
                text: 'Back to Sign In',
                isOutlined: true,
                onPressed: () {
                  Get.toNamed(AppRoutes.SIGN_IN);
                },
              )
              // Animation 7: Back button slides up
              .animate()
              .fadeIn(duration: 500.ms, delay: 1000.ms)
              .slideY(begin: 0.2),
               50.heightBox,
        ],
      ),
    );
  }
}
