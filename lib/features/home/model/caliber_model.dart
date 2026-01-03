import 'dart:convert';

class CaliberModel {
  final String name;
  final String size;

  CaliberModel({required this.name, required this.size});

  factory CaliberModel.fromMap(Map<String, dynamic> map) {
    return CaliberModel(
      name: map['name'],
      size: map['size'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'size': size,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory CaliberModel.fromJson(String source) =>
      CaliberModel.fromMap(jsonDecode(source));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaliberModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          size == other.size;

  @override
  int get hashCode => name.hashCode ^ size.hashCode;
}
