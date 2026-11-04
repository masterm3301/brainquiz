import 'package:brainquiz/game/attempt.dart';
import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/hold_simulation.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:flutter_test/flutter_test.dart';

Attempt _attempt(int level) =>
    Attempt(level: levels[level - 1], seed: 7)..finishStudy();

void _placeAll(Attempt a) {
  for (final b in a.tower.blocks) {
    expect(a.drop(b, 0), DropOutcome.placed);
  }
}

HoldSimulation _run(HoldSimulation sim) {
  for (var i = 0; i < 20000 && !sim.fallen && !sim.finished; i++) {
    sim.step(0.05);
  }
  return sim;
}

void main() {
  test('starts in memorise and finishStudy moves to build', () {
    final a = Attempt(level: levels[0], seed: 1);
    expect(a.phase, AttemptPhase.memorise);
    expect(a.drop(a.tray.first, 0), DropOutcome.returnedToTray);
    a.finishStudy();
    expect(a.phase, AttemptPhase.build);
  });

  group('drop rules', () {
    test('off-tower drop returns to tray and changes nothing', () {
      final a = _attempt(1);
      final trayBefore = [...a.tray];
      expect(a.drop(a.tray.first, 0.9), DropOutcome.returnedToTray);
      expect(a.tray, trayBefore);
      expect(a.placed, isEmpty);
    });

    test('valid drop moves block from tray to placed', () {
      final a = _attempt(1);
      final b = a.tower.blocks.first;
      final before = a.tray.length;
      expect(a.drop(b, 0.05), DropOutcome.placed);
      expect(a.tray.length, before - 1);
      expect(a.placed.single.block, b);
    });

    test('drop within tolerance snaps to the centre line', () {
      final a = _attempt(1);
      a.drop(a.tower.blocks.first, 0.02);
      expect(a.placed.single.x, 0);
    });

    test('drop near the block below snaps to its x', () {
      final a = _attempt(1);
      a.drop(a.tower.blocks[0], 0.1);
      a.drop(a.tower.blocks[1], 0.12);
      expect(a.placed[1].x, 0.1);
    });

    test('a block not in the tray is returned', () {
      final a = _attempt(1);
      const stranger = Block(
        color: BlockColor.red,
        shape: BlockShape.square,
        width: 0.99,
        height: 10,
      );
      expect(a.drop(stranger, 0), DropOutcome.returnedToTray);
      expect(a.placed, isEmpty);
    });

    test('cannot drop more than the level has rows', () {
      final a = _attempt(4);
      _placeAll(a);
      expect(a.drop(a.tray.first, 0), DropOutcome.returnedToTray);
      expect(a.placed.length, a.level.blocks);
    });
  });

  group('flow and limits', () {
    test('lock is ignored until every row is filled', () {
      final a = _attempt(1);
      expect(a.canLock, isFalse);
      a.lock();
      expect(a.phase, AttemptPhase.build);
      _placeAll(a);
      expect(a.canLock, isTrue);
      a.lock();
      expect(a.phase, AttemptPhase.windReady);
    });

    test('second look once, only in build', () {
      final a = _attempt(1);
      expect(a.earnSecondLook(), isTrue);
      expect(a.secondLookUsed, isTrue);
      expect(a.earnSecondLook(), isFalse);
      final b = Attempt(level: levels[0], seed: 1);
      expect(b.earnSecondLook(), isFalse);
    });

    test('ad brace only in windReady, once', () {
      final a = _attempt(1);
      expect(a.earnAdBrace(), isFalse);
      _placeAll(a);
      a.lock();
      expect(a.earnAdBrace(), isTrue);
      expect(a.adBraceEarned, isTrue);
      expect(a.earnAdBrace(), isFalse);
    });

    test('startHold gives 1 brace, or 2 with the ad', () {
      final a = _attempt(1);
      _placeAll(a);
      a.lock();
      final sim = a.startHold();
      expect(a.phase, AttemptPhase.hold);
      expect(sim.bracesLeft, 1);

      final b = _attempt(1);
      _placeAll(b);
      b.lock();
      b.earnAdBrace();
      expect(b.startHold().bracesLeft, 2);
    });

    test('ad brace is spent first, but usedBrace still caps stars', () {
      final a = _attempt(4);
      _placeAll(a);
      a.lock();
      a.earnAdBrace();
      final sim = a.startHold();
      expect(sim.brace(), isTrue);
      _run(sim);
      expect(sim.finished, isTrue);
      final r = a.finish(sim);
      expect(r.stood, isTrue);
      expect(r.correct, 6);
      expect(r.points, 30 * 6 + (sim.elapsed.floor() * 10 / 3).round());
      expect(r.stars, lessThanOrEqualTo(2));
      expect(r.stars, 2);
    });

    test('a paid brace costs 40', () {
      final a = _attempt(4);
      _placeAll(a);
      a.lock();
      final sim = a.startHold();
      sim.brace();
      _run(sim);
      final r = a.finish(sim);
      expect(r.points, 30 * 6 + (sim.elapsed.floor() * 10 / 3).round() - 40);
    });

    test('perfect stand scores full and three stars', () {
      final a = _attempt(4);
      _placeAll(a);
      a.lock();
      final sim = _run(a.startHold());
      final r = a.finish(sim);
      expect(r.stood, isTrue);
      expect(r.heldSeconds, 18);
      expect(r.points, 240);
      expect(r.stars, 3);
      expect(r.fellAtSeconds, 0);
      expect(r.lockStability, a.report.score);
      expect(a.phase, AttemptPhase.result);
    });

    test('a fallen sim gives 0 points, 0 stars, fellAtSeconds', () {
      final a = _attempt(4);
      final decoys = [...a.tray]..removeWhere(a.tower.blocks.contains);
      // Fill every row with decoys and spare blocks so rows are wrong.
      final wrongOrder = [...decoys, ...a.tower.blocks.reversed];
      for (final b in wrongOrder.take(a.level.blocks)) {
        expect(a.drop(b, 0), DropOutcome.placed);
      }
      expect(a.report.mustFall, isTrue);
      a.lock();
      final sim = _run(a.startHold());
      expect(sim.fallen, isTrue);
      final r = a.finish(sim);
      expect(r.stood, isFalse);
      expect(r.points, 0);
      expect(r.stars, 0);
      expect(
        r.fellAtSeconds,
        sim.elapsed.floor() < 1 ? 1 : sim.elapsed.floor(),
      );
      expect(r.headline, contains('wrong'));
    });

    test('a second finish returns the identical result', () {
      final a = _attempt(1);
      _placeAll(a);
      a.lock();
      final sim = _run(a.startHold());
      final r = a.finish(sim);
      expect(identical(a.finish(sim), r), isTrue);
    });
  });
}
