import 'package:brainquiz/ads/rewarded_ads.dart';
import 'package:brainquiz/game/attempt.dart';
import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/ui/screens/attempt_flow.dart';
import 'package:brainquiz/ui/widgets/arena.dart';
import 'package:brainquiz/ui/widgets/block_tray.dart';
import 'package:brainquiz/ui/widgets/neon_button.dart';
import 'package:brainquiz/ui/widgets/tower_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ads.dart';
import '../support/pump_app.dart';

/// The same attempt the screen builds (seed 42), for reading the answer.
Attempt reference(int level) => Attempt(level: levels[level - 1], seed: 42);

Future<void> pumpFlow(WidgetTester t, {int level = 1, RewardedAds? ads}) async {
  await pumpApp(
    t,
    ads: ads,
    home: AttemptFlow(levelNumber: level),
  );
}

Future<void> pumpSeconds(WidgetTester t, int seconds) async {
  for (var i = 0; i < seconds * 20 + 10; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> toBuild(WidgetTester t, {int level = 1, RewardedAds? ads}) async {
  await pumpFlow(t, level: level, ads: ads);
  await pumpSeconds(t, levels[level - 1].studySeconds);
}

/// Drags tray tile [i] to [to] (global).
Future<void> dragTile(WidgetTester t, int i, Offset to) async {
  final from = t.getCenter(find.byKey(ValueKey('tile-$i')));
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
  await dragTile(t, ref.tray.indexOf(block), arenaCentre(t));
  ref.drop(block, 0);
}

void main() {
  testWidgets('memorise shows the tower and then hides it', (t) async {
    await pumpFlow(t);
    expect(find.text('Level 1 of 12'), findsOneWidget);
    expect(find.text('Memorise the tower'), findsOneWidget);
    expect(find.text('TWO THINGS TO REMEMBER'), findsOneWidget);
    expect(
      find.text(
        'The order of the blocks, and that heavy wide pieces '
        'belong near the bottom.',
      ),
      findsOneWidget,
    );
    expect(find.text('6'), findsOneWidget);
    await pumpSeconds(t, 2);
    expect(find.text('4'), findsOneWidget);
    await pumpSeconds(t, 5);
    expect(find.text('Memorise the tower'), findsNothing);
    expect(find.text('Block 1 of 3'), findsOneWidget);
    expect(find.text('No timer'), findsOneWidget);
  });

  testWidgets('dropping on the centre line places a block', (t) async {
    await toBuild(t);
    final ref = reference(1)..finishStudy();
    expect(find.byType(Draggable<Block>), findsNWidgets(3));
    await placeRight(t, ref, 0);
    expect(find.text('Block 2 of 3'), findsOneWidget);
    expect(find.byType(Draggable<Block>), findsNWidgets(2));
  });

  testWidgets('dropping outside the arena returns the block', (t) async {
    await toBuild(t);
    await dragTile(t, 0, const Offset(200, 20));
    expect(find.text('Block 1 of 3'), findsOneWidget);
    expect(find.byType(Draggable<Block>), findsNWidgets(3));
  });

  testWidgets('dropping with no contact below returns the block', (t) async {
    await toBuild(t);
    final rect = t.getRect(find.byType(Arena));
    await dragTile(t, 0, Offset(rect.left + 22, rect.center.dy));
    expect(find.text('Block 1 of 3'), findsOneWidget);
    expect(find.byType(Draggable<Block>), findsNWidgets(3));
  });

  testWidgets('the meter drops after a wrong block and stays at 100 after '
      'a right one', (t) async {
    await toBuild(t);
    final ref = reference(1)..finishStudy();
    expect(find.text('100%'), findsOneWidget);
    await placeRight(t, ref, 0);
    expect(find.text('100%'), findsOneWidget);

    final wrong = ref.tray.firstWhere((b) => b != ref.tower.blocks[1]);
    await placeBlock(t, ref, wrong);
    expect(ref.report.score, lessThan(100));
    expect(find.text('100%'), findsNothing);
    expect(find.text('${ref.report.score}%'), findsOneWidget);
  });

  testWidgets('only one block can be dragged at a time', (t) async {
    await toBuild(t);
    for (final d in t.widgetList<Draggable<Block>>(
      find.byType(Draggable<Block>),
    )) {
      expect(d.maxSimultaneousDrags, 1);
    }
  });

  testWidgets('Lock is disabled until every row is filled', (t) async {
    await toBuild(t);
    final ref = reference(1)..finishStudy();
    NeonButton lock() =>
        t.widget<NeonButton>(find.widgetWithText(NeonButton, 'Lock the tower'));
    expect(lock().onPressed, isNull);
    await placeRight(t, ref, 0);
    await placeRight(t, ref, 1);
    expect(lock().onPressed, isNull);
    await placeRight(t, ref, 2);
    expect(find.text('All 3 placed'), findsOneWidget);
    expect(lock().onPressed, isNotNull);
  });

  testWidgets('the Place here marker has the same width whichever block is '
      'next', (t) async {
    await toBuild(t);
    final ref = reference(1)..finishStudy();
    double w() => t.getSize(find.byKey(const ValueKey('place-here'))).width;
    final before = w();
    expect(
      before,
      closeTo(0.58 * t.getSize(find.byType(TowerView)).width, .01),
    );
    await placeRight(t, ref, 0);
    expect(w(), closeTo(before, .01));
    await placeRight(t, ref, 1);
    expect(w(), closeTo(before, .01));
  });

  testWidgets('the tray pages when it is too large', (t) async {
    final blocks = [
      for (var i = 0; i < 11; i++)
        Block(
          color: BlockColor.green,
          shape: BlockShape.rectangle,
          width: 0.3 + i * 0.01,
          height: 30,
        ),
    ];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: BlockTray(blocks: blocks)),
        ),
      ),
    );
    expect(find.byType(Draggable<Block>), findsNWidgets(7));
    expect(find.text('+4'), findsOneWidget);
    await t.tap(find.text('+4'));
    await t.pump();
    expect(find.byType(Draggable<Block>), findsNWidgets(4));
    expect(find.text('+7'), findsOneWidget);
  });

  testWidgets('second look: no button when no ad is ready', (t) async {
    final ads = FakeAds();
    await toBuild(t, ads: ads);
    expect(find.text('See the tower again'), findsNothing);
    expect(find.text('Lock the tower'), findsOneWidget);
  });

  testWidgets('second look: earned shows the tower for 3s, then back '
      'unchanged', (t) async {
    final ads = FakeAds()..ready = true;
    await toBuild(t, ads: ads);
    final ref = reference(1)..finishStudy();
    await placeRight(t, ref, 0);
    await t.tap(find.text('See the tower again'));
    await t.pump();
    ads.complete(true);
    await t.pump();
    await t.pump();
    expect(find.byKey(const ValueKey('peek-tower')), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('peek-tower')), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('peek-tower')), findsNothing);
    expect(find.text('Block 2 of 3'), findsOneWidget);
    expect(find.byType(Draggable<Block>), findsNWidgets(2));
  });

  testWidgets('second look: closed early gives nothing and may be retried', (
    t,
  ) async {
    final ads = FakeAds()..ready = true;
    await toBuild(t, ads: ads);
    await t.tap(find.text('See the tower again'));
    await t.pump();
    ads.complete(false);
    await t.pump();
    expect(find.byKey(const ValueKey('peek-tower')), findsNothing);
    ads.ready = true;
    await t.pump();
    await t.tap(find.text('See the tower again'));
    await t.pump();
    expect(ads.showCount, 2);
  });

  testWidgets('second look: a double tap shows only one ad', (t) async {
    final ads = FakeAds()..ready = true;
    await toBuild(t, ads: ads);
    await t.tap(find.text('See the tower again'));
    await t.tap(find.text('See the tower again'));
    await t.pump();
    expect(ads.showCount, 1);
    ads.complete(false);
    await t.pump();
  });

  testWidgets('second look: only once per attempt', (t) async {
    final ads = FakeAds()..ready = true;
    await toBuild(t, ads: ads);
    await t.tap(find.text('See the tower again'));
    await t.pump();
    ads.complete(true);
    await t.pump(const Duration(seconds: 4));
    ads.ready = true;
    await t.pump();
    expect(find.text('See the tower again'), findsNothing);
    expect(find.text('Lock the tower'), findsOneWidget);
  });

  testWidgets('no overflow at 320x568, text scale 1.3, 10 blocks', (t) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final ads = FakeAds()..ready = true;
    await pumpFlow(t, level: 12, ads: ads);
    expect(t.takeException(), isNull);
    await pumpSeconds(t, 3);
    expect(find.text('Block 1 of 10'), findsOneWidget);
    expect(t.takeException(), isNull);
    final ref = reference(12)..finishStudy();
    for (var row = 0; row < 3; row++) {
      await placeRight(t, ref, row);
    }
    expect(t.takeException(), isNull);
  });
}
