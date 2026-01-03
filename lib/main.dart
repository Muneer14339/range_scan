import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oktoast/oktoast.dart';
import 'Screens/services/firearm_services.dart' show FirearmServices;
import 'core/constant/app_colors.dart';
import '/core/helper/db_helper.dart';
import '/core/helper/network_connection_helper.dart';
import '/routes/app_pages.dart';
import '/routes/app_routes.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Init SQLite FFI first (desktop only)
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ✅ Initialize Firebase once
  await Firebase.initializeApp();
 FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  // ✅ Initialize local DB (works offline too)
  await DBHelper().database;

  // ✅ Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

      // ✅ Transparent status bar
 SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // ✅ Start app
  runApp(const MyApp());

  // ✅ After app runs, try syncing if online
  final isOnline = await NetworkUtils.hasInternet();
  var services = FirearmServices();
  if (isOnline) {
    await services.syncPendingSessions();
    await services.syncPendingWeapons();
  }
  services.getAllData();
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
     const lightSystemIconsStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, 
      statusBarIconBrightness: Brightness.light, 
      statusBarBrightness: Brightness.dark,      
    );

    return OKToast(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: lightSystemIconsStyle,
        child: GetMaterialApp(
          title: 'Target Scoring Pro',
          transitionDuration: Duration.zero,
          themeMode: ThemeMode.dark,
          theme: ThemeData(
           appBarTheme:  AppBarTheme(
             backgroundColor: AppColors.surface,
             toolbarHeight: 0,
           ),
            
            primarySwatch: Colors.orange,
            textTheme: GoogleFonts.poppinsTextTheme(),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            
          ),
          getPages: getAppPages,
          initialRoute: AppRoutes.INTRO,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Sizer(
                builder: (context, orientation, screenType) {
                  return child!;
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
