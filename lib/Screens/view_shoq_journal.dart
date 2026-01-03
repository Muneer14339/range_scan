import 'dart:io';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';

class ViewShoqJournal extends StatelessWidget {
  const ViewShoqJournal({super.key});

  // Replace with the actual package name and iOS URL scheme of your app
  final String androidPackageName = "com.pa.shoq";
  final String iosUrlScheme = "shoq://";
  final String iosAppStoreId = "XXXXXXXXX"; // Your app's Apple App Store ID

  Future<void> launchShoqJournal() async {
    // The LaunchApp.openApp() function handles the logic for you.
    // It checks if the app is installed and opens it.
    // If not, 'openStore: true' will automatically redirect to the store.
    await LaunchApp.openApp(
      androidPackageName: androidPackageName,
      iosUrlScheme: iosUrlScheme,
      openStore: true,
      // You can also add an iOS app store link directly here.
      // iosAppStoreId: iosAppStoreId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: launchShoqJournal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Track Your Progress Over Time',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'See your shooting improvement trends and detailed analytics in ShoQ® Journal',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text(
                'View in ShoQ® Journal',
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
