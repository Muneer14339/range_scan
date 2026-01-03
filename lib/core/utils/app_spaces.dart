import 'package:flutter/widgets.dart';

extension SpaceExtension on num {
  /// Vertical space (height)
  SizedBox get heightBox => SizedBox(height: toDouble());

  /// Horizontal space (width)
  SizedBox get widthBox => SizedBox(width: toDouble());
}
