import 'block.dart';

class LevelConfig {
  const LevelConfig({
    required this.number,
    required this.blocks,
    required this.studySeconds,
    required this.holdSeconds,
    required this.gusts,
    required this.decoys,
    required this.colorCount,
    required this.shapes,
  });

  final int number;
  final int blocks;
  final int studySeconds;
  final int holdSeconds;
  final int gusts;
  final int decoys;
  final int colorCount;
  final List<BlockShape> shapes;

  double get windStrength => 0.8 + (number - 1) * 0.2 / 11;

  bool get wrongLimitApplies => number >= 3;
}

const _basic = [BlockShape.rectangle, BlockShape.square];
const _withTriangle = [..._basic, BlockShape.triangle];
const _allShapes = [..._withTriangle, BlockShape.invertedTriangle];

// number, blocks, study, hold, gusts, decoys, colors, shapes
final List<LevelConfig> levels = [
  _l(1, 3, 6, 8, 1, 0, 2, _basic),
  _l(2, 4, 6, 10, 1, 0, 2, _basic),
  _l(3, 5, 6, 14, 2, 2, 3, _withTriangle),
  _l(4, 6, 6, 18, 3, 4, 3, _withTriangle),
  _l(5, 7, 6, 22, 3, 4, 3, _allShapes),
  _l(6, 7, 5, 24, 3, 4, 3, _allShapes),
  _l(7, 8, 5, 26, 3, 5, 4, _allShapes),
  _l(8, 8, 5, 28, 4, 5, 4, _allShapes),
  _l(9, 9, 4, 30, 4, 6, 4, _allShapes),
  _l(10, 9, 4, 32, 4, 6, 4, _allShapes),
  _l(11, 10, 4, 35, 5, 7, 4, _allShapes),
  _l(12, 10, 3, 40, 5, 7, 4, _allShapes),
];

LevelConfig _l(
  int n,
  int blocks,
  int study,
  int hold,
  int gusts,
  int decoys,
  int colors,
  List<BlockShape> shapes,
) => LevelConfig(
  number: n,
  blocks: blocks,
  studySeconds: study,
  holdSeconds: hold,
  gusts: gusts,
  decoys: decoys,
  colorCount: colors,
  shapes: shapes,
);
