
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

ffi.DynamicLibrary _openLib() {
  if (Platform.isAndroid) return ffi.DynamicLibrary.open('libnative_opencv.so');
  if (Platform.isIOS)     return ffi.DynamicLibrary.process();
  if (Platform.isMacOS)   return ffi.DynamicLibrary.open('libnative_opencv.dylib');
  if (Platform.isWindows) return ffi.DynamicLibrary.open('native_opencv_windows_plugin.dll');
  if (Platform.isLinux)   return ffi.DynamicLibrary.open('libnative_opencv.so'); // optional
  throw UnsupportedError('Unsupported platform');
}

final _lib = _openLib();

// Original process image function typedefs
typedef _CFledProcessImage = ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>, ffi.Int32,
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,ffi.Pointer<Utf8>, ffi.Double,
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Pointer<Utf8>>, ffi.Pointer<ffi.Pointer<Utf8>>
    );
typedef _FledProcessImage = int Function(
    ffi.Pointer<ffi.Uint8>, int,
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, double,
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Pointer<Utf8>>, ffi.Pointer<ffi.Pointer<Utf8>>
    );

// Add bullet hole function typedefs
typedef _CFledAddBulletHole = ffi.Int32 Function(
    ffi.Double, ffi.Double,
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Pointer<Utf8>>, ffi.Pointer<ffi.Pointer<Utf8>>
    );
typedef _FledAddBulletHole = int Function(
    double, double,
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Pointer<Utf8>>, ffi.Pointer<ffi.Pointer<Utf8>>
    );

// Remove bullet hole function typedefs
typedef _CFledRemoveBulletHole = ffi.Int32 Function(
    ffi.Double, ffi.Double,
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Pointer<Utf8>>, ffi.Pointer<ffi.Pointer<Utf8>>
    );
typedef _FledRemoveBulletHole = int Function(
    double, double,
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Pointer<Utf8>>, ffi.Pointer<ffi.Pointer<Utf8>>
    );

// Memory management typedefs
typedef _CFreeBuffer = ffi.Void Function(ffi.Pointer<ffi.Uint8>);
typedef _CFreeCStr   = ffi.Void Function(ffi.Pointer<Utf8>);
typedef _FreeBuffer  = void Function(ffi.Pointer<ffi.Uint8>);
typedef _FreeCStr    = void Function(ffi.Pointer<Utf8>);

// Function lookups
final _FledProcessImage _fledProcessImage =
_lib.lookupFunction<_CFledProcessImage, _FledProcessImage>('fled_process_image');
final _FledAddBulletHole _fledAddBulletHole =
_lib.lookupFunction<_CFledAddBulletHole, _FledAddBulletHole>('fled_add_bullet_hole');
final _FledRemoveBulletHole _fledRemoveBulletHole =
_lib.lookupFunction<_CFledRemoveBulletHole, _FledRemoveBulletHole>('fled_remove_bullet_hole');
final _FreeBuffer _freeBuffer =
_lib.lookupFunction<_CFreeBuffer, _FreeBuffer>('free_buffer');
final _FreeCStr _freeCStr =
_lib.lookupFunction<_CFreeCStr, _FreeCStr>('free_cstr');

// class BulletHole {
//   final int index;
//   final double cxPx;
//   final double cyPx;
//   final double cxIn;
//   final double cyIn;
//   final int score;
//
//   BulletHole({
//     required this.index,
//     required this.cxPx,
//     required this.cyPx,
//     required this.cxIn,
//     required this.cyIn,
//     required this.score,
//   });
//
//   factory BulletHole.fromJson(Map<String, dynamic> m) => BulletHole(
//     index: (m['index'] as num).toInt(),
//     cxPx: (m['center_px']['x'] as num).toDouble(),
//     cyPx: (m['center_px']['y'] as num).toDouble(),
//     cxIn: (m['center_in']['x'] as num).toDouble(),
//     cyIn: (m['center_in']['y'] as num).toDouble(),
//     score: (m['score'] as num).toInt(),
//   );
//
//   Map<String, dynamic> toJson() => {
//     'index': index,
//     'center_px': {'x': cxPx, 'y': cyPx},
//     'center_in': {'x': cxIn, 'y': cyIn},
//     'score': score,
//   };
// }
// class FledResult {
//   final Uint8List processedJpeg;
//   final Map<String, dynamic> metrics;
//   /// Convenience typed list; parsed from metrics['holes'].
//   final List<BulletHole> holes;
//   final List<BulletHole> remappedBulletCenters;
//
//   // Updated constructor to include original image
//   FledResult(
//       this.processedJpeg,
//       this.metrics, this.remappedBulletCenters, [
//         this.holes = const [],
//
//       ]);
//
//   // Calculate total score (sum of all hole scores)
//   int get totalScore {
//     return holes.fold<int>(0, (sum, hole) {
//       return sum + hole.score;
//     });
//   }
//
//   double get averageScore {
//     if (holes.isEmpty) return 0.0;
//     return holes.fold<int>(0, (sum, hole) => sum + hole.score).toDouble() /
//         holes.length;
//   }
//
//   // Get the best shot (highest score)
//   int get bestShot {
//     if (holes.isEmpty) return 0;
//     return holes.map<int>((hole) => hole.score).reduce((a, b) => a > b ? a : b);
//   }
//
//   // Get the worst shot (lowest score)
//   int get worstShot {
//     if (holes.isEmpty) return 0;
//     return holes.map<int>((hole) => hole.score).reduce((a, b) => a < b ? a : b);
//   }
//   Map<String, dynamic> toJson() {
//     return {
//        // "processedJpeg": base64Encode(processedJpeg),
//       "metrics": metrics,
//       "holes": holes.map((h) => h.toJson()).toList(),
//       "totalScore": totalScore,
//       "averageScore": averageScore,
//       "bestShot": bestShot,
//     };
//   }
//
// // Helper to check if original image is available
// }

class NativeFled {
  static FledResult process({
    required Uint8List encodedInput,
    required String configPath,
    required String targetName,
    required String bulletCaliber,
    required String detectionMode,
    required double distanceYards,
  }) {
    if (encodedInput.isEmpty) {
      throw ArgumentError('encodedInput is empty');
    }
    if (encodedInput.length > 0x7fffffff) {
      throw ArgumentError('encodedInput too large for Int32 length');
    }

    // Zero-initialized allocations for safety on error paths.
    final inPtr       = calloc<ffi.Uint8>(encodedInput.length);
    final outBytesPtr = calloc<ffi.Pointer<ffi.Uint8>>();
    final outLenPtr   = calloc<ffi.Int32>();
    final outOrigBytesPtr = calloc<ffi.Pointer<ffi.Uint8>>(); // Added for original image
    final outOrigLenPtr   = calloc<ffi.Int32>(); // Added for original image length
    final outJsonPtr  = calloc<ffi.Pointer<Utf8>>();
    final outErrPtr   = calloc<ffi.Pointer<Utf8>>();

    inPtr.asTypedList(encodedInput.length).setAll(0, encodedInput);

    final cfg = configPath.toNativeUtf8();
    final tgt = targetName.toNativeUtf8();
    final cal = bulletCaliber.toNativeUtf8();
    final dm = detectionMode.toNativeUtf8();

    try {
      final rc = _fledProcessImage(
        inPtr, encodedInput.length, cfg, tgt, cal,dm, distanceYards,
        outBytesPtr, outLenPtr, outJsonPtr, outErrPtr,
      );


      // Pluck and free native error eagerly.
      String? nativeErr;
      final errP = outErrPtr.value;
      if (errP != ffi.nullptr) {
        nativeErr = errP.toDartString();
        _freeCStr(errP);
        outErrPtr.value = ffi.nullptr;
      }

      if (rc != 0) {
        throw Exception('fled_process_image rc=$rc'
            '${nativeErr != null ? ': $nativeErr' : ''}');
      }

      // Copy processed JPEG
      final ob = outBytesPtr.value;
      final olen = outLenPtr.value;
      if (ob == ffi.nullptr || olen <= 0) {
        throw Exception('Native returned empty JPEG buffer');
      }
      final processedJpeg = Uint8List.fromList(ob.asTypedList(olen));
      _freeBuffer(ob);

      // Copy original JPEG
      Uint8List? originalJpeg;
      final origB = outOrigBytesPtr.value;
      final origLen = outOrigLenPtr.value;
      if (origB != ffi.nullptr && origLen > 0) {
        originalJpeg = Uint8List.fromList(origB.asTypedList(origLen));
        _freeBuffer(origB);
      }

      // Copy JSON
      final jp = outJsonPtr.value;
      if (jp == ffi.nullptr) {
        throw Exception('Native returned null JSON');
      }
      final jsonStr = jp.toDartString();
      _freeCStr(jp);

      final metrics = json.decode(jsonStr) as Map<String, dynamic>;

      // Parse optional holes list
      final holesRaw = metrics['holes'];
      final holes = <BulletHole>[];
      if (holesRaw is List) {
        for (final e in holesRaw) {
          if (e is Map) {
            holes.add(BulletHole.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }

      // Parse optional holes list
      final remappedBulletCentersRaw = metrics['remapped_bullet_centers'];
      final remappedBullets = <BulletHole>[];
      if (remappedBulletCentersRaw is List) {
        for (final e in remappedBulletCentersRaw) {
          if (e is Map) {
            remappedBullets.add(BulletHole.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }

      return FledResult(processedJpeg, metrics,remappedBullets , holes,);
    } finally {
      calloc.free(inPtr);
      calloc.free(cfg);
      calloc.free(tgt);
      calloc.free(cal);
      calloc.free(dm);
      calloc.free(outBytesPtr);
      calloc.free(outLenPtr);
      calloc.free(outOrigBytesPtr); // Free original image pointer
      calloc.free(outOrigLenPtr); // Free original image length pointer
      calloc.free(outJsonPtr);
      calloc.free(outErrPtr);
    }
  }

  /// Add a bullet hole at the specified tap coordinates
  static FledResult addBulletHole({
    required double tapX,
    required double tapY,
  })
  {
    // Zero-initialized allocations for safety on error paths.
    final outBytesPtr = calloc<ffi.Pointer<ffi.Uint8>>();
    final outLenPtr   = calloc<ffi.Int32>();
    final outOrigBytesPtr = calloc<ffi.Pointer<ffi.Uint8>>(); // Added for original image
    final outOrigLenPtr   = calloc<ffi.Int32>(); // Added for original image length
    final outJsonPtr  = calloc<ffi.Pointer<Utf8>>();
    final outErrPtr   = calloc<ffi.Pointer<Utf8>>();

    try {
      final rc = _fledAddBulletHole(
        tapX, tapY,
        outBytesPtr, outLenPtr, outJsonPtr, outErrPtr,
      );

      // Pluck and free native error eagerly.
      String? nativeErr;
      final errP = outErrPtr.value;
      if (errP != ffi.nullptr) {
        nativeErr = errP.toDartString();
        _freeCStr(errP);
        outErrPtr.value = ffi.nullptr;
      }

      if (rc != 0) {
        throw Exception('fled_add_bullet_hole rc=$rc'
            '${nativeErr != null ? ': $nativeErr' : ''}');
      }

      // Copy processed JPEG
      final ob = outBytesPtr.value;
      final olen = outLenPtr.value;
      if (ob == ffi.nullptr || olen <= 0) {
        throw Exception('Native returned empty JPEG buffer');
      }
      final processedJpeg = Uint8List.fromList(ob.asTypedList(olen));
      _freeBuffer(ob);

      // Copy original JPEG
      Uint8List? originalJpeg;
      final origB = outOrigBytesPtr.value;
      final origLen = outOrigLenPtr.value;
      if (origB != ffi.nullptr && origLen > 0) {
        originalJpeg = Uint8List.fromList(origB.asTypedList(origLen));
        _freeBuffer(origB);
      }

      // Copy JSON
      final jp = outJsonPtr.value;
      if (jp == ffi.nullptr) {
        throw Exception('Native returned null JSON');
      }
      final jsonStr = jp.toDartString();
      _freeCStr(jp);

      final metrics = json.decode(jsonStr) as Map<String, dynamic>;

      // Parse optional holes list
      final holesRaw = metrics['holes'];
      final holes = <BulletHole>[];
      if (holesRaw is List) {
        for (final e in holesRaw) {
          if (e is Map) {
            holes.add(BulletHole.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }


      final remappedBulletCentersRaw = metrics['remapped_bullet_centers'];
      final remappedBullets = <BulletHole>[];
      if (remappedBulletCentersRaw is List) {
        for (final e in remappedBulletCentersRaw) {
          if (e is Map) {
            remappedBullets.add(BulletHole.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }

      return FledResult(processedJpeg, metrics,remappedBullets , holes,);
    } finally {
      calloc.free(outBytesPtr);
      calloc.free(outLenPtr);
      calloc.free(outOrigBytesPtr); // Free original image pointer
      calloc.free(outOrigLenPtr); // Free original image length pointer
      calloc.free(outJsonPtr);
      calloc.free(outErrPtr);
    }
  }

  /// Remove a bullet hole near the specified tap coordinates
  static FledResult removeBulletHole({
    required double tapX,
    required double tapY,
  })
  {
    // Zero-initialized allocations for safety on error paths.
    final outBytesPtr = calloc<ffi.Pointer<ffi.Uint8>>();
    final outLenPtr   = calloc<ffi.Int32>();
    final outOrigBytesPtr = calloc<ffi.Pointer<ffi.Uint8>>(); // Added for original image
    final outOrigLenPtr   = calloc<ffi.Int32>(); // Added for original image length
    final outJsonPtr  = calloc<ffi.Pointer<Utf8>>();
    final outErrPtr   = calloc<ffi.Pointer<Utf8>>();

    try {
      final rc = _fledRemoveBulletHole(
        tapX, tapY,
        outBytesPtr, outLenPtr, outJsonPtr, outErrPtr,
      );


      // Pluck and free native error eagerly.
      String? nativeErr;
      final errP = outErrPtr.value;
      if (errP != ffi.nullptr) {
        nativeErr = errP.toDartString();
        _freeCStr(errP);
        outErrPtr.value = ffi.nullptr;
      }

      if (rc != 0) {
        throw Exception('fled_remove_bullet_hole rc=$rc'
            '${nativeErr != null ? ': $nativeErr' : ''}');
      }

      // Copy processed JPEG
      final ob = outBytesPtr.value;
      final olen = outLenPtr.value;
      if (ob == ffi.nullptr || olen <= 0) {
        throw Exception('Native returned empty JPEG buffer');
      }
      final processedJpeg = Uint8List.fromList(ob.asTypedList(olen));
      _freeBuffer(ob);

      // Copy original JPEG
      Uint8List? originalJpeg;
      final origB = outOrigBytesPtr.value;
      final origLen = outOrigLenPtr.value;
      if (origB != ffi.nullptr && origLen > 0) {
        originalJpeg = Uint8List.fromList(origB.asTypedList(origLen));
        _freeBuffer(origB);
      }

      // Copy JSON
      final jp = outJsonPtr.value;
      if (jp == ffi.nullptr) {
        throw Exception('Native returned null JSON');
      }
      final jsonStr = jp.toDartString();
      _freeCStr(jp);

      final metrics = json.decode(jsonStr) as Map<String, dynamic>;

      // Parse optional holes list
      final holesRaw = metrics['holes'];
      final holes = <BulletHole>[];
      if (holesRaw is List) {
        for (final e in holesRaw) {
          if (e is Map) {
            holes.add(BulletHole.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }

      final remappedBulletCentersRaw = metrics['remapped_bullet_centers'];
      final remappedBullets = <BulletHole>[];
      if (remappedBulletCentersRaw is List) {
        for (final e in remappedBulletCentersRaw) {
          if (e is Map) {
            remappedBullets.add(BulletHole.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }

      return FledResult(processedJpeg, metrics,remappedBullets , holes,);


    } finally {
      calloc.free(outBytesPtr);
      calloc.free(outLenPtr);
      calloc.free(outOrigBytesPtr); // Free original image pointer
      calloc.free(outOrigLenPtr); // Free original image length pointer
      calloc.free(outJsonPtr);
      calloc.free(outErrPtr);
    }
  }
}

class BulletHole {
  final int index;
  final double cxPx;
  final double cyPx;
  final double cxIn;
  final double cyIn;
  final int score;

  const BulletHole({
    required this.index,
    required this.cxPx,
    required this.cyPx,
    required this.cxIn,
    required this.cyIn,
    required this.score,
  });

  BulletHole copyWith({
    int? index,
    double? cxPx,
    double? cyPx,
    double? cxIn,
    double? cyIn,
    int? score,
  }) {
    return BulletHole(
      index: index ?? this.index,
      cxPx: cxPx ?? this.cxPx,
      cyPx: cyPx ?? this.cyPx,
      cxIn: cxIn ?? this.cxIn,
      cyIn: cyIn ?? this.cyIn,
      score: score ?? this.score,
    );
  }

  factory BulletHole.fromJson(Map<String, dynamic> m) => BulletHole(
    index: (m['index'] as num).toInt(),
    cxPx: (m['center_px']['x'] as num).toDouble(),
    cyPx: (m['center_px']['y'] as num).toDouble(),
    cxIn: (m['center_in']['x'] as num).toDouble(),
    cyIn: (m['center_in']['y'] as num).toDouble(),
    score: (m['score'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'index': index,
    'center_px': {'x': cxPx, 'y': cyPx},
    'center_in': {'x': cxIn, 'y': cyIn},
    'score': score,
  };

  @override
  String toString() =>
      'BulletHole(index=$index, px=($cxPx,$cyPx), in=($cxIn,$cyIn), score=$score)';
}

class FledResult {
  final Uint8List processedJpeg;
  final Map<String, dynamic> metrics;

  /// Parsed holes (mutable list for UI convenience).
  final List<BulletHole> holes;

  /// If you store remapped centers separately.
  final List<BulletHole> remappedBulletCenters;

  FledResult(
      this.processedJpeg,
      this.metrics,
      this.remappedBulletCenters, [
        List<BulletHole> holes = const [],
      ]) : holes = List<BulletHole>.from(holes);

  // ---------- Derived scores ----------
  int get totalScore => holes.fold<int>(0, (sum, h) => sum + h.score);

  double get averageScore =>
      holes.isEmpty ? 0.0 : totalScore.toDouble() / holes.length;

  int get bestShot =>
      holes.isEmpty ? 0 : holes.map((h) => h.score).reduce((a, b) => a > b ? a : b);

  int get worstShot =>
      holes.isEmpty ? 0 : holes.map((h) => h.score).reduce((a, b) => a < b ? a : b);

  // ---------- Copy / JSON ----------
  FledResult copyWith({
    Uint8List? processedJpeg,
    Map<String, dynamic>? metrics,
    List<BulletHole>? holes,
    List<BulletHole>? remappedBulletCenters,
  }) {
    return FledResult(
      processedJpeg ?? this.processedJpeg,
      metrics ?? this.metrics,
      remappedBulletCenters ?? this.remappedBulletCenters,
      holes ?? this.holes,
    );
  }

  /// Accepts either top-level "holes" or "metrics['holes']".
  factory FledResult.fromJson(Map<String, dynamic> m) {
    final metrics = (m['metrics'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    List<dynamic>? rawHoles = m['holes'] as List<dynamic>?;
    rawHoles ??= metrics['holes'] as List<dynamic>?;

    final holes = (rawHoles ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BulletHole.fromJson)
        .toList();

    // If you serialize remapped centers, accept both keys.
    List<dynamic>? rawRemapped = m['remappedBulletCenters'] as List<dynamic>?;
    rawRemapped ??= m['group']?['remapped_bullet_centers'] as List<dynamic>?; // optional alt path
    final remapped = (rawRemapped ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BulletHole.fromJson)
        .toList();

    // processedJpeg may not be serialized; default to empty if absent
    final processedJpeg = m['processedJpeg'] is Uint8List
        ? (m['processedJpeg'] as Uint8List)
        : Uint8List(0);

    return FledResult(processedJpeg, metrics, remapped, holes);
  }

  Map<String, dynamic> toJson() {
    return {
      // "processedJpeg": base64Encode(processedJpeg), // keep off if not needed
      "metrics": metrics,
      "holes": holes.map((h) => h.toJson()).toList(),
      "totalScore": totalScore,
      "averageScore": averageScore,
      "bestShot": bestShot,
      "worstShot": worstShot,
      // Optionally include remapped:
      // "remappedBulletCenters": remappedBulletCenters.map((h) => h.toJson()).toList(),
    };
  }
}

extension FledResultMutX on FledResult {
  /// Update one hole's pixel center (in-place list mutation).
  void setHolePxInPlace(int i, double x, double y) {
    if (i < 0 || i >= holes.length) return;
    holes[i] = holes[i].copyWith(cxPx: x, cyPx: y);
  }

  /// Remove hole by index (in-place).
  void removeHoleAtInPlace(int i) {
    if (i < 0 || i >= holes.length) return;
    holes.removeAt(i);
  }

  /// Append a hole (in-place).
  void addHoleInPlace(BulletHole h) {
    holes.add(h);
  }
}

extension FledResultImmutableX on FledResult {
  FledResult replaceHoleAt(int i, BulletHole hole) {
    if (i < 0 || i >= holes.length) return this;
    final newHoles = List<BulletHole>.from(holes);
    newHoles[i] = hole;
    return copyWith(holes: newHoles);
  }

  FledResult removeHoleAt(int i) {
    if (i < 0 || i >= holes.length) return this;
    final newHoles = List<BulletHole>.from(holes)..removeAt(i);
    return copyWith(holes: newHoles);
  }

  FledResult addHole(BulletHole h) {
    final newHoles = List<BulletHole>.from(holes)..add(h);
    return copyWith(holes: newHoles);
  }
}





// Uint8List? _originalFromJson(Map<String, dynamic>? metrics) {
//   //its calling
//   //    Uint8List? originalJpeg =  _originalFromJson(res?.metrics);
//   if (metrics==null) return null;
//   final images = metrics['images'];
//   if (images is Map<String, dynamic>) {
//     final b64 = images['original_jpeg_b64'];
//     if (b64 is String && b64.isNotEmpty) {
//       try {
//         return base64Decode(b64);
//       } catch (_) { /* ignore */ }
//     }
//   }
//   return null;
// }

