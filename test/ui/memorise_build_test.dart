import 'package:brainquiz/game/attempt.dart';
import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/ui/screens/build_view.dart';
import 'package:brainquiz/ui/widgets/arena.dart';
import 'package:brainquiz/ui/widgets/block_view.dart';
import 'package:brainquiz/ui/widgets/block_tray.dart';
import 'package:brainquiz/ui/widgets/neon_button.dart';
import 'package:brainquiz/ui/widgets/tower_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ads.dart';
import '../support/flow_helpers.dart';
import '../support/pump_app.dart';

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
    int held() => t
        .widgetList<BlockView>(find.byType(BlockView))
        .where((v) => v.heldWhite)
        .length;
    final a = await t.startGesture(
      t.getCenter(find.byType(Draggable<Block>).at(0)),
    );
    final b = await t.startGesture(
      t.getCenter(find.byType(Draggable<Block>).at(1)),
    );
    for (var s = 1; s <= 4; s++) {
      await a.moveBy(const Offset(0, -20));
      await t.pump(const Duration(milliseconds: 20));
    }
    for (var s = 1; s <= 4; s++) {
      await b.moveBy(const Offset(0, -20));
      await t.pump(const Duration(milliseconds: 20));
    }
    expect(held(), 1);
    await a.up();
    await b.up();
    await t.pump();
  });

  testWidgets('the Block N of M header stays on one line at 393 wide', (
    t,
  ) async {
    t.view.physicalSize = const Size(393, 852);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await toBuild(t, level: 12);
    final size = t.getSize(find.text('Block 1 of 10'));
    expect(size.height, lessThan(32));
  });

  Future<(Attempt, double)> pumpBuild(WidgetTester t, int level) async {
    final a = reference(level)..finishStudy();
    await pumpApp(t, home: BuildView(attempt: a));
    await t.pump();
    await t.pump();
    return (a, t.getSize(find.byType(TowerView)).width);
  }

  testWidgets('the drop x matches an off-centre finger, and snaps to the '
      'centre inside the tolerance', (t) async {
    final (a, inner) = await pumpBuild(t, 1);
    final ref = reference(1)..finishStudy();
    final block = ref.tower.blocks[0];
    await dragTile(
      t,
      ref.tray.indexOf(block),
      arenaCentre(t) + Offset(0.12 * inner, 0),
    );
    expect(a.placed.single.x, closeTo(0.12, 1e-3));

    final (b, inner2) = await pumpBuild(t, 1);
    await dragTile(
      t,
      ref.tray.indexOf(block),
      arenaCentre(t) + Offset(0.02 * inner2, 0),
    );
    expect(b.placed.single.x, 0);
  });

  testWidgets('the drop x is still right on a scaled-down tower', (t) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final (a, inner) = await pumpBuild(t, 12);
    final ref = reference(12)..finishStudy();
    for (var row = 0; row < 3; row++) {
      await placeRight(t, ref, row);
    }
    // placeRight dropped on `ref`, not `a`; mirror the screen's attempt.
    expect(a.placed.length, 3);
    expect(
      t.getSize(find.byKey(const ValueKey('place-here'))).height,
      lessThan(40),
    );
    final next = ref.tower.blocks[3];
    await dragTile(
      t,
      ref.tray.indexOf(next),
      arenaCentre(t) + Offset(0.1 * inner, 0),
    );
    expect(a.placed.length, 4);
    expect(a.placed.last.x, closeTo(0.1, 1e-3));
  });

  testWidgets('tile sizes keep each block\'s width and proportions', (t) async {
    Block rect(double w) => Block(
      color: BlockColor.green,
      shape: BlockShape.rectangle,
      width: w,
      height: 34,
    );
    final square = Block(
      color: BlockColor.cyan,
      shape: BlockShape.square,
      width: .22,
      height: .22 * 340,
    );
    final blocks = [rect(.30), rect(.54), rect(.66), rect(.90), square];
    for (final aspect in [1.0, 2.6]) {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 356,
                child: BlockTray(blocks: blocks, tileAspect: aspect),
              ),
            ),
          ),
        ),
      );
      final sizes = [
        for (final b in blocks)
          t.getSize(
            find
                .descendant(
                  of: find.byType(Draggable<Block>).at(blocks.indexOf(b)),
                  matching: find.byType(CustomPaint),
                )
                .first,
          ),
      ];
      for (var i = 1; i < 4; i++) {
        expect(sizes[i].width, greaterThan(sizes[i - 1].width + 3));
      }
      expect(sizes[3].width / sizes[0].width, closeTo(3, .05));
      expect(sizes[4].width, closeTo(sizes[4].height, .01));
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

  testWidgets('the pager is ignored while a block is held', (t) async {
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
    final g = await t.startGesture(
      t.getCenter(find.byType(Draggable<Block>).at(0)),
    );
    await g.moveBy(const Offset(0, -30));
    await t.pump();
    await t.tap(find.text('+4'));
    await t.pump();
    expect(find.text('+4'), findsOneWidget);
    expect(find.byType(Draggable<Block>), findsNWidgets(7));
    await g.up();
    await t.pump();
    await t.tap(find.text('+4'));
    await t.pump();
    expect(find.byType(Draggable<Block>), findsNWidgets(4));
  });

  testWidgets('second look: no button when no ad is ready', (t) async {
    final ads = FakeAds();
    await toBuild(t, ads: ads);
    expect(find.text('See the tower again'), findsNothing);
    expect(find.text('Lock the tower'), findsOneWidget);
  });

  testWidgets('second look: the 2-star limit shows beside the button', (t) async {
    final ads = FakeAds()..ready = true;
    await toBuild(t, ads: ads);
    const note = 'The ad limits this attempt to 2 stars.';
    expect(find.text('See the tower again'), findsOneWidget);
    expect(find.text(note), findsOneWidget);
    ads.ready = false;
    await t.pump();
    expect(find.text('See the tower again'), findsNothing);
    expect(find.text(note), findsNothing);
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
    // Dragging is off during the peek, and the meter does not move.
    await dragTile(t, 0, arenaCentre(t));
    expect(find.text('Block 2 of 3'), findsOneWidget);
    expect(find.byType(Draggable<Block>), findsNWidgets(2));
    expect(find.text('100%'), findsOneWidget);
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

  group('system text scale 2.0 at 320x568, level 12', () {
    for (final adReady in [false, true]) {
      testWidgets('Build stays playable, ad ready: $adReady', (t) async {
        const size = Size(320, 568);
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await toBuild(t, level: 12, ads: FakeAds()..ready = adReady);
        expect(find.text('Block 1 of 10'), findsOneWidget);
        expect(t.getSize(find.byType(Arena)).height, greaterThan(0));
        final lock = t.getRect(
          find.widgetWithText(NeonButton, adReady ? 'Lock' : 'Lock the tower'),
        );
        expect(lock.top, greaterThanOrEqualTo(0));
        expect(lock.bottom, lessThanOrEqualTo(size.height));
        final ref = reference(12)..finishStudy();
        await placeRight(t, ref, 0);
        expect(find.text('Block 2 of 10'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  });
}
