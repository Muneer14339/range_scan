import 'dart:convert';

import 'package:flutter/services.dart';

class ProcessedData {
  final int? id;
  final Uint8List? jpegImage;
  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> holes;

  ProcessedData({
    this.id,
    required this.jpegImage,
    required this.metrics,
    required this.holes,
  });

  int get totalScore {
    return holes.fold<int>(0, (sum, hole) => sum + (hole['score'] ?? 0) as int);
  }

  double get averageScore {
    if (holes.isEmpty) return 0.0;
    return totalScore.toDouble() / holes.length;
  }

  int get bestShot {
    if (holes.isEmpty) return 0;
    return holes
        .map<int>((hole) => hole['score'] ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  Map<String, dynamic> toMap() {
    return {
      'jpegImage': jpegImage,
      'metrics': json.encode(metrics),
      'holes': json.encode(holes),
    };
  }
}
