import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/ui/screens/about_screen.dart';
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
Finder key(String k) => find.byKey(ValueKey(k));

/// Switches home to the Wind tab.
Future<void> openWind(WidgetTester t) async {
  await t.tap(key('mode-wind'));
  await t.pumpAndSettle();
  expect(windPlay(), findsOneWidget);
}

  testWidgets('a new player lands on Tower build, level 1', (t) async {
    await pumpApp(t);
    expect(find.text('Memory\nTowers'), findsOneWidget);
    expect(t.widget<Text>(buttonText(memoryPlay())).data, 'Play level 1');
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('NEXT UP · WARM-UP'), findsOneWidget);
    expect(find.text('3 cubes · 4 colours'), findsOneWidget);
    expect(t.widget<Text>(key('menu-stars')).data, '0/135');
    expect(t.widget<Text>(key('menu-points')).data, '0');
    expect(key('memory-cube-1'), findsOneWidget);
    expect(key('memory-cube-2'), findsNothing, reason: 'locked: no button');
    expect(t.widget<Text>(key('menu-locked-count')).data, '+29');
    expect(windPlay(), findsNothing, reason: 'Wind is the other tab');
    expect(key('about'), findsOneWidget);
    expect(key('menu-help'), findsOneWidget);
  });

  testWidgets('the HUD adds up stars and points from both games', (t) async {
    await pumpApp(t,
        progress: cleared(3),
        memoryProgress: const Progress({
          1: LevelRecord(stars: 2, bestPoints: 40),
        }, lastLevel: 33));
    expect(t.widget<Text>(key('menu-stars')).data, '11/135');
    expect(t.widget<Text>(key('menu-points')).data,
        formatPoints(400 + 800 + 1200 + 40));
    expect(find.textContaining('1/33'), findsOneWidget);
    expect(find.textContaining('3/12'), findsOneWidget);
  });

  testWidgets('Wind tab: its tower, card, steps and Play level N', (t) async {
    await pumpApp(t, progress: cleared(3));
    await openWind(t);
    expect(find.text('Wind\nLevels'), findsOneWidget);
    expect(t.widget<Text>(buttonText(windPlay())).data, 'Play level 4');
    expect(memoryPlay(), findsNothing);
    expect(find.text('NEXT UP · 4 OF 12'), findsOneWidget);
    expect(find.text('6 blocks'), findsOneWidget);
    expect(find.text('Strong wind'), findsOneWidget);
    expect(find.text('Memorise'), findsOneWidget);
    expect(find.text('Rebuild'), findsOneWidget);
    expect(find.text('Lock it'), findsOneWidget);
    for (final n in [1, 2, 3, 4]) {
      expect(key('wind-block-$n'), findsOneWidget);
    }
    await t.tap(key('mode-memory'));
    await t.pumpAndSettle();
    expect(memoryPlay(), findsOneWidget);
  });

  testWidgets('after all 12, Play becomes Replay', (t) async {
    await pumpApp(t, progress: cleared(12));
    await openWind(t);
    expect(find.text('Replay level 12'), findsOneWidget);
    expect(find.text('ALL 12 CLEARED'), findsOneWidget);
  });

  testWidgets('a cleared cube replays its level; the next one plays', (t) async {
    await pumpApp(t,
        memoryProgress: Progress(cleared(2).records, lastLevel: 33));
    await t.tap(key('memory-cube-1'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text('LEVEL 1 OF 33'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(key('memory-cube-3'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text('LEVEL 3 OF 33'), findsOneWidget);
  });

  testWidgets('a tall ladder folds old levels into +N, which opens the list',
      (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pumpApp(t,
        memoryProgress: Progress(cleared(24).records, lastLevel: 33));
    expect(key('memory-cube-25'), findsOneWidget);
    expect(key('memory-cube-24'), findsOneWidget);
    expect(key('memory-cube-1'), findsNothing);
    await t.tap(key('menu-more-cleared'));
    await t.pumpAndSettle();
    expect(find.byType(MemoryLevelsScreen), findsOneWidget);
  });

  testWidgets('the next-up card opens the full list of levels', (t) async {
    await pumpApp(t);
    await t.tap(key('memory-card'));
    await t.pumpAndSettle();
    expect(find.byType(MemoryLevelsScreen), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    await openWind(t);
    await t.tap(key('wind-card'));
    await t.pumpAndSettle();
    expect(find.byType(LevelsScreen), findsOneWidget);
    expect(find.text('3 blocks · 8s of wind'), findsOneWidget);
  });

  testWidgets('? opens About with How to play already open', (t) async {
    await pumpApp(t);
    await t.tap(key('menu-help'));
    await t.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Study the tower before the countdown ends.'),
        findsOneWidget);
  });

  group('Privacy options, on the About page', () {
    Future<void> openAbout(WidgetTester t, FakeAds ads) async {
      await pumpApp(t, ads: ads);
      await t.tap(key('about'));
      await t.pumpAndSettle();
    }

    testWidgets('hidden when not required', (t) async {
      await openAbout(t, FakeAds());
      expect(find.text('Privacy options'), findsNothing);
    });

    testWidgets('shown when required, and opens the form', (t) async {
      final ads = FakeAds()..privacyRequired = true;
      await openAbout(t, ads);
      final button = key('about-privacy');
      await t.scrollUntilVisible(button, 200);
      await t.ensureVisible(button);
      await t.pumpAndSettle();
      await t.tap(button);
      await t.pump();
      expect(ads.privacyShowCount, 1);
    });

    testWidgets('appears when the requirement arrives later', (t) async {
      final ads = FakeAds();
      await openAbout(t, ads);
      ads.privacyRequired = true;
      await t.pump();
      await t.scrollUntilVisible(key('about-privacy'), 200);
      expect(key('about-privacy'), findsOneWidget);
    });
  });

  testWidgets('wind Play opens level 1, and back returns to the Wind tab',
      (t) async {
    await pumpApp(t);
    await openWind(t);
    await t.tap(windPlay());
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(AttemptFlow), findsOneWidget);
    expect(find.text('Level 1 of 12'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(windPlay(), findsOneWidget);
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

  testWidgets('About: how to play folds open, and every section shows',
      (t) async {
    await pumpApp(t);
    await t.tap(find.byKey(const ValueKey('about')));
    await t.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Study the tower before the countdown ends.'),
        findsNothing,
        reason: 'the rules stay hidden until tapped');
    expect(find.text('TOP MEMORY RECALLERS'), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.text('MADE BY'), findsOneWidget);
    expect(find.text(developerBio), findsOneWidget);
    expect(find.text('github.com/masterm3301'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('about-how-to-play')));
    await t.pumpAndSettle();
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

    await t.tap(find.byKey(const ValueKey('about-how-to-play')));
    await t.pumpAndSettle();
    expect(find.text('Study the tower before the countdown ends.'),
        findsNothing);
  });

  group('GitHub link', () {
    Future<List<Uri>> tapGithub(WidgetTester t, {required bool opens}) async {
      final opened = <Uri>[];
      await pumpApp(t,
          home: AboutScreen(openLink: (url) async {
            opened.add(url);
            return opens;
          }));
      final link = find.byKey(const ValueKey('about-github'));
      await t.ensureVisible(link);
      await t.pumpAndSettle();
      await t.tap(link);
      await t.pumpAndSettle();
      return opened;
    }

    testWidgets('opens the developer profile', (t) async {
      final opened = await tapGithub(t, opens: true);
      expect(opened, [Uri.parse('https://github.com/masterm3301')]);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('says so when the link cannot open', (t) async {
      await tapGithub(t, opens: false);
      expect(find.textContaining('Could not open the link'), findsOneWidget);
    });
  });

  for (final home in <Widget>[
    const MenuScreen(),
    const LevelsScreen(),
    const MemoryLevelsScreen(),
  ]) {
    if (home is MenuScreen) {
      testWidgets('MenuScreen Wind tab has no overflow at 320x568, scale 1.3',
          (t) async {
        t.view.physicalSize = const Size(320, 568);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearAllTestValues);
        await pumpApp(t, progress: cleared(3), home: home);
        await t.tap(key('mode-wind'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
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

  group('Reset game', () {
    Future<(MemoryProgressStore, MemoryProgressStore)> openReset(
        WidgetTester t) async {
      final wind = MemoryProgressStore(cleared(3));
      final memory = MemoryProgressStore(
          Progress(cleared(5).records, lastLevel: 33));
      await pumpApp(t, store: wind, memoryStore: memory);
      await t.tap(find.byKey(const ValueKey('about')));
      await t.pumpAndSettle();
      final reset = find.byKey(const ValueKey('about-reset'));
      await t.ensureVisible(reset);
      await t.pumpAndSettle();
      await t.tap(reset);
      await t.pumpAndSettle();
      expect(find.text('Reset game?'), findsOneWidget);
      return (wind, memory);
    }

    testWidgets('Keep my progress changes nothing', (t) async {
      final (wind, memory) = await openReset(t);
      await t.tap(find.byKey(const ValueKey('about-reset-cancel')));
      await t.pumpAndSettle();
      expect(find.text('Reset game?'), findsNothing);
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(wind.progress.records, hasLength(3));
      expect(memory.progress.records, hasLength(5));
    });

    testWidgets('confirming wipes both games, saves, and goes home',
        (t) async {
      final (wind, memory) = await openReset(t);
      await t.tap(find.byKey(const ValueKey('about-reset-confirm')));
      await t.pumpAndSettle();
      expect(find.byType(AboutScreen), findsNothing);
      expect(find.byType(MenuScreen), findsOneWidget);
      expect(find.text('Play level 1'), findsOneWidget);
      expect(t.widget<Text>(key('menu-stars')).data, '0/135');
      expect(wind.progress.records, isEmpty);
      expect(memory.progress.records, isEmpty);
      expect(memory.progress.lastLevel, 33);
    });
  });
}
