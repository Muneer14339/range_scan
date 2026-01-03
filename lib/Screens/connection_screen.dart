import 'dart:math';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/Screens/auth/components/logout_dialog.dart';
import '/Screens/controller/connection_controller.dart';
import '/core/constant/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart'; // flutter_animate dependency

class ConnectionScreen extends GetView<ConnectionController> {
  static const routeName = '/connection-screen';
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    controller.activeTabIndex.value = 0;
    return WillPopScope(
      onWillPop: controller.onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(screenWidth, context),
              _buildStepTabBar(),
              _buildScreenContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button or Placeholder
                Obx(
                  () =>
                      controller.activeTabIndex.value > 0
                          ? Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              splashRadius: 22,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                              ),
                              onPressed: controller.goBack,
                              tooltip: 'Back',
                            ),
                          )
                          : const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(width: 48),
                          ),
                ),
                // Title with subtle entrance animation
                Text(
                  'RangeScan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: min(screenWidth * 0.064, 24),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    shadows: [
                      Shadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),

                // Logout Button
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      showLogoutDialog(context);
                    },
                    icon: const Icon(
                      EneftyIcons.logout_2_outline,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------

  Widget _buildStepTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Obx(
        () => Row(
          children: List.generate(controller.stepLabels.length, (index) {
            final isFilled = index <= controller.activeTabIndex.value;

            BorderRadius borderRadius;
            if (index == 0) {
              borderRadius = const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              );
            } else if (index == controller.stepLabels.length - 1) {
              borderRadius = const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              );
            } else {
              borderRadius = BorderRadius.zero;
            }

            final tabItem = Expanded(
              child: GestureDetector(
                // Allow tapping only for previously completed steps
                onTap: () {
                  if (index < controller.activeTabIndex.value) {
                    controller.onTabTap(index);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: isFilled ? AppColors.primary : AppColors.surface,
                  ),
                  child: Text(
                    controller.stepLabels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isFilled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: isFilled ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );

            // 🌟 Subtle animation for the active/newly filled step
            if (isFilled && index == controller.activeTabIndex.value) {
              return tabItem
                  .animate(key: ValueKey(index)) // Key for re-running animation
                  .scale(
                    duration: 300.ms,
                    curve: Curves.easeOut,
                    begin: const Offset(0.98, 0.98),
                    end: const Offset(1.0, 1.0),
                  );
            }

            return tabItem;
          }),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------

  Widget _buildScreenContent() {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Obx(
          () => IndexedStack(
            index: controller.activeTabIndex.value,
            children:
                controller.screens
                    .asMap()
                    .entries
                    .map(
                      (e) => KeyedSubtree(
                        key: PageStorageKey(
                          'step_${e.key}_${e.value.runtimeType}',
                        ),
                        child: e.value
                            .animate(key: ValueKey(e.key)) // Key for transition
                            .fadeIn(duration: 300.ms)
                            .slideX(
                              begin: 0.02, // Very slight slide
                              end: 0,
                              duration: 300.ms,
                              curve: Curves.easeOutCubic,
                            ), // Subtle screen transition
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}
