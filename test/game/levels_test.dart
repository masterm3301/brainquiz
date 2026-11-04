import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('level table matches the spec', () {
    const table = [
      // blocks, study, hold, gusts, decoys
      [3, 6, 8, 1, 0], [4, 6, 10, 1, 0], [5, 6, 14, 2, 2], [6, 6, 18, 3, 4],
      [7, 6, 22, 3, 4], [7, 5, 24, 3, 4], [8, 5, 26, 3, 5], [8, 5, 28, 4, 5],
      [9, 4, 30, 4, 6], [9, 4, 32, 4, 6], [10, 4, 35, 5, 7], [10, 3, 40, 5, 7],
    ];
    expect(levels, hasLength(12));
    for (var i = 0; i < 12; i++) {
      final l = levels[i];
      expect([
        l.blocks,
        l.studySeconds,
        l.holdSeconds,
        l.gusts,
        l.decoys,
      ], table[i]);
      expect(l.number, i + 1);
    }
  });

  test('wind and shape progression', () {
    expect(levels.first.windStrength, closeTo(0.8, 1e-9));
    expect(levels.last.windStrength, closeTo(1.0, 1e-9));
    expect(levels[1].wrongLimitApplies, isFalse);
    expect(levels[2].wrongLimitApplies, isTrue);
    expect(levels[1].shapes, [BlockShape.rectangle, BlockShape.square]);
    expect(levels[2].shapes, contains(BlockShape.triangle));
    expect(levels[3].shapes, isNot(contains(BlockShape.invertedTriangle)));
    expect(levels[4].shapes, contains(BlockShape.invertedTriangle));
    expect(levels[1].colorCount, 2);
    expect(levels[2].colorCount, 3);
  });
}
