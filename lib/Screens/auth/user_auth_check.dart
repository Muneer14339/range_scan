
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/custom_widgets/main_base_scaffold.dart';
import '/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserAuthCheck extends StatefulWidget {
  static const String routeName = "/user-auth-check";
  const UserAuthCheck({super.key});

  @override
  State<UserAuthCheck> createState() => _UserAuthCheckState();
}

class _UserAuthCheckState extends State<UserAuthCheck> {
  @override
  void initState()  {
    super.initState();
    checkAuth();
  }
Future<void> checkAuth() async {
   final prefs = await SharedPreferences.getInstance();
    final isUserLogged = prefs.getBool('isUserLogged') ?? false;

    if (isUserLogged) {
      Get.offAllNamed(AppRoutes.CONNECTION_SCREEN);
    } else {
      Get.offAllNamed(AppRoutes.SIGN_IN);
    }
  
}
  @override
  Widget build(BuildContext context) {
    return MainBaseScaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // const CircularProgressIndicator(),
              // const SizedBox(height: 20),
              // Text(
              //   _isOffline
              //       ? "Offline mode (cached login)"
              //       : "Checking authentication...",
              //   style: const TextStyle(color: Colors.white70),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
