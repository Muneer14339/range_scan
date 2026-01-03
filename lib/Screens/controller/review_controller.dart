// import 'dart:math';
// import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'dart:io';
// import 'dart:math' as math;

// import '/models/shots_model.dart';

// import '../../core/utils/toast_utils.dart';
// import '../../ffi_bridge/ffi_binding.dart';


// class ReviewController extends GetxController with GetSingleTickerProviderStateMixin {
  
//   // Observables
//   final RxString editMode = 'remove'.obs;
//   final RxInt expectedShotCount = 10.obs;
//   final RxnInt highlightedShotId = RxnInt(null);
//   final RxnString selectedTarget = RxnString(null);
//   final Rx<File?> capturedImage = Rx<File?>(null);
//   final RxList<Shot> shots = <Shot>[].obs;
  
//   // Animation
//   late AnimationController animationController;
//   late Animation<double> fadeAnimation;
//   late Animation<Offset> slideAnimation;
  
//   // Callback
//   final VoidCallback? onFinalize;
  
//   // Global result reference
//   FledResult? res;
//   FledResult? get currentResult => res;
  
//   ReviewController({this.onFinalize});

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeAnimations();
//   }

//   @override
//   void onClose() {
//     animationController.dispose();
//     super.onClose();
//   }

//   void _initializeAnimations() {
//     animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );

//     fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
//     );

//     slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 20),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
//     );

//     animationController.forward();
//   }

//   // Getters
//   int get totalScore => shots.fold(0, (sum, shot) => sum + shot.score);
//   double get averageScore => shots.isEmpty ? 0 : totalScore / shots.length;
//   int get bestShot => shots.isEmpty ? 0 : shots.map((s) => s.score).reduce(math.max);

//   // Methods
//   void setCapturedImage(File image) {
//     capturedImage.value = image;
//   }

//   void setExpectedShotCount(int count) {
//     expectedShotCount.value = count;
//   }

//   void setSelectedTarget(String target) {
//     selectedTarget.value = target;
//   }

//   void setEditMode(String mode) {
//     editMode.value = mode;
//   }

//   void highlightShot(int? shotId) {
//     highlightedShotId.value = shotId;
//   }

//   void removeShot(int shotId) {
//     shots.removeWhere((shot) => shot.id == shotId);
    
//     // Re-index shots
//     for (int i = 0; i < shots.length; i++) {
//       shots[i] = shots[i].callback(id: i + 1);
//     }
//   }

//   void addShot(double x, double y) {
//     final dx = x - 50;
//     final dy = y - 50;
//     final distance = math.sqrt(dx * dx + dy * dy);

//     int score = _calculateScore(distance);
    
//     shots.add(Shot(
//       id: shots.length + 1,
//       x: x,
//       y: y,
//       score: score,
//     ));
//   }

//   int _calculateScore(double distance) {
//     if (distance < 8) return 10;
//     if (distance < 12) return 9;
//     if (distance < 18) return 8;
//     if (distance < 25) return 7;
//     if (distance < 32) return 6;
//     if (distance < 38) return 5;
//     if (distance < 42) return 4;
//     if (distance < 47) return 3;
//     if (distance < 52) return 2;
//     return 1;
//   }

//   void generateMockResults() {
//     final variance = math.Random().nextInt(3) - 1;
//     final actualShots = math.max(1, expectedShotCount.value + variance);

//     shots.clear();

//     for (int i = 0; i < actualShots; i++) {
//       final angle = math.Random().nextDouble() * 2 * math.pi;
//       const maxRadius = 45.0;
//       final radius = math.Random().nextDouble() * maxRadius;

//       final x = 50 + (radius * math.cos(angle) / maxRadius) * 40;
//       final y = 50 + (radius * math.sin(angle) / maxRadius) * 40;

//       int score = _calculateScore(radius);
//       shots.add(Shot(id: i + 1, x: x, y: y, score: score));
//     }
//   }

//   Future<void> handleTargetTap(Offset point) async {
//     final tapX = point.dx;
//     final tapY = point.dy;
    
//     try {
//       if (editMode.value == "remove") {
//         final result = await removeBulletHoleWorker(tapX, tapY);
//         if (result != null) {
//           res = result; // Update global result
//           debugPrint('Removed bullet hole at ($tapX, $tapY)');
//           debugPrint('Remaining holes: ${result.metrics['group']}');
//         }
//       } else if (editMode.value == "add") {
//         final result = await fledAddBulletWorker(tapX, tapY);
//         if (result != null) {
//           res = result; // Update global result
//           debugPrint('Added bullet hole at ($tapX, $tapY)');
//           debugPrint('Total holes: ${result.holes.length}');
//         }
//       }
//     } catch (e) {
//       debugPrint('Error handling target tap: $e');
//     }
//   }

//   void finalizeShooting() {
//     onFinalize?.call();
//     ToastUtils.showInfo(message: 'Finalizing results...');
//   }
// }
