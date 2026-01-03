import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import is correctly handled
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

class SignInScreen extends GetView<AuthController> {
  static const routeName = '/sign-in-screen';
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainBaseScaffold(
      body: SingleChildScrollView(
        child: Form(
          key: controller.loginFormKey,
          child: Column(
            children: [
              120.heightBox,
              Text(
                    '🚀 Ready to Scan?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .moveY(begin: -50, end: 0, curve: Curves.easeOut)
                  .then(delay: 100.ms)
                  .shake(
                    hz: 2,
                    duration: 300.ms,
                    rotation: 0.001,
                  ), // Subtle finishing effect
              20.heightBox,
              Text(
                    'Sign in and keep making progress with RangeScan',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 100.ms)
                  .slideY(begin: -0.3, curve: Curves.easeOut),
              20.heightBox,
              CustomTextFormField(
                    title: 'Email',
                    labelText: 'Enter your email',
                    isRequired: true,
                    controller: controller.loginEmailCtrl,
                    inputFormatters: InputFormat.denySpace,
                    validator: Validators.emailValidator.call,
                    keyboardType: TextInputType.emailAddress,
                    prefixWidget: Icon(
                      EneftyIcons.sms_outline,
                      color: AppColors.textSecondary,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .slideX(begin: -0.2, curve: Curves.easeOut),
              10.heightBox,
              Obx(
                () => CustomTextFormField(
                      title: 'Password',
                      labelText: 'Enter your password',
                      isRequired: true,
                      controller: controller.loginPasswordCtrl,
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
                          controller.togglePassword(
                            controller.isPasswordVisible,
                          );
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
                    .fadeIn(duration: 500.ms, delay: 400.ms)
                    .slideX(begin: 0.2, curve: Curves.easeOut),
              ),
              16.heightBox,
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                      onTap: () {
                        controller.clearTextField();
                        Get.toNamed(AppRoutes.FORGET_PASSWORD);
                      },
                      child: Text(
                        'Forget Password?',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 500.ms)
                    .slideX(begin: 0.1),
              ),
              20.heightBox,
              AppAsyncLoadingButton(
                    isLoading: controller.isLoading,
                    title: 'Sign In',
                    onTap: () async {
                      controller.login();
                    },
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .scaleXY(begin: 0.8, curve: Curves.easeOutBack),
              40.heightBox,
              _buildDivider()
                  // Animation 7: Divider fades in
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 700.ms),
              20.heightBox,
              GoogleSignButton(
                    onTap: () {
                      controller.signInWithGoogle();
                    },
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 900.ms)
                  .scale(curve: Curves.elasticOut),
              20.heightBox,
              AppCommonButton(
                    isOutlined: true,
                    text: 'Don\'t have an account?  Sign Up',
                    onPressed: () {
                      controller.clearTextField();
                      Get.toNamed(AppRoutes.SIGN_UP);
                    },
                  )
                  // Animation 9: Sign Up button slides up from the bottom
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 1000.ms)
                  .slideY(begin: 1, curve: Curves.easeOut),
                   50.heightBox,
            ],
          ),
        ),
      ),
    );
  }

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

class GoogleSignButton extends StatelessWidget {
  final VoidCallback? onTap;
  const GoogleSignButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Image.asset('assets/google.png', height: 40, width: 40),
        ),
      ),
    );
  }
}
