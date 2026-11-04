import 'package:brainquiz/game/attempt.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/progress/progress_controller.dart';
import 'package:brainquiz/progress/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'tower_build.progress';

AttemptResult result(
  int level, {
  bool stood = true,
  int stars = 3,
  int points = 100,
}) => AttemptResult(
  level: levels[level - 1],
  stood: stood,
  correct: 4,
  total: 4,
  heldSeconds: 10,
  points: stood ? points : 0,
  stars: stood ? stars : 0,
  lockStability: 80,
  fellAtSeconds: stood ? 0 : 5,
  headline: '',
  detail: '',
);

class _ThrowingStore implements ProgressStore {
  @override
  Future<Progress> load() async => Progress.empty;
  @override
  Future<void> save(Progress progress) async => throw StateError('disk full');
}

void main() {
  test('keeps best stars and best points separately', () {
    final p = Progress.empty
        .withResult(result(1, stars: 3, points: 100))
        .withResult(result(1, stars: 2, points: 200));
    expect(p.records[1]!.stars, 3);
    expect(p.records[1]!.bestPoints, 200);
  });

  test('total is the sum of bests, so replaying cannot farm', () {
    final once = Progress.empty.withResult(result(1, points: 100));
    final twice = once.withResult(result(1, points: 100));
    expect(twice.totalPoints, once.totalPoints);
    final two = twice.withResult(result(2, points: 50));
    expect(two.totalPoints, 150);
    expect(two.hasPlayed, isTrue);
    expect(Progress.empty.hasPlayed, isFalse);
  });

  test('a fall saves nothing and loses nothing', () {
    final base = Progress.empty.withResult(result(1));
    expect(identical(base.withResult(result(1, stood: false)), base), isTrue);
    expect(
      identical(
        Progress.empty.withResult(result(1, stood: false)),
        Progress.empty,
      ),
      isTrue,
    );
    expect(base.records[1]!.bestPoints, 100);
  });

  test('unlocks only the next level', () {
    expect(Progress.empty.isUnlocked(1), isTrue);
    expect(Progress.empty.isUnlocked(2), isFalse);
    expect(Progress.empty.nextLevel, 1);
    final p = Progress.empty.withResult(result(1));
    expect(p.isUnlocked(2), isTrue);
    expect(p.isUnlocked(3), isFalse);
    expect(p.nextLevel, 2);
    expect(p.allCleared, isFalse);
  });

  test('all cleared keeps next level at 12', () {
    var p = Progress.empty;
    for (var n = 1; n <= 12; n++) {
      p = p.withResult(result(n));
    }
    expect(p.allCleared, isTrue);
    expect(p.nextLevel, 12);
  });

  test('survives a store round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final p = Progress.empty
        .withResult(result(1, stars: 3, points: 120))
        .withResult(result(2, stars: 1, points: 80));
    await SharedPrefsProgressStore().save(p);
    final loaded = await SharedPrefsProgressStore().load();
    expect(loaded.records.keys.toSet(), {1, 2});
    expect(loaded.records[1]!.stars, 3);
    expect(loaded.records[1]!.bestPoints, 120);
    expect(loaded.records[2]!.stars, 1);
    expect(loaded.records[2]!.bestPoints, 80);
    expect(loaded.totalPoints, 200);
  });

  test('no saved value loads empty', () async {
    SharedPreferences.setMockInitialValues({});
    expect((await SharedPrefsProgressStore().load()).records, isEmpty);
  });

  test('corrupt or future data starts empty and does not throw', () async {
    for (final bad in [
      'not json',
      '{"version":99,"levels":{}}',
      '{"version":1,"levels":{"x":1}}',
      '[]',
      '{"version":1,"levels":{"13":{"stars":1,"points":1}}}',
      '{"version":1,"levels":{"0":{"stars":1,"points":1}}}',
      '{"version":1,"levels":{"1":{"stars":4,"points":1}}}',
      '{"version":1,"levels":{"1":{"stars":-1,"points":1}}}',
      '{"version":1,"levels":{"1":{"stars":1,"points":-5}}}',
      '{"version":1,"levels":{"1":{"stars":"3","points":1}}}',
    ]) {
      SharedPreferences.setMockInitialValues({_key: bad});
      expect(
        (await SharedPrefsProgressStore().load()).records,
        isEmpty,
        reason: bad,
      );
    }
    SharedPreferences.setMockInitialValues({_key: 5});
    expect((await SharedPrefsProgressStore().load()).records, isEmpty);
  });

  test('controller loads, records and notifies', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProgressController(SharedPrefsProgressStore());
    var notified = 0;
    c.addListener(() => notified++);
    await c.load();
    await c.record(result(1, points: 70));
    expect(c.progress.records[1]!.bestPoints, 70);
    expect(notified, greaterThan(0));
    final again = ProgressController(SharedPrefsProgressStore());
    await again.load();
    expect(again.progress.records[1]!.bestPoints, 70);
  });

  test(
    'a failing save keeps the in-memory result and does not throw',
    () async {
      final c = ProgressController(_ThrowingStore());
      await c.load();
      await c.record(result(1, points: 70));
      expect(c.progress.records[1]!.bestPoints, 70);
    },
  );

  test('formatPoints', () {
    expect(formatPoints(1240), '1,240');
    expect(formatPoints(12), '12');
    expect(formatPoints(1000000), '1,000,000');
    expect(formatPoints(0), '0');
  });
}
