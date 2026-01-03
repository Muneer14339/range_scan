import 'dart:convert';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '/Screens/capture_screen.dart';
import '/Screens/components/loading_dialog.dart';
import '/Screens/models/main_session_record_model.dart';
import '/Screens/on_tap_cordinates.dart';
import '/Screens/services/firearm_services.dart'
    show FirearmServices;
import '/Screens/view_shoq_journal.dart';
import '/core/utils/app_spaces.dart';
import '/core/utils/toast_utils.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'controller/connection_controller.dart';

class ResultScreen extends StatefulWidget {
  final String targetType;
  final VoidCallback? onNewSession;


  const ResultScreen({
    super.key,
    this.targetType = 'Unknown',
    this.onNewSession,

  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int? highlightedShotId;
  final GlobalKey _resultKey = GlobalKey(); // 👈 added for screenshot
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // Get values from the model
  int get totalScore => res?.totalScore ?? 0;
  double get averageScore => res?.averageScore ?? 0.0;
  int get bestShot => res?.bestShot ?? 0;


  //   bool isShowTitleBullets = false;
  // void toggleShowTitleBullets() {
  //   setState(() {
  //     isShowTitleBullets = !isShowTitleBullets;
  //   });
  // }
Future<void> _shareResults({int targetPxWidth = 3840}) async {
  final shareText = 'RangeScan Results';
  // Use a global key or context accessible from your widget for the dialog.
  // Assuming 'context' is available here (e.g., from a State object).
  final BuildContext? dialogContext = mounted ? context : null; 

  // 1. SHOW LOADING DIALOG (Begin)
  if (dialogContext != null) {
    // You'll need to implement this function (e.g., a simple AlertDialog 
    // with a CircularProgressIndicator).
    showLoadingDialog(dialogContext, 'Please waiting ... generating your share result.');
  }
  
  try {
    // ... all existing logic for grabbing boundary, calculating scale,
    // and rendering the image remains here ...

    // 1) grab the boundary
    final boundary = _resultKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;

    // 2) compute scale to reach target pixel width
    final logicalWidth = boundary.size.width;
    if (logicalWidth <= 0) throw Exception("Invalid boundary size");

    double pixelRatio = targetPxWidth / logicalWidth;

    // 3) Safety: clamp pixelRatio
    const double maxScale = 8.0; // conservative upper bound
    final double safePixelRatio = pixelRatio.clamp(1.0, maxScale);

    // 4) try to render at the safe pixel ratio
    ui.Image image;
    try {
      image = await boundary.toImage(pixelRatio: safePixelRatio);
    } catch (e) {
      // If rendering at high scale fails, try a smaller scale
      final fallbackRatio = (safePixelRatio / 2).clamp(1.0, maxScale);
      image = await boundary.toImage(pixelRatio: fallbackRatio);
    }

    // 5) convert to PNG bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final fileBytes = pngBytes;

    // 6) save to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/results_ultrahd.png');
    await file.writeAsBytes(fileBytes);

    // 2. DISMISS DIALOG (Before Sharing)
    if (dialogContext != null) {
      // Ensure the dialog is dismissed before the share sheet opens
      Navigator.pop(dialogContext); 
    }

    // 7. SHARE (This is usually quick once the file exists)
    await Share.shareXFiles(
      [XFile(file.path)],
      text: shareText,
      subject: 'Target Scoring Results (Ultra HD)',
    );

  } catch (e, st) {
    // 3. DISMISS DIALOG (On Error)
    if (dialogContext != null) {
      // Ensure the dialog is dismissed if an error occurs
      Navigator.pop(dialogContext);
    }

    // fallback: copy text and show toast
    await Clipboard.setData(ClipboardData(text: shareText));
    if (mounted) {
      ToastUtils.showSimpleToast('Failed to create ultra HD image — results copied to clipboard.');
    }
    // Optional: log error for debugging
    log("Share ultraHD failed: $e\n$st");
  }
}
  var controller = Get.find<ConnectionController>();
  void _startNewSession() {
    widget.onNewSession?.call();
    // ToastUtils.showSimpleToast('Starting new session...');
  }
Uint8List? _originalFromJson(Map<String, dynamic>? metrics) {
 
  if (metrics==null) return null;
  final images = metrics['images'];
  if (images is Map<String, dynamic>) {
    final b64 = images['original_jpeg_b64'];
    if (b64 is String && b64.isNotEmpty) {
      try {
        return base64Decode(b64);
      } catch (_) { /* ignore */ }
    }
  }
  return null;
}
  Widget _buildTargetPreview() {
     Uint8List? originalJpeg =  _originalFromJson(res?.metrics);
    return originalJpeg == null
        ? const Center(child: Text("No Image Available"))
        :   pane(
      originalJpeg,
      // res!.processedJpeg,
      onTapPixel: null,
      bulletHoles: res!.remappedBulletCenters,
      ringDiameterPixels: res?.metrics['bullet_diameter_pixels'] * 0.4,
      groupCenter: Offset(
        res?.metrics['group']['remapped_min_enclosing_center_x'],
        res?.metrics['group']['remapped_min_enclosing_center_y'],
      ),
      groupRadius: res?.metrics['group']['min_enclosing_radius_pixels'],
      repaintBoundaryKey: _repaintBoundaryKey, 
      isTitleBulletHole: controller.isShowTitleBullets.value, // Add this line
    );
  }

  Widget _pane(Uint8List? bytes) => Card(
    margin: const EdgeInsets.all(2),
    clipBehavior: Clip.antiAlias,
    child:
        bytes == null
            ? const Center(child: Text('—'))
            : InteractiveViewer(
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
  );
Future<void> _downloadImage() async {
  // Use a context accessible from your widget (assuming 'context' is from a State object).
  final BuildContext? dialogContext = mounted ? context : null;

  // 1. SHOW LOADING DIALOG (Begin)
  if (dialogContext != null) {
    // Show a dialog to let the user know the process has started
    showLoadingDialog(dialogContext, 'Generating and saving image...');
  }

  try {
    if (_repaintBoundaryKey.currentContext == null) {
      if (dialogContext != null) Navigator.pop(dialogContext); // Dismiss on early exit
     
      return;
    }

    RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    
    // **CAUTION**: pixelRatio 10.0 is very high and can cause OutOfMemory errors.
    // Consider adding a safety clamp similar to the previous example.
    const pixelRatio = 10.0; // Ultra HD quality 

    // 1) Render the widget to an image
    ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    
    // 2) Convert the image to PNG bytes
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // 3) Save the image bytes to the user's gallery
    await _saveImageToGallery(pngBytes); 

    // 2. DISMISS DIALOG (Success)
    if (dialogContext != null) {
      Navigator.pop(dialogContext); 
    }
    ToastUtils.showSuccess(message: 'Image saved to gallery successfully!');
    // Show final success message
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('HD Image saved! ${image.width}x${image.height}px')),
    // );

  } catch (e) {
    // 3. DISMISS DIALOG (Error)
    if (dialogContext != null) {
      Navigator.pop(dialogContext); 
    }
    
    print('Error: $e');
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Error saving image: ${e.toString()}')),
    // );
  }
}

// NOTE: You must have the _saveImageToGallery function defined elsewhere, 
// usually involving the 'image_gallery_saver' or 'path_provider' and 'permission_handler' packages.
  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else if (sdkInt >= 30) {
        var status = await Permission.storage.request();
        if (status.isDenied) {
          status = await Permission.manageExternalStorage.request();
        }
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      return status.isGranted;
    }
    return false;
  }

  Future<void> _saveImageToGallery(Uint8List? bytes) async {
    if (bytes == null) {
      ToastUtils.showError(message: 'No image data to save');
      return;
    }

    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        ToastUtils.showError(message: 'Permission denied');
        return;
      }
      await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'RangeScan ${DateTime.now().millisecondsSinceEpoch}',
      );
      ToastUtils.showSuccess(message: 'Image saved to gallery successfully!');
    } catch (e) {
      ToastUtils.showError(
        message:
            'Error saving image to gallery or please check your permissions',
      );
    }
  }

  Widget _buildScoreBreakdown() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      padding: EdgeInsets.zero,
      children: [
        _buildScoreItem('Shots Fired', '${res?.holes.length}'),
        _buildScoreItem('Average Score', averageScore.toStringAsFixed(1)),
        _buildScoreItem('Best Shot', '$bestShot'),
        _buildScoreItem(
          'Group Size (inches)',
          (res?.metrics['group']['group_size'] ?? 0.0).toStringAsFixed(2),
        ),
        _buildScoreItem(
          'MOA',
          (res?.metrics['group']['moa'] ?? 0.0).toStringAsFixed(2),
        ),
        _buildScoreItem(
          'Extreme Spread',
          (res?.metrics['group']['extreme_spread'] ?? 0.0).toStringAsFixed(2),
        ),
      ],
    );
  }

  Widget _buildScoreItem(String title, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: min(screenWidth * 0.037, 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: min(screenWidth * 0.053, 16),
              fontWeight: FontWeight.bold,
              color: const Color(0xFFff6b35),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _shareResults,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.707, -0.707),
                  end: Alignment(0.707, 0.707),
                  colors: [Color(0xFFff6b35), Color(0xFFf7931e)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x4Dff6b35),
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Share Results',
                  style: TextStyle(
                    fontSize: min(screenWidth * 0.042, 18),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: min(screenWidth * 0.042, 18)),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              var controller = Get.find<ConnectionController>();
              var services = FirearmServices();
              controller.insertUserWeaponData().then((value) {
                final session = MainSessionRecordModel(
                  recordId: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: controller.userId.value ?? '',
                  weaponId: controller.weaponId,
                  targetPaper: controller.selectedTarget.value?.value ?? '',
                  distance: controller.distance.toString(),
                  caliber: controller.selectedCaliber.value,
                  imagePath: "/images/session1.png",
                  finalShotResult: jsonEncode(res?.toJson()),
                );
                log(session.toJson().toString());
                services.insertSession(session);
                _startNewSession();
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
              backgroundColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'New Session',
              style: TextStyle(
                fontSize: min(screenWidth * 0.042, 18),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Final Results',
                    style: TextStyle(
                      fontSize: min(screenWidth * 0.064, 18),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFff6b35),
                      shadows: const [
                        Shadow(color: Color(0x4Dff6b35), blurRadius: 10),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await _downloadImage();
                    },
                    icon: const Icon(
                      Icons.save_alt_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 👇 Wrap results in RepaintBoundary
              RepaintBoundary(
                key: _resultKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      _buildTargetPreview(),
                      Text(
                        'Total Score: $totalScore',
                        style: const TextStyle(
                          color: Color(0xFFff6b35),
                          fontSize: 30,
                        ),
                      ),
                      _buildScoreBreakdown(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              24.heightBox,
              ViewShoqJournal(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
