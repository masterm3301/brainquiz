import 'dart:math';

import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/hold_simulation.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/game/stability.dart';
import 'package:brainquiz/game/tower_generator.dart';
import 'package:flutter_test/flutter_test.dart';

const seeds = 300;

void run(HoldSimulation s) {
  while (!s.fallen && !s.finished) {
    s.step(1 / 60);
  }
}

HoldSimulation sim(
  LevelConfig level,
  int score,
  int seed, {
  bool mustFall = false,
  int braces = 0,
}) => HoldSimulation(
  level: level,
  stabilityScore: score,
  mustFall: mustFall,
  seed: seed,
  braces: braces,
);

List<PlacedBlock> straight(List<Block> blocks) => [
  for (final b in blocks) PlacedBlock(b, 0),
];

enum BracePlan { never, reactive, spaced }

const _reactiveLean = 9.0;

/// Runs a whole hold with two braces available, spent per [plan]:
/// never; reactive (whenever |lean| first exceeds 9 degrees, and again the
/// next time it exceeds 9 after dropping back); or spaced (start of gust 1,
/// then 2 seconds later).
HoldSimulation holdWithPlan(
  LevelConfig level,
  StabilityReport report,
  int seed,
  BracePlan plan,
) {
  final s = sim(
    level,
    report.score,
    seed,
    mustFall: report.mustFall,
    braces: plan == BracePlan.never ? 0 : 2,
  );
  final firstGust = scheduleGusts(level, Random(seed)).first.start;
  var armed = true;
  while (!s.fallen && !s.finished) {
    s.step(1 / 60);
    if (plan == BracePlan.reactive) {
      if (s.leanDegrees.abs() <= _reactiveLean) {
        armed = true;
      } else if (armed && !s.fallen) {
        s.brace();
        armed = false;
      }
    } else if (plan == BracePlan.spaced) {
      if (s.bracesUsed == 0 && s.elapsed >= firstGust) {
        s.brace();
      } else if (s.bracesUsed == 1 && s.elapsed >= firstGust + 2) {
        s.brace();
      }
    }
  }
  return s;
}

void main() {
  test('a perfect copy never falls, at any level, with no brace', () {
    for (final level in levels) {
      for (var seed = 0; seed < seeds; seed++) {
        final t = generateTower(level, seed);
        final r = assessStability(
          target: t.blocks,
          placed: straight(t.blocks),
          level: level,
        );
        final s = sim(level, r.score, seed, mustFall: r.mustFall);
        run(s);
        expect(s.fallen, isFalse, reason: 'level ${level.number} seed $seed');
      }
    }
  });

  test('any tower scoring 70 or more never falls', () {
    for (final level in levels) {
      for (var seed = 0; seed < seeds; seed++) {
        final score = 70 + seed % 31;
        final s = sim(level, score, seed);
        run(s);
        expect(
          s.fallen,
          isFalse,
          reason: 'level ${level.number} seed $seed score $score',
        );
      }
    }
  });

  test('a score below 40 falls at least 90% of the time', () {
    for (final level in levels) {
      var fell = 0;
      for (var seed = 0; seed < seeds; seed++) {
        final s = sim(level, seed % 40, seed);
        run(s);
        if (s.fallen) fell++;
      }
      expect(
        fell / seeds,
        greaterThanOrEqualTo(0.9),
        reason: 'level ${level.number}: $fell of $seeds fell',
      );
    }
  });

  test('from level 3, two wrong blocks always fall, with any brace timing', () {
    for (final level in levels.where((l) => l.wrongLimitApplies)) {
      for (var seed = 0; seed < seeds; seed++) {
        final t = generateTower(level, seed);
        // Swap two rows for decoys so exactly two rows are wrong.
        final extras = [
          for (final b in t.tray)
            if (!t.blocks.contains(b)) b,
        ];
        final wrong = [...t.blocks];
        wrong[0] = extras[0];
        wrong[1] = extras[1];
        final r = assessStability(
          target: t.blocks,
          placed: straight(wrong),
          level: level,
        );
        expect(r.mustFall, isTrue);
        for (final plan in BracePlan.values) {
          final s = holdWithPlan(level, r, seed, plan);
          final reason =
              'level ${level.number} seed $seed plan $plan score ${r.score}';
          expect(s.fallen, isTrue, reason: reason);
          if (plan == BracePlan.reactive) {
            expect(s.bracesUsed, 2, reason: 'both braces spent: $reason');
          }
          if (plan == BracePlan.spaced) {
            // A must-fall tower topples inside the 2s gap in every run, so
            // the second brace is never reached; the first is always spent.
            expect(s.bracesUsed, greaterThanOrEqualTo(1), reason: reason);
          }
        }
      }
    }
  });

  test('from level 3, a player with no memory clears at most 2%', () {
    for (final level in levels.where((l) => l.wrongLimitApplies)) {
      var cleared = 0;
      for (var seed = 0; seed < seeds; seed++) {
        final t = generateTower(level, seed);
        final rng = Random(seed + 7777);
        final picks = ([...t.tray]..shuffle(rng)).take(level.blocks).toList();
        final r = assessStability(
          target: t.blocks,
          placed: straight(picks),
          level: level,
        );
        if (!holdWithPlan(level, r, seed, BracePlan.reactive).fallen) {
          cleared++;
        }
      }
      expect(
        cleared / seeds,
        lessThanOrEqualTo(0.02),
        reason: 'level ${level.number}: $cleared of $seeds cleared',
      );
    }
  });
}
