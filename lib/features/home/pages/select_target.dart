import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import '/core/constant/app_colors.dart';
import '/core/utils/app_spaces.dart';
import '/custom_widgets/app_bar.dart';
import '/custom_widgets/app_buttons.dart';
import '/features/home/controller/home_controller.dart';
import '/features/home/model/target_model.dart';
import '/features/home/pages/select_distance.dart';

class SelectTarget extends GetView<HomeController> {
  const SelectTarget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Select Target'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF24547B), // bluish background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.6), // light green border
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.push_pin,
                    color: Colors.pinkAccent,
                    size: 18,
                  ),
                  10.widthBox,
                  Text(
                    "Selected Caliber : ${controller.selectedCaliber.value?.name}",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            20.heightBox,
            Expanded(
              child: ListView.builder(
                itemCount: controller.targets.length,
                itemBuilder: (context, index) {
                  final target = controller.targets[index];
                  return _buildTargetItem(target);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        if (controller.selectedTarget.value == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
          child: AppCommonButton(
            text: "Continue with ${controller.selectedTarget.value!.name}",
            onPressed: () {
              Get.to(SelectDistance());
            },
          ),
        );
      }),
    );
  }

  Widget _buildTargetItem(TargetModel target) {
    return Obx(() {
      final isSelected = controller.selectedTarget.value?.id == target.id;

      return GestureDetector(
        onTap: () => controller.selectTarget(target),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Colors.green.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.white.withOpacity(0.2),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      target.name ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        target.emoji ?? '',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                target.description ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                target.specs ?? '',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    });
  }
}
