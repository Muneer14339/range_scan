import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '/Screens/capture_screen.dart';
import '/Screens/components/nra_instruction_dialog.dart';
import '/Screens/components/pa_instructions_dialog.dart'
    show LightingRequiredDialog, NoBulletsForRedDialog;
import '/Screens/loadout_screen.dart';
import '/Screens/models/firearm_model.dart';
import '/Screens/models/main_session_record_model.dart';
import '/Screens/models/target_model.dart';
import '/Screens/models/user_weapon_model.dart';
import '/Screens/result_screen.dart';
import '/Screens/review_screen.dart';
import '/Screens/services/firearm_services.dart';
import '/Screens/target_screen.dart';
import '/core/helper/network_connection_helper.dart';
import '/core/utils/toast_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ffi_bridge/ffi_binding.dart';


class ConnectionController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Listen to login/logout changes
    firebaseAuth.authStateChanges().listen((User? user) {
      if (user != null) {
        userId.value = user.uid;
        log("✅ Logged in with uid: ${user.uid}");
      } else {
        userId.value = null;
        log("🚪 User logged out");
      }
    });
    gettingDataAtStartedOfApp();
    fetchData();
     isFirearmLoading.value = true;
    _loadConfigJson().then((_) {
     
      log("Config prepared at: ${configPath.value}");
      _loadData(userId.value ?? '').whenComplete( () {
        isFirearmLoading.value = false;
       
        log('Firearms loaded');

      });
    });
    services = FirearmServices();
    services.syncWeaponsFromFirebase(userId.value ?? '');
  }
  RxBool isFirearmLoading = false.obs;
  final firebaseAuth = FirebaseAuth.instance;
  RxBool isTargetBrightHole = true.obs;
  void onChangeIsTargetBrightHole(bool value) {
    if (selectedTarget.value?.name == 'Black Ring') {
      isTargetBrightHole.value = true;
    }
    isTargetBrightHole.value = value;
    log("isTargetBrightHole: ${isTargetBrightHole.value}");
  }

  //* all data and methods according to loadout screen */
  var userId = RxnString();
  var firearms = <FirearmModel>[].obs;
  //* Load firearms from Firebase and SQLite
 Future<void> _loadData(String userId) async {
  final firearmServices = FirearmServices();

  try {
    final isOnline = await NetworkUtils.hasInternet();

    if (isOnline) {
      // 🔹 1. Fetch public firearms from Firebase
      final publicSnapshot =
          await FirebaseFirestore.instance.collection("firearms").get();

      final publicFresh = publicSnapshot.docs
          .map((doc) => FirearmModel.fromJson(doc.data()))
          .toList();

      if (publicFresh.isNotEmpty) {
        await firearmServices.saveFirearms(publicFresh);
        log("✅ Synced ${publicFresh.length} public firearms to SQLite");
      }

      // 🔹 2. Fetch user weapons from Firebase
      final userWeaponsSnapshot = await FirebaseFirestore.instance
          .collection("weapons")
          .where("userId", isEqualTo: userId)
          .get();

      final userWeapons = userWeaponsSnapshot.docs
          .map((doc) => WeaponModel.fromJson(doc.data()))
          .toList();

      if (userWeapons.isNotEmpty) {
        await firearmServices.saveUserWeapons(userWeapons);
        // log("✅ Synced ${userWeapons.length} user weapons to SQLite");
      }
    } else {
      log("📴 No internet, loading only from SQLite");
    }
  } catch (e) {
    log("⚠️ Firebase fetch failed: $e");
  }

  // 🔹 3. Load local public firearms
  final publicFirearms = await firearmServices.loadFirearms();

  // 🔹 4. Load local user weapons
  final userWeaponsLocal = await firearmServices.getWeaponsByUser(userId);

  // 🔹 5. Extract firearm models from user weapons
  final userFirearms = userWeaponsLocal
      .where((w) => w.firearm != null)
      .map((w) => w.firearm!)
      .toList();

  if (userFirearms.isNotEmpty) {
    log("✅ Loaded ${userFirearms.length} user firearms from SQLite");
  }

  // 🔹 6. Merge public + user firearms — remove duplicates
  final merged = [...publicFirearms, ...userFirearms];

  // Use a Set with unique key based on firearm identity (make, model, caliber, type)
  final uniqueFirearms = <String, FirearmModel>{};

  for (final f in merged) {
    final key = [
      f.make?.toLowerCase().trim(),
      f.model?.toLowerCase().trim(),
      f.caliber?.toLowerCase().trim(),
      f.type?.toLowerCase().trim(),
    ].join('-');

    uniqueFirearms[key] = f;
  }

  firearms.assignAll(uniqueFirearms.values.toList());

  log("✅ Loaded ${firearms.length} total unique firearms (public + user)");

  if (firearms.isNotEmpty) {
    final first = firearms.first;
    log("First firearm: ${first.caliber} - ${first.type} - ${first.caliberDiameter}");
  }
}


  List<String> get types =>
      firearms.map((f) => f.type).whereType<String>().toSet().toList();

  List<String>? get calibers {
  if (selectedType.isEmpty) return [];

  final filtered = firearms
      .where((f) => f.type == selectedType.value)
      .toList();

  // Sort safely by numeric diameter (handling nulls)
  filtered.sort((a, b) {
    final aDiameter = a.caliberDiameter ?? double.infinity;
    final bDiameter = b.caliberDiameter ?? double.infinity;
    return aDiameter.compareTo(bDiameter);
  });

  // Keep unique calibers while preserving sorted order
  final uniqueCalibers = <String>{};
  final sortedCalibers = <String>[];

  for (final f in filtered) {
    if (f.caliber != null && uniqueCalibers.add(f.caliber!)) {
      sortedCalibers.add(f.caliber!);
    }
  }

  return sortedCalibers;
  }

  double? selectedDiameter;
  void onCaliberSelected(String caliber) {
    selectedCaliber.value = caliber;

    final match = firearms.firstWhere(
      (f) => f.type == selectedType.value && f.caliber == caliber,
      orElse: () => FirearmModel(caliberDiameter: 0),
    );

    selectedDiameter = match.caliberDiameter ?? 0;
    log("Selected diameter: $selectedDiameter for caliber: $caliber");
  }
  //********************************************************************************** */

  //* All main workflow of connection screen and methods */
  final RxInt activeTabIndex = 0.obs;
  final Rx<FledResult> shots = FledResult(Uint8List(0), {}, []).obs;
  final RxString configPath = ''.obs;

  Future<void> _loadConfigJson() async {
    final data = await rootBundle.load("assets/config.json");
    configData = jsonDecode(utf8.decode(data.buffer.asUint8List()));

    final directory = await Directory.systemTemp.createTemp();
    final file = File("${directory.path}/config.json");
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    configPath.value = file.path;
  }

  Map<String, dynamic> configData = {};

  /// Update target config dynamically
  Future<void> updateTargetConfig({
    required String categoryName,
    required String targetName,
    required String caliber,
  }) async {
    try {
      final categories = configData["target_categories"];
      if (categories == null || categories is! List) {
        log("❌ target_categories missing or not a List in configData");
        return;
      }

      final category = categories.cast<Map<String, dynamic>?>().firstWhere(
        (c) => c?["name"] == categoryName,
        orElse: () => null,
      );
      if (category == null) {
        log("❌ Category not found: $categoryName");
        return;
      }

      final targets = category["targets"];
      if (targets == null || targets is! List) {
        log("❌ targets missing or not a List in category: $categoryName");
        return;
      }

      final target = targets.cast<Map<String, dynamic>?>().firstWhere(
        (t) => t?["name"] == targetName,
        orElse: () => null,
      );
      if (target == null) {
        log("❌ Target not found: $targetName in $categoryName");
        return;
      }
      target["default_bullet_caliber"] = caliber;
      // ✅ Update bullet_calibers list
      final calibers = (configData["bullet_calibers"] as List?) ?? [];
      final existing = calibers.cast<Map<String, dynamic>>().firstWhere(
        (c) => c["name"].toString().toLowerCase() == caliber.toLowerCase(),
        orElse: () => {},
      );

      if (existing.isEmpty) {
        final trimmedCaliber = caliber.trim().toLowerCase();

        final normalized = trimmedCaliber.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9.]'),
          '',
        );

        // double diameter;
        // if (normalized.contains('9mm')) {
        //   diameter = 0.355;
        // } else if (normalized.contains('22lr') ||
        //     normalized.contains('.22lr')) {
        //   diameter = 0.223;
        // } else if (normalized.contains('.45 ACP')) {
        //   diameter = 0.452;
        // } else {
        //   diameter = 0.249;
        // }

        final newCaliber = {
          "name": caliber,
          "diameter_inches": selectedDiameter,
        };
        calibers.add(newCaliber);
        configData["bullet_calibers"] = calibers;
        log(" Added new caliber: ${jsonEncode(newCaliber)}");
      } else {
        log(
          "ℹ Caliber already exists: ${existing["name"]} (${existing["diameter_inches"]} in.)",
        );
      }
      final file = File(configPath.value);
      await file.writeAsString(jsonEncode(configData), flush: true);
      log("✅ Updated target '$targetName' in '$categoryName'");
      log("🔍 default_bullet_caliber = ${target["default_bullet_caliber"]}");
    } catch (e) {
      log("⚠️ Failed to update config: $e");
    }
  }

  Future<void> verifyConfig({
    required String categoryName,
    required String targetName,
  }) async {
    try {
      final file = File(configPath.value);

      if (!await file.exists()) {
        log("❌ Config file not found at: ${configPath.value}");
        return;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content);

      final categories = json["target_categories"] as List?;
      if (categories == null) {
        log("❌ No target_categories found");
        return;
      }

      final category = categories.cast<Map<String, dynamic>?>().firstWhere(
        (c) => c?["name"] == categoryName,
        orElse: () => null,
      );
      if (category == null) {
        log("❌ Category not found: $categoryName");
        return;
      }

      final targets = category["targets"] as List?;
      if (targets == null) {
        log("❌ No targets found in category: $categoryName");
        return;
      }

      final target = targets.cast<Map<String, dynamic>?>().firstWhere(
        (t) => t?["name"] == targetName,
        orElse: () => null,
      );
      if (target == null) {
        log("❌ Target not found: $targetName");
        return;
      }

      final caliber = target["default_bullet_caliber"];
      log("🔍 Verified default_bullet_caliber for '$targetName': $caliber");
    } catch (e) {
      log("⚠️ Failed to verify config: $e");
    }
  }

  // Constants
  final List<String> stepLabels = const [
    'Loadout',
    'Targets',
    'Capture',
    'Review',
    'Results',
  ];

  RxDouble? distance = 0.0.obs;

  // Methods
  void goTo(int nextIndex) {
    activeTabIndex.value = nextIndex.clamp(0, stepLabels.length - 1);
  }

  void goBack() {
    if (activeTabIndex.value > 0) {
      activeTabIndex.value -= 1;
    } else {
      Get.back();
    }
  }

  Future<bool> onWillPop() async {
    if (activeTabIndex.value > 0) {
      goBack();
      return false;
    }
    return true;
  }

  void onLoadoutProceed(String clbr) async {
    selectedCaliber.value = clbr;
    // await insertUserWeaponData();
    goTo(1);
  }

  void onTargetProceed(
    String type,
    double dis,
    String configP,
    String detectionMode,
  ) async {
    await updateTargetConfig(
      categoryName: selectedTarget.value?.category ?? '',
      targetName: selectedTarget.value?.value ?? '',
      caliber: selectedCaliber.value,
    );
    await verifyConfig(
      categoryName: selectedTarget.value?.category ?? '',
      targetName: selectedTarget.value?.value ?? '',
    );
    selectedTarget.value?.value = type;
    distance?.value = dis;
    configPath.value = configP;
    isTargetBrightHole.value = detectionMode == 'light' ? true : false;
    goTo(2);
  }

  void onCaptureProcessed(FledResult processedData, String newTargetType) {
    shots.value = processedData;
    goTo(3);
  }

  void onReviewFinalize() {
    goTo(4);
  }

  void onNewSession() {
    selectedTarget.value = null;
    selectedCategory.value = '';
    activeTabIndex.value = 0;
    shots.value = FledResult(Uint8List(0), {}, []);
    distance?.value = 0.0;
    selectedCaliber.value = '';
    selectedType.value = '';
    notesCtrl.text = '';
  }

  void onTabTap(int index) {
    if (index <= activeTabIndex.value) {
      goTo(index);
    } else {
      ToastUtils.showInfo(message: 'Complete this step first to proceed');
    }
  }

  List<Widget> get screens => [
    LoadoutScreen(onProceed: onLoadoutProceed),
    TargetScreen(
      caliber: selectedCaliber.value,
      onProceed: onTargetProceed,
      distance: distance?.value ?? 0.0,
      detectionMode: isTargetBrightHole.value ? 'light' : 'dark',
    ),
    Obx(
      () => CaptureScreen(
        targetType: selectedTarget.value?.value ?? '',
        configPath: configPath.value,
        onProcessed: onCaptureProcessed,
        dis: distance?.value ?? 00,
        caliber: selectedCaliber.value,
        detectionMode: isTargetBrightHole.value ? 'light' : 'dark',
        categoryName: selectedTarget.value?.category ?? '',
        targetName: selectedTarget.value?.name ?? '',
      ),
    ),
    ReviewScreen(onFinalize: onReviewFinalize),
    ResultScreen(
      targetType: selectedTarget.value?.value ?? '',

      onNewSession: onNewSession,
    ),
  ];
 RxBool isShowTitleBullets = false.obs;
  //********************************************************************************** */
  //* all data and methods according to loadout screen

  TextEditingController notesCtrl = TextEditingController();
  TextEditingController addCaliberCtrl = TextEditingController();
  TextEditingController diameterCtrl = TextEditingController();
  // Form state
  var selectedType = ''.obs;
  var selectedCaliber = ''.obs;
  final statusMessage = ''.obs;

  final formKey = GlobalKey<FormState>();

  /// Validate & Save Loadout
  bool validateAndSave() {
    final ok = formKey.currentState?.validate() ?? false;
    if (ok) formKey.currentState?.save();
    return ok;
  }
var calculatedDiameter = 0.0.obs;
  WeaponModel addCaliberModel = WeaponModel();
  void addCaliber() {
    if (addCaliberCtrl.text.isEmpty ) {
      // Optionally show a message if either field is empty
      ToastUtils.showError(message: 'Please enter  caliber.');
      return;
    }
    if(calculatedDiameter.value == 0.0){
      ToastUtils.showError(message: 'Please enter valid caliber then diameter automatically calculated.');
      return;
    }

   

    addCaliberModel = WeaponModel(
      userId: userId.value,
      firearm: FirearmModel(
        type: selectedType.value,
        caliber: addCaliberCtrl.text,
        caliberDiameter: calculatedDiameter.value,
      ),

      // diameter: diameterValue.toString(),
    );

    services.insertWeapon(addCaliberModel).whenComplete(() {
      ToastUtils.showSuccess(message: 'Caliber added successfully.');
      log(addCaliberModel.toJson().toString());
      Get.back();
      _loadData(userId.value ?? '');
      refresh();
      addCaliberCtrl.clear();
      diameterCtrl.clear();

      print('Firearm added successfully!');
    });
  }

  void saveLoadout({void Function(String)? onProceed}) {
if(selectedType.value.isEmpty){
  ToastUtils.showError(message: 'Please select a firearm type');
  return;
}

    if (selectedCaliber.isEmpty) {
      _showError('Please select a caliber');
      return;
    }

    if (distance == null || distance!.value <= 0) {
      _showError('Please enter a valid shooting distance');
      return;
    }

    // final shotCount = int.tryParse(shotCountController.text);
    // if (shotCount == null || shotCount < 1 || shotCount > 15) {
    //   _showError('Please enter a valid number of shots (1-15)');
    //   return;
    // }

    statusMessage.value = 'Loadout saved successfully!';
    if (selectedCaliber.isNotEmpty) {
      onProceed?.call(selectedCaliber.value);
    }

    Future.delayed(const Duration(seconds: 3), () {
      statusMessage.value = '';
    });
  }

  void _showError(String msg) {
    ToastUtils.showError(message: msg);
  }

  //********************************************************************************** */
  //* All target related data and methods
  RxString selectedCategory = ''.obs;
  Rx<TargetModel?> selectedTarget = Rx<TargetModel?>(null);
  final List<TargetModel> targetsList = [
    TargetModel(
      category: "NRA Target Papers",
      value: "B-2 - 50 FT. Slow Fire",
      name: "B-2 - 50 FT. Slow Fire",
    ),
    TargetModel(
      category: "NRA Target Papers",
      value: "B-3 - 50 FT. Timed and Rapid Fire",
      name: "B-3 - 50 FT. Timed and Rapid Fire",
    ),
    TargetModel(
      category: "NRA Target Papers",
      value: "B-4 - 20 Yard Slow Fire",
      name: "B-4 - 20 Yard Slow Fire",
    ),
    TargetModel(
      category: "NRA Target Papers",
      value: "B-5 - 20 Yard Timed and Rapid Fire",
      name: "B-5 - 20 Yard Timed and Rapid Fire",
    ),
    TargetModel(
      category: "NRA Target Papers",
      value: "B-6 - 50 Yard Slow Fire",
      name: "B-6 - 50 Yard Slow Fire",
    ),
    TargetModel(
      category: "NRA Target Papers",
      value: "B-8 - 25 Yard Timed and Rapid Fire",
      name: "B-8 - 25 Yard Timed and Rapid Fire",
    ),
    TargetModel(
      category: "NRA Target Papers",
      value: "B-16 - 25 Yard Slow Fire",
      name: "B-16 - 25 Yard Slow Fire",
    ),
  ];

  final List<TargetModel> paList = [
    TargetModel(
      category: "PA Target Paper",
      value: "PA (White and Red)",
      name: "Red Ring",
      // text: 'Red Ring',
    ),
    TargetModel(
      category: "PA Target Paper",
      value: "PA (White and Red)",
      name: "Black Ring",
      // text: 'Black Ring',
    ),
    // TargetModel(
    //   category: "PA Target Paper",
    //   value: "PA (White and Red)",
    //   name: "PA Standard Target",
    // ),
    // TargetModel(
    //   category: "PA Target Paper",
    //   value: "PA (White and Red)",
    //   name: "PA Precision Target",
    // ),
    // TargetModel(
    //   category: "PA Target Paper",
    //   value: "PA (White and Red)",
    //   name: "PA Competition Target",
    // ),
  ];

  final List<TargetModel> customList = [
    TargetModel(category: "Custom", value: "close_range", name: "Close Range"),
    TargetModel(
      category: "Custom",
      value: "standard_practice",
      name: "Standard Practice",
    ),
    TargetModel(category: "Custom", value: "precision", name: "Precision"),
    TargetModel(
      category: "Custom",
      value: "custom_paper",
      name: "Add Your Custom Paper",
    ),
  ];

  void selectCategory(String category) {
    selectedCategory.value = category;
    if (category == 'NRA Target Papers') {
      isTargetBrightHole.value = true;
      log(
        "Selected NRA Target Papers and isTargetBrightHole is ${isTargetBrightHole.value}",
      );
    }
    selectedTarget.value = null; // reset target when switching category
  }

  void selectTarget(TargetModel target, BuildContext context) async {
    selectedTarget.value = target;
    if (target.category == 'NRA Target Papers') {
      isTargetBrightHole.value = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => NRAInstructionsDialog(
              onTap: () {
                Navigator.pop(context);
                isTargetBrightHole.value = true;
                onTargetProceed(
                  selectedTarget.value?.value ?? '',
                  distance?.value ?? 0,
                  configPath.value,
                  isTargetBrightHole.value ? 'light' : 'dark',
                );
              },
            ),
      );

      log(
        "Selected NRA Target Papers and isTargetBrightHole is ${isTargetBrightHole.value}",
      );
    } else if (target.category == 'PA Target Paper') {
      if (target.name == 'Black Ring') {
        isTargetBrightHole.value = true;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => LightingRequiredDialog(
                onTap: () {
                  Navigator.pop(context);
                  isTargetBrightHole.value = true;
                  onTargetProceed(
                    selectedTarget.value?.value ?? '',
                    distance?.value ?? 0,
                    configPath.value,
                    isTargetBrightHole.value ? 'light' : 'dark',
                  );
                },
              ),
        );
      } else {
        isTargetBrightHole.value = false;
        log(
          "Selected PA Target Papers and isTargetBrightHole is ${isTargetBrightHole.value}",
        );
        onTargetProceed(
          selectedTarget.value?.value ?? '',
          distance?.value ?? 0,
          configPath.value,
          isTargetBrightHole.value ? 'light' : 'dark',
        );
      }
      log(
        "Selected PA Target Papers and isTargetBrightHole is ${isTargetBrightHole.value}",
      );
    }

    log(
      "Selected Target: ${selectedTarget.value?.value} in category ${target.category}",
    );
  }
  //********************************************************************************** */
  //* save user session and weapon data to local sqflite database

  //* now use it for the dummy data insertion and fetching
  var services = FirearmServices();
  String weaponId = '';
  Future<void> insertUserWeaponData() async {
    final firearmModel = FirearmModel(
      type: selectedType.value,
      caliber: selectedCaliber.value,
      caliberDiameter: selectedDiameter,
    );
    final weaponModel = WeaponModel(
      weaponId: weaponId,
      userId: userId.value ?? '',
      firearm: firearmModel,
      notes: notesCtrl.text,
      createdAt: DateTime.now(),
    );

    log(weaponId);
    log(weaponModel.toJson().toString());
    log("Inserting  data into the database");
    String? finalWeaponId = await services.insertWeapon(weaponModel);
    weaponId = finalWeaponId ?? '';
    // await db.insertSession(session);
    await fetchData();
    // await db.insertSession(session);
  }

  List<MainSessionRecordModel> sessionsList = [];
  List<WeaponModel> weaponsList = [];
  Future<void> fetchData() async {
    log("Fetching data from the database");

    // // Get all weapons of user
    // final weapons = await services.getWeaponsByUser(userId.value ?? '');
    // log("Weapons of u1: ${weapons.map((w) => w.createdAt).toList()}");
    // weaponsList = weapons;
    // log("User ID: $userId");
    // log(weaponsList.length.toString());

    // // Get all sessions of user
    // final sessions = await services.getSessionsByUser(userId.value ?? '');
    // // log("Sessions of u1: ${sessions.map((s) => s.targetPaper).toList()}");
    // sessionsList = sessions;
    // log("User ID: $userId");
    // log('Sessions List Length: ${sessionsList.length}');
    // log(sessions.length.toString());

    // // Get weapon by ID
    // final weapon = await services.getWeaponById("w1");
    // log("Weapon w1 firearm: ${weapon?.firearm.model}");
  }

  void gettingDataAtStartedOfApp() async {
    log("Getting data at started of app");
    var services = FirearmServices();
    //   // await services.syncPendingSessions();
    //   // await services.syncPendingWeapons();
    //   // final allData = await services.getAllData();

    //   log(
    //     "Weapons total: ${allData['weapons']['total']}, "
    //     "pending: ${allData['weapons']['pending']}, "
    //     "synced: ${allData['weapons']['synced']}",
    //   );

    //   log(
    //     "Sessions total: ${allData['sessions']['total']}, "
    //     "pending: ${allData['sessions']['pending']}, "
    //     "synced: ${allData['sessions']['synced']}",
    //   );
    // }
  }
}
