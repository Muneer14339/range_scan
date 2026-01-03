import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import '/core/utils/app_spaces.dart';



class ToastUtils {
  static const Duration _defaultAnimationDuration = Duration(milliseconds: 1000);
  static const Duration _defaultToastDuration = Duration(seconds: 5);
  static const ToastPosition _defaultPosition = ToastPosition.top;
  static const double _defaultRadius = 8.0;
  static const EdgeInsets _defaultMargin = EdgeInsets.symmetric(horizontal: 10);
  static const EdgeInsets _defaultPadding = EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0);

  static void showSuccess({
    String? title,
    required String message,
    Duration duration = _defaultToastDuration,
    ToastPosition position = _defaultPosition,
  }) {
    _showCustomToast(
      title: title,
      message: message,
      duration: duration,
      position: position,
      backgroundColor: const Color.fromARGB(255, 6, 117, 10),
      icon: Icons.task_alt_outlined,
    );
  }

  static void showError({
    String? title,
    required String message,
    Duration duration = _defaultToastDuration,
    ToastPosition position = _defaultPosition,
  }) {
    _showCustomToast(
      title: title,
      message: message,
      duration: duration,
      position: position,
      backgroundColor: Colors.red,
      icon: EneftyIcons.danger_outline,
    );
  }

  static void showInfo({
    String? title,
    required String message,
    Duration duration = _defaultToastDuration,
    ToastPosition position = _defaultPosition,
  }) {
    _showCustomToast(
      title: title,
      message: message,
      duration: duration,
      position: position,
      backgroundColor: Colors.orange,
      icon: EneftyIcons.information_outline,
    );
  }

  static void showWarning({
    String? title,
    required String message,
    Duration duration = _defaultToastDuration,
    ToastPosition position = _defaultPosition,
  }) {
    _showCustomToast(
      title: title,
      message: message,
      duration: duration,
      position: position,
      backgroundColor: Colors.orange.withOpacity(0.9),
      icon: Icons.warning,
    );
  }

  static void _showCustomToast({
    String? title,
    required String message,
    required Duration duration,
    required ToastPosition position,
    required Color backgroundColor,
    required IconData icon,
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
  }) {
    final hasTitle = title?.isNotEmpty ?? false;

    showToastWidget(
      _AnimatedToast(
        duration: _defaultAnimationDuration,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isWide = screenWidth >= 600;
            final maxWidth = isWide ? 600.0 : double.infinity;

            return Align(
               alignment: Alignment.topCenter,
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                margin: _defaultMargin,
                padding: _defaultPadding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_defaultRadius),
                  border: Border.all(color: backgroundColor),
                  color: backgroundColor,
                  boxShadow: _defaultBoxShadow,
                ),
                child: Row(
                  children: [
                    AnimatedIconWidget(icon: icon, color: iconColor),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasTitle) ...[
                            Text(title!, style: _titleTextStyle(textColor)),
                            const SizedBox(height: 4.0),
                          ],
                          Flexible(
                            child: Text(
                              message,
                              style: _messageTextStyle(textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      duration: duration,
      position: position,
      handleTouch: true,
    );
  }

  static void showSimpleToast(
    String message, {
    Duration duration = _defaultToastDuration,
    ToastPosition position = _defaultPosition,
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    double radius = _defaultRadius,
    String? buttonText,
    VoidCallback? onButtonTap,
  }) {
    showToastWidget(
      _AnimatedToast(
        duration: _defaultAnimationDuration,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isWide = screenWidth >= 600;
            final maxWidth = isWide ? 600.0 : double.infinity;

            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: _defaultPadding,
                margin: _defaultMargin,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: _defaultBoxShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: _messageTextStyle(textColor),
                      ),
                    ),
                 10.widthBox,
                    if (buttonText != null && onButtonTap != null)
                      TextButton(
                        onPressed: onButtonTap,
                        child: Text(
                          buttonText,
                          style: _messageTextStyle(textColor),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      duration: duration,
      position: position,
      handleTouch: true,
    );
  }

  static void dismissAll() => dismissAllToast();

  static List<BoxShadow> get _defaultBoxShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static TextStyle _titleTextStyle(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle _messageTextStyle(Color color) => TextStyle(
        fontSize: 15,
        color: color,
        fontWeight: FontWeight.w600,
      );
}

// Animation widget remains unchanged
class _AnimatedToast extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _AnimatedToast({required this.child, required this.duration});

  @override
  _AnimatedToastState createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)
        .drive(Tween<double>(begin: 0.8, end: 1.0));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut)
        .drive(Tween<double>(begin: 0.0, end: 1.0));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

class AnimatedIconWidget extends StatefulWidget {
  final IconData icon;
  final Color color;

  const AnimatedIconWidget({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AnimatedIconWidgetState createState() => _AnimatedIconWidgetState();
}

class _AnimatedIconWidgetState extends State<AnimatedIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ToastUtils._defaultAnimationDuration,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(widget.icon, color: widget.color, size: 20),
    );
  }
}
