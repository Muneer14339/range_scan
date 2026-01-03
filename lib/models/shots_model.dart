class Shot {
  final int id;
  final double x;
  final double y;
  final int score;
  bool highlighted;

  Shot({
    required this.id,
    required this.x,
    required this.y,
    required this.score,
    this.highlighted = false,
  });
}