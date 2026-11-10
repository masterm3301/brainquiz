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

  /// Grows with the tower: 2s plus a second a cube while the tower is a
  /// single column, then about 0.7s for each cube above that.
  int get studySeconds => cubes <= _singleTowerMax
      ? 2 + cubes
      : 2 + _singleTowerMax + ((cubes - _singleTowerMax) * 0.7).ceil();

  /// How long a rewarded peek shows the tower again during the rebuild.
  int get peekSeconds => 3 + cubes ~/ 15;

  /// The warm-up levels stand as one single tower; later levels split
  /// into as many towers as give the biggest cubes.
  int? get maxColumns => number <= warmUpLevels ? 1 : null;
}

/// Levels 1 to 12: one tower, one more cube each level.
const int warmUpLevels = 12;

/// Cubes in the tallest single tower, on the last warm-up level.
const int _singleTowerMax = 3 + warmUpLevels - 1;

/// How the ladder grows after level 1: (cubes added a level, levels).
const memoryStages = [(1, warmUpLevels - 1), (2, 7), (5, 7), (7, 7)];

/// Cube counts: 3 on level 1, +1 a level up to level 12, then +2 for 7
/// levels, +5 for 7 levels and +7 for 7 levels: 33 levels, 3 to 112 cubes.
List<int> memoryCubeCounts() {
  final counts = [3];
  for (final (step, levels) in memoryStages) {
    for (var i = 0; i < levels; i++) {
      counts.add(counts.last + step);
    }
  }
  return counts;
}

/// A new colour joins the palette every few levels, up to all eight.
int _colorsFor(int number) => switch (number) {
  <= 4 => 4,
  <= 8 => 5,
  <= 14 => 6,
  <= 21 => 7,
  _ => 8,
};

/// The ladder's stages: name, how it grows, first and last level.
const memoryStageTable = [
  ('Warm-up', 'One tower · +1 cube a level', 1, 12),
  ('Build-up', '+2 cubes a level', 13, 19),
  ('Climb', '+5 cubes a level', 20, 26),
  ('Summit', '+7 cubes a level', 27, 33),
];

/// The stage level [number] belongs to.
String memoryStageName(int number) => memoryStageTable
    .firstWhere(
      (s) => number <= s.$4,
      orElse: () => memoryStageTable.last,
    )
    .$1;

final List<MemoryLevel> memoryLevels = [
  for (final (i, cubes) in memoryCubeCounts().indexed)
    MemoryLevel(number: i + 1, cubes: cubes, colors: _colorsFor(i + 1)),
];
