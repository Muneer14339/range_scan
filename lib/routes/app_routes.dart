// ignore_for_file: constant_identifier_names

import '/Screens/auth/forget_password.dart';
import '/Screens/auth/sign_in_screen.dart';
import '/Screens/auth/sign_up_screen.dart';
import '/Screens/auth/user_auth_check.dart';
import '/Screens/auth/verify_email.dart';
import '/Screens/connection_screen.dart';

class AppRoutes {
  static const String INTRO = '/';
  static const String SIGN_IN = SignInScreen.routeName;
  static const String SIGN_UP = SignUpScreen.routeName;
  static const String FORGET_PASSWORD = ForgetPassword.routeName;
  static const String VERIFY_EMAIL = VerifyEmailScreen.routeName;
  static const String USER_AUTH_CHECK = UserAuthCheck.routeName;
  static const String CONNECTION_SCREEN   = ConnectionScreen.routeName;
}
