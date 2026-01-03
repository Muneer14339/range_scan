import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class TargetCaptureScreen extends StatefulWidget {
  const TargetCaptureScreen({super.key});

  @override
  State<TargetCaptureScreen> createState() => _TargetCaptureScreenState();
}

class _TargetCaptureScreenState extends State<TargetCaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController =
          CameraController(_cameras![0], ResolutionPreset.high, enableAudio: false);

      await _cameraController!.initialize();
      setState(() {});
    }
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;
    _isFlashOn = !_isFlashOn;
    await _cameraController!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final XFile file = await _cameraController!.takePicture();
    debugPrint("Captured: ${file.path}");
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      debugPrint("Picked from gallery: ${image.path}");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double rectWidth = MediaQuery.of(context).size.width * 0.8;
    final double rectHeight = MediaQuery.of(context).size.height * 0.6;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_cameraController!),

                /// Dark overlay with transparent rectangle cut-out
                CustomPaint(
                  size: Size.infinite,
                  painter: OverlayPainter(
                    rectWidth: rectWidth,
                    rectHeight: rectHeight,
                  ),
                ),

                /// Top text
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: const [
                      Text(
                        ".45 ACP • undefined • 25 feet",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Align target within frame",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                /// Middle instruction
               
                /// Bottom controls
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Flash button
                      IconButton(
                        icon: Icon(
                          Icons.flash_on,
                          color: _isFlashOn ? Colors.yellow : Colors.white,
                          size: 32,
                        ),
                        onPressed: _toggleFlash,
                      ),

                      // Capture button
                      GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Gallery button
                      IconButton(
                        icon: const Icon(
                          Icons.photo,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _pickFromGallery,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// CustomPainter for dark overlay + green rectangle cutout
class OverlayPainter extends CustomPainter {
  final double rectWidth;
  final double rectHeight;

  OverlayPainter({required this.rectWidth, required this.rectHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: rectWidth,
      height: rectHeight,
    );

    // Dark full screen
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Clear rectangle area
    canvas.saveLayer(Rect.largest, Paint());
    paint.blendMode = BlendMode.clear;
    canvas.drawRect(rect, paint);
    canvas.restore();

    // Draw green border
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
