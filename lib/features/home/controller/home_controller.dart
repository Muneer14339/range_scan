import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/features/home/model/target_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/caliber_model.dart';

class HomeController extends GetxController {

  //*  select caliber list and all related data
  static const String _key = "favorites";

  final favorites = <CaliberModel>[].obs;
  final allCalibers = <CaliberModel>[
    CaliberModel(name: "9×19", size: "9.02mm • .355\""),
    CaliberModel(name: ".223", size: "5.70mm • .224\""),
    CaliberModel(name: ".22 LR", size: "5.59mm • .220\""),
    CaliberModel(name: ".308", size: "7.85mm • .308\""),
    CaliberModel(name: ".380 ACP", size: "9.02mm"),
    CaliberModel(name: ".38 Special", size: "9.07mm"),
    CaliberModel(name: ".357 Magnum", size: "9.07mm"),
    CaliberModel(name: ".40 S&W", size: "10.16mm"),
  ].obs;

  final selectedCaliber = Rxn<CaliberModel>();

  // -----------------------------
  // 🔹 Load favorites on init
  // -----------------------------
  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
    _initializeTargets();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favs = prefs.getStringList(_key) ?? [];
    favorites.assignAll(favs.map((e) => CaliberModel.fromJson(e)).toList());
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favs = favorites.map((e) => e.toJson()).toList();
    await prefs.setStringList(_key, favs);
  }

  // -----------------------------
  // 🔹 Selection + Favorites logic
  // -----------------------------
  void selectCaliber(CaliberModel caliber) {
    selectedCaliber.value = caliber;
    allCalibers.refresh();
  }

  void toggleFavorite(CaliberModel caliber) async {
    if (favorites.contains(caliber)) {
      favorites.remove(caliber);
    } else {
      favorites.add(caliber);
    }
    await _saveFavorites(); // persist change
    allCalibers.refresh();
  }

  bool isFavorite(CaliberModel caliber) {
    return favorites.contains(caliber);
  }


//* all date related to select target paper


final selectedTargetCategory = TargetCategory.nra.obs;
  final selectedTarget = Rxn<TargetModel>();
  final targets = <TargetModel>[].obs;
   void _initializeTargets() {
    targets.addAll([
      // NRA Targets
      TargetModel(
        id: 'nra-b8',
        name: 'NRA B-8 Pistol',
        description: 'Standard 25-yard pistol target with scoring rings 7-10 and X-ring',
        specs: '10.5" × 12" • 10-ring: 3.39" • X-ring: 1.695"',
        emoji: '🎯',
        category: TargetCategory.nra,
      ),
      TargetModel(
        id: 'nra-b6',
        name: 'NRA B-6 Pistol',
        description: '50-yard pistol target with smaller rings for precision shooting',
        specs: '10.5" × 12" • 10-ring: 2.54" • X-ring: 1.27"',
        emoji: '🎯',
        category: TargetCategory.nra,
      ),
      TargetModel(
        id: 'nra-a23',
        name: 'NRA A-23/5',
        description: '50-foot .22 caliber target with fine scoring rings',
        specs: '7" × 10" • 10-ring: 0.69" • X-ring: 0.345"',
        emoji: '🎯',
        category: TargetCategory.nra,
      ),
      TargetModel(
        id: 'nra-sr1',
        name: 'NRA SR-1 Center Fire Rifle',
        description: '100-yard rifle target for center fire cartridges',
        specs: '13" × 13" • 10-ring: 3" • X-ring: 1.5"',
        emoji: '🎯',
        category: TargetCategory.nra,
      ),
      TargetModel(
        id: 'nra-a17',
        name: 'NRA A-17 Rifle',
        description: '50-yard rifle target with precision scoring',
        specs: '7" × 10" • 10-ring: 1.5" • X-ring: 0.75"',
        emoji: '🎯',
        category: TargetCategory.nra,
      ),
      // Precision Targets
      TargetModel(
        id: 'precision-1',
        name: 'Precision Target 1',
        description: 'High precision target for competitive shooting',
        specs: '8" × 8" • 10-ring: 1" • X-ring: 0.5"',
        emoji: '🎯',
        category: TargetCategory.precision,
      ),
      TargetModel(
        id: 'precision-2',
        name: 'Precision Target 2',
        description: 'Ultra-fine precision target for benchrest shooting',
        specs: '6" × 6" • 10-ring: 0.5" • X-ring: 0.25"',
        emoji: '🎯',
        category: TargetCategory.precision,
      ),
    ]);
  }

  void selectTargetCategory(TargetCategory category) {
    selectedTargetCategory.value = category;
  }

  void selectTarget(TargetModel target) {
    selectedTarget.value = target;
  }

//* all date related to select distance in yards

// Observable variables
  final selectedPistolDistance = Rxn<String>();
  final selectedRifleDistance = Rxn<String>();
  final selectedIndoorDistance = Rxn<String>();
  final selectedCustomDistance = Rxn<String>();

  final customDistanceTextController = TextEditingController();

  final List<String> pistolDistances = [
    '7 yards',
    '15 yards',
    '25 yards',
    '50 yards',
  ];

  final List<String> rifleDistances = [
    '100 yards',
    '200 yards',
    '300 yards',
    '500 yards',
    '600 yards',
  ];

  final List<String> indoorDistances = [
    '3 yards',
    '5 yards',
    '7 yards',
    '10 yards',
    '15 yards',
  ];

  // Computed property for checking if any selection exists
  bool get hasSelection =>
      selectedPistolDistance.value != null ||
      selectedRifleDistance.value != null ||
      selectedIndoorDistance.value != null ||
      (selectedCustomDistance.value != null && selectedCustomDistance.value!.isNotEmpty);

  // Get the currently selected distance
  String get currentSelection {
    return selectedPistolDistance.value ??
           selectedRifleDistance.value ??
           selectedIndoorDistance.value ??
           selectedCustomDistance.value ??
           '';
  }

  void clearAllSelections() {
    selectedPistolDistance.value = null;
    selectedRifleDistance.value = null;
    selectedIndoorDistance.value = null;
    selectedCustomDistance.value = null;
    customDistanceTextController.clear();
  }

  void selectDistance(String category, String? distance) {
    // Clear all selections first
    clearAllSelections();

    // Set the selected distance for the specific category
    switch (category) {
      case 'pistol':
        selectedPistolDistance.value = distance;
        break;
      case 'rifle':
        selectedRifleDistance.value = distance;
        break;
      case 'indoor':
        selectedIndoorDistance.value = distance;
        break;
      case 'custom':
        selectedCustomDistance.value = distance;
        break;
    }
  }

  void onCustomDistanceChanged(String value) {
    // Clear other selections when typing in custom field
    selectedPistolDistance.value = null;
    selectedRifleDistance.value = null;
    selectedIndoorDistance.value = null;
    selectedCustomDistance.value = value.isNotEmpty ? value : null;
  }

 
}
