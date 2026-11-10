import 'package:brainquiz/memory/memory_levels.dart';
import 'package:brainquiz/memory/memory_round.dart';
import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/ui/screens/memory_game_screen.dart';
import 'package:brainquiz/ui/screens/memory_levels_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ads.dart';
import '../support/pump_app.dart';

const _memory = Progress({
  1: LevelRecord(stars: 3, bestPoints: 68),
  2: LevelRecord(stars: 2, bestPoints: 84),
});

List<int> _answer(int level) =>
    MemoryRound(level: memoryLevels[level - 1], seed: 42).target;

Future<void> _open(WidgetTester t, Widget home,
    {Size? size, bool adReady = false}) async {
  t.view.physicalSize = size ?? const Size(428, 908);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await pumpApp(t,
      memoryProgress: _memory,
      ads: FakeAds()..ready = adReady,
      home: home);
  await t.pump();
}

Future<void> _tap(WidgetTester t, String key) async {
  await t.tap(find.byKey(ValueKey(key)));
  await t.pump();
}

Future<void> _shoot(WidgetTester t, String name) async {
  await t.pump(const Duration(milliseconds: 400));
  await expectLater(
      find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  testWidgets('memory levels golden', (t) async {
    await _open(t, const MemoryLevelsScreen());
    await _shoot(t, 'memory_levels');
  });

  testWidgets('memory study golden', (t) async {
    await _open(t, const MemoryGameScreen(levelNumber: 13));
    await t.pump(const Duration(seconds: 2));
    await _shoot(t, 'memory_study');
  });

  testWidgets('memory recall golden', (t) async {
    await _open(t, const MemoryGameScreen(levelNumber: 13), adReady: true);
    await _tap(t, 'memory-ready');
    for (final c in _answer(13).take(14)) {
      await _tap(t, 'palette-$c');
    }
    await _shoot(t, 'memory_recall');
  });

  testWidgets('memory result golden', (t) async {
    await _open(t, const MemoryGameScreen(levelNumber: 13));
    await _tap(t, 'memory-ready');
    final answer = _answer(13);
    for (var i = 0; i < answer.length; i++) {
      final c = i % 7 == 3 ? (answer[i] + 1) % 6 : answer[i];
      await _tap(t, 'palette-$c');
    }
    await _tap(t, 'memory-check');
    await _shoot(t, 'memory_result');
  });

  testWidgets('memory level 22 small phone golden', (t) async {
    await _open(t, const MemoryGameScreen(levelNumber: 33),
        size: const Size(360, 640));
    await t.pump(const Duration(seconds: 2));
    await _shoot(t, 'memory_study_112');
  });

  testWidgets('memory level 12 single tower small phone golden', (t) async {
    await _open(t, const MemoryGameScreen(levelNumber: 12),
        size: const Size(360, 640));
    await t.pump(const Duration(seconds: 2));
    await _shoot(t, 'memory_study_level_12');
  });

  testWidgets('memory peek offer golden', (t) async {
    await _open(t, const MemoryGameScreen(levelNumber: 13), adReady: true);
    await _tap(t, 'memory-ready');
    await _tap(t, 'memory-peek');
    await _shoot(t, 'memory_peek_offer');
  });

  testWidgets('memory miss with Same tower golden', (t) async {
    await _open(t, const MemoryGameScreen(levelNumber: 3),
        size: const Size(360, 640), adReady: true);
    await _tap(t, 'memory-ready');
    for (final c in _answer(3)) {
      await _tap(t, 'palette-${(c + 1) % 4}');
    }
    await _tap(t, 'memory-check');
    await _shoot(t, 'memory_miss_same_tower');
  });
}
