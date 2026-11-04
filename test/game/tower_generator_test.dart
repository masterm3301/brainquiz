import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/game/tower_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _seeds = 200;

void _forEach(void Function(LevelConfig level, int seed) body) {
  for (final level in levels) {
    for (var seed = 0; seed < _seeds; seed++) {
      body(level, seed);
    }
  }
}

List<Block> _decoys(GeneratedTower t) {
  final real = t.blocks.toSet();
  return [
    for (final b in t.tray)
      if (!real.contains(b)) b,
  ];
}

int _attributeDiffs(Block a, Block b) =>
    (a.color != b.color ? 1 : 0) +
    (a.shape != b.shape ? 1 : 0) +
    (a.width != b.width || a.height != b.height ? 1 : 0);

void main() {
  test('sizes: blocks and tray match the level', () {
    _forEach((level, seed) {
      final t = generateTower(level, seed);
      expect(t.seed, seed);
      expect(t.blocks.length, level.blocks);
      expect(t.tray.length, level.blocks + level.decoys);
    });
  });

  test('same seed gives the same tower', () {
    _forEach((level, seed) {
      final a = generateTower(level, seed);
      final b = generateTower(level, seed);
      expect(listEquals(a.blocks, b.blocks), isTrue);
      expect(listEquals(a.tray, b.tray), isTrue);
    });
  });

  test('never repeats the previous tower', () {
    for (final level in levels) {
      var previous = <Block>[];
      for (var seed = 0; seed < _seeds; seed++) {
        final t = generateTower(level, seed, previous: previous);
        expect(listEquals(t.blocks, previous), isFalse);
        previous = t.blocks;
      }
    }
  });

  test('a repeat is avoided even when the same seed is replayed', () {
    for (final level in levels) {
      final first = generateTower(level, 7);
      final again = generateTower(level, 7, previous: first.blocks);
      expect(listEquals(again.blocks, first.blocks), isFalse);
      expect(again.seed, 7);
    }
  });

  test('every tray block is distinct, so a choice is never ambiguous', () {
    _forEach((level, seed) {
      final t = generateTower(level, seed);
      expect(t.tray.toSet().length, t.tray.length);
    });
  });

  test('no two tray blocks share colour, shape, and width', () {
    _forEach((level, seed) {
      final tray = generateTower(level, seed).tray;
      final looks = {for (final b in tray) (b.color, b.shape, b.width)};
      expect(
        looks.length,
        tray.length,
        reason: 'level ${level.number} seed $seed',
      );
    });
  });

  test('tray contains every tower block', () {
    _forEach((level, seed) {
      final t = generateTower(level, seed);
      expect(t.tray.toSet().containsAll(t.blocks), isTrue);
    });
  });

  test('uses only the level shapes and colour count', () {
    _forEach((level, seed) {
      final t = generateTower(level, seed);
      expect(
        level.shapes.toSet().containsAll(t.blocks.map((b) => b.shape)),
        isTrue,
      );
      final colors = t.blocks.map((b) => b.color).toSet();
      expect(colors.length, lessThanOrEqualTo(level.colorCount));
      expect(colors.every((c) => c.index < level.colorCount), isTrue);
    });
  });

  test('tower blocks are never red; only decoys may be', () {
    var sawRedDecoy = false;
    _forEach((level, seed) {
      final t = generateTower(level, seed);
      expect(t.blocks.any((b) => b.color == BlockColor.red), isFalse);
      if (_decoys(t).any((b) => b.color == BlockColor.red)) sawRedDecoy = true;
    });
    expect(sawRedDecoy, isTrue);
  });

  test('towers taper: the bottom block is at least as wide as the top', () {
    _forEach((level, seed) {
      final t = generateTower(level, seed);
      expect(t.blocks.first.width, greaterThanOrEqualTo(t.blocks.last.width));
    });
  });

  test('block dimensions come from the allowed sets', () {
    const widths = [.30, .42, .54, .66, .78, .90];
    const heights = [26.0, 34.0, 44.0];
    const squares = [.16, .22, .28];
    _forEach((level, seed) {
      for (final b in generateTower(level, seed).blocks) {
        if (b.shape == BlockShape.square) {
          expect(squares, contains(b.width));
          expect(b.height, closeTo(b.width * 340, 1e-9));
        } else {
          expect(widths, contains(b.width));
          expect(heights, contains(b.height));
        }
      }
    });
  });

  test('from level 7, decoys differ from some real block in exactly one '
      'attribute', () {
    for (final level in levels.where((l) => l.number >= 7)) {
      for (var seed = 0; seed < _seeds; seed++) {
        final t = generateTower(level, seed);
        final decoys = _decoys(t);
        expect(decoys.length, level.decoys);
        for (final d in decoys) {
          expect(
            t.blocks.any((r) => _attributeDiffs(d, r) == 1),
            isTrue,
            reason: 'level ${level.number} seed $seed decoy $d',
          );
        }
      }
    }
  });
}
