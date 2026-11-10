import 'dart:math' as math;

import 'package:brainquiz/game/attempt.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/ui/widgets/collapse_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final level in [4, 8, 12]) {
    for (final (width, height) in [(338.0, 440.0), (280.0, 300.0)]) {
      for (final direction in [-1, 1]) {
        test('level $level rests inside the arena, above the floor '
            '(${width.toInt()}x${height.toInt()}, dir $direction)', () {
          final a = Attempt(level: levels[level - 1], seed: 42)..finishStudy();
          for (final b in a.tower.blocks) {
            a.drop(b, 0);
          }
          for (var seed = 0; seed < 25; seed++) {
            final plan = planCollapse(
              placed: a.placed,
              seed: seed,
              direction: direction,
              width: width,
              availableHeight: height,
            );
            expect(
              plan.falls.length,
              level == 12 ? 11 : levels[level - 1].blocks + 1,
            );
            for (final f in plan.falls) {
              final r = f.rest;
              expect(r.left, greaterThanOrEqualTo(-1e-6), reason: 'seed $seed');
              expect(r.right, lessThanOrEqualTo(width + 1e-6));
              expect(r.low, greaterThanOrEqualTo(plan.floorTop - 1e-6));
              expect(r.high, lessThanOrEqualTo(height + 1e-6));
            }
          }
        });
      }
    }
  }

  test('the same seed gives the same scatter', () {
    final a = Attempt(level: levels[7], seed: 42)..finishStudy();
    for (final b in a.tower.blocks) {
      a.drop(b, 0);
    }
    CollapsePlan plan() => planCollapse(
      placed: a.placed,
      seed: 3,
      direction: 1,
      width: 338,
      availableHeight: 440,
    );
    final x = plan(), y = plan();
    for (var i = 0; i < x.falls.length; i++) {
      expect(x.falls[i].rest, y.falls[i].rest);
      expect(x.falls[i].angle, y.falls[i].angle);
    }
  });

  for (final direction in [-1, 1]) {
    test('blocks land the way the tower fell, spread out '
        '(dir $direction)', () {
      final a = Attempt(level: levels[7], seed: 42)..finishStudy();
      for (final b in a.tower.blocks) {
        a.drop(b, 0);
      }
      final plan = planCollapse(
        placed: a.placed,
        seed: 3,
        direction: direction,
        width: 338,
        availableHeight: 440,
      );
      final xs = [for (final f in plan.falls.skip(1)) f.endX]..sort();
      expect(xs.last - xs.first, greaterThan(338 * 0.3));
      final mean = xs.reduce((p, q) => p + q) / xs.length;
      expect(direction * (mean - 169), greaterThan(0));
      // Nothing lands far behind the plinth.
      for (final x in xs) {
        expect(direction * (x - 169), greaterThan(-338 * 0.15 - 1e-6));
      }
    });
  }

  test('the collapse starts from the lean it fell at and ends on the '
      'rest spots', () {
    final a = Attempt(level: levels[7], seed: 42)..finishStudy();
    for (final b in a.tower.blocks) {
      a.drop(b, 0);
    }
    final plan = planCollapse(
      placed: a.placed,
      seed: 3,
      direction: 1,
      width: 338,
      availableHeight: 440,
    );
    expect(plan.falls.last.poseAt(0).angle, closeTo(12 * math.pi / 180, 1e-9));
    for (final f in plan.falls) {
      expect(f.landAt, lessThanOrEqualTo(collapseSeconds));
      final end = f.poseAt(collapseSeconds);
      expect(end.x, closeTo(f.endX, 1e-6));
      expect(end.y, closeTo(f.endY, 1e-6));
      expect(end.angle, closeTo(f.angle, 1e-6));
    }
  });
}
