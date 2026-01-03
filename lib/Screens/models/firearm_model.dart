class FirearmModel {
  final String? brand;
  final String? caliber;
  final String? firingMechanism;
  final String? generation;
  final String? make;
  final String? model;
  final String? type;
  final double? caliberDiameter;

  FirearmModel({
    this.brand,
    this.caliber,
    this.firingMechanism,
    this.generation,
    this.make,
    this.model,
    this.type,
    this.caliberDiameter,
  });

  factory FirearmModel.fromJson(Map<String, dynamic> json) {
    return FirearmModel(
      brand: json['brand'] ?? '',
      caliber: json['caliber'] ?? '',
      firingMechanism: json['firing_mechanism'] ?? '',
      generation: json['generation'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      type: json['type'] ?? '',
      caliberDiameter:
          (json['caliber_diameter'] is num)
              ? (json['caliber_diameter'] as num).toDouble()
              : double.tryParse(
                    json['caliber_diameter']?.toString() ?? '0.0',
                  ) ??
                  0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'brand': brand ?? '',
    'caliber': caliber ?? '',
    'firing_mechanism': firingMechanism ?? '',
    'generation': generation ?? '',
    'make': make ?? '',
    'model': model ?? '',
    'type': type ?? '',
    'caliber_diameter': caliberDiameter ?? 0.0,
  };
}
