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

void main() {
  Future<void> shoot(WidgetTester t, Widget home, String name,
      {bool sheet = false}) async {
    t.view.physicalSize = const Size(428, 908);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pumpApp(t, progress: _progress, home: home);
    if (sheet) {
      await t.tap(find.text('How to play'));
      await t.pumpAndSettle();
    }
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets('menu golden', (t) => shoot(t, const MenuScreen(), 'menu'));
  testWidgets('levels golden', (t) => shoot(t, const LevelsScreen(), 'levels'));
  testWidgets('how to play golden',
      (t) => shoot(t, const MenuScreen(), 'how_to_play', sheet: true));
}
