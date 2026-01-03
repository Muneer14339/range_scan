import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '/Screens/components/add_custom_caliber_dialog.dart';
import '/Screens/controller/connection_controller.dart';
import '/custom_widgets/app_buttons.dart';
import '/custom_widgets/custom_drop_down.dart';

class LoadoutScreen extends GetView<ConnectionController> {
  final void Function(String caliber)? onProceed;
  const LoadoutScreen({super.key, this.onProceed});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1c1c1c),
      body: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 5, 16, 16),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure Your Loadout',
                  style: TextStyle(
                    color: const Color(0xFFff6b35),
                    fontSize: min(screenWidth * 0.053, 22),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Obx(() {
                        return AppDropdown<String>(
                          label: "Firearm Type",
                          hintText: 'Select firearm type',
                          isRequired: true,
                          isLoading: controller.isFirearmLoading.value,
                          value:
                              controller.selectedType.value.isEmpty
                                  ? null
                                  : controller.selectedType.value,
                          items: controller.types,
                          itemLabel: (item) => item,
                          onChanged: (value) {
                            controller.selectedType.value = value ?? '';
                            controller.selectedCaliber.value =
                                ''; // reset caliber
                          },
                        );
                      }),
                    ),
                    // const SizedBox(width: 16),
                    // Padding(
                    //   padding: const EdgeInsets.only(top: 30.0),
                    //   child: AddIconButton(
                    //     onTap: () {
                    //       ToastUtils.showInfo(
                    //           message: "Feature coming soon!");
                    //     },
                    //   ),
                    // ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Obx(() {
                        return AppDropdown<String>(
                          label: "Caliber",
                          hintText: 'Select caliber',
                          isRequired: true,
                          buttonText: 'Add Custom Caliber',
                          showButton: true,
                          // searchHint: 'Enter caliber',
                          // enableSearch: true,
                          onButtonTap: () {
                            showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AddCustomCaliberDialog(),
                            );
                          },
                          value:
                              controller.selectedCaliber.value.isEmpty
                                  ? null
                                  : controller.selectedCaliber.value,
                          items: controller.calibers??[],
                          itemLabel: (item) => item,
                          onChanged: (value) {
                            controller.onCaliberSelected(value ?? '');
                          },
                          enabled:
                              controller
                                  .selectedType
                                  .value
                                  .isNotEmpty, // disable until type chosen
                        );
                      }),
                    ),
                    // const SizedBox(width: 16),
                    // Padding(
                    //   padding: const EdgeInsets.only(top: 30.0),
                    //   child: AddIconButton(
                    //     onTap: () {
                    //       ToastUtils.showInfo(
                    //           message: "Feature coming soon!");
                    //     },
                    //   ),
                    // )
                  ],
                ),
                const SizedBox(height: 24),

                /// Shots
                // _buildFormGroup(
                //   label: 'Number of Shots (Max 15)',
                //   isRequired: true,
                //   child: _buildTextField(
                //     controller: controller.shotCountController,
                //     placeholder: 'Enter number of shots',
                //     keyboardType: TextInputType.number,
                //   ),
                // ),

                /// Distance
                Obx(
                  () => AppDropdown<double>(
                    label: "Shooting Distance",
                    hintText: 'Select distance in yards',
                    isRequired: true,
                    value: controller.distance?.value,
                    items: [7,10, 15, 20, 25, 30, 50],
                    itemLabel: (item) => item.floor().toString(),
                    onChanged: (value) {
                      controller.distance?.value = value ?? 0;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                /// Shots
                buildFormGroup(
                  label: 'Notes',
                  child: buildTextField(
                    controller: controller.notesCtrl,
                    placeholder: 'Ammunition, Condition, Target, etc.',
                    keyboardType: TextInputType.text,
                    maxLines: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: AppCommonButton(
          text: 'Start Session',
          onPressed: () {
            controller.saveLoadout(onProceed: onProceed);
            // if (controller.statusMessage.isNotEmpty) {
            //   ToastUtils.showSuccess(message: controller.statusMessage.value);
            // }
          },
        ),
      ),
    );
  }
}

Widget buildFormGroup({
  required String label,
  required Widget child,
  bool isRequired = false,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: const TextStyle(
            color: Color(0xFFff6b35),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

Widget buildTextField({
  required TextEditingController controller,
  required String placeholder,
  TextInputType? keyboardType,
  int? maxLines,
  TextInputFormatter? inputFormatter,
}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white.withOpacity(0.1),
    ),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,

      style: const TextStyle(color: Colors.white, fontSize: 16),
      inputFormatters: inputFormatter != null ? [inputFormatter] : null,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 16,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.8,
          vertical: 12.8,
        ),
      ),
    ),
  );
}
