import 'package:cloud_firestore/cloud_firestore.dart';
import '/Screens/models/firearm_model.dart';

class WeaponModel {
  final String? weaponId;
  final String? userId;
  final FirearmModel? firearm;
  String? notes;
  final DateTime? createdAt;

  WeaponModel({
    this.weaponId,
     this.userId,
     this.firearm,
    this.notes,
    this.createdAt,
  });

  factory WeaponModel.fromJson(Map<String, dynamic> json) {
     DateTime? parsedDate;

    // 🔹 Handle Firestore Timestamp or String safely
    if (json['createdAt'] != null) {
      final value = json['createdAt'];
      if (value is Timestamp) {
        parsedDate = value.toDate();
      } else if (value is String) {
        parsedDate = DateTime.tryParse(value);
      }
    }
    return WeaponModel(
      weaponId: json['weaponId'] ?? '',
      userId: json['userId'] ?? '',
      // sessionId: json['sessionId'] ?? '',
      firearm: FirearmModel.fromJson(json['firearm'] ?? {}),
      notes: json['notes'] ?? '',
      createdAt:
         parsedDate
    );
  }

  Map<String, dynamic> toJson() => {
    'weaponId': weaponId,
    'userId': userId,
    'firearm': firearm?.toJson(),
    'notes': notes??'',
    'createdAt': DateTime.now(),
  };
}
