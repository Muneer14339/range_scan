// import 'dart:typed_data';

// import '/ffi_bridge/ffi_binding.dart' show NativeFled;

// import '../models/fled_result_model.dart';

// class FledService {
//   static Future<FledResult?> processImage({
//     required Uint8List bytes,
//     required String configPath,
//     required String targetName,
//     required String bulletCaliber,
//     required double distanceYards,
//   }) async {
//     final res = NativeFled.process(
//       encodedInput: bytes,
//       configPath: configPath,
//       targetName: targetName,
//       bulletCaliber: bulletCaliber,
//       distanceYards: distanceYards,
//     );

//     if (res == null) return null;

//     return FledResult(
//       processedJpeg: res.processedJpeg,
//       metrics: res.metrics,
//       holes: (res.holes ?? [])
//           .map((h) => BulletHole.fromJson(h as Map<String, dynamic>))
//           .toList(),
//     );
//   }
// }
