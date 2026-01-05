import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Added the import for animations
import '/Screens/auth/controller/auth_controller.dart';
import '/Screens/auth/sign_in_screen.dart';
import '/core/constant/app_colors.dart';
import '/core/constant/input_formatters.dart';
import '/core/constant/validators.dart';
import '/core/utils/app_spaces.dart';
import '/custom_widgets/app_buttons.dart';
import '/custom_widgets/custom_app_textfield.dart'
    show CustomTextFormField;
import '/custom_widgets/main_base_scaffold.dart';
import '/routes/app_routes.dart';

class SignUpScreen extends GetView<AuthController> {
  static const routeName = '/sign-up';
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainBaseScaffold(
      body: SingleChildScrollView(
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              100.heightBox,
              Text(
                '👋 Welcome!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              )
                  // Animation 1: Title slides in from the top
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: -0.5),
              20.heightBox,
              Text(
                'Create your account to get started with RangeScan 🚀',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              )
                  // Animation 2: Subtitle slides in below the title
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 100.ms)
                  .slideY(begin: -0.3),
        
              20.heightBox,
              CustomTextFormField(
                title: 'First Name',
                labelText: 'Enter your first name',
                isRequired: true,
                controller: controller.signupFirstNameCtrl,
                validator: Validators.nameValidator.call,
                inputFormatters: InputFormat.nameFormatter,
                prefixWidget: Icon(
                  EneftyIcons.user_outline,
                  color: AppColors.textSecondary,
                ),
              )
                  // Animation 3: First Name field slides in from the left
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideX(begin: -0.1),
        
              CustomTextFormField(
                title: 'Location',
                labelText: 'Enter your location',
                isRequired: true,
                focusNode: controller.locationFocus,
                controller: controller.locationCtrl,
                enabled: true,
                prefixWidget: Icon(
                  EneftyIcons.location_outline,
                  color: AppColors.textSecondary,
                ),
                onTap: () {
                  controller.locationFocus.unfocus();
                  controller.pickCountry(context);
                },
              )
                  // Animation 4: Location field slides in from the right
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .slideX(begin: 0.1),
              
              CustomTextFormField(
                title: 'Email',
                labelText: 'Enter your email',
                isRequired: true,
                controller: controller.signupEmailCtrl,
                inputFormatters: InputFormat.denySpace,
                validator: Validators.emailValidator.call,
                keyboardType: TextInputType.emailAddress,
                prefixWidget: Icon(
                  EneftyIcons.sms_outline,
                  color: AppColors.textSecondary,
                ),
              )
                  // Animation 5: Email field slides in from the left
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms)
                  .slideX(begin: -0.1),
              
              10.heightBox,
              Obx(
                () => CustomTextFormField(
                  title: 'Password',
                  labelText: 'Enter your password',
                  isRequired: true,
                  controller: controller.signupPasswordCtrl,
                  inputFormatters: InputFormat.denySpace,
                  validator: Validators.passwordValidator.call,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: controller.isPasswordVisible.value,
                  autofillHints: const [AutofillHints.password],
                  prefixWidget: Icon(
                    EneftyIcons.lock_outline,
                    color: AppColors.textSecondary,
                  ),
                  suffixWidget: GestureDetector(
                    onTap: () {
                      controller.togglePassword(controller.isPasswordVisible);
                    },
                    child: Icon(
                      controller.isPasswordVisible.value
                          ? EneftyIcons.eye_slash_outline
                          : EneftyIcons.eye_outline,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 500.ms)
                    .slideX(begin: 0.1),
              ),
        
              30.heightBox,
              AppAsyncLoadingButton(
                isLoading: controller.isLoading,
                title: 'Sign up',
                onTap: () async {
                  controller.signup();
                },
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 600.ms)
                  .scale(delay: 600.ms, duration: 400.ms, curve: Curves.easeOutBack),
              
              40.heightBox,
              _buildDivider()
                  // Animation 8: Divider fades in
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 700.ms),
              
              20.heightBox,
              GoogleSignButton(
                onTap: () {
                  controller.signInWithGoogle();
                },
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 800.ms)
                  .scale(delay: 800.ms, duration: 400.ms, curve: Curves.easeOutBack),
              
              20.heightBox,
              AppCommonButton(
                isOutlined: true,
                text: 'Already have an account?  Sign In',
                onPressed: () {
                  controller.clearTextField();
                  Get.toNamed(AppRoutes.SIGN_IN);
                },
              ) .animate()
                  .fadeIn(duration: 500.ms, delay: 900.ms)
                  .slideY(begin: 0.5),
                    50.heightBox,
            ],
          ),
        ),
      ),
    );
  }

  // Helper widgets are included here to make the file runnable.
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.textPrimary)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: TextStyle(color: AppColors.textPrimary)),
        ),
        const Expanded(child: Divider(color: AppColors.textPrimary)),
      ],
    );
  }
}
