import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import '/core/constant/app_colors.dart';
import '/core/utils/app_spaces.dart';
import '/custom_widgets/app_buttons.dart' show AppCommonButton;
import 'dart:io';
import 'dart:math' as math;
import '../ffi_bridge/ffi_binding.dart';
import '../models/shots_model.dart';
import 'capture_screen.dart';
import 'controller/connection_controller.dart';
import 'on_tap_cordinates.dart';

// The Shot class seems to be replaced by BulletHole from ffi_binding.dart,
// but keeping the TargetScoringState for context.
// class Shot {
//   final int id;
//   final double x;
//   final double y;
//   final int score;
//   bool highlighted;
//
//   Shot({
//     required this.id,
//     required this.x,
//     required this.y,
//     required this.score,
//     this.highlighted = false,
//   });
// }

class TargetScoringState extends ChangeNotifier {
  static final TargetScoringState _instance = TargetScoringState._internal();

  factory TargetScoringState() => _instance;

  TargetScoringState._internal();

  File? capturedImage;
  List<Shot> shots = [];
  int expectedShotCount = 10;
  String editMode = 'remove';
  int? highlightedShotId;
  String? selectedTarget;

  void setCapturedImage(File image) {
    capturedImage = image;
    notifyListeners();
  }

  void setExpectedShotCount(int count) {
    expectedShotCount = count;
    notifyListeners();
  }

  void setSelectedTarget(String target) {
    selectedTarget = target;
    notifyListeners();
  }

  void generateMockResults() {
    final variance = math.Random().nextInt(3) - 1;
    final actualShots = math.max(1, expectedShotCount + variance);

    shots.clear();

    for (int i = 0; i < actualShots; i++) {
      final angle = math.Random().nextDouble() * 2 * math.pi;
      const maxRadius = 45.0;
      final radius = math.Random().nextDouble() * maxRadius;

      final x = 50 + (radius * math.cos(angle) / maxRadius) * 40;
      final y = 50 + (radius * math.sin(angle) / maxRadius) * 40;

      int score = 0;
      if (radius < 8)
        score = 10;
      else if (radius < 12)
        score = 9;
      else if (radius < 18)
        score = 8;
      else if (radius < 25)
        score = 7;
      else if (radius < 32)
        score = 6;
      else if (radius < 38)
        score = 5;
      else if (radius < 42)
        score = 4;
      else
        score = math.max(1, math.Random().nextInt(3) + 1);

      shots.add(Shot(id: i + 1, x: x, y: y, score: score));
    }

    notifyListeners();
  }

  void setEditMode(String mode) {
    editMode = mode;
    notifyListeners();
  }

  void highlightShot(int? shotId) {
    highlightedShotId = shotId;
    notifyListeners();
  }

  void removeShot(int shotId) {
    shots.removeWhere((shot) => shot.id == shotId);

    for (int i = 0; i < shots.length; i++) {
      shots[i] = Shot(
        id: i + 1,
        x: shots[i].x,
        y: shots[i].y,
        score: shots[i].score,
        highlighted: shots[i].highlighted,
      );
    }

    notifyListeners();
  }

  void addShot(double x, double y) {
    final dx = x - 50;
    final dy = y - 50;
    final distance = math.sqrt(dx * dx + dy * dy);

    int score = 0;
    if (distance < 8)
      score = 10;
    else if (distance < 12)
      score = 9;
    else if (distance < 18)
      score = 8;
    else if (distance < 25)
      score = 7;
    else if (distance < 32)
      score = 6;
    else if (distance < 38)
      score = 5;
    else if (distance < 42)
      score = 4;
    else if (distance < 47)
      score = 3;
    else if (distance < 52)
      score = 2;
    else
      score = 1;

    shots.add(Shot(id: shots.length + 1, x: x, y: y, score: score));

    notifyListeners();
  }

  int get totalScore => shots.fold(0, (sum, shot) => sum + shot.score);

  double get averageScore => shots.isEmpty ? 0 : totalScore / shots.length;

  int get bestShot =>
      shots.isEmpty ? 0 : shots.map((s) => s.score).reduce(math.max);
}

class ReviewScreen extends StatefulWidget {
  final VoidCallback? onFinalize;

  const ReviewScreen({super.key, this.onFinalize});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  final TargetScoringState _state = TargetScoringState();

  @override
  void initState() {
    super.initState();
    // 💡 ADDED: Start listening to the TargetScoringState
    _state.addListener(_onStateChange);
  }

  // 💡 ADDED: Listener callback to trigger a rebuild
  void _onStateChange() {
    // Calling setState here ensures the UI rebuilds when _state.editMode changes
    setState(() {});
  }

  @override
  void dispose() {
    // 💡 ADDED: Stop listening to prevent memory leaks
    _state.removeListener(_onStateChange);
    super.dispose();
  }

  var controller = Get.find<ConnectionController>();
  void toggleShowTitleBullets() {
    setState(() {
      controller.isShowTitleBullets.value = !controller.isShowTitleBullets.value;
     
    });
     print(controller.isShowTitleBullets.value);
  }

  void _finalizeShooting() {
  
    widget.onFinalize?.call();
    // ToastUtils.showInfo(message: 'Finalizing results...');
  }

  Widget _buildModeButton(String mode, String label, bool isActive) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 💡 The state change happens here:
            _state.setEditMode(mode);
            // Since _onStateChange is registered as a listener, it will call setState
            // and rebuild this widget, updating the button's color.
          },
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 9.6),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    isActive
                        ? const Color(0xFFff6b35)
                        : Colors.white.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
              color:
                  isActive
                      ? const Color(0xFFff6b35).withOpacity(0.2)
                      : Colors.transparent,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: min(screenWidth * 0.034, 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Replace with jpegImage from the model
  Widget _buildTargetPreview() {
    print("bullet_diameter_pixels=${res?.metrics['bullet_diameter_pixels']}");
    FledResult? forRemove;

    return res?.processedJpeg == null
        ? Center(child: Text("No Image Available"))
        : ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: double.infinity,
            child: pane(
              res?.processedJpeg,
              isTitleBulletHole: controller.isShowTitleBullets.value,

              onTapPixel: (pt) async {
                final tapX = pt.dx;
                final tapY = pt.dy;

                // 1) Optimistic local add (so UI updates immediately)
                // if (res != null) {
                //   final nextIdx = res!.holes.isNotEmpty ? (res!.holes.last.index + 1) : 1;
                //   // cxIn/cyIn unknown here; keep 0.0 or compute if you have px→in conversion
                //   res!.holes.add(
                //     BulletHole(
                //       index: nextIdx,
                //       cxPx: tapX,
                //       cyPx: tapY,
                //       cxIn: 0.0,
                //       cyIn: 0.0,
                //       score: 10, // or any default you prefer
                //     ),
                //   );
                // }

                // 2) Backend add (don’t clobber local holes)
                try {
                  final backend = await fledAddBulletWorker(tapX, tapY);
                  debugPrint('Tap @ image px: ($tapX, $tapY)');

                  if (backend != null && res != null) {

                    // Optionally refresh non-hole fields from backend:
                    res = res!.copyWith(
                      processedJpeg: backend.processedJpeg,
                      metrics: backend.metrics,
                      holes: backend.holes,
                      remappedBulletCenters: backend.remappedBulletCenters
                      // keep local holes to preserve indices/order you control
                    );
                    debugPrint('Tap_holes_length (server) = ${res?.holes.length}');

                    setState(() {});

                  }
                } catch (e) {
                  debugPrint('fledAddBulletWorker error: $e');
                  // Optional: rollback optimistic add on error
                  // res!.holes.removeLast(); setState(() {});
                }
              },

              bulletHoles: res?.holes,
              ringDiameterPixels: ((res?.metrics['bullet_diameter_pixels'] ?? 9.08) as num).toDouble() * 0.4,
              groupCenter: Offset(
                ((res?.metrics['group']['min_enclosing_center_x'] ?? 0) as num).toDouble(),
                ((res?.metrics['group']['min_enclosing_center_y'] ?? 0) as num).toDouble(),
              ),
              groupRadius: ((res?.metrics['group']['min_enclosing_radius_pixels'] ?? 0) as num).toDouble(),

              onRingDragStart: (index, pt) async {
                debugPrint('Started dragging ring $index at: $pt');
                forRemove = null;
                // Tell backend we’re moving this hole away from its old spot, but DO NOT overwrite `res`.
                try {
                  forRemove = await removeBulletHoleWorker(pt.dx, pt.dy);
                  debugPrint('removeBulletHoleWorker OK @ (${pt.dx}, ${pt.dy})');
                } catch (e) {
                  debugPrint('removeBulletHoleWorker error: $e');
                }

                // Keep local list intact during drag; painter shows blue ring overlay.
                setState(() {});
              },

              onRingDragEnd: (index, endCoord, isDeleted) async {
                final tapX = endCoord.dx;
                final tapY = endCoord.dy;

                if (res == null || res!.holes.isEmpty || index < 0 || index >= res!.holes.length) {
                  debugPrint('onRingDragEnd: invalid index or res null');
                  return;
                }

                if (isDeleted) {
                  debugPrint(
                      'Ring $index deleted. Original position: $endCoord');

                  // 1) Remove locally so UI/hit-tests update immediately
                  res!.holes.removeAt(index);
                  if (forRemove != null && res != null) {
                    res = res!.copyWith(
                        processedJpeg: forRemove?.processedJpeg,
                        metrics: forRemove?.metrics,
                        holes: forRemove?.holes,
                        remappedBulletCenters: forRemove?.remappedBulletCenters
                      // keep local holes to preserve indices/order you control
                    );
                    setState(() {});

                    // 2) If backend needs an explicit delete here, call it (you already removed on start).
                    // await removeBulletHoleWorker(...); // if required again

                  }
                }
                  else {
                  debugPrint('Ring $index moved to: $endCoord');

                  // 1) Update locally so the next long-press hits the new spot
                  final prev = res!.holes[index];
                  res!.holes[index] = prev.copyWith(cxPx: tapX, cyPx: tapY);

                  // 2) Sync with backend (re-add at new position); do not overwrite local holes
                  try {
                    final backend = await fledAddBulletWorker(tapX, tapY);
                    debugPrint('fledAddBulletWorker OK. server holes=${backend?.holes.length}');
                    if (backend != null && res != null) {
                      res = res!.copyWith(
                          processedJpeg: backend.processedJpeg,
                          metrics: backend.metrics,
                          holes: backend.holes,
                          remappedBulletCenters: backend.remappedBulletCenters
                        // keep local holes to preserve indices/order you control
                      );
                      setState(() {});

                      // Keep local holes as we’ve already updated the moved one.
                    }
                  } catch (e) {
                    debugPrint('fledAddBulletWorker error: $e');
                    // Optional rollback on failure:
                    // res!.holes[index] = prev; setState(() {});
                  }
                }
              },
            )
          ),
        );
  }

  Widget _buildShotScoreItem(BulletHole hole) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        // Optional logic for selecting a shot
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),

        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.7),
          // border: Border.all(color: AppColors.primary, width: 1),
          // borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Text(
                'S${hole.index}',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: min(screenWidth * 0.042, 16),
                ),
              ),
            ),
            Text(
              ' - ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: min(screenWidth * 0.042, 16),
              ),
            ),
            Expanded(
              child: Text(
                ' ${hole.score}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: min(screenWidth * 0.042, 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: AppCommonButton(
          text: 'Finalize Shooting',
          onPressed: _finalizeShooting,
          height: 56,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildTargetPreview(),

                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          res?.holes.length == 0
                              ? SizedBox()
                              : Container(
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.primary,
                                ),
                                child: Text(
                                  // 'Shot Scores',
                                  'Total shots: ${res == null ? '' : res?.holes.length}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: min(screenWidth * 0.042, 18),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          5.heightBox,
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadiusGeometry.circular(8),
                              child: SizedBox(
                                width: 79,
                                child: Builder(
                                  builder: (context) {
                                    final holes = List<BulletHole>.from(
                                      res?.holes ?? [],
                                    )..sort(
                                      (a, b) => b.score.compareTo(a.score),
                                    );
                                    return ListView.builder(
                                      shrinkWrap: true,

                                      padding: EdgeInsets.all(0),
                                      itemCount: holes.length,
                                      itemBuilder: (context, index) {
                                        final hole = holes[index];
                                        return _buildShotScoreItem(hole);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          5.heightBox,
                          SizedBox(
                            width: 80,
                            child: Transform.scale(
                              scale: 1.1, // Increase size (1.0 = default)
                              child: CupertinoSwitch(
                                inactiveTrackColor: AppColors.background,
                                value: controller.isShowTitleBullets.value,
                                onChanged: (v) {
                                  setState(() {
                                 controller.   isShowTitleBullets.value = v;
                                  });
                                },
                              ),
                            ),
                          ),
                          // GridView.builder(
                          //   shrinkWrap: true,

                          //   padding: EdgeInsets.symmetric(
                          //     vertical: 8,
                          //   ), // 👈 removes extra top spac

                          //   itemCount: res?.holes.length,
                          //   gridDelegate:
                          //       const SliverGridDelegateWithFixedCrossAxisCount(
                          //         crossAxisCount:
                          //             1, // show 2 per row (change to 3 if needed)
                          //         crossAxisSpacing: 6,
                          //         mainAxisSpacing: 6,
                          //         mainAxisExtent: 50,
                          //       ),
                          //   itemBuilder: (context, index) {
                          //     final hole = res?.holes[index];
                          //     return _buildShotScoreItem(
                          //       hole ??
                          //           BulletHole(
                          //             index: 0,
                          //             cxPx: 0.0,
                          //             cyPx: 0.0,
                          //             cxIn: 0.0,
                          //             cyIn: 0.0,
                          //             score: 0,
                          //           ),
                          //     );
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              res?.holes.length == 0
                  ? Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primary,
                    ),
                    child: const Text(
                      'No shots detected',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  )
                  : SizedBox(),
              SizedBox(height: res?.holes.length == 0 ? 0 : 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Row(
                    //   children: [
                    //     _buildModeButton(
                    //       'remove',
                    //       'Remove Holes',
                    //       // This comparison triggers the color change
                    //       _state.editMode == 'remove',
                    //     ),
                    //     const SizedBox(width: 8),
                    //     _buildModeButton(
                    //       'add',
                    //       'Add Holes',
                    //       // This comparison triggers the color change
                    //       _state.editMode == 'add',
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 16),
                    Text(
                      _state.editMode == 'remove'
                          ? 'Long press on holes to remove or move'
                          : 'Long press on target to add holes',
                      style: TextStyle(
                        fontSize: min(screenWidth * 0.038, 16.4),
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
