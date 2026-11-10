import 'package:brainquiz/ads/rewarded_ads.dart';
import 'package:brainquiz/memory/memory_levels.dart';
import 'package:brainquiz/memory/memory_round.dart';
import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/progress/progress_store.dart';
import 'package:brainquiz/ui/app_scope.dart';
import 'package:brainquiz/ui/screens/memory_game_screen.dart';
import 'package:brainquiz/ui/screens/memory_levels_screen.dart';
import 'package:brainquiz/ui/screens/menu_screen.dart';
import 'package:brainquiz/ui/widgets/cube_tower.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_ads.dart';
import '../support/flow_helpers.dart' show phone, pumpSeconds;
import '../support/pump_app.dart';

/// The round the screen builds (pumpApp seeds every round with 42).
List<int> answer(int level) =>
    MemoryRound(level: memoryLevels[level - 1], seed: 42).target;

String title(WidgetTester t) =>
    t.widget<Text>(find.byKey(const ValueKey('memory-title'))).data!;

Future<void> openLevel(WidgetTester t, int level,
    {Progress? memory, RewardedAds? ads, int Function()? newSeed}) async {
  await pumpApp(
    t,
    memoryProgress: memory ?? Progress.empty,
    ads: ads,
    newSeed: newSeed,
    home: MemoryGameScreen(levelNumber: level),
  );
  await t.pump();
}

Future<void> tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(ValueKey(key)));
  await t.pump();
}

Future<void> fill(WidgetTester t, List<int> colors) async {
  for (final c in colors) {
    await tapKey(t, 'palette-$c');
  }
  await t.pump(const Duration(milliseconds: 300));
}

Progress memoryOf(WidgetTester t) =>
    AppScope.of(t.element(find.byType(Scaffold).first))
        .memoryProgress
        .progress;

void main() {
  testWidgets('perfect level 1 from the home screen: 3 stars, saved, next',
      (t) async {
    phone(t);
    SharedPreferences.setMockInitialValues({});
    await pumpApp(
      t,
      memoryStore: SharedPrefsProgressStore.memory(memoryLevels.length),
    );
    await t.tap(find.byKey(const ValueKey('memory-play')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(title(t), 'Remember the colours');
    expect(find.text('LEVEL 1 OF 33'), findsOneWidget);
    expect(t.widget<CubeTower>(find.byType(CubeTower)).cubes, answer(1));

    await tapKey(t, 'memory-ready');
    expect(title(t), 'Rebuild the tower');
    expect(t.widget<CubeTower>(find.byType(CubeTower)).cubes,
        everyElement(isNull));

    await fill(t, answer(1));
    await tapKey(t, 'memory-check');
    expect(title(t), 'Perfect memory');
    expect(find.text('3/3'), findsOneWidget);
    final record = memoryOf(t).records[1]!;
    expect(record.stars, 3);
    expect(record.bestPoints, greaterThan(30), reason: 'early start bonus');

    // Saved under its own key; the wind ladder is untouched.
    final saved =
        await SharedPrefsProgressStore.memory(memoryLevels.length).load();
    expect(saved.records[1]?.stars, 3);
    expect((await SharedPrefsProgressStore().load()).records, isEmpty);

    await tapKey(t, 'memory-primary');
    await t.pump();
    expect(find.text('LEVEL 2 OF 33'), findsOneWidget);
    expect(title(t), 'Remember the colours');
  });

  testWidgets('the countdown ends the study on its own', (t) async {
    phone(t);
    await openLevel(t, 1);
    await pumpSeconds(t, memoryLevels[0].studySeconds);
    expect(title(t), 'Rebuild the tower');
  });

  testWidgets('a wrong tower is not cleared and records nothing', (t) async {
    phone(t);
    await openLevel(t, 1);
    await tapKey(t, 'memory-ready');
    final wrong = [for (final c in answer(1)) (c + 1) % 4];
    await fill(t, wrong);
    await tapKey(t, 'memory-check');
    expect(title(t), 'Not quite');
    expect(find.text('0/3'), findsOneWidget);
    expect(find.textContaining('You need 3 right'), findsOneWidget);
    expect(memoryOf(t).records, isEmpty);

    await tapKey(t, 'memory-primary');
    expect(title(t), 'Remember the colours');
  });

  testWidgets('Check waits for every cube; tap a cube to fix it; undo',
      (t) async {
    phone(t);
    await openLevel(t, 1);
    await tapKey(t, 'memory-ready');
    final right = answer(1);
    final wrongFirst = (right[0] + 1) % 4;
    await fill(t, [wrongFirst, right[1]]);
    await tapKey(t, 'memory-check');
    expect(title(t), 'Rebuild the tower', reason: 'one slot still empty');

    await tapKey(t, 'palette-${right[2]}');
    // Fix the bottom cube by tapping it, then picking its colour.
    final tower = find.byType(CubeTower);
    final box = t.getRect(tower);
    await t.tapAt(Offset(box.center.dx, box.bottom - 30));
    await t.pump();
    expect(t.widget<CubeTower>(tower).cursor, 0);
    await tapKey(t, 'palette-${right[0]}');
    expect(t.widget<CubeTower>(tower).cubes, right);

    await tapKey(t, 'memory-undo');
    expect(t.widget<CubeTower>(tower).cubes.first, wrongFirst);
    await tapKey(t, 'memory-undo');
    expect(t.widget<CubeTower>(tower).cubes.last, isNull);
  });

  testWidgets('the last level offers the way back to the ladder', (t) async {
    phone(t);
    await openLevel(t, 33, memory: Progress({
      for (var i = 1; i <= 32; i++)
        i: const LevelRecord(stars: 3, bestPoints: 10),
    }));
    await tapKey(t, 'memory-ready');
    await fill(t, answer(33));
    await tapKey(t, 'memory-check');
    expect(title(t), 'Perfect memory');
    expect(find.text('All 33 cleared'), findsOneWidget);
    await tapKey(t, 'memory-primary');
    await t.pumpAndSettle();
    expect(find.byType(MemoryLevelsScreen), findsOneWidget);
  });

  testWidgets('memory ladder: 33 levels in four stages, locked past next',
      (t) async {
    await pumpApp(t, home: const MemoryLevelsScreen());
    expect(find.text('WARM-UP'), findsOneWidget);
    expect(find.text('3 cubes · 4 colours · 5s'), findsOneWidget);
    for (final stage in ['BUILD-UP', 'CLIMB', 'SUMMIT']) {
      await t.scrollUntilVisible(find.text(stage), 300);
    }
    await t.scrollUntilVisible(find.text('Level 33'), 300);
    expect(find.text('112 cubes · 8 colours · ${memoryLevels.last.studySeconds}s'),
        findsOneWidget);
    await t.scrollUntilVisible(find.text('Level 1'), -400);
    await t.tap(find.text('Level 2'));
    await t.pumpAndSettle();
    expect(find.byType(MemoryGameScreen), findsNothing);
    await t.tap(find.text('Level 1'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(MemoryGameScreen), findsOneWidget);
  });

  testWidgets('home shows Memory Towers progress', (t) async {
    await pumpApp(t, memoryProgress: const Progress({
      1: LevelRecord(stars: 3, bestPoints: 70),
      2: LevelRecord(stars: 1, bestPoints: 90),
    }));
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.text('Play level 3'), findsOneWidget);
    expect(find.textContaining('2/33'), findsOneWidget);
    expect(find.text('160'), findsOneWidget);
  });

  for (final level in [1, 12, 13, 33]) {
    for (final size in const [Size(320, 568), Size(428, 908)]) {
      testWidgets('level $level fits ${size.width}x${size.height} at 1.3',
          (t) async {
        phone(t, size: size);
        t.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(t.platformDispatcher.clearAllTestValues);
        await openLevel(t, level, ads: FakeAds()..ready = true);
        expect(t.takeException(), isNull);
        await tapKey(t, 'memory-ready');
        expect(find.byKey(const ValueKey('memory-peek')), findsOneWidget);
        await fill(t, answer(level));
        expect(t.takeException(), isNull);
        await tapKey(t, 'memory-check');
        expect(t.takeException(), isNull);
        expect(title(t), 'Perfect memory');
      });
    }
  }

  group('rewarded ads', () {
    Finder key(String k) => find.byKey(ValueKey(k));

    // The rebuild cursor pulses forever, so no pumpAndSettle here.
    Future<void> settle(WidgetTester t) =>
        t.pump(const Duration(milliseconds: 600));

    Future<void> watch(WidgetTester t, String button, FakeAds ads,
        {bool rewarded = true}) async {
      final shown = ads.showCount;
      await tapKey(t, button);
      await settle(t);
      expect(find.text('Watch ad'), findsOneWidget);
      await t.tap(key('ad-offer-watch'));
      await settle(t);
      expect(ads.showCount, shown + 1);
      ads.complete(rewarded);
      await t.pump();
      await t.pump();
    }

    testWidgets('no ad loaded: no Peek, no Same tower', (t) async {
      phone(t);
      await openLevel(t, 1);
      await tapKey(t, 'memory-ready');
      expect(key('memory-peek'), findsNothing);
      await fill(t, [for (final c in answer(1)) (c + 1) % 4]);
      await tapKey(t, 'memory-check');
      expect(title(t), 'Not quite');
      expect(key('memory-retry-ad'), findsNothing);
    });

    testWidgets('Peek shows the tower again, keeps the cubes, caps at 2',
        (t) async {
      phone(t);
      final ads = FakeAds()..ready = true;
      await openLevel(t, 4, ads: ads);
      await tapKey(t, 'memory-ready');
      final right = answer(4);
      await fill(t, right.take(2).toList());

      await watch(t, 'memory-peek', ads);
      expect(title(t), 'Take a peek');
      final tower = find.byType(CubeTower);
      expect(t.widget<CubeTower>(tower).cubes, right);
      await tapKey(t, 'palette-0');
      expect(title(t), 'Take a peek', reason: 'no placing during a peek');

      await pumpSeconds(t, memoryLevels[3].peekSeconds);
      expect(title(t), 'Rebuild the tower');
      expect(t.widget<CubeTower>(tower).cubes.take(2), right.take(2));
      expect(t.widget<CubeTower>(tower).cubes[2], isNull);
      ads.ready = true;
      await t.pump();
      expect(key('memory-peek'), findsNothing, reason: 'one peek a round');

      await fill(t, right.skip(2).toList());
      await tapKey(t, 'memory-check');
      expect(title(t), 'Perfect memory');
      expect(find.textContaining('caps it at 2 stars'), findsOneWidget);
      expect(memoryOf(t).records[4]!.stars, 2);
    });

    testWidgets('Not now, or an ad closed early, gives nothing', (t) async {
      phone(t);
      final ads = FakeAds()..ready = true;
      await openLevel(t, 2, ads: ads);
      await tapKey(t, 'memory-ready');

      await tapKey(t, 'memory-peek');
      await settle(t);
      await t.tap(key('ad-offer-cancel'));
      await settle(t);
      expect(ads.showCount, 0);
      expect(title(t), 'Rebuild the tower');

      await watch(t, 'memory-peek', ads, rewarded: false);
      expect(title(t), 'Rebuild the tower');
      ads.ready = true;
      await t.pump();
      expect(key('memory-peek'), findsOneWidget, reason: 'peek not used up');
      await fill(t, answer(2));
      await tapKey(t, 'memory-check');
      expect(memoryOf(t).records[2]!.stars, 3);
    });

    testWidgets('Same tower after a miss replays the exact colours',
        (t) async {
      phone(t);
      final ads = FakeAds()..ready = true;
      var seed = 100;
      await openLevel(t, 3, ads: ads, newSeed: () => seed++);
      final tower = find.byType(CubeTower);
      final first = List.of(t.widget<CubeTower>(tower).cubes);
      await tapKey(t, 'memory-ready');
      await fill(t, [for (final c in first) (c! + 1) % 4]);
      await tapKey(t, 'memory-check');
      expect(title(t), 'Not quite');

      await watch(t, 'memory-retry-ad', ads);
      expect(title(t), 'Remember the colours');
      expect(t.widget<CubeTower>(tower).cubes, first);

      await tapKey(t, 'memory-ready');
      await fill(t, [for (final c in first) c!]);
      await tapKey(t, 'memory-check');
      expect(title(t), 'Perfect memory');
      expect(memoryOf(t).records[3]!.stars, 2);

      // A free retry still gives new colours.
      await tapKey(t, 'memory-secondary');
      expect(t.widget<CubeTower>(tower).cubes, isNot(first));
    });
  });
}
