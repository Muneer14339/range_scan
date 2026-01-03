import 'package:get/get.dart';
import '/Screens/auth/controller/auth_controller.dart';
import '/Screens/auth/forget_password.dart';
import '/Screens/auth/sign_in_screen.dart';
import '/Screens/auth/sign_up_screen.dart';
import '/Screens/auth/user_auth_check.dart';
import '/Screens/auth/verify_email.dart';
import '/Screens/connection_screen.dart';
import '/Screens/controller/connection_controller.dart';

import '../Screens/auth/intro.dart';
import 'app_routes.dart';

get getAppPages => [
  GetPage(name: AppRoutes.INTRO, page: () => const Intro()),
  GetPage(
    name: AppRoutes.SIGN_IN,
    page: () => const SignInScreen(),
    binding: BindingsBuilder.put(() => AuthController(), permanent: true),
  ),
  GetPage(
    name: AppRoutes.SIGN_UP,
    page: () => const SignUpScreen(),
    binding: BindingsBuilder.put(() => AuthController()),
  ),
  GetPage(
    name: AppRoutes.FORGET_PASSWORD,
    page: () => const ForgetPassword(),
    binding: BindingsBuilder.put(() => AuthController()),
  ),
  GetPage(
    name: AppRoutes.USER_AUTH_CHECK,
    page: () => const UserAuthCheck(),
    binding: BindingsBuilder.put(() => AuthController(), permanent: true),
  ),
  GetPage(
    name: AppRoutes.VERIFY_EMAIL,
    page: () => const VerifyEmailScreen(),
    binding: BindingsBuilder.put(() => AuthController()),
  ),
  GetPage(
    name: AppRoutes.CONNECTION_SCREEN,
    page: () => const ConnectionScreen(),
    binding: BindingsBuilder.put(() => ConnectionController(), permanent: true),
  ),
];
