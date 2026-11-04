import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/game/stability.dart';
import 'package:flutter_test/flutter_test.dart';

Block blockOf(BlockColor color, double width, double height) => Block(
      color: color,
      shape: BlockShape.rectangle,
      width: width,
      height: height,
    );

Block recolour(Block b) => Block(
      color: b.color == BlockColor.red ? BlockColor.cyan : BlockColor.red,
      shape: b.shape,
      width: b.width,
      height: b.height,
    );

List<PlacedBlock> straight(Iterable<Block> blocks) =>
    [for (final b in blocks) PlacedBlock(b, 0)];

final target = [
  blockOf(BlockColor.green, 0.9, 44),
  blockOf(BlockColor.cyan, 0.7, 34),
  blockOf(BlockColor.yellow, 0.5, 26),
];
final level3 = levels[2];
final level2 = levels[1];

StabilityReport reportWithScore(int score) => StabilityReport(
      score: score,
      mustFall: false,
      wrongRows: const [],
      crooked: const [],
      topHeavy: false,
      meterLine: meterLineFor(score),
    );

final perfectReport =
    assessStability(target: target, placed: straight(target), level: level3);

void main() {
  test('a straight perfect copy scores 100 at every prefix', () {
    for (var n = 0; n <= target.length; n++) {
      final r = assessStability(
          target: target, placed: straight(target.take(n)), level: level3);
      expect(r.score, 100);
      expect(r.mustFall, isFalse);
    }
  });
  test('snapDrop snaps to the centre line, then to the block below', () {
    expect(snapDrop(0.03, belowX: 0), 0);
    expect(snapDrop(0.05, belowX: 0), 0.05);
    expect(snapDrop(0.31, belowX: 0.3), 0.3);
    expect(snapDrop(0.02, belowX: 0.3), 0);
  });
  test('wrong colour alone is a wrong block', () {
    final r = assessStability(
        target: target,
        placed: straight([recolour(target[0]), target[1], target[2]]),
        level: level3);
    expect(r.wrongRows, [1]);
    expect(r.score, 78);
    expect(r.mustFall, isFalse);
  });
  test('two wrong blocks must fall from level 3, not on level 2', () {
    final placed =
        straight([recolour(target[0]), recolour(target[1]), target[2]]);
    final l3 =
        assessStability(target: target, placed: placed, level: level3);
    expect(l3.mustFall, isTrue);
    expect(l3.score, lessThanOrEqualTo(35));
    expect(assessStability(target: target, placed: placed, level: level2)
        .mustFall, isFalse);
  });
  test('a crooked drop lowers the score and records row and side', () {
    final placed = [
      PlacedBlock(target[0], 0),
      PlacedBlock(target[1], -0.12),
      PlacedBlock(target[2], -0.12),
    ];
    final r = assessStability(target: target, placed: placed, level: level3);
    expect(r.wrongRows, isEmpty);
    expect(r.score, lessThan(100));
    expect(r.crooked.single.row, 2);
    expect(r.crooked.single.side, Side.left);
  });
  test('wide block too high is top heavy', () {
    final r = assessStability(
        target: target, placed: straight(target.reversed), level: level3);
    expect(r.topHeavy, isTrue);
  });
  test('touchesBelow needs real overlap', () {
    expect(touchesBelow(target[1], 0.4, null), isTrue);
    expect(touchesBelow(target[1], 0.5, null), isFalse);
    expect(touchesBelow(target[2], 0.0, PlacedBlock(target[0], 0)), isTrue);
  });
  test('meter line follows the score', () {
    expect(perfectReport.meterLine, 'Centre of mass still over the pillar.');
    expect(reportWithScore(55).meterLine,
        'Getting shaky. Centre of mass is drifting.');
    expect(reportWithScore(20).meterLine, 'Too unstable to last in the wind.');
  });
}
