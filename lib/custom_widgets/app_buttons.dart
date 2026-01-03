import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '/core/constant/app_colors.dart';

class AppCommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined; // NEW
  final Color backgroundColor;
  final Color outlineColor; // NEW
  final double borderRadius;
  final double height;
  final double? width;
  final TextStyle? textStyle;

  const AppCommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false, // default = false
    this.backgroundColor = AppColors.primary,
    this.outlineColor = AppColors.primary,
    this.borderRadius = 12,
    this.height = 50,
    this.width,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isOutlined ? Border.all(color: outlineColor, width: 2) : null,
        boxShadow:
            isOutlined
                ? [] // no shadow for outlined button
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: Center(
          child: Text(
            text,
            style:
                textStyle ??
                TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    ).animate()
          .fadeIn(delay: Duration(milliseconds: 1200))
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))
          .then(delay: 200.ms)
          .shimmer(duration: 12000.ms, color: AppColors.primaryLight);
  }
}

class AppAsyncLoadingButton extends StatelessWidget {
  final String? title;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Widget? child;
  final Rx<bool>? isLoading;

  AppAsyncLoadingButton({
    super.key,
    this.title,
    this.width,
    this.onTap,
    this.child,
    Rx<bool>? isLoading,
    this.height,
  }) : isLoading = isLoading ?? false.obs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = isLoading?.value ?? false;

      Widget buttonContent = SizedBox(
            height: height ?? 50,
            width: width ?? double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onPressed: onTap,
              child:
                  loading
                      ? const SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                      : child ??
                          Text(
                            title ?? 'Save',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
            ),
          )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 1200))
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))
          .then(delay: 200.ms)
          .shimmer(duration: 12000.ms, color: AppColors.primaryLight);

      return IgnorePointer(ignoring: loading, child: buttonContent);
    });
  }
}

class AddIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  const AddIconButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        ),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
