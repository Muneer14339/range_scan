import '/Screens/models/user_weapon_model.dart';

class MainSessionRecordModel {
  final String recordId;
  final String userId;
  final WeaponModel? weapon;
  String weaponId = '';
  final String targetPaper;
  final String distance;
  final String caliber; //
  final String imagePath;
  final dynamic finalShotResult;
  final bool isSynced;
  final DateTime? createdAt;

  MainSessionRecordModel({
    required this.recordId,
    required this.userId,
    required this.weaponId,
    this.weapon,
    required this.targetPaper,
    required this.distance,
    required this.caliber,
    required this.imagePath,
    required this.finalShotResult,
    this.isSynced = false,
    this.createdAt 
  });

  factory MainSessionRecordModel.fromJson(Map<String, dynamic> json) {
    return MainSessionRecordModel(
      recordId: json['recordId'] ?? '',
      weaponId: json['weaponId'] ?? '',
      userId: json['userId'] ?? '',
      weapon: WeaponModel.fromJson(json['weapon'] ?? {}),
      targetPaper: json['targetPaper'] ?? '',
      distance: json['distance'] ?? '',
      caliber: json['caliber'] ?? '',
      imagePath: json['imagePath'] ?? '',
      finalShotResult: json['finalShotResult'],
      isSynced: json['isSynced'] == 1,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'recordId': recordId,
    'userId': userId,
    'weaponId': weaponId,
    // 'weapon': weapon?.toJson(),
    'targetPaper': targetPaper,
    'distance': distance,
    'caliber': caliber,
    'imagePath': imagePath,
    'finalShotResult': finalShotResult,
    'isSynced': isSynced ? 1 : 0,
    'createdAt':DateTime.now(),
  };
}
