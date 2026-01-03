import 'package:form_field_validator/form_field_validator.dart';

class Validators {
  static final emailValidator = MultiValidator([
    ..._minMaxValidator(title: 'Email', min: 4, max: 100),
    EmailValidator(errorText: "Enter a valid email address."),
  ]);

  static final nameValidator = MultiValidator(
    _minMaxValidator(title: 'Name', min: 3, max: 40),
  );
  static final diameterValidator = MultiValidator(
    _minMaxValidator(title: 'Diameter', min: 1, max: 4),
    //  MaxValueValidator(0.249),
    
  );
  static final passwordValidator = MultiValidator([
    ..._minMaxValidator(title: 'Password', min: 8, max: 25),
    PatternValidator(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[#?!@$%^&*-]).+$',
      errorText:
          'Password must include upper and lower case letters, a number, and a special character.',
    ),
  ]);

  static List<TextFieldValidator> _minMaxValidator({
    required String title,
    required int min,
    required int max,
  }) => [
    _minValidator(title: title, min: min),
    _maxValidator(title: title, max: max),
  ];

  static TextFieldValidator _minValidator({
    required String title,
    required int min,
  }) => MinLengthValidator(
    min,
    errorText: '$title must be at least $min characters long.',
  );

  static TextFieldValidator _maxValidator({
    required String title,
    required int max,
  }) => MaxLengthValidator(
    max,
    errorText: '$title should not be greater than $max characters.',
  );

  static bool isUserId(String text) {
    return RegExp(r'^([a-zA-Z\d]{4,})$').hasMatch(text);
  }

  static String? emailValidation(String? value) {
    if (value.toString().isNotEmpty) {
      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value!)) {
        return 'Enter valid Email';
      }
    }
    return null;
  }
}
class MaxValueValidator extends FieldValidator<String> {
  final double maxValue;

  MaxValueValidator(this.maxValue)
      : super('Value cannot exceed $maxValue');

  @override
  bool isValid(String? value) {
    if (value == null || value.isEmpty) return true;

    final numValue = double.tryParse(value);
    if (numValue == null) return false;
    return numValue <= maxValue;
  }
}