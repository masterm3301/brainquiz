import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/ui/screens/attempt_flow.dart';
import 'package:brainquiz/ui/screens/levels_screen.dart';
import 'package:brainquiz/ui/screens/memory_levels_screen.dart';
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
Finder windPlay() => find.byKey(const ValueKey('wind-play'));
Finder memoryPlay() => find.byKey(const ValueKey('memory-play'));
Finder buttonText(Finder button) =>
    find.descendant(of: button, matching: find.byType(Text));

  testWidgets('first launch shows both games with Play', (t) async {
    await pumpApp(t);
    expect(find.text('Tower Build'), findsOneWidget);
    expect(find.text('Memory Towers'), findsOneWidget);
    expect(find.text('Wind Levels'), findsOneWidget);
    expect(find.text('Play'), findsNWidgets(2));
    expect(find.text('Levels'), findsNWidgets(2));
    expect(find.text('How to play'), findsOneWidget);
    expect(find.textContaining('Continue'), findsNothing);
  });

  testWidgets('returning player sees Continue level N and total', (t) async {
    await pumpApp(t, progress: cleared(3));
    expect(t.widget<Text>(buttonText(windPlay())).data, 'Continue level 4');
    expect(t.widget<Text>(buttonText(memoryPlay())).data, 'Play');
    expect(find.text('3 of 12 cleared'), findsOneWidget);
    expect(find.text(formatPoints(400 + 800 + 1200)), findsOneWidget);
  });

  testWidgets('after all 12, Continue is replaced', (t) async {
    await pumpApp(t, progress: cleared(12));
    expect(find.text('Replay level 12'), findsOneWidget);
    expect(find.text('All 12 cleared'), findsOneWidget);
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
    await t.tap(windPlay());
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
    await t.tap(find.byKey(const ValueKey('wind-levels')));
    await t.pumpAndSettle();
    expect(find.text('Wind Levels'), findsOneWidget);
    expect(find.text('3 blocks · 8s of wind'), findsOneWidget);
    await t.scrollUntilVisible(find.textContaining('10 blocks').last, 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('10 blocks'), findsWidgets);
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

  testWidgets('how to play explains both games', (t) async {
    await pumpApp(t);
    await t.tap(find.text('How to play'));
    await t.pumpAndSettle();
    expect(find.text('Memory Towers'), findsWidgets);
    expect(find.textContaining('Tap a colour to stack the next cube'),
        findsOneWidget);
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

  for (final home in <Widget>[
    const MenuScreen(),
    const LevelsScreen(),
    const MemoryLevelsScreen(),
  ]) {
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
