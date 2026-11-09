/// One level of Memory Towers: how many cubes, how many colours they are
/// drawn from, and how long the player may study them.
class MemoryLevel {
  const MemoryLevel({
    required this.number,
    required this.cubes,
    required this.colors,
  });

  final int number;
  final int cubes;
  final int colors;

  /// Grows with the tower: a short base plus about 0.7s per cube.
  int get studySeconds => 3 + (cubes * 0.7).ceil();
}

/// Cube counts: 5 on level 1, then +2 for 7 levels, +5 for 7 levels and
/// +7 for 7 levels, so 22 levels from 5 up to 103 cubes.
List<int> memoryCubeCounts() {
  final counts = [5];
  for (final step in const [2, 5, 7]) {
    for (var i = 0; i < 7; i++) {
      counts.add(counts.last + step);
    }
  }
  return counts;
}

/// A new colour joins the palette every few levels, up to all eight.
int _colorsFor(int number) => switch (number) {
  <= 3 => 4,
  <= 6 => 5,
  <= 9 => 6,
  <= 14 => 7,
  _ => 8,
};

final List<MemoryLevel> memoryLevels = [
  for (final (i, cubes) in memoryCubeCounts().indexed)
    MemoryLevel(number: i + 1, cubes: cubes, colors: _colorsFor(i + 1)),
];
