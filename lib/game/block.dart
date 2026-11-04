enum BlockColor { green, cyan, yellow, red }

enum BlockShape { rectangle, square, triangle, invertedTriangle }

class Block {
  const Block({
    required this.color,
    required this.shape,
    required this.width,
    required this.height,
  });

  final BlockColor color;
  final BlockShape shape;

  /// Fraction of arena width.
  final double width;

  /// Logical pixels at scale 1.
  final double height;

  /// Width times height, halved for both triangles.
  double get mass {
    final area = width * height;
    return shape == BlockShape.triangle || shape == BlockShape.invertedTriangle
        ? area / 2
        : area;
  }

  @override
  bool operator ==(Object other) =>
      other is Block &&
      other.color == color &&
      other.shape == shape &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(color, shape, width, height);
}

const Block pillar = Block(
  color: BlockColor.red,
  shape: BlockShape.rectangle,
  width: 0.18,
  height: 70,
);
