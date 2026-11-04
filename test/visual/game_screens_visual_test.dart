import 'package:brainquiz/game/attempt.dart';
import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/ui/screens/attempt_flow.dart';
import 'package:brainquiz/ui/widgets/arena.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ads.dart';
import '../support/pump_app.dart';
import '../ui/memorise_build_test.dart' show placeBlock, placeRight;

void main() {
  Future<void> pumpSeconds(WidgetTester t, double seconds) async {
    for (var i = 0; i < seconds * 20; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(WidgetTester t, {FakeAds? ads}) async {
    t.view.physicalSize = const Size(428, 908);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pumpApp(t, ads: ads, home: const AttemptFlow(levelNumber: 4));
  }

  /// Studies, builds (right or wrong) and taps lock on level 4, seed 42.
  Future<void> buildAndLock(
    WidgetTester t, {
    required bool right,
    FakeAds? ads,
  }) async {
    await open(t, ads: ads);
    await pumpSeconds(t, 6.5);
    final ref = Attempt(level: levels[3], seed: 42)..finishStudy();
    for (var row = 0; row < levels[3].blocks; row++) {
      if (right) {
        await placeRight(t, ref, row);
      } else {
        await placeBlock(t, ref, ref.tray.first);
      }
    }
    expect(ref.report.mustFall, !right);
    await t.tap(
      find.text(ads == null ? 'Lock the tower' : 'Lock'),
    );
    for (var i = 0; i < 3; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> golden(WidgetTester t, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

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
        find.byType(Draggable<Block>).at(ref.tray.indexOf(block)),
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

  testWidgets('wind ready golden', (t) async {
    await buildAndLock(t, right: true, ads: FakeAds()..ready = true);
    await golden(t, 'wind_ready');
  });

  testWidgets('hold golden', (t) async {
    await buildAndLock(t, right: true);
    await pumpSeconds(t, 11);
    await golden(t, 'hold');
  });

  testWidgets('stood golden', (t) async {
    await buildAndLock(t, right: true);
    await pumpSeconds(t, 19);
    await golden(t, 'stood');
  });

  testWidgets('fell golden', (t) async {
    await buildAndLock(t, right: false);
    await pumpSeconds(t, 19);
    await pumpSeconds(t, 2);
    await golden(t, 'fell');
  });
}
