import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../core/constant/app_colors.dart';

class CustomTextFormField extends StatelessWidget {
  final String? title;
  final TextEditingController? controller;
  final String? validationKey;
  final FocusNode? focusNode;
  final bool? autofocus;
  final String? labelText;
  final FloatingLabelBehavior floatingLabelBehavior;
  final String? hintText;
  final bool? readOnly;
  final bool? enabled;
  final bool isRequired;
  final bool? obscureText;
  final String obscuringCharacter;
  final String requiredLabelCharacter;
  final Color? requiredLabelColor;
  final BoxConstraints? prefixIconConstraints;
  final Widget? prefixWidget;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final double? prefixIconSize;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final double? suffixIconSize;
  final Color? suffixIconColor;
  final void Function(String?)? onChanged;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onSuffixTap;
  final VoidCallback? onTap;
  final void Function(String?)? onSave;
  final void Function(String?)? onFieldSubmit;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final String? requiredErrorMessage;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final TextStyle? textStyle;
  final Color? fillColor;
  final Color? cursorColor;
  final Color? errorColor;
  final Color? disabledColor;
  final TextCapitalization? textCapitalization;
  final double? borderRadius;
  final bool showValidator;

  const CustomTextFormField({
    super.key,
    this.title,
    this.validationKey,
    this.controller,
    this.isRequired = false,
    this.requiredLabelColor,
    this.requiredLabelCharacter = '*',
    this.labelText,
    this.floatingLabelBehavior = FloatingLabelBehavior.never,
    this.hintText,
    this.prefixIcon,
    this.prefixIconSize,
    this.prefixIconColor,
    this.prefixIconConstraints,
    this.prefixWidget,
    this.suffixIcon,
    this.suffixWidget,
    this.suffixIconSize,
    this.suffixIconColor,
    this.obscureText,
    this.obscuringCharacter = '*',
    this.onChanged,
    this.onSuffixTap,
    this.validator,
    this.requiredErrorMessage,
    this.onSave,
    this.inputFormatters,
    this.textInputAction,
    this.autofillHints,
    this.keyboardType,
    this.onEditingComplete,
    this.onFieldSubmit,
    this.readOnly,
    this.focusNode,
    this.maxLines,
    this.maxLength,
    this.fillColor,
    this.autofocus,
    this.textCapitalization,
    this.textStyle,
    this.cursorColor,
    this.errorColor,
    this.disabledColor,
    this.onTap,
    this.borderRadius = 10,
    this.enabled,
    this.showValidator = true,
  }) : assert(
         prefixWidget == null || prefixIcon == null,
         'Cannot provide both a prefixWidget and a prefixIconData\n'
         'To provide custom, use "prefixWidget".',
       ),
       assert(
         prefixWidget == null || prefixIconColor == null,
         'Cannot provide both a prefixWidget and a prefixIconColor\n'
         'To provide custom, use "prefixWidget".',
       ),
       assert(
         suffixWidget == null || suffixIcon == null,
         'Cannot provide both a suffixWidget and a suffixIconData\n'
         'To provide custom, use "suffixWidget".',
       ),
       assert(
         suffixWidget == null || suffixIconColor == null,
         'Cannot provide both a suffixWidget and a suffixIconColor\n'
         'To provide custom, use "suffixWidget".',
       );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          if (title != null)
            Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  text: title,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  children:
                      isRequired
                          ? [
                            TextSpan(
                              text: ' $requiredLabelCharacter',
                              style: TextStyle(
                                color: requiredLabelColor ?? Colors.red,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]
                          : [],
                ),
              ),
            ),
          if (title != null) const SizedBox(height: 10),
          TextFormField(
            textAlign: TextAlign.left,
            controller: controller,
            cursorColor: AppColors.primary,
            cursorRadius: const Radius.circular(32),
            cursorWidth: 2,
            decoration: buildInputDecoration2(),
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            autofocus: autofocus ?? false,
            focusNode: focusNode,
            onTap: onTap,
            maxLines: maxLines ?? 1,
            maxLength: maxLength,
            buildCounter:
                (_, {required currentLength, maxLength, required isFocused}) =>
                    null,
            scrollPadding: const EdgeInsets.all(8),
            textCapitalization:
                textCapitalization ?? TextCapitalization.sentences,
            onEditingComplete: onEditingComplete,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            autovalidateMode: AutovalidateMode.disabled,
            enableSuggestions: true,
            onSaved: onSave,
            onFieldSubmitted: onFieldSubmit,
            validator: (value) {
              if (isRequired && showValidator) {
                if (value?.trim().isEmpty ?? true) {
                  return '$title is required *';
                }

                if (validator != null) return validator!(value?.trim());
              } else {
                if ((value?.trim().isNotEmpty ?? false) && showValidator) {
                  if (validator != null) return validator!(value?.trim());
                } else if (!showValidator) {
                  return validator?.call(value?.trim());
                }
              }

              return null;
            },
            autofillHints: autofillHints,
            keyboardType: keyboardType ?? TextInputType.text,
            onChanged: onChanged,
            
            obscureText: obscureText ?? false,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: Device.screenType == ScreenType.tablet ? 15.sp : 16.sp,
              fontWeight: FontWeight.bold,
            ),
            obscuringCharacter: obscuringCharacter,
            enabled: enabled ?? true,
          ),
        ],
      ),
    );
  }

  InputDecoration buildInputDecoration2() {
    return InputDecoration(
      filled: true,
      fillColor: fillColor ?? AppColors.background,
      errorMaxLines: 2,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(13),
        child: prefixWidget,
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.all(11),
        child: suffixWidget,
      ),
      floatingLabelBehavior: floatingLabelBehavior,
      contentPadding: const EdgeInsets.only(bottom: 10, top: 10, left: 10),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
          color: Colors.redAccent,
        ), //<-- SEE HERE
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: AppColors.primary,
        ), //<-- SEE HERE
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
          color: Colors.redAccent,
        ), //<-- SEE HERE
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: AppColors.textPrimary,
        ), //<-- SEE HERE
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
         width: 1,
          color: disabledColor ?? AppColors.textPrimary,
        ), //<-- SEE HERE
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      errorStyle: TextStyle(
        color: errorColor ?? Colors.redAccent,
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: Color(0xFF929292),
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
      ),
      border: InputBorder.none,
      alignLabelWithHint: true,
      label: Text(
        labelText ?? '',
        style: TextStyle(
          color: Color(0xFF9F9DA1),
          fontSize: Device.screenType == ScreenType.tablet ? 16.sp : 17.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
