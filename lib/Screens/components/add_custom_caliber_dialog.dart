import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '/Screens/components/nra_instruction_dialog.dart';
import '/Screens/controller/connection_controller.dart';
import '/Screens/loadout_screen.dart';
import '/core/constant/app_colors.dart';
import '/core/utils/app_spaces.dart';

class AddCustomCaliberDialog extends GetView<ConnectionController> {
  const AddCustomCaliberDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Custom Caliber',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            20.heightBox,
            CaliberInputField(controller: controller.addCaliberCtrl),
            20.heightBox,
            ActionButton(
              title: 'Add',
              onTap: () {
                controller.addCaliber();
              },
              onCancel: () {
                controller.calculatedDiameter.value = 0.0;
                controller.addCaliberCtrl.clear();
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CaliberInputField extends StatefulWidget {
  final TextEditingController controller;
  const CaliberInputField({super.key, required this.controller});

  @override
  State<CaliberInputField> createState() => _CaliberInputFieldState();
}

class _CaliberInputFieldState extends State<CaliberInputField> {
  String? _errorText;
  var controller = Get.find<ConnectionController>();

  /// 🔹 Bullet Diameter Calculation Logic
  static String? calculateBulletDiameter(
    String? caliber,
    String? existingDiameter,
  ) {
    if (existingDiameter != null && existingDiameter.isNotEmpty) {
      return existingDiameter;
    }
    if (caliber == null || caliber.isEmpty) return null;

    final cal = caliber.trim().toLowerCase();

    try {
      // Rule 1: Starts with "." (.45, .308)
      if (cal.startsWith('.')) {
        final match = RegExp(r'^\.(\d+)').firstMatch(cal);
        if (match != null) {
          return '0.${match.group(1)}';
        }
      }

      // Rule 2: Gauge-based
      if (cal.contains('gauge') ||
          cal.contains('ga') ||
          cal.contains('bore')) {
        final gaugeMatch = RegExp(r'(\d+\.?\d*)').firstMatch(cal);
        if (gaugeMatch != null) {
          final gauge = double.parse(gaugeMatch.group(1)!);
          final diameter = 1.67 / pow(gauge, 1 / 3);
          return diameter.toStringAsFixed(3);
        }
      }

      // Rule 3: Cross format (7.62x39mm or 9.23x8.4mm)
      if (cal.contains('x')) {
        final match =
            RegExp(r'(\d+\.?\d*)x(\d+\.?\d*)\s*(mm)?').firstMatch(cal);
        if (match != null) {
          final mm = double.parse(match.group(1)!); // take first value
          return (mm / 25.4).toStringAsFixed(3);
        }
      }

      // Rule 4: mm-based
      if (cal.contains('mm')) {
        final match = RegExp(r'(\d+\.?\d*)mm').firstMatch(cal);
        if (match != null) {
          final mm = double.parse(match.group(1)!);
          return (mm / 25.4).toStringAsFixed(3);
        }
      }

      // Rule 5: Starts with number like "45 ACP"
      final numberMatch = RegExp(r'^(\d+)(?:\s|$)').firstMatch(cal);
      if (numberMatch != null) {
        final num = int.parse(numberMatch.group(1)!);
        return '0.$num';
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// 🔹 Validation Logic
  String? _validateCaliber(String value) {
    if (value.isEmpty) return 'Please enter a caliber';
    final error = CaliberValidator.validate(value);
    return error;
  }

  /// 🔹 Handle User Input
  void _onCaliberChanged(String val) {
    final err = _validateCaliber(val);
    final diameter = err == null ? calculateBulletDiameter(val, null) : null;

    setState(() {
      _errorText = err;
      controller.calculatedDiameter.value =
          double.tryParse(diameter ?? '0.0') ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildFormGroup(
          label: 'Caliber',
          isRequired: true,
          child: TextFormField(
            controller: widget.controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '.45 ACP or 9mm or 12 gauge',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              errorText: _errorText,
              errorMaxLines: 6,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^[0-9a-zA-Z.\sxX\-\/]*$'),
              ),
              SingleDotInputFormatter(),
            ],
            onChanged: _onCaliberChanged,
          ),
        ),
        const SizedBox(height: 8),
        if (controller.calculatedDiameter.value > 0 && _errorText == null)
          Text(
            '💡 Estimated Bullet Diameter: ${controller.calculatedDiameter} inches',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// Prevents multiple dots in input
class SingleDotInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.contains('..') || RegExp(r'^\.\.').hasMatch(text)) {
      return oldValue;
    }
    return newValue;
  }
}

/// 🔹 Caliber Validator (with cross format decimal support)
class CaliberValidator {
  static final _inchPattern = RegExp(r'^\.(\d{2,3})$'); // e.g. .45, .308

  static final _inchNamedPattern = RegExp(
    r'^\.(\d{2,3})(-\d{2,3})?\s*[a-zA-Z][a-zA-Z\s-]*$',
    caseSensitive: false,
  );

  static final _gaugePattern = RegExp(
    r'^(\d{1,2}(\.\d+)?)\s*(gauge|ga)$',
    caseSensitive: false,
  );

  static final _mmPattern = RegExp(
    r'^(\d{1,2}(\.\d+)?)\s*mm$',
    caseSensitive: false,
  );

  /// ✅ Supports decimals in both sides of "x"
  static final _crossMmPattern = RegExp(
    r'^(\d{1,2}(\.\d+)?)x(\d{1,3}(\.\d+)?)\s*(mm)?$',
    caseSensitive: false,
  );

  static final _namedPattern = RegExp(
    r'^(\d{2,3})\s+[a-zA-Z][a-zA-Z\s-]+$',
    caseSensitive: false,
  ); // 45 ACP, 22 LR

  /// ✅ Validates acceptable formats
  static bool isValid(String? caliber) {
    if (caliber == null || caliber.trim().isEmpty) return false;

    final normalized = caliber.trim();

    if (_hasMixedFormats(normalized)) return false;

    return _inchPattern.hasMatch(normalized) ||
        _inchNamedPattern.hasMatch(normalized) ||
        _gaugePattern.hasMatch(normalized) ||
        _mmPattern.hasMatch(normalized) ||
        _crossMmPattern.hasMatch(normalized) ||
        _namedPattern.hasMatch(normalized);
  }

  /// ✅ Detects if input has mixed/conflicting formats
  static bool _hasMixedFormats(String input) {
    final lower = input.toLowerCase();
    if (lower.startsWith('.') && lower.contains('mm')) return true;
    if (lower.split('.').length > 3) return true;
    if ((lower.contains('gauge') || lower.contains('ga')) &&
        lower.contains('mm')) {
      return true;
    }
    return false;
  }

  /// ✅ Returns validation message
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Caliber is required';
    }

    final normalized = value.trim();

    if (_hasMixedFormats(normalized)) {
      return 'Mixed formats not allowed. Use ONLY one format:\n'
          '• Inches: .45, .308, .30-30\n'
          '• MM: 9mm, 5.56mm\n'
          '• Gauge: 12 gauge, 20ga\n'
          '• Cross: 7.62x39mm\n'
          '• Named: 45 ACP, 22 LR';
    }

    if (!isValid(normalized)) {
      return 'Invalid format. Examples:\n'
          '• .45 or .308 (inches)\n'
          '• 9mm or 5.56mm (millimeters)\n'
          '• 12 gauge or 20ga (gauge)\n'
          '• 7.62x39mm or 9.23x8.4mm (cross)\n'
          '• 45 ACP or 22 LR (named)';
    }

    return null;
  }

  static String normalize(String caliber) {
    return caliber
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'(?<=\d)\s*mm', caseSensitive: false), 'mm')
        .replaceAll(RegExp(r'(?<=\d)\s*x\s*(?=\d)', caseSensitive: false), 'x');
  }

  /// ✅ Extract approximate inch diameter (if available)
  static double? extractInchDiameter(String caliber) {
    final match = RegExp(r'^\.(\d{2,3})').firstMatch(caliber);
    if (match != null) {
      return double.tryParse(match.group(1)!)! / 100;
    }
    return null;
  }
}
