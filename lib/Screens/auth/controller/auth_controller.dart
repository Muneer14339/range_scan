import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '/Screens/auth/model/user_model.dart';
import '/core/constant/app_colors.dart';
import '/core/errors/firebase_error_handler.dart';
import '/core/utils/toast_utils.dart';
import 'package:country_picker/country_picker.dart';
import '/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class AuthController extends GetxController {
  RxBool isLoading = false.obs;

  // 🔹 Auto-check timer for email verification
  Timer? _emailCheckTimer;

  // Text controllers
  final loginEmailCtrl = TextEditingController();
  final loginPasswordCtrl = TextEditingController();

  final signupFirstNameCtrl = TextEditingController();
  final signupEmailCtrl = TextEditingController();
  final signupPasswordCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  final forgetPasswordCtrl = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final loginFormKey = GlobalKey<FormState>();

  //* Password visibility toggles
  RxBool isPasswordVisible = true.obs;
  RxBool isResetPasswordVisible = true.obs;
  RxBool isConfirmPasswordVisible = true.obs;

  void togglePassword(RxBool value) {
    value.value = !value.value;
  }

  Future<void> saveUserId(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', uid);

    log('User ID at save : $uid');
  }

  FocusNode locationFocus = FocusNode();
  void pickCountry(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        backgroundColor: AppColors.background,
        textStyle: TextStyle(color: AppColors.textPrimary),
        searchTextStyle: TextStyle(color: AppColors.textPrimary),
        inputDecoration: InputDecoration(
          filled: true,
          fillColor: AppColors.background,
          hintStyle: TextStyle(color: AppColors.textPrimary),
          hintText: 'Search country',
        ),
      ),
      onSelect: (country) {
        locationCtrl.text = country.name;
      },
    );
  }

  var userId = RxnString();
  final firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  //********************* Login with email & password ********************* */
  Future<void> login() async {
    if (loginFormKey.currentState!.validate()) {
      try {
        isLoading.value = true;
        final result = await firebaseAuth.signInWithEmailAndPassword(
          email: loginEmailCtrl.text.trim(),
          password: loginPasswordCtrl.text.trim(),
        );
     if (result.user != null) {
          await saveUserId(result.user!.uid);
          await firestore.collection('users').doc(result.user!.uid).update({
            'currentlyLogin': 'RS',
          });

          final userDoc =
              await firestore.collection('users').doc(result.user!.uid).get();

          if (userDoc.exists) {
            currentUser.value = UserModel.fromJson(userDoc.data()!);
            await setUserLoggedIn(true);
            Get.offAndToNamed(AppRoutes.CONNECTION_SCREEN);
            clearTextField();
          }
        }
        // if (result.user != null) {
        //   if (result.user!.emailVerified) {
        //     await saveUserId(result.user!.uid);
        //     await firestore.collection('users').doc(result.user!.uid).update({
        //       'currentlyLogin': 'RS',
        //     });

        //     final userDoc =
        //         await firestore.collection('users').doc(result.user!.uid).get();

        //     if (userDoc.exists) {
        //       currentUser.value = UserModel.fromJson(userDoc.data()!);
        //       await setUserLoggedIn(true);
        //       Get.offAndToNamed(AppRoutes.CONNECTION_SCREEN);
        //       clearTextField();
        //     }
        //   } else {
        //     // ToastUtils.showError(
        //     //   message:
        //     //       "Please verify your email (${result.user?.email ?? ''}) before continuing. Please check your inbox or spam folder.",
        //     // );
        //     Get.offAllNamed(AppRoutes.VERIFY_EMAIL);
        //     startEmailVerificationAutoCheck();
        //     clearTextField();
        //   }
        // }
      } catch (e) {
        ToastUtils.showError(
          message: FirebaseErrorHandler.getAuthErrorMessage(e),
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  //********************* Google Sign-In ********************* */
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Future<User?> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        final userRef = firestore.collection('users').doc(user.uid);
        final userDoc = await userRef.get();
        await saveUserId(user.uid);
        if (userDoc.exists) {
          await userRef.update({'currentlyLogin': 'RS'});
          currentUser.value = UserModel.fromJson(userDoc.data()!);
        } else {
          UserModel userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            firstName: user.displayName ?? '',
            location: 'PK',
            role: 0,
            registeredFrom: 'RS',
            currentlyLogin: 'RS',
          );
          await userRef.set(userModel.toJson());
          currentUser.value = userModel;
        }
        await setUserLoggedIn(true);
        Get.offAllNamed(AppRoutes.CONNECTION_SCREEN);
      }
      return user;
    } catch (e) {
      log("Google Sign-In Error: $e");
      ToastUtils.showError(
        message: FirebaseErrorHandler.getAuthErrorMessage(e),
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  //********************* Signup with email & password ********************* */
  Future<void> signup() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      try {
        final result = await firebaseAuth.createUserWithEmailAndPassword(
          email: signupEmailCtrl.text.trim(),
          password: signupPasswordCtrl.text.trim(),
        );

        if (result.user != null) {
          await result.user!.updateDisplayName(signupFirstNameCtrl.text.trim());
          // await result.user!
          //     .sendEmailVerification(); // 🔹 send verification email

          // ToastUtils.showSuccess(
          //   message:
          //       "Verification email has been sent to ${result.user?.email}! Please check your inbox or spam folder.",
          // );
          // Get.offAllNamed(AppRoutes.VERIFY_EMAIL);
          await _createUserInFirestore(result.user!);
          await setUserLoggedIn(true);
          Get.offAllNamed(AppRoutes.CONNECTION_SCREEN);
          // startEmailVerificationAutoCheck();
          // clearTextField();
        } else {
          throw Exception('Signup failed');
        }
      } catch (e) {
        ToastUtils.showError(
          message: FirebaseErrorHandler.getAuthErrorMessage(e),
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  void clearTextField() async {
    signupFirstNameCtrl.clear();
    signupEmailCtrl.clear();
    signupPasswordCtrl.clear();
    loginEmailCtrl.clear();
    loginPasswordCtrl.clear();
    locationCtrl.clear();
  }

  Future<void> _createUserInFirestore(User user) async {
    final userRef = firestore.collection('users').doc(user.uid);

    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      UserModel userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        firstName: user.displayName ?? signupFirstNameCtrl.text.trim(),
        location: locationCtrl.text,
        role: 0,
        registeredFrom: 'RS',
        currentlyLogin: 'RS',
        password: signupPasswordCtrl.text.trim(),
      );
      await userRef.set(userModel.toJson());
      currentUser.value = userModel;
      log("User created in Firestore: ${userModel.toJson()}");
    }
  }

  //************************** Forget password ************************ */
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        ToastUtils.showError(message: "Please enter your email first");
        return;
      }
      isLoading.value = true;
      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        ToastUtils.showError(message: "This email address is does not exist.");
        return;
      }
      await firebaseAuth.sendPasswordResetEmail(email: email);
      ToastUtils.showSuccess(
        message:
            "Password reset link sent to $email. Check your inbox or spam folder.",
      );
    } catch (e) {
      ToastUtils.showError(
        message: FirebaseErrorHandler.getAuthErrorMessage(e),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await firebaseAuth.currentUser?.sendEmailVerification();
      ToastUtils.showSuccess(
        message:
            "Verification email resent to ${firebaseAuth.currentUser?.email ?? ''}! Please check your inbox or spam folder.",
      );
    } catch (e) {
      ToastUtils.showError(
        message: FirebaseErrorHandler.getAuthErrorMessage(e),
      );
    }
  }

  /// 🔹 Manual check verification status
  Future<void> checkEmailVerified() async {
    await firebaseAuth.currentUser?.reload();
    final user = firebaseAuth.currentUser;

    if (user != null && user.emailVerified) {
      stopEmailVerificationAutoCheck();

      Get.offAllNamed(AppRoutes.CONNECTION_SCREEN);
      setUserLoggedIn(true);
    } else {
      ToastUtils.showError(
        message:
            "Please verify your email ${user?.email ?? ''} before continuing.",
      );
    }
  }

  /// 🔹 Auto check every 5s until verified
  void startEmailVerificationAutoCheck() {
    stopEmailVerificationAutoCheck();
    _emailCheckTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      await firebaseAuth.currentUser?.reload();
      final user = firebaseAuth.currentUser;
      if (user != null && user.emailVerified) {
        stopEmailVerificationAutoCheck();
        await setUserLoggedIn(true);
        Get.offAllNamed(AppRoutes.CONNECTION_SCREEN);
      }
    });
  }

  void stopEmailVerificationAutoCheck() {
    _emailCheckTimer?.cancel();
    _emailCheckTimer = null;
  }

  /// Logout
  Future<void> logout() async {
    try {
      isLoading.value = true;
      await firebaseAuth.signOut();
      currentUser.value = null;
      stopEmailVerificationAutoCheck();
      clearUserSession();
      Get.offAllNamed(AppRoutes.SIGN_IN);
    } catch (e) {
      ToastUtils.showError(
        message: FirebaseErrorHandler.getAuthErrorMessage(e),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setUserLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUserLogged', value);
    log('isUserLogged set to: $value');
  }

  Future<bool> getUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isUserLogged') ?? false;
  }

  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    log('SharedPreferences cleared');
  }

  @override
  void onClose() {
    super.onClose();
  }
}
