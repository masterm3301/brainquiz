import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/ui/screens/attempt_flow.dart';
import 'package:brainquiz/ui/screens/levels_screen.dart';
import 'package:brainquiz/ui/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ads.dart';
import '../support/pump_app.dart';

Progress cleared(int n) => Progress({
      for (var i = 1; i <= n; i++)
        i: LevelRecord(stars: 3, bestPoints: 400 * i),
    });

void main() {
  testWidgets('first launch shows Play', (t) async {
    await pumpApp(t);
    expect(find.text('Tower Build'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);
    expect(find.textContaining('Continue'), findsNothing);
  });

  testWidgets('returning player sees Continue level N and total', (t) async {
    await pumpApp(t, progress: cleared(3));
    expect(find.text('Continue level 4'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    expect(find.text(formatPoints(400 + 800 + 1200)), findsOneWidget);
  });

  testWidgets('after all 12, Continue is replaced', (t) async {
    await pumpApp(t, progress: cleared(12));
    expect(find.text('Replay level 12'), findsOneWidget);
    expect(find.textContaining('Continue'), findsNothing);
  });

  group('Privacy options entry', () {
    testWidgets('hidden when not required', (t) async {
      await pumpApp(t, ads: FakeAds());
      expect(find.text('Privacy options'), findsNothing);
    });

    testWidgets('shown when required, and opens the form', (t) async {
      final ads = FakeAds()..privacyRequired = true;
      await pumpApp(t, ads: ads);
      expect(find.text('Privacy options'), findsOneWidget);
      await t.tap(find.text('Privacy options'));
      await t.pump();
      expect(ads.privacyShowCount, 1);
    });

    testWidgets('appears when the requirement arrives after launch', (t) async {
      final ads = FakeAds();
      await pumpApp(t, ads: ads);
      ads.privacyRequired = true;
      await t.pump();
      expect(find.text('Privacy options'), findsOneWidget);
    });

    testWidgets('fits a small phone without pushing the buttons off', (t) async {
      const size = Size(360, 640);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await pumpApp(t, ads: FakeAds()..privacyRequired = true);
      expect(t.getRect(find.text('Privacy options')).bottom,
          lessThanOrEqualTo(size.height));
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('Play opens level 1', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Play'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(AttemptFlow), findsOneWidget);
    expect(find.text('Level 1 of 12'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
  });

  testWidgets('levels list shows all 12 with block counts', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Levels'));
    await t.pumpAndSettle();
    expect(find.text('Twelve levels'), findsOneWidget);
    expect(find.text('3 blocks'), findsOneWidget);
    await t.scrollUntilVisible(find.text('10 blocks').last, 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('10 blocks'), findsWidgets);
  });

  testWidgets('locked levels ignore taps', (t) async {
    await pumpApp(t, home: const LevelsScreen());
    await t.tap(find.text('Level 5'));
    await t.pumpAndSettle();
    expect(find.byType(LevelsScreen), findsOneWidget);
    expect(find.byType(AttemptFlow), findsNothing);
  });

  testWidgets('unlocked and cleared levels open', (t) async {
    await pumpApp(t, progress: cleared(2), home: const LevelsScreen());
    await t.tap(find.text('Level 1'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Level 1 of 12'), findsOneWidget);
    expect(find.byType(AttemptFlow), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.text('Level 3'));
    await t.pumpAndSettle();
    expect(find.byType(AttemptFlow), findsOneWidget);
  });

  testWidgets('cleared levels show stars and best points', (t) async {
    await pumpApp(t, progress: Progress({
      1: const LevelRecord(stars: 2, bestPoints: 1240),
    }), home: const LevelsScreen());
    expect(find.text('1,240'), findsOneWidget);
    expect(find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == '2 of 3 stars'), findsOneWidget);
  });

  testWidgets('how to play shows the three 1b rules', (t) async {
    await pumpApp(t);
    await t.tap(find.text('How to play'));
    await t.pumpAndSettle();
    expect(find.text('Study the tower before the countdown ends.'),
        findsOneWidget);
    expect(
        find.text(
            'Rebuild it from the bottom up. Placed blocks stay put, so drop them straight.'),
        findsOneWidget);
    expect(
        find.text(
            'Lock it and hold through the wind. Wrong blocks and crooked drops can bring it down.'),
        findsOneWidget);
  });

  for (final home in <Widget>[const MenuScreen(), const LevelsScreen()]) {
    testWidgets('${home.runtimeType} has no overflow at 320x568, scale 1.3',
        (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearAllTestValues);
      await pumpApp(t, progress: cleared(3), home: home);
      expect(t.takeException(), isNull);
    });
  }
}
