import '/Screens/models/firearm_model.dart';

class AddCaliberModel {
  final String? userId;
  final FirearmModel? firearm;

  AddCaliberModel({this.userId, this.firearm});

  factory AddCaliberModel.fromJson(Map<String, dynamic> json) {
    return AddCaliberModel(
      userId: json['user_id'] ?? '',
      firearm: FirearmModel.fromJson({
        'brand': json['brand'] ?? '',
        'caliber': json['caliber'] ?? '',
        'firing_mechanism': json['firing_mechanism'] ?? '',
        'generation': json['generation'] ?? '',
        'make': json['make'] ?? '',
        'model': json['model'] ?? '',
        'type': json['type'] ?? '',
        'caliber_diameter': json['diameter'] ?? 0.0,
      }),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId ?? '',
      'brand': firearm?.brand ?? '',
      'caliber': firearm?.caliber ?? '',
      'firing_mechanism': firearm?.firingMechanism ?? '',
      'generation': firearm?.generation ?? '',
      'make': firearm?.make ?? '',
      'model': firearm?.model ?? '',
      'type': firearm?.type ?? '',
      'caliber_diameter': firearm?.caliberDiameter ?? 0.0,
    };
  }
}
