class TargetModel {
  final String ?id;
  final String ?name;
  final String ?description;
  final String ?specs;
  final String ?emoji;
  final TargetCategory ?category;

  TargetModel({
     this.id,
     this.name,
     this.description,
     this.specs,
     this.emoji,
     this.category,
  });
}

enum TargetCategory { nra, precision, custom }