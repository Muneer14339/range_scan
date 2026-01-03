class TargetModel {
  String category;
   String name;
  final String? text;
  String value;

  TargetModel({
    required this.category,
    required this.name,
    this.text,
    required this.value,
  });
}
