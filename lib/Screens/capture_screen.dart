import 'dart:math';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/route_manager.dart';

import 'package:image_picker/image_picker.dart';
import '/Screens/components/nra_instruction_dialog.dart';
import '/Screens/components/pa_instructions_dialog.dart';
import '/Screens/review_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../ffi_bridge/ffi_binding.dart';
import 'dart:convert' show ascii;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

FledResult? res; // keep global

Future<FledResult?> fledAddBulletWorker(double tapX, double tapY) async {
  return NativeFled.addBulletHole(tapX: tapX, tapY: tapY);
}

Future<FledResult?> removeBulletHoleWorker(double tapX, double tapY) async {
  return NativeFled.removeBulletHole(tapX: tapX, tapY: tapY);
}

// 👇 Worker function for compute (must be top-level / static)
Future<FledResult?> _fledWorker(Map<String, Object?> args) async {
  final bytes = args['bytes'] as Uint8List;
  final configPath = args['configPath'] as String;
  final targetName = args['targetName'] as String;
  final bulletCal = args['bulletCaliber'] as String;
  final distanceYds = (args['distanceYards'] as num).toDouble();
  final detectionMode = args['detectionMode'] as String;

  return NativeFled.process(
    encodedInput: bytes,
    configPath: configPath,
    targetName: targetName,
    bulletCaliber: bulletCal,
    distanceYards: distanceYds,
    detectionMode: detectionMode,
  );
}

class CaptureScreen extends StatefulWidget {
  final void Function(FledResult processedData, String targetType)? onProcessed;
  final String targetType;
  final String configPath;
  final double dis;
  final String caliber;
  final String detectionMode;
  String? categoryName;
  String? targetName;

  CaptureScreen({
    super.key,
    this.onProcessed,
    required this.targetType,
    required this.dis,
    required this.caliber,
    required this.configPath,
    required this.detectionMode,
    this.categoryName,
    this.targetName,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _inputBytes;
  Uint8List? _processedJpeg;
  Map<String, dynamic>? _metrics;
  List<BulletHole>? _holes;
  bool _busy = false;
  bool _isProcessing = false;

  String _captureMode = 'upload';
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  final TargetScoringState _state = TargetScoringState();

  late AnimationController _animationController;
  late String _detectionMode;
  @override
  void initState() {
    super.initState();
    _detectionMode = widget.detectionMode;
    print(_detectionMode);
    print(widget.categoryName);
    print(widget.targetName);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _initializeCameras();
  }

  @override
  void didUpdateWidget(covariant CaptureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detectionMode != widget.detectionMode) {
      setState(() {
        _detectionMode = widget.detectionMode; // 🔄 sync with parent
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCameras() async {
    try {
      await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
    }
  }

  Future<void> _startCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;

      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse:
            () => cams.isNotEmpty ? cams.first : throw Exception("No camera"),
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
      });
    } catch (e, st) {
      debugPrint('[FLED][UI][ERR] _startCamera failed: $e\n$st');
    }
  }

  Future<void> _disposeCamera() async {
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;
    _isCameraInitialized = false;
  }

  Future<void> _capturePhoto() async {
    if (_busy || _isProcessing) return;
    final cc = _cameraController;
    if (!_isCameraInitialized || cc == null) return;

    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final xfile = await cc.takePicture();
      final bytes = await xfile.readAsBytes();

      if (!mounted) return;
      setState(() {
        _inputBytes = bytes;
        _processedJpeg = null;
        _metrics = null;
        _holes = null;
        _busy = true;
      });

      await _processWith(bytes);
    } catch (e, st) {
      debugPrint('[FLED][UI][ERR] _capturePhoto failed: $e\n$st');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pick(ImageSource src) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: src,
      imageQuality: 100,
      maxWidth: 3000,
      maxHeight: 3000,
    );
    if (x == null) return;

    final rawBytes = await x.readAsBytes();
    final bytes = await _normalizeIfHeic(rawBytes);
    if (!mounted) return;

    setState(() {
      _inputBytes = bytes;
      _processedJpeg = null;
      _metrics = null;
      _holes = null;
      _busy = true;
    });

    await _processWith(bytes);
  }

  bool _looksLikeHeic(Uint8List b) {
    if (b.length < 12) return false;
    final tag = ascii.decode(b.sublist(4, 8), allowInvalid: true);
    if (tag != 'ftyp') return false;
    final brand = ascii.decode(b.sublist(8, 12), allowInvalid: true);
    const brands = {'heic', 'heix', 'hevc', 'heis', 'mif1', 'msf1', 'heif'};
    return brands.contains(brand);
  }

  Future<Uint8List> _normalizeIfHeic(Uint8List bytes) async {
    if (!_looksLikeHeic(bytes)) return bytes;
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final bd = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return Uint8List.view(bd!.buffer);
  }

  Future<void> _processWith(Uint8List bytes) async {
    _showLoadingDialog();

    try {
      // 🔑 Let dialog render
      await Future.delayed(const Duration(milliseconds: 100));

      // 👇 Run heavy work in isolate
      res = await compute(_fledWorker, {
        'bytes': bytes,
        'configPath': widget.configPath,
        'targetName': widget.targetType,
        'bulletCaliber': widget.caliber,
        'distanceYards': widget.dis,
        'detectionMode': _detectionMode,
      });

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      if (res != null) {
        final detectedEllipses =
            res!.metrics['counts']?['detected_ellipses'] ?? 0;
        final detectedHoles =
            res!.metrics['counts']?['detected_bullet_holes'] ?? 0;

        if (detectedHoles > 0) {
          // ✅ Valid detection
          if (!mounted) return;
          setState(() {
            _processedJpeg = res!.processedJpeg;
            _metrics = res!.metrics;
            _holes = res!.holes;
            _busy = false;
          });
          widget.onProcessed?.call(res!, _state.selectedTarget ?? 'Unknown');
        } else {
          if (widget.categoryName == "NRA Target Papers") {
            showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => NoHolesDetectedDialog(
                    onRetake: () {
                      Get.back();
                      _capturePhoto();
                    },
                  ),
            );
          } else if (widget.categoryName == "PA Target Paper") {
            if (widget.targetName == "Black Ring") {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) => NoBulletsForBlackWhiteDialog(
                      onRetake: () {
                        Get.back();
                        _pick(ImageSource.gallery);
                      },
                    ),
              );
            } else {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) =>
                        NoBulletsForRedDialog(selectMode: _detectionMode),
              );
              if (result != null) {
                final mode = result['mode'] as String;
                print("New user-selected detection mode: $mode");
                if (mounted) {
                  setState(() => _detectionMode = mode); // update local mode
                }
                await _processWith(_inputBytes!);
              }
            }
          }

          if (mounted) setState(() => _busy = false);
        }
      } else {
        if (mounted) setState(() => _busy = false);
      }
    } catch (e, st) {
      debugPrint('[FLED][UI][ERR] Processing error: $e\n$st');
      if (mounted) {
        Navigator.of(context).pop();
        if (widget.categoryName == "NRA Target Papers") {
          showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => NoHolesDetectedDialog(
                  onRetake: () {
                    Get.back();
                    
                  
                    setState(() => _captureMode = 'camera');
                  },
                  onRetry: () {
                    Get.back();

                    _pick(ImageSource.gallery);
                  },
                ),
          );
        } else if (widget.categoryName == "PA Target Paper") {
          if (widget.targetName == "Black Ring") {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => NoBulletsForBlackWhiteDialog(
                    onRetake: () {
                      Get.back();
                     
                     
                      setState(() => _captureMode = 'camera');
                    },
                  ),
            );
          } else {
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) =>
                      NoBulletsForRedDialog(selectMode: _detectionMode),
            );
            if (result != null) {
              final mode = result['mode'] as String;
              print("New user-selected detection mode: $mode");
              if (mounted) {
                setState(() => _detectionMode = mode); // update local mode
              }
              await _processWith(_inputBytes!);
            }
          }
        }

        setState(() => _busy = false);
      }
    }
  }

  // --- UI dialogs unchanged ---
  void _showLoadingDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _loadingDialog(screenWidth),
    );
  }

  void _showErrorDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _errorDialog(screenWidth),
    );
  }

  Widget _errorDialog(double screenWidth) => Dialog(
    backgroundColor: const Color(0xFF2d2d2d),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Error',
            style: TextStyle(
              color: const Color(0xFFff6b35),
              fontSize: min(screenWidth * 0.053, 22),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Could not detect rings or shot marks. Please upload a sharper photo with good lighting.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: min(screenWidth * 0.042, 16),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFff6b35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );

  Widget _loadingDialog(double screenWidth) => Dialog(
    backgroundColor: const Color(0xFF2d2d2d),
    child: Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFff6b35)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Calculating Score...',
            style: TextStyle(
              color: const Color(0xFFff6b35),
              fontSize: min(screenWidth * 0.053, 22),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing target and detecting shot holes',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: min(screenWidth * 0.042, 18),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  // --- Capture mode UI unchanged ---
  Widget _buildCaptureModeTab(String mode, String icon, String label) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isActive = _captureMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchCaptureMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12.8),
          decoration: BoxDecoration(
            gradient:
                isActive
                    ? const LinearGradient(
                      colors: [Color(0xFFff6b35), Color(0xFFf7931e)],
                    )
                    : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$icon $label',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: min(screenWidth * 0.038, 16.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _switchCaptureMode(String mode) {
    setState(() => _captureMode = mode);
    if (mode == 'camera') {
      _startCamera();
    } else {
      _disposeCamera();
    }
  }

  Widget _buildCameraMode() {
    return Center(
      child:
          _isCameraInitialized && _cameraController != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: double.infinity,
                  child: CameraPreview(_cameraController!),
                ),
              )
              : const Text(
                'Camera not available',
                style: TextStyle(color: Colors.white),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(_detectionMode);
    print(widget.categoryName);
    print(widget.targetName);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildCaptureModeTab('camera', '📷', 'Camera'),
                _buildCaptureModeTab('upload', '🖼️', 'Upload'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _captureMode == 'camera'
                      ? _buildCameraMode()
                      : InkWell(
                        onTap: () => _pick(ImageSource.gallery),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.image, size: 80, color: Colors.white54),
                            SizedBox(height: 12),
                            Text(
                              'Upload an image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _captureMode == 'camera'
              ? FloatingActionButton(
                backgroundColor: const Color(0xFFff6b35),
                onPressed: _capturePhoto,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              )
              : null,
    );
  }
}
