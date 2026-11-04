import 'package:brainquiz/game/attempt.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/ui/screens/attempt_flow.dart';
import 'package:brainquiz/ui/widgets/arena.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  Future<void> open(WidgetTester t) async {
    t.view.physicalSize = const Size(428, 908);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pumpApp(t, home: const AttemptFlow(levelNumber: 4));
  }

  Future<void> pumpSeconds(WidgetTester t, double seconds) async {
    for (var i = 0; i < seconds * 20; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('memorise golden', (t) async {
    await open(t);
    await pumpSeconds(t, 2.5);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/memorise.png'),
    );
  });

  testWidgets('build mid-way golden', (t) async {
    await open(t);
    await pumpSeconds(t, 6.5);
    final ref = Attempt(level: levels[3], seed: 42)..finishStudy();
    for (var row = 0; row < 4; row++) {
      final block = ref.tower.blocks[row];
      final from = t.getCenter(
        find.byKey(ValueKey('tile-${ref.tray.indexOf(block)}')),
      );
      final to = t.getCenter(find.byType(Arena));
      final g = await t.startGesture(from);
      for (var s = 1; s <= 10; s++) {
        await g.moveTo(Offset.lerp(from, to, s / 10)!);
        await t.pump(const Duration(milliseconds: 20));
      }
      await g.up();
      await t.pump();
      ref.drop(block, 0);
    }
    await t.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/build_midway.png'),
    );
  });
}
