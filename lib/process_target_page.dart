// import 'dart:convert' show JsonEncoder, ascii;
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
//
// import 'package:flutter/foundation.dart' show compute;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
//
// import 'ffi_bridge/ffi_binding.dart';
//
//
// Future<Map<String, Object?>> _fledWorker(Map<String, Object?> args) async {
//   final bytes        = args['bytes'] as Uint8List;
//   final configPath   = args['configPath'] as String;
//   final targetName   = args['targetName'] as String;
//   final bulletCal    = args['bulletCaliber'] as String;
//   final distanceYds  = (args['distanceYards'] as num).toDouble();
//
//   // Call native on the worker isolate.
//   final res = NativeFled.process(
//     encodedInput: bytes,
//     configPath: configPath,
//     targetName: targetName,
//     bulletCaliber: bulletCal,
//     distanceYards: distanceYds,
//   );
//
//   // Extract sendable holes list (List<Map<String, dynamic>>).
//   final holes = (res.metrics['holes'] is List)
//       ? List<Map<String, dynamic>>.from(
//     (res.metrics['holes'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
//   )
//       : const <Map<String, dynamic>>[];
//
//   // Return plain sendables
//   return <String, Object?>{
//     'jpeg': res.processedJpeg,
//     'metrics': res.metrics,
//     'holes': holes,
//   };
// }
//
// class ProcessTargetPage extends StatefulWidget {
//   const ProcessTargetPage({super.key});
//
//   @override
//   State<ProcessTargetPage> createState() => _ProcessTargetPageState();
// }
//
// class _ProcessTargetPageState extends State<ProcessTargetPage> {
//   Uint8List? _inputBytes;
//   Uint8List? _processedJpeg;
//   Map<String, dynamic>? _metrics;
//   List<Map<String, dynamic>>? _holes; // <-- NEW: parsed holes for UI
//   String? _configPath;
//   bool _busy = false;
//
//   // Defaults
//   String _target = "PA (White and Red)";
//   String _caliber = ".22lr";
//   double _yards = 25.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _prepareConfigPath();
//   }
//   final _holesVController = ScrollController();
//   final _holesHController = ScrollController();
//
//   @override
//   void dispose() {
//     _holesVController.dispose();
//     _holesHController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _prepareConfigPath() async {
//     try {
//       final data = await rootBundle.load('assets/config.json');
//       final dir = await getTemporaryDirectory();
//       final cfgPath = '${dir.path}/config.json';
//       await File(cfgPath).writeAsBytes(data.buffer.asUint8List(), flush: true);
//       if (!mounted) return;
//       setState(() => _configPath = cfgPath);
//       debugPrint('[FLED][UI] Config copied to $cfgPath');
//     } catch (e, st) {
//       debugPrint('[FLED][UI][ERR] Failed to load assets/config.json: $e\n$st');
//     }
//   }
//
//   // --- HEIC/HEIF handling (normalize to PNG so OpenCV can decode) ---
//
//   bool _looksLikeHeic(Uint8List b) {
//     if (b.length < 12) return false;
//     final tag = ascii.decode(b.sublist(4, 8), allowInvalid: true);
//     if (tag != 'ftyp') return false;
//     final brand = ascii.decode(b.sublist(8, 12), allowInvalid: true);
//     const brands = {'heic', 'heix', 'hevc', 'heis', 'mif1', 'msf1', 'heif'};
//     return brands.contains(brand);
//   }
//
//   Future<Uint8List> _normalizeIfHeic(Uint8List bytes) async {
//     if (!_looksLikeHeic(bytes)) return bytes;
//     final codec = await ui.instantiateImageCodec(bytes);
//     final frame = await codec.getNextFrame();
//     final bd = await frame.image.toByteData(format: ui.ImageByteFormat.png);
//     return Uint8List.view(bd!.buffer);
//   }
//
//   Future<void> _pick(ImageSource src) async {
//     try {
//       final picker = ImagePicker();
//       final x = await picker.pickImage(
//         source: src,
//         imageQuality: 100,
//         maxWidth: 3000,  // optional downscale for performance
//         maxHeight: 3000,
//       );
//       if (x == null) return;
//       final rawBytes = await x.readAsBytes();
//       final bytes = await _normalizeIfHeic(rawBytes);
//       if (!mounted) return;
//       setState(() {
//         _inputBytes = bytes;
//         _processedJpeg = null;
//         _metrics = null;
//         _holes = null;
//       });
//       debugPrint('[FLED][UI] Picked image: ${bytes.length} bytes');
//     } catch (e, st) {
//       debugPrint('[FLED][UI][ERR] Image pick failed: $e\n$st');
//     }
//   }
//
//   Future<void> _process() async {
//     if (_inputBytes == null) {
//       debugPrint('[FLED][UI][ERR] Pick an image first');
//       return;
//     }
//     if (_configPath == null) {
//       debugPrint('[FLED][UI][ERR] Config not ready yet');
//       return;
//     }
//
//     setState(() => _busy = true);
//     final t0 = DateTime.now();
//
//     // Capture values into locals (avoid capturing `this` anywhere).
//     final bytes   = _inputBytes!;
//     final cfg     = _configPath!;
//     final target  = _target;
//     final cal     = _caliber;
//     final yards   = _yards;
//
//     debugPrint('[FLED][UI] dispatch worker… bytes=${bytes.length} target=$target cal=$cal yd=$yards');
//
//     try {
//       final out = await compute<Map<String, Object?>, Map<String, Object?>>(
//         _fledWorker,
//         <String, Object?>{
//           'bytes': bytes,
//           'configPath': cfg,
//           'targetName': target,
//           'bulletCaliber': cal,
//           'distanceYards': yards,
//         },
//       );
//
//       final processedJpeg = out['jpeg'] as Uint8List;
//       final metrics = out['metrics'] as Map<String, dynamic>;
//       final holes = (out['holes'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
//
//       debugPrint('[FLED][UI] worker OK in ${DateTime.now().difference(t0).inMilliseconds} ms, jpeg=${processedJpeg.length}B');
//
//       // Log each hole EXACTLY as requested
//       for (final h in holes) {
//         final j = {
//           "index": h["index"],
//           "center_px": {
//             "x": h["center_px"]?["x"],
//             "y": h["center_px"]?["y"],
//           },
//           "center_in": {
//             "x": h["center_in"]?["x"],
//             "y": h["center_in"]?["y"],
//           },
//           "score": h["score"],
//         };
//         debugPrint('[FLED][UI] hole -> ${const JsonEncoder().convert(j)}');
//       }
//
//       if (!mounted) return;
//       setState(() {
//         _processedJpeg = processedJpeg;
//         _metrics = metrics;
//         _holes = holes;
//       });
//     } catch (e, st) {
//       debugPrint('[FLED][UI][ERR] Processing error: $e\n$st');
//     } finally {
//       if (mounted) setState(() => _busy = false);
//     }
//   }
//
//   Future<void> _saveProcessed() async {
//     if (_processedJpeg == null) {
//       debugPrint('[FLED][UI][ERR] Process an image first');
//       return;
//     }
//     try {
//       final dir = await getTemporaryDirectory();
//       final outPath = '${dir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       await File(outPath).writeAsBytes(_processedJpeg!, flush: true);
//       debugPrint('[FLED][UI] Saved: $outPath');
//     } catch (e, st) {
//       debugPrint('[FLED][UI][ERR] Save failed: $e\n$st');
//     }
//   }
//
//   // (Optional) Keep if you still want non-error toasts for success cases.
//   void _snack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final canRun = _inputBytes != null && !_busy;
//     final canSave = _processedJpeg != null && !_busy;
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('FLED Process')),
//       body: Column(
//         children: [
//           if (_busy) const LinearProgressIndicator(minHeight: 2),
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _busy ? null : () => _pick(ImageSource.gallery),
//                   icon: const Icon(Icons.photo_library),
//                   label: const Text('Gallery'),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton.icon(
//                   onPressed: _busy ? null : () => _pick(ImageSource.camera),
//                   icon: const Icon(Icons.photo_camera),
//                   label: const Text('Camera'),
//                 ),
//                 const Spacer(),
//                 ElevatedButton.icon(
//                   onPressed: canSave ? _saveProcessed : null,
//                   icon: const Icon(Icons.save_alt),
//                   label: const Text('Save'),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton.icon(
//                   onPressed: canRun ? _process : null,
//                   icon: _busy
//                       ? const SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                       : const Icon(Icons.play_arrow),
//                   label: Text(_busy ? 'Processing...' : 'Process'),
//                 ),
//               ],
//             ),
//           ),
//           // Quick parameter row (free text; swap for dropdowns if you have fixed lists)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextFormField(
//                     initialValue: _target,
//                     decoration: const InputDecoration(labelText: 'Target name'),
//                     onChanged: (v) => _target = v,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 SizedBox(
//                   width: 120,
//                   child: TextFormField(
//                     initialValue: _caliber,
//                     decoration: const InputDecoration(labelText: 'Caliber'),
//                     onChanged: (v) => _caliber = v,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 SizedBox(
//                   width: 110,
//                   child: TextFormField(
//                     initialValue: _yards.toStringAsFixed(1),
//                     decoration: const InputDecoration(labelText: 'Yards'),
//                     keyboardType: TextInputType.number,
//                     onChanged: (v) {
//                       final d = double.tryParse(v);
//                       if (d != null) _yards = d;
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Expanded(
//             child: Row(
//               children: [
//                 Expanded(child: _pane('Original', _inputBytes)),
//                 Expanded(child: _pane('Processed', _processedJpeg)),
//               ],
//             ),
//           ),
//           // if (_metrics != null)
//           //   Container(
//           //     width: double.infinity,
//           //     height: 200,
//           //     padding: const EdgeInsets.all(12),
//           //     color: Theme.of(context).colorScheme.surfaceContainerHighest,
//           //     child: SingleChildScrollView(
//           //       scrollDirection: Axis.horizontal,
//           //       child: Text(
//           //         const JsonEncoder.withIndent('  ').convert(_metrics),
//           //         style: const TextStyle(
//           //           fontFamily: 'monospace',
//           //           fontSize: 12,
//           //         ),
//           //       ),
//           //     ),
//           //   ),
//           if (_holes != null && _holes!.isNotEmpty)
//             SizedBox(
//               height: 200,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
//                 child: _holesTable(_holes!), // unchanged call
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _pane(String title, Uint8List? bytes) => Card(
//     margin: const EdgeInsets.all(12),
//     clipBehavior: Clip.antiAlias,
//     child: Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8),
//           child: Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               title,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//         ),
//         Expanded(
//           child: bytes == null
//               ? const Center(child: Text('—'))
//               : InteractiveViewer(
//             child: Image.memory(bytes, fit: BoxFit.contain),
//           ),
//         ),
//       ],
//     ),
//   );
//   Widget _holesTable(List<Map<String, dynamic>> holes) {
//     final rows = holes.map<DataRow>((h) {
//       final idx = h['index'];
//       final px = h['center_px'] as Map?;
//       final pin = h['center_in'] as Map?;
//       final xPx = px?['x'];
//       final yPx = px?['y'];
//       final xIn = pin?['x'];
//       final yIn = pin?['y'];
//       final score = h['score'];
//       return DataRow(cells: [
//         DataCell(Text('$idx')),
//         DataCell(Text('${xPx is num ? xPx.toStringAsFixed(2) : xPx}')),
//         DataCell(Text('${yPx is num ? yPx.toStringAsFixed(2) : yPx}')),
//         DataCell(Text('${xIn is num ? xIn.toStringAsFixed(3) : xIn}')),
//         DataCell(Text('${yIn is num ? yIn.toStringAsFixed(3) : yIn}')),
//         DataCell(Text('$score')),
//       ]);
//     }).toList();
//
//     final table = DataTable(
//       headingRowHeight: 36,
//       dataRowMinHeight: 32,
//       dataRowMaxHeight: 36,
//       columns: const [
//         DataColumn(label: Text('#')),
//         DataColumn(label: Text('x_px')),
//         DataColumn(label: Text('y_px')),
//         DataColumn(label: Text('x_in')),
//         DataColumn(label: Text('y_in')),
//         DataColumn(label: Text('score')),
//       ],
//       rows: rows,
//     );
//
//     // vertical scroll (outer) + horizontal scroll (inner)
//     return Card(
//       elevation: 1,
//       child: Scrollbar(
//         controller: _holesVController,
//         thumbVisibility: true,
//         child: SingleChildScrollView(
//           controller: _holesVController,
//           scrollDirection: Axis.vertical,
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Scrollbar(
//             controller: _holesHController,
//             thumbVisibility: true,
//             notificationPredicate: (notif) => notif.depth == 1,
//             child: SingleChildScrollView(
//               controller: _holesHController,
//               scrollDirection: Axis.horizontal,
//               physics: const AlwaysScrollableScrollPhysics(),
//               child: table,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Widget _holesTable(List<Map<String, dynamic>> holes) {
//   //   final rows = holes.map<DataRow>((h) {
//   //     final idx = h['index'];
//   //     final px = h['center_px'] as Map?;
//   //     final pin = h['center_in'] as Map?;
//   //     final xPx = px?['x'];
//   //     final yPx = px?['y'];
//   //     final xIn = pin?['x'];
//   //     final yIn = pin?['y'];
//   //     final score = h['score'];
//   //     return DataRow(cells: [
//   //       DataCell(Text('$idx')),
//   //       DataCell(Text('${xPx?.toStringAsFixed(2) ?? xPx}')),
//   //       DataCell(Text('${yPx?.toStringAsFixed(2) ?? yPx}')),
//   //       DataCell(Text('${xIn is num ? xIn.toStringAsFixed(3) : xIn}')),
//   //       DataCell(Text('${yIn is num ? yIn.toStringAsFixed(3) : yIn}')),
//   //       DataCell(Text('$score')),
//   //     ]);
//   //   }).toList();
//   //
//   //   return Card(
//   //     elevation: 1,
//   //     child: SingleChildScrollView(
//   //       scrollDirection: Axis.horizontal,
//   //       child: DataTable(
//   //         headingRowHeight: 36,
//   //         dataRowMinHeight: 32,
//   //         dataRowMaxHeight: 36,
//   //         columns: const [
//   //           DataColumn(label: Text('#')),
//   //           DataColumn(label: Text('x_px')),
//   //           DataColumn(label: Text('y_px')),
//   //           DataColumn(label: Text('x_in')),
//   //           DataColumn(label: Text('y_in')),
//   //           DataColumn(label: Text('score')),
//   //         ],
//   //         rows: rows,
//   //       ),
//   //     ),
//   //   );
//   // }
// }
//
