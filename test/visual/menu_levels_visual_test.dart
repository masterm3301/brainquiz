import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/ui/screens/levels_screen.dart';
import 'package:brainquiz/ui/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

const _progress = Progress({
  1: LevelRecord(stars: 3, bestPoints: 360),
  2: LevelRecord(stars: 2, bestPoints: 280),
  3: LevelRecord(stars: 3, bestPoints: 400),
});

const _designMemory = Progress({
  1: LevelRecord(stars: 3, bestPoints: 90),
  2: LevelRecord(stars: 3, bestPoints: 90),
  3: LevelRecord(stars: 2, bestPoints: 90),
  4: LevelRecord(stars: 3, bestPoints: 90),
  5: LevelRecord(stars: 2, bestPoints: 90),
  6: LevelRecord(stars: 2, bestPoints: 90),
  7: LevelRecord(stars: 1, bestPoints: 87),
}, lastLevel: 33);

const _designWind = Progress({1: LevelRecord(stars: 1, bestPoints: 0)});

const _memory = Progress({
  1: LevelRecord(stars: 3, bestPoints: 42),
  2: LevelRecord(stars: 3, bestPoints: 55),
  3: LevelRecord(stars: 2, bestPoints: 61),
  4: LevelRecord(stars: 3, bestPoints: 80),
  5: LevelRecord(stars: 1, bestPoints: 70),
  6: LevelRecord(stars: 3, bestPoints: 96),
}, lastLevel: 33);

void main() {
  Future<void> shoot(WidgetTester t, Widget home, String name,
      {bool sheet = false,
      Size size = const Size(428, 908),
      Key? tapKey,
      Progress memory = _memory,
      Progress wind = _progress}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pumpApp(t,
        progress: wind, memoryProgress: memory, home: home);
    await t.pump(const Duration(seconds: 2));
    if (sheet) {
      await t.tap(find.byKey(const ValueKey('about')));
      await t.pumpAndSettle();
    }
    if (tapKey != null) {
      await t.tap(find.byKey(tapKey));
      await t.pumpAndSettle();
    }
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets('menu golden', (t) => shoot(t, const MenuScreen(), 'menu'));
  testWidgets('menu wind golden',
      (t) => shoot(t, const MenuScreen(), 'menu_wind',
          tapKey: const ValueKey('mode-wind')));
  testWidgets('menu as designed, 390x844', (t) async {
    await shoot(t, const MenuScreen(), 'menu_design',
        size: const Size(390, 844), memory: _designMemory, wind: _designWind);
  });
  testWidgets('menu wind as designed, 390x844', (t) async {
    await shoot(t, const MenuScreen(), 'menu_wind_design',
        size: const Size(390, 844),
        memory: _designMemory,
        wind: _designWind,
        tapKey: const ValueKey('mode-wind'));
  });
  testWidgets('menu new player small phone golden',
      (t) => shoot(t, const MenuScreen(), 'menu_new_small',
          size: const Size(360, 640),
          memory: const Progress({}, lastLevel: 33),
          wind: Progress.empty));
  testWidgets('menu wind new player small phone golden',
      (t) => shoot(t, const MenuScreen(), 'menu_wind_new_small',
          size: const Size(360, 640),
          memory: const Progress({}, lastLevel: 33),
          wind: Progress.empty,
          tapKey: const ValueKey('mode-wind')));
  testWidgets('menu many cleared golden',
      (t) => shoot(t, const MenuScreen(), 'menu_many_cleared',
          size: const Size(360, 640),
          memory: Progress({
            for (var i = 1; i <= 24; i++)
              i: const LevelRecord(stars: 2, bestPoints: 50),
          }, lastLevel: 33)));
  testWidgets('menu small phone golden',
      (t) => shoot(t, const MenuScreen(), 'menu_small',
          size: const Size(360, 640)));
  testWidgets('levels golden', (t) => shoot(t, const LevelsScreen(), 'levels'));
  testWidgets('about golden',
      (t) => shoot(t, const MenuScreen(), 'about', sheet: true));
  testWidgets('about with how to play open golden', (t) async {
    await shoot(t, const MenuScreen(), 'about_how_to_play', sheet: true,
        tapKey: const ValueKey('about-how-to-play'));
  });
}
