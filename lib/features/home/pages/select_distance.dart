import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import '/core/constant/app_colors.dart';
import '/core/utils/app_spaces.dart';
import '/custom_widgets/app_bar.dart';
import '/custom_widgets/app_buttons.dart';
import '/features/home/controller/home_controller.dart';

class SelectDistance extends GetView<HomeController> {
  const SelectDistance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Select Distance'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: ListView(
          padding: EdgeInsets.all(0),
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
                  Expanded(
                    child: Text(
                      "Selected Caliber : ${controller.selectedCaliber.value?.name}   -   ${controller.selectedTarget.value?.name}",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            20.heightBox,

            _buildDistanceCard(
              icon: Icons.gps_fixed,
              title: 'Pistol Distance',
              subtitle: 'Standard pistol shooting distances',
              isPopular: true,
              selectedValue: controller.selectedPistolDistance,
              options: controller.pistolDistances,
              onChanged: (value) => controller.selectDistance('pistol', value),
            ),
            16.heightBox,
            _buildDistanceCard(
              icon: Icons.my_location,
              title: 'Rifle Distance',
              subtitle: 'Precision rifle shooting distances',
              selectedValue: controller.selectedRifleDistance,
              options: controller.rifleDistances,
              onChanged: (value) => controller.selectDistance('rifle', value),
            ),
            16.heightBox,
            _buildDistanceCard(
              icon: Icons.home,
              title: 'Indoor Range',
              subtitle: 'Typical indoor range distances',
              selectedValue: controller.selectedIndoorDistance,
              options: controller.indoorDistances,
              onChanged: (value) => controller.selectDistance('indoor', value),
            ),
            16.heightBox,
            // Custom Distance Card
            _buildCustomDistanceCard(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        if (!controller.hasSelection) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: AppCommonButton(
            text: "Continue with ${controller.currentSelection}",
            onPressed: () {
              // Get.to(TargetCaptureView());
            },
          ),
        );
      }),
    );
  }

  Widget _buildDistanceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isPopular = false,
    required Rxn<String> selectedValue,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Obx(
                () => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedValue.value,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    hint: Text(
                      'Choose ${title.toLowerCase()}...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    dropdownColor: const Color(0xFF1a237e),
                    items:
                        options.map((String distance) {
                          return DropdownMenuItem<String>(
                            value: distance,
                            child: Text(
                              distance,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDistanceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Custom Distance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your own shooting distance',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.customDistanceTextController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'e.g., 75 yards',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              onChanged: controller.onCustomDistanceChanged,
            ),
          ],
        ),
      ),
    );
  }
}
