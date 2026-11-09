import 'dart:ui';

import 'package:brainquiz/memory/cube_layout.dart';
import 'package:brainquiz/memory/memory_levels.dart';
import 'package:brainquiz/memory/memory_round.dart';
import 'package:flutter_test/flutter_test.dart';

MemoryRound recalling(int level, {int seed = 1}) =>
    MemoryRound(level: memoryLevels[level - 1], seed: seed)..finishStudy();

void main() {
  group('levels', () {
    test('5 cubes, then +2 x7, +5 x7, +7 x7', () {
      expect(memoryLevels.map((l) => l.cubes), [
        5, 7, 9, 11, 13, 15, 17, 19, //
        24, 29, 34, 39, 44, 49, 54, //
        61, 68, 75, 82, 89, 96, 103,
      ]);
      expect(memoryLevels.map((l) => l.number),
          List.generate(22, (i) => i + 1));
    });

    test('colours start at 4, never drop, and stop at the palette size', () {
      expect(memoryLevels.first.colors, 4);
      expect(memoryLevels.last.colors, 8);
      for (var i = 1; i < memoryLevels.length; i++) {
        expect(memoryLevels[i].colors,
            greaterThanOrEqualTo(memoryLevels[i - 1].colors));
      }
    });

    test('study time grows with the tower', () {
      for (var i = 1; i < memoryLevels.length; i++) {
        expect(memoryLevels[i].studySeconds,
            greaterThan(memoryLevels[i - 1].studySeconds));
      }
    });
  });

  group('round', () {
    test('towers are seeded, in range, and never 4 alike in a row', () {
      for (final level in memoryLevels) {
        for (var seed = 0; seed < 30; seed++) {
          final a = MemoryRound(level: level, seed: seed).target;
          expect(MemoryRound(level: level, seed: seed).target, a);
          expect(a.length, level.cubes);
          expect(a.every((c) => c >= 0 && c < level.colors), isTrue);
          for (var i = 3; i < a.length; i++) {
            expect(
                a[i] == a[i - 1] && a[i] == a[i - 2] && a[i] == a[i - 3],
                isFalse);
          }
        }
      }
      expect(MemoryRound(level: memoryLevels[5], seed: 1).target,
          isNot(MemoryRound(level: memoryLevels[5], seed: 2).target));
    });

    test('no placing during study', () {
      final r = MemoryRound(level: memoryLevels.first, seed: 1)..place(0);
      expect(r.filled, 0);
      expect(r.phase, MemoryPhase.study);
    });

    test('colours fill bottom up; tapping a cube recolours it', () {
      final r = recalling(1);
      r.place(0);
      r.place(1);
      expect(r.placed.take(2), [0, 1]);
      expect(r.cursor, 2);
      r.select(0);
      expect(r.cursor, 0);
      r.place(3);
      expect(r.placed[0], 3);
      expect(r.cursor, 2, reason: 'back to the next free slot');
    });

    test('cannot jump ahead to an empty slot past the next one', () {
      final r = recalling(1)..select(3);
      expect(r.cursor, 0);
    });

    test('undo reverts placing and recolouring', () {
      final r = recalling(1)
        ..place(0)
        ..place(1)
        ..select(0)
        ..place(2);
      r.undo();
      expect(r.placed.take(2), [0, 1]);
      expect(r.cursor, 0);
      r.undo();
      expect(r.placed[1], isNull);
      r.undo();
      expect(r.filled, 0);
      expect(r.canUndo, isFalse);
    });

    test('perfect copy: 3 stars, 10 a cube plus 3 a saved second', () {
      final r = MemoryRound(level: memoryLevels.first, seed: 7)
        ..finishStudy(secondsLeft: 4);
      r.target.forEach(r.place);
      expect(r.complete, isTrue);
      final result = r.check();
      expect(r.phase, MemoryPhase.result);
      expect(result.correct, 5);
      expect(result.stars, 3);
      expect(result.points, 50 + 12);
    });

    test('stars by share right, and a miss below three quarters', () {
      MemoryResult withRight(int correct, int total) => MemoryResult(
            level: memoryLevels.first,
            correct: correct,
            total: total,
            secondsSaved: 5,
          );
      expect(withRight(19, 19).stars, 3);
      expect(withRight(18, 19).stars, 2);
      expect(withRight(17, 19).stars, 1);
      expect(withRight(15, 19).stars, 1);
      expect(withRight(14, 19).stars, 0);
      expect(withRight(14, 19).passed, isFalse);
      expect(withRight(14, 19).points, 0);
      expect(withRight(4, 5).passed, isTrue);
      expect(withRight(3, 5).passed, isFalse);
    });
  });

  group('cube layout', () {
    const areas = [Size(280, 200), Size(330, 420), Size(388, 520), Size(54, 84)];

    test('every level fits, with no overlaps, and taps find the cube', () {
      for (final area in areas) {
        for (final level in memoryLevels) {
          final layout = CubeLayout(level.cubes, area);
          final rects = [
            for (var i = 0; i < level.cubes; i++) layout.rectOf(i),
          ];
          final bounds = (Offset.zero & area).inflate(0.01);
          for (var i = 0; i < rects.length; i++) {
            expect(bounds.contains(rects[i].topLeft), isTrue);
            expect(bounds.contains(rects[i].bottomRight), isTrue);
            expect(layout.indexAt(rects[i].center), i);
            for (var j = i + 1; j < rects.length; j++) {
              expect(rects[i].intersect(rects[j]).isEmpty ||
                      rects[i].intersect(rects[j]).width <= 0 ||
                      rects[i].intersect(rects[j]).height <= 0,
                  isTrue);
            }
          }
        }
      }
    });

    test('towers fill bottom up, left tower first, tallest first', () {
      final layout = CubeLayout(11, const Size(200, 200));
      expect(layout.columns, greaterThan(1));
      expect(layout.rectOf(1).bottom, layout.rectOf(0).top);
      final heights = layout.columnHeights;
      expect(heights.reduce((a, b) => a + b), 11);
      for (var i = 1; i < heights.length; i++) {
        expect(heights[i], lessThanOrEqualTo(heights[i - 1]));
      }
      expect(layout.rectOf(heights.first).left,
          greaterThan(layout.rectOf(0).right));
    });

    test('103 cubes stay tappable on a small phone', () {
      final layout = CubeLayout(103, const Size(240, 230));
      expect(layout.cube, greaterThanOrEqualTo(20));
    });

    test('a short tower is one column, not giant cubes', () {
      final layout = CubeLayout(5, const Size(330, 420));
      expect(layout.columns, 1);
      expect(layout.cube, lessThanOrEqualTo(72));
    });
  });
}
