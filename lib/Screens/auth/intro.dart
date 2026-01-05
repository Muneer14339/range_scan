import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '/core/constant/app_colors.dart';
import '/core/utils/app_spaces.dart';
import '/custom_widgets/app_buttons.dart';
import '/custom_widgets/main_base_scaffold.dart';

import '../../routes/app_routes.dart';

class Intro extends StatelessWidget {
  static const routeName = '/';
  const Intro({super.key});

  // 🔹 Define styles in one place
  final TextStyle headingStyle = const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  final TextStyle bodyStyle = const TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  final TextStyle boldPrimary = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  final TextStyle boldAccent = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // 🔹 Helper for paragraph
  Widget buildParagraph(List<InlineSpan> spans) {
    return RichText(text: TextSpan(style: bodyStyle, children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return MainBaseScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            100.heightBox,

            // Heading with fade + scale + slide
            Center(child: Text("Welcome to RangeScan", style: headingStyle))
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1))
                .slideY(begin: -0.2, end: 0),

            20.heightBox,

            // Paragraph 1
            buildParagraph([
                  TextSpan(text: "RangeScan", style: boldPrimary),
                  const TextSpan(text: " is part of the "),
                  TextSpan(text: "ShoQ® Journal", style: boldAccent),
                  const TextSpan(
                    text:
                        " system. It automatically detects bullet holes and calculates your scores instantly.",
                  ),
                ])
                .animate()
                .fadeIn(delay: 200.ms)
                .slideX(begin: -0.3, end: 0, curve: Curves.easeOut),

            16.heightBox,

            // Paragraph 2
            buildParagraph([
                  const TextSpan(text: "RangeScan is simple to use — just "),
                  TextSpan(
                    text: "shoot, scan, and get your scores",
                    style: boldPrimary,
                  ),
                  const TextSpan(text: ". You can also "),
                  TextSpan(text: "create your own targets", style: boldPrimary),
                  const TextSpan(
                    text:
                        ", and RangeScan will detect holes and provide scoring automatically.",
                  ),
                ])
                .animate()
                .fadeIn(delay: 400.ms)
                .slideX(begin: 0.3, end: 0, curve: Curves.easeOut),

            16.heightBox,

            // Paragraph 3
            buildParagraph([
                  const TextSpan(text: "Our "),
                  TextSpan(text: "ScoreTune", style: boldPrimary),
                  const TextSpan(
                    text:
                        " feature lets you adjust results on the fly — add or remove holes instantly to fine-tune accuracy.",
                  ),
                ])
                .animate()
                .fadeIn(delay: 600.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

            16.heightBox,

            // Paragraph 4
            buildParagraph([
                  const TextSpan(
                    text: "All session data is securely saved inside your ",
                  ),
                  TextSpan(
                    text: "ShoQ® Journal",
                    style: boldAccent.copyWith(
                      color: AppColors.primary,
                    ), // Orange accent
                  ),
                  const TextSpan(text: " for review and analysis."),
                ])
                .animate()
                .fadeIn(delay: 800.ms)
                .slideX(begin: -0.3, end: 0, curve: Curves.easeOut),

            30.heightBox,

            // Button with bounce + glow effect
            AppCommonButton(
                  text: 'Get IT',
                  onPressed: () {
                    Get.offAndToNamed(AppRoutes.USER_AUTH_CHECK);
                  },
                )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 1200))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))
                .then(delay: 200.ms)
                .shimmer(duration: 12000.ms, color: AppColors.primaryLight),
          ],
        ),
      ),
    );
  }
}
