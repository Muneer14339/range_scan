// import 'dart:math';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:image_picker/image_picker.dart';
// import '/Screens/controller/connection_controller.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:get/get.dart';
// import 'dart:io';
// import 'dart:convert' show JsonEncoder, ascii, json;
// import 'dart:typed_data';
// import 'dart:ui' as ui;

// import '../../../ffi_bridge/ffi_binding.dart';

// // Models
// class ProcessedData {
//   final int? id;
//   final Uint8List? jpegImage;
//   final Map<String, dynamic> metrics;
//   final List<Map<String, dynamic>> holes;

//   ProcessedData({
//     this.id,
//     required this.jpegImage,
//     required this.metrics,
//     required this.holes,
//   });

//   int get totalScore {
//     return holes.fold<int>(0, (sum, hole) => sum + (hole['score'] ?? 0) as int);
//   }

//   double get averageScore {
//     if (holes.isEmpty) return 0.0;
//     return totalScore.toDouble() / holes.length;
//   }

//   int get bestShot {
//     if (holes.isEmpty) return 0;
//     return holes
//         .map<int>((hole) => hole['score'] ?? 0)
//         .reduce((a, b) => a > b ? a : b);
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'jpegImage': jpegImage,
//       'metrics': json.encode(metrics),
//       'holes': json.encode(holes),
//     };
//   }

//   factory ProcessedData.fromMap(Map<String, dynamic> map) {
//     return ProcessedData(
//       id: map['id'],
//       jpegImage: map['jpegImage'],
//       metrics: json.decode(map['metrics']),
//       holes: List<Map<String, dynamic>>.from(json.decode(map['holes'])),
//     );
//   }
// }

// // Controller
// class CaptureController extends GetxController
//     with GetSingleTickerProviderStateMixin {
//   // Observables
//   final RxString captureMode = 'upload'.obs;
//   final RxBool isCameraInitialized = false.obs;
//   final RxBool isProcessing = false.obs;
//   final RxBool isBusy = false.obs;
//   final Rx<File?> selectedImage = Rx<File?>(null);

//   // Private variables
//   Uint8List? inputBytes;
//   CameraController? _cameraController;
//   List<CameraDescription>? cameras;
//   late AnimationController animationController;
//   late Animation<double> fadeAnimation;
//   late Animation<Offset> slideAnimation;
//   var targetController = Get.find<ConnectionController>();
//   // Parameters
//   // final String targetType;
//   // final String configPath;
//   // final double distance;
//   // final String caliber;
//   // final Function(FledResult, String)? onProcessed;

//   // CaptureController({
//   //   required this.targetType,
//   //   required this.configPath,
//   //   required this.distance,
//   //   required this.caliber,
//   //   this.onProcessed,
//   // });

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeAnimations();
//     _initializeCameras();
//   }

//   @override
//   void onClose() {
//     animationController.dispose();
//     _disposeCamera();
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

//   Future<void> _initializeCameras() async {
//     try {
//       cameras = await availableCameras();
//     } catch (e) {
//       debugPrint('Error initializing cameras: $e');
//     }
//   }

//   void switchCaptureMode(String mode) {
//     captureMode.value = mode;
//     if (mode == 'camera') {
//       startCamera();
//     } else {
//       _disposeCamera();
//     }
//   }

//   Future<void> startCamera() async {
//     try {
//       final status = await Permission.camera.request();
//       if (!status.isGranted) {
//         debugPrint('[FLED][UI][ERR] Camera permission denied');
//         return;
//       }

//       final cams = await availableCameras();
//       CameraDescription? back;
//       for (final c in cams) {
//         if (c.lensDirection == CameraLensDirection.back) {
//           back = c;
//           break;
//         }
//       }

//       back ??= cams.isNotEmpty ? cams.first : null;
//       if (back == null) {
//         debugPrint('[FLED][UI][ERR] No cameras available');
//         return;
//       }

//       final controller = CameraController(
//         back,
//         ResolutionPreset.high,
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.jpeg,
//       );

//       await controller.initialize();

//       _cameraController = controller;
//       isCameraInitialized.value = true;

//       debugPrint('[FLED][UI] Camera initialized: ${back.name}');
//     } catch (e, st) {
//       debugPrint('[FLED][UI][ERR] _startCamera failed: $e\n$st');
//     }
//   }

//   Future<void> _disposeCamera() async {
//     try {
//       await _cameraController?.dispose();
//     } catch (_) {}
//     _cameraController = null;
//     isCameraInitialized.value = false;
//   }

//   Future<void> capturePhoto() async {
//     if (isBusy.value || isProcessing.value) return;

//     final cc = _cameraController;
//     if (!isCameraInitialized.value || cc == null) {
//       debugPrint('[FLED][UI][ERR] Camera not initialized');
//       return;
//     }

//     isProcessing.value = true;
//     try {
//       final xfile = await cc.takePicture();
//       final bytes = await xfile.readAsBytes();

//       inputBytes = bytes;
//       isBusy.value = true;

//       await Future.delayed(const Duration(milliseconds: 200));
//       _processImage(imageFile: File(xfile.path));
//       await _processWith(bytes);

//       debugPrint('[FLED][UI] Captured ${bytes.length} bytes -> running FLED');
//     } catch (e, st) {
//       debugPrint('[FLED][UI][ERR] _capturePhoto failed: $e\n$st');
//     } finally {
//       isProcessing.value = false;
//     }
//   }

//   Future<void> pickFromSource(ImageSource source) async {
//     try {
//       final picker = ImagePicker();
//       final x = await picker.pickImage(
//         source: source,
//         imageQuality: 100,
//         maxWidth: 3000,
//         maxHeight: 3000,
//       );

//       if (x == null) return;

//       final rawBytes = await x.readAsBytes();
//       final bytes = await _normalizeIfHeic(rawBytes);

//       inputBytes = bytes;
//       selectedImage.value = File(x.path);
//       isBusy.value = true;
//       isProcessing.value = true;

//       await Future.delayed(const Duration(milliseconds: 200));
//       _processImage(imageFile: File(x.path));
//       await _processWith(bytes);

//       debugPrint('[FLED][UI] Picked image: ${bytes.length} bytes');
//     } catch (e, st) {
//       debugPrint('[FLED][UI][ERR] Image pick failed: $e\n$st');
//     }
//   }

//   Future<Uint8List> _normalizeIfHeic(Uint8List bytes) async {
//     if (!_looksLikeHeic(bytes)) return bytes;

//     final codec = await ui.instantiateImageCodec(bytes);
//     final frame = await codec.getNextFrame();
//     final bd = await frame.image.toByteData(format: ui.ImageByteFormat.png);

//     return Uint8List.view(bd!.buffer);
//   }

//   bool _looksLikeHeic(Uint8List b) {
//     if (b.length < 12) return false;
//     final tag = ascii.decode(b.sublist(4, 8), allowInvalid: true);
//     if (tag != 'ftyp') return false;
//     final brand = ascii.decode(b.sublist(8, 12), allowInvalid: true);
//     const brands = {'heic', 'heix', 'hevc', 'heis', 'mif1', 'msf1', 'heif'};
//     return brands.contains(brand);
//   }

//   Future<void> _processWith(Uint8List bytes) async {
//     // debugPrint(
//     //   '[FLED][UI] Processing... bytes=${bytes.length} target=$targetType cal=$caliber yd=$distance',
//     // );
//     debugPrint(
//       '[FLED][UI] Processing... bytes=${bytes.length} target=${targetController.selectedTarget.value?.value ?? ''} cal=${targetController.selectedCaliber.value} yd=${targetController.distance ?? 0.0}',
//     );
//     print(targetController.selectedTarget.value?.value ?? '');
//     print(targetController.selectedCaliber.value);
//     print(targetController.distance ?? 0.0);

//     try {
//       final result = await _fledWorker({
//         'bytes': bytes,
//         'configPath': targetController.configPath.value,
//         'targetName': targetController.selectedTarget.value?.value ?? '',
//         'bulletCaliber': targetController.selectedCaliber.value,
//         'distanceYards': targetController.distance ?? 0.0,
//       });

//       final metrics = result?.metrics;
//       if (metrics != null) {
//         final counts = metrics['counts'] as Map<String, dynamic>?;
//         int detectedEllipses = counts?['detected_ellipses'] as int? ?? 0;

//         debugPrint("Detected Ellipses: $detectedEllipses");

//         if (detectedEllipses > 0) {
//           _handleProcessingSuccess(result!);
//         } else {
//           _handleProcessingError();
//         }
//       } else {
//         _handleProcessingError();
//       }
//     } catch (e, st) {
//       debugPrint('[FLED][UI][ERR] Processing error: $e\n$st');
//       _handleProcessingError();
//     }
//   }

//   void _handleProcessingSuccess(FledResult result) {
//     isBusy.value = false;
//     Get.back();
//     targetController.onCaptureProcessed(
//       result,
//       targetController.selectedTarget.value?.value ?? '',
//     );
//   }

//   void _handleProcessingError() {
//     isBusy.value = false;
//     Get.back();
//     _processImage(isError: true);
//   }

//   Future<FledResult?> _fledWorker(Map<String, Object?> args) async {
//     final bytes = args['bytes'] as Uint8List;
//     final configPath = args['configPath'] as String;
//     final targetName = args['targetName'] as String;
//     final bulletCal = args['bulletCaliber'] as String;
//     final distanceYds = (args['distanceYards'] as num).toDouble();

//     return NativeFled.process(
//       encodedInput: bytes,
//       configPath: configPath,
//       targetName: targetName,
//       bulletCaliber: bulletCal,
//       distanceYards: distanceYds,
//     );
//   }

//   void _processImage({File? imageFile, bool isError = false}) {
//     final screenWidth = Get.width;

//     Get.dialog(
//       Dialog(
//         backgroundColor: const Color(0xFF2d2d2d),
//         child:
//             isError
//                 ? _buildErrorDialog(screenWidth)
//                 : _buildProcessingDialog(screenWidth),
//       ),
//       barrierDismissible: false,
//     );
//   }

//   Widget _buildErrorDialog(double screenWidth) {
//     return Stack(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Error',
//                 style: TextStyle(
//                   color: const Color(0xFFff6b35),
//                   fontSize: min(screenWidth * 0.053, 22),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'We could not properly detect the rings or shot marks in your target image. Please upload a sharper photo, making sure the target is well-lit and fully visible.',
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.9),
//                   fontSize: min(screenWidth * 0.042, 16),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFff6b35),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                 ),
//                 onPressed: () => Get.back(),
//                 child: Text(
//                   'OK',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.9),
//                     fontSize: min(screenWidth * 0.042, 16),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Positioned(
//           top: 8,
//           right: 8,
//           child: IconButton(
//             icon: const Icon(Icons.close, color: Colors.white),
//             onPressed: () => Get.back(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildProcessingDialog(double screenWidth) {
//     return Container(
//       padding: const EdgeInsets.all(48),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           SizedBox(
//             width: 60,
//             height: 60,
//             child: CircularProgressIndicator(
//               strokeWidth: 4,
//               valueColor: const AlwaysStoppedAnimation<Color>(
//                 Color(0xFFff6b35),
//               ),
//               backgroundColor: const Color(0xFFff6b35).withOpacity(0.3),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Calculating Score...',
//             style: TextStyle(
//               color: const Color(0xFFff6b35),
//               fontSize: min(screenWidth * 0.053, 22),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Analyzing target and detecting shot holes',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.8),
//               fontSize: min(screenWidth * 0.042, 18),
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }
