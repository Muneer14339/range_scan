import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/utils/app_spaces.dart';
import '/custom_widgets/app_bar.dart';
import '/custom_widgets/app_buttons.dart';
import '/features/home/controller/home_controller.dart';
import '/features/home/pages/select_target.dart';

class CaliberView extends GetView<HomeController> {
  const CaliberView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF123B82),
      appBar: const CommonAppBar(title: "Select Caliber", hideBack: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Favorites ---
              const Text(
                "⭐ Favorites",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              10.heightBox,
              Obx(() {
                if (controller.favorites.isEmpty) {
                  return const Text(
                    "No favorites yet",
                    style: TextStyle(color: Colors.white70),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: controller.favorites.length,
                  itemBuilder: (context, index) {
                    final caliber = controller.favorites[index];

                    return GestureDetector(
                      onTap: () => controller.selectCaliber(caliber),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              caliber.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              caliber.size,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),

              20.heightBox,

              // --- All Calibers ---
              const Text(
                "All Calibers",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              10.heightBox,

              Obx(
                () => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.allCalibers.length,
                  itemBuilder: (context, index) {
                    final caliber = controller.allCalibers[index];
                    final isSelected =
                        controller.selectedCaliber.value == caliber;
                    final isFav = controller.isFavorite(caliber);

                    return GestureDetector(
                      onTap: () => controller.selectCaliber(caliber),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color:
                              isSelected
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.green
                                    : Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Caliber name + size
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    caliber.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    caliber.size,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Fav button
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.star : Icons.star_border_outlined,
                                color: isFav ? Colors.yellow : Colors.white54,
                              ),
                              onPressed:
                                  () => controller.toggleFavorite(caliber),
                            ),

                            // // Selected check mark
                            // if (isSelected)
                            //   const Icon(
                            //     Icons.check_circle,
                            //     color: Colors.green,
                            //   ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // --- Bottom Button ---
      bottomNavigationBar: Obx(() {
        if (controller.selectedCaliber.value == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: AppCommonButton(
            text: "Continue with ${controller.selectedCaliber.value!.name}",
            onPressed: () {
              Get.to(SelectTarget());
            },
          ),
        );
      }),
    );
  }
}
