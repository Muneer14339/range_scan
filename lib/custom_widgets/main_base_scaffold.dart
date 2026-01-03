import 'package:flutter/material.dart';
import '/core/constant/app_colors.dart';

class MainBaseScaffold extends StatelessWidget {
  final Widget body;
  final Padding? padding;
  const MainBaseScaffold({super.key, required this.body, this.padding});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: padding ?? Padding(padding: const EdgeInsets.all(16), child: body),
    );
  }
}
