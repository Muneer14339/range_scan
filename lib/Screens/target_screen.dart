import 'dart:math';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/Screens/models/target_model.dart';
import '/core/constant/app_colors.dart';
import '/core/utils/app_spaces.dart';
import 'package:url_launcher/url_launcher.dart';
import 'controller/connection_controller.dart';

class TargetScreen extends StatefulWidget {
  final String caliber;
  final double distance;
  final String detectionMode;
  final void Function(
    String targetType,
    double dis,
    String configPath,
    String detectionMode,
  )?
  onProceed;

  const TargetScreen({
    super.key,
    this.onProceed,
    required this.caliber,
    required this.distance,
    required this.detectionMode,
  });

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  late ConnectionController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ConnectionController());
  }

  Widget _buildCategoryCard({
    required String category,
    required String title,
    required String description,
    Widget ?child,
    String? message,
    required Widget options,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Obx(() {
      final isSelected = controller.selectedCategory.value == category;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFFFF6B35).withOpacity(0.08) // orangish tint
                  : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? const Color(0xFFff6b35) : Colors.transparent,
            width: 1.5,
          ),

          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          splashColor: Colors.transparent,
          onTap: () => controller.selectCategory(category),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: min(screenWidth * 0.051, 21),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFff6b35),
                        ),
                      ),
                    ),
                    // message != null
                    //     ? Tooltip(
                    //       padding: const EdgeInsets.all(8),
                    //       margin: const EdgeInsets.all(16),
                    //       triggerMode: TooltipTriggerMode.tap,
                    //       showDuration: const Duration(seconds: 5),

                    //       decoration: BoxDecoration(
                    //         color: AppColors.primary,
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //       richMessage: TextSpan(
                    //         text: message ?? "",
                    //         style: const TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 15,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //       child: Icon(
                    //         EneftyIcons.information_outline,
                    //         color: Colors.white,
                    //       ),
                    //     )
                    //     : SizedBox(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: min(screenWidth * 0.038, 16.4),
                  ),
                ),
                const SizedBox(height: 8),
                child ?? const SizedBox(),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isSelected ? null : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      child: options,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTargetItem(TargetModel target) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Obx(() {
      final isSelected = controller.selectedTarget.value == target;
      return InkWell(
        onTap: () => controller.selectTarget(target, context),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFff6b35) : Colors.transparent,
            ),
            color:
                isSelected
                    ? const Color(0xFFff6b35).withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  target.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: min(screenWidth * 0.042, 18),
                  ),
                ),
              ),

              Text(
                target.text ?? '',
                style: TextStyle(
                  color: Colors.red,

                  fontSize: min(screenWidth * 0.042, 16),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCustomTargetOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Coming soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Icon(Icons.upload_file, size: 48, color: Color(0xFFff6b35)),
                // SizedBox(height: 12),
                // Text(
                //   'Click to upload your custom target image',
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // SizedBox(height: 8),
                // Text(
                //   'Supported formats: JPEG, PNG',
                //   style: TextStyle(color: Colors.grey),
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        children: [
          // Obx(
          //   () =>
          //       controller.selectedTarget.value?.value != null
          //           ? UploadInfoText(
          //             text:
          //                 controller.isTargetBrightHole.value
          //                     ? 'Upload target image with bright/white background'
          //                     : 'Upload target image with dark/black background',
          //           )
          //           : const SizedBox(),
          // ),
          10.heightBox,
          _buildCategoryCard(
            category: "NRA",
            title: "NRA Target Papers",
            message: 'NRA target requires Bright Hole mode',
            description:
                "Official NRA target papers for shooting competitions.",
            options: Column(
              children: controller.targetsList.map(_buildTargetItem).toList(),
            ),
          ),
          _buildCategoryCard(
            category: "PA",
            title: "PulseAim Targets",

            description: "Smart targets for shooting drills ",
            child: PulseAimDownloadBanner(),
            options: Column(
              children: [
                
                // Obx(
                //   () =>
                //       controller.selectedTarget.value?.name == 'Red Ring'
                //           ? Row(
                //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //             children: [
                //               Expanded(
                //                 child: Column(
                //                   crossAxisAlignment: CrossAxisAlignment.start,
                //                   children: [
                //                     Text(
                //                       controller.isTargetBrightHole.value
                //                           ? 'Bright Hole'
                //                           : 'Dark Hole',
                //                       style: const TextStyle(
                //                         color: Colors.white,
                //                         fontWeight: FontWeight.bold,
                //                         fontSize: 15,
                //                       ),
                //                     ),
                //                     // Text(
                //                     //   'Use Bright → for outdoor or back-lit targets (holes look bright)',
                //                     //   style: TextStyle(
                //                     //     color:
                //                     //         controller.isTargetBrightHole.value
                //                     //             ? Colors.green
                //                     //             : Colors.white,
                //                     //     fontSize: 14,
                //                     //   ),
                //                     // ),
                //                     // Text(
                //                     //   'Use Dark → for indoor or front-lit targets (holes look dark)',
                //                     //   style: TextStyle(
                //                     //     color:
                //                     //         controller.isTargetBrightHole.value
                //                     //             ? Colors.white
                //                     //             : Colors.green,
                //                     //     fontSize: 14,
                //                     //   ),
                //                     // ),
                //                   ],
                //                 ),
                //               ),
                //               CupertinoSwitch(
                //                 value: controller.isTargetBrightHole.value,
                //                 onChanged:
                //                     controller.onChangeIsTargetBrightHole,
                //               ),
                //             ],
                //           )
                //           : SizedBox(),
                // ),
                10.heightBox,
                Column(
                  children: controller.paList.map(_buildTargetItem).toList(),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Document Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                      size: 35,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Custom Target Title
                  const Text(
                    'Custom Target',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Upload or define your own target.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),

                  const SizedBox(height: 20),

                  // Coming Soon Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.access_time, color: Colors.orange, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                

                  // // Description Text
                  // Text(
                  //   'This feature is currently in development. You\'ll be able to create and upload custom targets for your training sessions.',
                  //   style: TextStyle(
                  //     color: Colors.grey[500],
                  //     fontSize: 13,
                  //     height: 1.5,
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),

                  // const SizedBox(height: 16),

                  // // Stay tuned text
                  // Text(
                  //   'Stay tuned for updates.',
                  //   style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class PulseAimDownloadBanner extends StatelessWidget {


  const PulseAimDownloadBanner({
    super.key,
  });
 Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.rangescan.com/target.html');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Download PulseAim Targets',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick red or black ring based on your lighting',
                  style: TextStyle(
                    color:AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap:  _launchURL,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A59),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center ,
                children: [
                  const Icon(
                    Icons.file_download,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Get',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class UploadInfoText extends StatelessWidget {
  final String text;
  const UploadInfoText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFF6B35).withOpacity(0.08), // orangish tint

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            const Icon(
              EneftyIcons.information_outline,
              color: Color(0xFFFF8C00),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Color(0xFFFF8C00),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
