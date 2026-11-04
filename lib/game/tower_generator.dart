import 'dart:math';

import 'block.dart';
import 'levels.dart';

class GeneratedTower {
  const GeneratedTower({
    required this.seed,
    required this.blocks,
    required this.tray,
  });

  final int seed;

  /// Bottom first, pillar not included.
  final List<Block> blocks;

  /// Real blocks plus decoys, shuffled.
  final List<Block> tray;
}

const _widths = [.30, .42, .54, .66, .78, .90];
const _heights = [26.0, 34.0, 44.0];
const _squareWidths = [.16, .22, .28];
const _towerColors = [BlockColor.green, BlockColor.cyan, BlockColor.yellow];
const _flexShapes = [
  BlockShape.rectangle,
  BlockShape.triangle,
  BlockShape.invertedTriangle,
];
const _decoyRetries = 1000;

GeneratedTower generateTower(
  LevelConfig level,
  int seed, {
  List<Block>? previous,
}) {
  var attemptSeed = seed;
  for (var attempt = 1; ; attempt++) {
    final tower = _build(level, attemptSeed);
    if (previous == null || !_sameBlocks(tower.blocks, previous)) {
      return GeneratedTower(seed: seed, blocks: tower.blocks, tray: tower.tray);
    }
    attemptSeed = seed + attempt * 0x9E3779B1;
  }
}

bool _sameBlocks(List<Block> a, List<Block> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

GeneratedTower _build(LevelConfig level, int seed) {
  final random = Random(seed);
  late List<Block> blocks;
  do {
    blocks = _tower(level, random);
  } while (blocks.first.width < blocks.last.width ||
      {for (final b in blocks) _look(b)}.length != blocks.length);

  final tray = [...blocks];
  final taken = {for (final b in blocks) _look(b)};
  for (var i = 0; i < level.decoys; i++) {
    final decoy = _decoy(level, blocks, taken, random);
    taken.add(_look(decoy));
    tray.add(decoy);
  }
  tray.shuffle(random);
  return GeneratedTower(seed: seed, blocks: blocks, tray: tray);
}

/// What tells tray blocks apart. Heights are too close to read on a tray
/// tile (26 and 34 draw about 5 and 7px high), so height does not count.
(BlockColor, BlockShape, double) _look(Block b) => (b.color, b.shape, b.width);

List<Block> _tower(LevelConfig level, Random random) {
  final n = level.blocks;
  final colors = _towerColors.take(level.colorCount).toList();
  return [
    for (var i = 0; i < n; i++)
      () {
        // Ideal width step falls linearly from widest (bottom) to narrowest.
        final ideal = n == 1 ? 5.0 : (1 - i / (n - 1)) * 5;
        final step = (ideal.round() + random.nextInt(3) - 1).clamp(0, 5);
        final shape = level.shapes[random.nextInt(level.shapes.length)];
        return _make(
          colors[random.nextInt(colors.length)],
          shape,
          step,
          random,
        );
      }(),
  ];
}

Block _make(BlockColor color, BlockShape shape, int widthStep, Random random) {
  if (shape == BlockShape.square) {
    final width = _squareWidths[(widthStep * 2 / 5).round()];
    return Block(color: color, shape: shape, width: width, height: width * 340);
  }
  return Block(
    color: color,
    shape: shape,
    width: _widths[widthStep],
    height: _heights[random.nextInt(_heights.length)],
  );
}

Block _decoy(
  LevelConfig level,
  List<Block> real,
  Set<(BlockColor, BlockShape, double)> taken,
  Random random,
) {
  for (var i = 0; i < _decoyRetries; i++) {
    final candidate = level.number < 7
        ? _randomDecoy(level, random)
        : _variant(level, real[random.nextInt(real.length)], random);
    if (candidate != null && !taken.contains(_look(candidate))) {
      return candidate;
    }
  }
  throw StateError('Could not find a distinct decoy for level ${level.number}');
}

Block _randomDecoy(LevelConfig level, Random random) {
  final red = random.nextInt(4) == 0;
  final color = red
      ? BlockColor.red
      : _towerColors[random.nextInt(level.colorCount)];
  final shape = level.shapes[random.nextInt(level.shapes.length)];
  return _make(color, shape, random.nextInt(6), random);
}

/// Copies [source] and changes exactly one of colour, shape, or size.
Block? _variant(LevelConfig level, Block source, Random random) {
  switch (random.nextInt(3)) {
    case 0:
      final colors = [
        for (final c in BlockColor.values)
          if (c != source.color) c,
      ];
      return _with(source, color: colors[random.nextInt(colors.length)]);
    case 1:
      final shapes = [
        for (final s in _flexShapes)
          if (s != source.shape && level.shapes.contains(s)) s,
      ];
      if (source.shape == BlockShape.square || shapes.isEmpty) return null;
      return _with(source, shape: shapes[random.nextInt(shapes.length)]);
    default:
      final square = source.shape == BlockShape.square;
      final table = square ? _squareWidths : _widths;
      final from = table.indexOf(source.width);
      final steps = [
        for (var i = 0; i < table.length; i++)
          if ((i - from).abs() >= 2) i,
      ];
      if (steps.isEmpty) return null;
      final width = table[steps[random.nextInt(steps.length)]];
      return _with(
        source,
        width: width,
        height: square
            ? width * 340
            : _heights[random.nextInt(_heights.length)],
      );
  }
}

Block _with(
  Block b, {
  BlockColor? color,
  BlockShape? shape,
  double? width,
  double? height,
}) => Block(
  color: color ?? b.color,
  shape: shape ?? b.shape,
  width: width ?? b.width,
  height: height ?? b.height,
);
