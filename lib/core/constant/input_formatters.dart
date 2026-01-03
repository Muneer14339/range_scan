// Remember Input Formatters can be chained so their order matters
// means output of 1st formatter is used in 2nd formatter.
import 'package:flutter/services.dart';

class InputFormat {
  static final emailFormatter = <TextInputFormatter>[
    NoLeadingSpaceFormatter(),
    FilteringTextInputFormatter.deny(RegExp(r'[/\\]')),
    LengthLimitingTextInputFormatter(
      100,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    ),
  ];

  static final denySpace = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
  ];

  static final denyStartSpace = <TextInputFormatter>[NoLeadingSpaceFormatter()];

  static final nameFormatter = <TextInputFormatter>[
    NoLeadingSpaceFormatter(),
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
    LengthLimitingTextInputFormatter(
      25,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    ),
  ];

  static final firstNameFormatter = <TextInputFormatter>[
    NoLeadingSpaceFormatter(),
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
    LengthLimitingTextInputFormatter(
      25,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    ),
  ];
  static final lastNameFormatter = <TextInputFormatter>[
    LengthLimitingTextInputFormatter(
      25,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    ),
  ];
}

class NoLeadingSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith(' ')) {
      final String trimedText = newValue.text.trimLeft();

      return TextEditingValue(
        text: trimedText,
        selection: TextSelection(
          baseOffset: trimedText.length,
          extentOffset: trimedText.length,
        ),
      );
    }

    return newValue;
  }
}

class IpAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    int dotCounter = 0;
    var buffer = StringBuffer();
    String ipField = "";

    for (int i = 0; i < text.length; i++) {
      if (dotCounter < 4) {
        if (text[i] != ".") {
          ipField += text[i];
          if (ipField.length < 3) {
            buffer.write(text[i]);
          } else if (ipField.length == 3) {
            if (int.parse(ipField) <= 255) {
              buffer.write(text[i]);
            } else {
              if (dotCounter < 3) {
                buffer.write(".");
                dotCounter++;
                buffer.write(text[i]);
                ipField = text[i];
              }
            }
          } else if (ipField.length == 4) {
            if (dotCounter < 3) {
              buffer.write(".");
              dotCounter++;
              buffer.write(text[i]);
              ipField = text[i];
            }
          }
        } else {
          if (dotCounter < 3) {
            buffer.write(".");
            dotCounter++;
            ipField = "";
          }
        }
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CNICFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 15; i++) {
      // Limit to 15 characters
      var inputChar = text[i];
      if (_isDigit(inputChar)) {
        buffer.write(inputChar);
        if ((buffer.length == 5 || buffer.length == 12) && buffer.length < 15) {
          buffer.write('-');
        }
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }

  bool _isDigit(String s) {
    return double.tryParse(s) != null;
  }
}
