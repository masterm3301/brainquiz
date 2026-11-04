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

/// Runs a hold, spending braces per [plan]: a list of (gust number, offset s).
bool fallsWithPlan(
  LevelConfig level,
  StabilityReport report,
  int seed,
  List<int> braceGusts,
) {
  final s = sim(
    level,
    report.score,
    seed,
    mustFall: report.mustFall,
    braces: braceGusts.length,
  );
  final gusts = scheduleGusts(level, Random(seed));
  final pending = [for (final g in braceGusts) gusts[g].start];
  while (!s.fallen && !s.finished) {
    s.step(1 / 60);
    for (var i = pending.length - 1; i >= 0; i--) {
      if (s.elapsed >= pending[i]) {
        s.brace();
        pending.removeAt(i);
      }
    }
  }
  return s.fallen;
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
      final last = level.gusts - 1;
      final plans = <List<int>>[
        [],
        [0, 0],
        [last, last],
        [level.gusts - 2, last],
      ];
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
        for (final plan in plans) {
          expect(
            fallsWithPlan(level, r, seed, plan),
            isTrue,
            reason:
                'level ${level.number} seed $seed braces at gusts $plan '
                'score ${r.score}',
          );
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
        final picks = [
          for (var i = 0; i < level.blocks; i++)
            t.tray[rng.nextInt(t.tray.length)],
        ];
        final r = assessStability(
          target: t.blocks,
          placed: straight(picks),
          level: level,
        );
        if (!fallsWithPlan(level, r, seed, [
          level.gusts - 1,
          level.gusts - 1,
        ])) {
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
