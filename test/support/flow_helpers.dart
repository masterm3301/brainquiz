import 'package:brainquiz/ads/rewarded_ads.dart';
import 'package:brainquiz/game/attempt.dart';
import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/progress/progress_store.dart';
import 'package:brainquiz/ui/screens/attempt_flow.dart';
import 'package:brainquiz/ui/widgets/arena.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_ads.dart';
import 'pump_app.dart';

/// The same attempt the screen builds (seed 42), for reading the answer.
Attempt reference(int level) => Attempt(level: levels[level - 1], seed: 42);

Future<void> pumpFlow(
  WidgetTester t, {
  int level = 1,
  RewardedAds? ads,
  ProgressStore? store,
  Progress progress = Progress.empty,
}) async {
  await pumpApp(
    t,
    ads: ads,
    store: store,
    progress: progress,
    home: AttemptFlow(levelNumber: level),
  );
}

/// Exactly [seconds] of 50ms frames, with no slack at the end.
Future<void> pumpFor(WidgetTester t, double seconds) async {
  for (var i = 0; i < (seconds * 20).round(); i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> pumpSeconds(WidgetTester t, int seconds) async {
  for (var i = 0; i < seconds * 20 + 10; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> toBuild(
  WidgetTester t, {
  int level = 1,
  RewardedAds? ads,
  ProgressStore? store,
  Progress progress = Progress.empty,
}) async {
  await pumpFlow(
    t,
    level: level,
    ads: ads,
    store: store,
    progress: progress,
  );
  await pumpSeconds(t, levels[level - 1].studySeconds);
}

/// Drags tray tile [i] to [to] (global).
Future<void> dragTile(WidgetTester t, int i, Offset to) async {
  final from = t.getCenter(find.byType(Draggable<Block>).at(i));
  final g = await t.startGesture(from);
  for (var s = 1; s <= 10; s++) {
    await g.moveTo(Offset.lerp(from, to, s / 10)!);
    await t.pump(const Duration(milliseconds: 20));
  }
  await g.up();
  await t.pump();
}

Offset arenaCentre(WidgetTester t) => t.getCenter(find.byType(Arena));

/// Places the tower's real block [row] on the centre line.
Future<void> placeRight(WidgetTester t, Attempt ref, int row) =>
    placeBlock(t, ref, ref.tower.blocks[row]);

/// Drops [block] on the centre line, mirroring it on [ref].
Future<void> placeBlock(WidgetTester t, Attempt ref, Block block) async {
  // A tray of more than 8 blocks is paged: flip pages until it is on show.
  for (var i = 0; i < 4; i++) {
    final shown = t
        .widgetList<Draggable<Block>>(find.byType(Draggable<Block>))
        .map((d) => d.data)
        .toList();
    final local = shown.indexOf(block);
    if (local >= 0) {
      await dragTile(t, local, arenaCentre(t));
      ref.drop(block, 0);
      return;
    }
    await t.tap(find.textContaining(RegExp(r'^\+\d+$')));
    await t.pump();
  }
  fail('block never appeared in the tray');
}


/// A phone-sized screen for the flow tests.
void phone(WidgetTester t, {Size size = const Size(428, 908)}) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> tapLock(WidgetTester t) async {
  final finder = find.text('Lock the tower').evaluate().isNotEmpty
      ? find.text('Lock the tower')
      : find.text('Lock');
  await t.tap(finder);
  await t.pump();
  await t.pump();
  await t.pump();
}

/// Builds the whole tower right and locks it.
Future<void> buildPerfect(
  WidgetTester t,
  int level, {
  FakeAds? ads,
  ProgressStore? store,
  Progress progress = Progress.empty,
}) async {
  await toBuild(t, level: level, ads: ads, store: store, progress: progress);
  final ref = reference(level);
  ref.finishStudy();
  for (var row = 0; row < levels[level - 1].blocks; row++) {
    await placeRight(t, ref, row);
  }
  await tapLock(t);
}

/// Builds with the first tray blocks, which is wrong on level 4+. Returns
/// the reference attempt holding the same report the screen holds.
Future<Attempt> buildWrong(WidgetTester t, int level, {FakeAds? ads}) async {
  await toBuild(t, level: level, ads: ads);
  final ref = reference(level);
  ref.finishStudy();
  for (var row = 0; row < levels[level - 1].blocks; row++) {
    await placeBlock(t, ref, ref.tray.first);
  }
  expect(ref.report.mustFall, isTrue);
  await tapLock(t);
  return ref;
}
