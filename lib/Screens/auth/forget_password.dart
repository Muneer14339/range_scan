import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Added for animation
import '/Screens/auth/controller/auth_controller.dart';
import '/core/constant/app_colors.dart';
import '/core/constant/input_formatters.dart';
import '/core/constant/validators.dart';
import '/core/utils/app_spaces.dart';
import '/custom_widgets/app_buttons.dart';
import '/custom_widgets/custom_app_textfield.dart'
    show CustomTextFormField;
import '/custom_widgets/main_base_scaffold.dart';
import '/routes/app_routes.dart';

class ForgetPassword extends GetView<AuthController> {
  static const routeName = '/forget-password';
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return MainBaseScaffold(
      body: SingleChildScrollView(
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              150.heightBox,
              Text(
                    '🔑 Forgot Your Password?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  )
                  // Animation 1: Title slides and fades in
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: -0.5),
              20.heightBox,
              Text(
                    'No worries! Enter your registered email address below and we’ll send you instructions to reset your password.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(begin: -0.3),
              30.heightBox,
              CustomTextFormField(
                    title: 'Email',
                    labelText: 'Enter your email',
                    isRequired: true,
                    controller: controller.forgetPasswordCtrl,
                    inputFormatters: InputFormat.denySpace,
                    validator: Validators.emailValidator.call,
                    keyboardType: TextInputType.emailAddress,
                    prefixWidget: Icon(
                      EneftyIcons.sms_outline,
                      color: AppColors.textSecondary,
                    ),
                  )
                  // Animation 3: Email field slides and fades in
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms)
                  .slideX(begin: -0.1),
              30.heightBox,
              AppAsyncLoadingButton(
                    isLoading: controller.isLoading,
                    title: 'Send Reset Link',
                    onTap: () async {
                      await controller.resetPassword(
                        controller.forgetPasswordCtrl.text,
                      );
                    },
                  )
                  // Animation 4: Send button scales up
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 600.ms)
                  .scale(
                    delay: 600.ms,
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
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 800.ms)
                  .slideY(begin: 0.2),
                   50.heightBox,
            ],
          ),
        ),
      ),
    );
  }
}
