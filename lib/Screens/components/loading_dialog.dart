// Placeholder for the showLoadingDialog function
import 'package:flutter/material.dart';
import '/core/constant/app_colors.dart';

void showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    // Prevent dismissing by tapping outside or pressing back button
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false, // Prevent back button dismissal

        child: AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: AppColors.primary, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: Row(
            children: <Widget>[
              SizedBox(
                width: 30,
                height: 30,
                child: const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.white,
                  fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
