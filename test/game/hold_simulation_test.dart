import 'dart:math';

import 'package:brainquiz/game/hold_simulation.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:flutter_test/flutter_test.dart';

void run(HoldSimulation s) {
  while (!s.fallen && !s.finished) {
    s.step(1 / 60);
  }
}

void main() {
  test('finishes exactly at the hold time when it stands', () {
    final s = HoldSimulation(
      level: levels[3],
      stabilityScore: 100,
      mustFall: false,
      seed: 1,
      braces: 0,
    );
    run(s);
    expect(s.fallen, isFalse);
    expect(s.finished, isTrue);
    expect(s.elapsed, closeTo(18, 0.05));
    expect(s.secondsLeft, 0);
  });

  test('gusts fit inside the hold, one per slot, at least 2.5s long', () {
    for (final level in levels) {
      for (var seed = 0; seed < 300; seed++) {
        final gusts = scheduleGusts(level, Random(seed));
        expect(gusts.length, level.gusts);
        final slot = level.holdSeconds / level.gusts;
        for (var i = 0; i < gusts.length; i++) {
          final g = gusts[i];
          expect(g.start, greaterThanOrEqualTo(i * slot - 1e-9));
          expect(
            g.start + g.duration,
            lessThanOrEqualTo((i + 1) * slot + 1e-9),
          );
          expect(g.start + g.duration, lessThanOrEqualTo(level.holdSeconds));
          expect(g.duration, greaterThanOrEqualTo(2.5));
          expect(g.amplitude, inInclusiveRange(0.8, 1.0));
          expect(g.direction.abs(), 1);
        }
      }
    }
  });

  test('a huge dt cannot skip time, as when returning from background', () {
    final s = HoldSimulation(
      level: levels[3],
      stabilityScore: 100,
      mustFall: false,
      seed: 1,
      braces: 0,
    );
    s.step(60);
    expect(s.elapsed, closeTo(0.05, 1e-9));
    expect(clampedDt(60), 0.05);
    expect(clampedDt(0.01), 0.01);
  });

  test('brace halves the lean and is limited', () {
    final s = HoldSimulation(
      level: levels[3],
      stabilityScore: 30,
      mustFall: false,
      seed: 3,
      braces: 1,
    );
    while (s.leanDegrees.abs() <= 1 && !s.fallen && !s.finished) {
      s.step(1 / 60);
    }
    final before = s.leanDegrees;
    expect(before.abs(), greaterThan(1));
    expect(s.bracesLeft, 1);
    expect(s.brace(), isTrue);
    expect(s.leanDegrees, closeTo(before / 2, 1e-9));
    expect(s.bracesLeft, 0);
    expect(s.bracesUsed, 1);
    expect(s.brace(), isFalse);
    expect(s.bracesUsed, 1);
  });

  test('brace is refused after the round is over', () {
    final s = HoldSimulation(
      level: levels[0],
      stabilityScore: 100,
      mustFall: false,
      seed: 1,
      braces: 2,
    );
    run(s);
    expect(s.brace(), isFalse);
  });

  test('gust index and wind flag follow the schedule', () {
    final s = HoldSimulation(
      level: levels[3],
      stabilityScore: 100,
      mustFall: false,
      seed: 5,
      braces: 0,
    );
    expect(s.gustIndex, 0);
    var maxIndex = 0;
    var sawWind = false;
    while (!s.finished) {
      s.step(1 / 60);
      maxIndex = max(maxIndex, s.gustIndex);
      sawWind |= s.windActive;
    }
    expect(maxIndex, 3);
    expect(sawWind, isTrue);
    expect(s.stabilityPercent, inInclusiveRange(0, 100));
  });

  test('brace eases lean for 4 seconds, and a second brace restarts it', () {
    final level = levels[11];
    HoldSimulation make() => HoldSimulation(
      level: level,
      stabilityScore: 70,
      mustFall: false,
      seed: 2,
      braces: 2,
    );
    // The second gust starts at 8s or later, so braces can precede it.
    final gust = scheduleGusts(level, Random(2))[1];
    final plain = make(), during = make(), once = make(), twice = make();
    void stepAll(double t) {
      for (final s in [plain, during, once, twice]) {
        while (s.elapsed < t) {
          s.step(1 / 60);
        }
      }
    }

    // During a gust, a brace gives a lower lean than an identical hold.
    stepAll(gust.start + 0.5);
    expect(during.brace(), isTrue);
    stepAll(gust.start + 2);
    expect(plain.leanDegrees.abs(), greaterThan(1));
    expect(during.leanDegrees.abs(), lessThan(plain.leanDegrees.abs()));

    // Braces before the gust: a single one covers 4s, a second restarts it.
    final first = gust.start - 3.5;
    final fresh = [make(), make(), make()]; // plain, once, twice
    for (final s in fresh) {
      while (s.elapsed < first) {
        s.step(1 / 60);
      }
    }
    expect(fresh[1].brace(), isTrue);
    expect(fresh[2].brace(), isTrue);
    void stepFresh(double t) {
      for (final s in fresh) {
        while (s.elapsed < t) {
          s.step(1 / 60);
        }
      }
    }

    stepFresh(gust.start - 1);
    expect(fresh[2].brace(), isTrue); // window now runs to gust.start + 3
    // At gust.start + 2 the first window (ended at +0.5) is over for "once"
    // but still running for "twice": twice leans less, and once is back to
    // the unbraced lean.
    stepFresh(gust.start + 2);
    expect(fresh[2].leanDegrees.abs(), lessThan(fresh[1].leanDegrees.abs()));
    expect(fresh[2].leanDegrees.abs(), lessThan(fresh[0].leanDegrees.abs()));
    // The restarted window itself ends: a few seconds later the twice-braced
    // hold has caught up with the unbraced one (gust 2 is 5s long, so ends
    // at gust.start + 5).
    stepFresh(gust.start + 4.9);
    expect(fresh[1].leanDegrees, closeTo(fresh[0].leanDegrees, 0.5));
    expect(fresh[2].leanDegrees, closeTo(fresh[0].leanDegrees, 1.5));
    expect(fresh[2].bracesUsed, 2);
  });
}
