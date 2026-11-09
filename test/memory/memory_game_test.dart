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

import '../support/flow_helpers.dart' show phone, pumpSeconds;
import '../support/pump_app.dart';

/// The round the screen builds (pumpApp seeds every round with 42).
List<int> answer(int level) =>
    MemoryRound(level: memoryLevels[level - 1], seed: 42).target;

String title(WidgetTester t) =>
    t.widget<Text>(find.byKey(const ValueKey('memory-title'))).data!;

Future<void> openLevel(WidgetTester t, int level, {Progress? memory}) async {
  await pumpApp(
    t,
    memoryProgress: memory ?? Progress.empty,
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
    expect(find.text('LEVEL 1 OF 22'), findsOneWidget);
    expect(t.widget<CubeTower>(find.byType(CubeTower)).cubes, answer(1));

    await tapKey(t, 'memory-ready');
    expect(title(t), 'Rebuild the tower');
    expect(t.widget<CubeTower>(find.byType(CubeTower)).cubes,
        everyElement(isNull));

    await fill(t, answer(1));
    await tapKey(t, 'memory-check');
    expect(title(t), 'Perfect memory');
    expect(find.text('5/5'), findsOneWidget);
    final record = memoryOf(t).records[1]!;
    expect(record.stars, 3);
    expect(record.bestPoints, greaterThan(50), reason: 'early start bonus');

    // Saved under its own key; the wind ladder is untouched.
    final saved =
        await SharedPrefsProgressStore.memory(memoryLevels.length).load();
    expect(saved.records[1]?.stars, 3);
    expect((await SharedPrefsProgressStore().load()).records, isEmpty);

    await tapKey(t, 'memory-primary');
    await t.pump();
    expect(find.text('LEVEL 2 OF 22'), findsOneWidget);
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
    expect(find.text('0/5'), findsOneWidget);
    expect(find.textContaining('You need 4 right'), findsOneWidget);
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
    await fill(t, [wrongFirst, ...right.skip(1).take(3)]);
    await tapKey(t, 'memory-check');
    expect(title(t), 'Rebuild the tower', reason: 'one slot still empty');

    await tapKey(t, 'palette-${right[4]}');
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
    await openLevel(t, 22, memory: Progress({
      for (var i = 1; i <= 21; i++)
        i: const LevelRecord(stars: 3, bestPoints: 10),
    }));
    await tapKey(t, 'memory-ready');
    await fill(t, answer(22));
    await tapKey(t, 'memory-check');
    expect(title(t), 'Perfect memory');
    expect(find.text('All 22 cleared'), findsOneWidget);
    await tapKey(t, 'memory-primary');
    await t.pumpAndSettle();
    expect(find.byType(MemoryLevelsScreen), findsOneWidget);
  });

  testWidgets('memory ladder: 22 levels in three stages, locked past next',
      (t) async {
    await pumpApp(t, home: const MemoryLevelsScreen());
    expect(find.text('WARM-UP'), findsOneWidget);
    expect(find.text('5 cubes · 4 colours · 7s'), findsOneWidget);
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
    expect(find.text('Continue level 3'), findsOneWidget);
    expect(find.text('2 of 22 cleared'), findsOneWidget);
    expect(find.text('160'), findsOneWidget);
  });

  for (final level in [1, 9, 22]) {
    for (final size in const [Size(320, 568), Size(428, 908)]) {
      testWidgets('level $level fits ${size.width}x${size.height} at 1.3',
          (t) async {
        phone(t, size: size);
        t.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(t.platformDispatcher.clearAllTestValues);
        await openLevel(t, level);
        expect(t.takeException(), isNull);
        await tapKey(t, 'memory-ready');
        await fill(t, answer(level));
        expect(t.takeException(), isNull);
        await tapKey(t, 'memory-check');
        expect(t.takeException(), isNull);
        expect(title(t), 'Perfect memory');
      });
    }
  }
}
