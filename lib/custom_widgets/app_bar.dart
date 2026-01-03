import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constant/app_colors.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final Widget? child;
  final bool hideBack;

  const CommonAppBar({
    this.title,
    this.hideBack = false,
    this.actions,
    this.backgroundColor,
    this.leading,
    this.child,
    this.onBackPressed,
    super.key,
  }) : assert(
          (title != null) ^ (child != null),
          "Either title or child must be provided, not both.",
        );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight,
      title: child ??
          Text(
            title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
      actions: actions,
      leading: hideBack
          ? null
          : leading ?? AppBackBtn(onTap: onBackPressed),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AppBackBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const AppBackBtn({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(26), // better ripple effect
        onTap: onTap ?? Get.back,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 15,
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
      ),
    );
  }
}
