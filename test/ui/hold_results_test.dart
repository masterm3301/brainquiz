import 'package:brainquiz/game/attempt.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/game/explanation.dart';
import 'package:brainquiz/game/tower_generator.dart';
import 'package:brainquiz/ui/screens/levels_screen.dart';
import 'package:brainquiz/ui/app_scope.dart';
import 'package:brainquiz/ui/screens/attempt_flow.dart';
import 'package:brainquiz/ui/screens/fell_view.dart';
import 'package:brainquiz/ui/screens/hold_view.dart';
import 'package:brainquiz/ui/screens/stood_view.dart';
import 'package:brainquiz/ui/screens/wind_ready_view.dart';
import 'package:brainquiz/ui/widgets/collapse_view.dart';
import 'package:brainquiz/ui/widgets/neon_button.dart';
import 'package:brainquiz/ui/widgets/tower_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ads.dart';
import '../support/pump_app.dart';
import '../support/flow_helpers.dart';

AppScope scopeOf(WidgetTester t) =>
    AppScope.of(t.element(find.byType(AttemptFlow)));

int stars(WidgetTester t, int level) =>
    scopeOf(t).progress.progress.records[level]?.stars ?? 0;

void main() {
  testWidgets('no ad ready: Lock goes straight to the wind', (t) async {
    phone(t);
    await buildPerfect(t, 1);
    expect(find.text('It has to stand'), findsOneWidget);
    expect(find.textContaining('Watch ad'), findsNothing);
  });

  testWidgets('ad ready: offer shown before the wind', (t) async {
    phone(t);
    final ads = FakeAds()..ready = true;
    await buildPerfect(t, 1, ads: ads);
    expect(find.text('Watch ad for an extra brace'), findsOneWidget);
    expect(find.text('Start the wind'), findsOneWidget);
    expect(find.text('It has to stand'), findsNothing);
    await t.tap(find.text('Start the wind'));
    await t.pump();
    expect(find.text('It has to stand'), findsOneWidget);
  });

  testWidgets('earned ad gives 2 braces; closed early gives 1', (t) async {
    phone(t);
    final ads = FakeAds()..ready = true;
    await buildPerfect(t, 1, ads: ads);
    await t.tap(find.text('Watch ad for an extra brace'));
    await t.pump();
    ads.complete(true);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('Start the wind'));
    await t.pump();
    expect(find.text('Brace it (2 left)'), findsOneWidget);
    expect(
      find.text('Free brace from the ad. Use it to steady the tower.'),
      findsOneWidget,
    );
    await t.tap(find.text('Brace it (2 left)'));
    await t.pump();
    expect(find.text('Brace it (1 left)'), findsOneWidget);
    expect(
      find.text(
        'One brace left. Use it to steady the tower — costs 40 points.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an ad closed early gives 1 brace', (t) async {
    phone(t);
    final ads = FakeAds()..ready = true;
    await buildPerfect(t, 1, ads: ads);
    await t.tap(find.text('Watch ad for an extra brace'));
    await t.pump();
    ads.complete(false);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('Start the wind'));
    await t.pump();
    expect(find.text('Brace it (1 left)'), findsOneWidget);
    await t.tap(find.text('Brace it (1 left)'));
    await t.pump();
    expect(find.textContaining('Brace it'), findsNothing);
    expect(find.textContaining('One brace left'), findsNothing);
  });

  testWidgets('a double tap shows only one extra-brace ad', (t) async {
    phone(t);
    final ads = FakeAds()..ready = true;
    await buildPerfect(t, 1, ads: ads);
    final button = find.text('Watch ad for an extra brace');
    await t.tap(button);
    await t.tap(button, warnIfMissed: false);
    await t.pump();
    expect(ads.showCount, 1);
    ads.complete(true);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Watch ad for an extra brace'), findsNothing);
    await t.tap(find.text('Start the wind'));
    await t.pump();
    expect(find.text('Brace it (2 left)'), findsOneWidget);
  });

  testWidgets('no ad button appears during the wind', (t) async {
    phone(t);
    final ads = FakeAds()..ready = true;
    await buildPerfect(t, 1, ads: ads);
    await t.tap(find.text('Start the wind'));
    await t.pump();
    ads.ready = true;
    await t.pump();
    expect(find.byType(HoldView), findsOneWidget);
    expect(find.textContaining('Watch ad'), findsNothing);
    expect(find.text('AD'), findsNothing);
  });

  testWidgets('hold shows the sheet stats', (t) async {
    phone(t);
    await buildPerfect(t, 1);
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('HANDS OFF — WIND IS ON'), findsOneWidget);
    expect(find.text('WIND'), findsOneWidget);
    expect(find.text('LEAN'), findsOneWidget);
    expect(find.text('STABILITY'), findsOneWidget);
    expect(find.text('Gust 1 of 1'), findsOneWidget);
    expect(find.text('8s'), findsOneWidget);
    await pumpSeconds(t, 2);
    expect(find.text('6s'), findsOneWidget);
    final tower = t.widget<TowerView>(find.byType(TowerView));
    expect(tower.placed.length, 3);
  });

  testWidgets('a perfect copy reaches the stood screen and records it', (
    t,
  ) async {
    phone(t);
    await buildPerfect(t, 1);
    await pumpSeconds(t, 9);
    expect(find.text('Your tower stood'), findsOneWidget);
    expect(find.text('HELD 8 SECONDS'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('8s'), findsOneWidget);
    expect(find.text('+117'), findsOneWidget);
    expect(find.text('WHY IT HELD'), findsOneWidget);
    expect(find.text('Level 2 — hold for 10s'), findsOneWidget);
    expect(scopeOf(t).progress.progress.records.length, 1);
    expect(scopeOf(t).progress.progress.records[1]!.bestPoints, 117);
    expect(stars(t, 1), 3);
  });

  testWidgets('stood button goes to the next level', (t) async {
    phone(t);
    await buildPerfect(t, 1);
    await pumpSeconds(t, 9);
    await t.tap(find.text('Level 2 — hold for 10s'));
    await t.pump();
    expect(find.text('Level 2 of 12'), findsOneWidget);
    expect(find.text('Memorise the tower'), findsOneWidget);
    expect(scopeOf(t).progress.progress.records.length, 1);
  });

  testWidgets('clearing level 12 shows the final state', (t) async {
    phone(t);
    final progress = Progress({
      for (var n = 1; n <= 11; n++) n: const LevelRecord(stars: 3, bestPoints: 100),
    });
    await buildPerfect(t, 12, progress: progress);
    await pumpSeconds(t, 41);
    expect(find.text('Your tower stood'), findsOneWidget);
    expect(find.text('You cleared all 12'), findsOneWidget);
    expect(scopeOf(t).progress.progress.records.containsKey(12), isTrue);
    await t.tap(find.text('You cleared all 12'));
    await t.pumpAndSettle();
    expect(find.byType(LevelsScreen), findsOneWidget);
    expect(find.text('Twelve levels'), findsOneWidget);
  });

  testWidgets('a stood result is saved exactly once', (t) async {
    phone(t);
    final store = CountingProgressStore(Progress.empty);
    await buildPerfect(t, 1, store: store);
    await pumpSeconds(t, 9);
    expect(find.text('Your tower stood'), findsOneWidget);
    await pumpSeconds(t, 3);
    expect(store.saves, 1);
    await t.tap(find.text('Level 2 — hold for 10s'));
    await t.pump();
    await pumpSeconds(t, 1);
    expect(store.saves, 1);
    expect(scopeOf(t).progress.progress.records.length, 1);
  });

  testWidgets('a fall shows the true reason and records nothing', (t) async {
    phone(t);
    final ref = await buildWrong(t, 4);
    await pumpSeconds(t, 19);
    final text = explainFall(ref.report, total: 6);
    expect(find.text(text.headline), findsOneWidget);
    expect(find.text(text.detail), findsOneWidget);
    expect(find.text('${ref.report.score}%'), findsOneWidget);
    expect(find.textContaining('FELL AT '), findsOneWidget);
    expect(find.textContaining(' OF 18 SECONDS'), findsOneWidget);
    expect(find.text('At lock'), findsOneWidget);
    expect(find.text('WHAT WENT WRONG'), findsOneWidget);
    expect(find.byType(CollapseView), findsOneWidget);
    expect(find.text('Replay the fall'), findsOneWidget);
    expect(find.text('Build again'), findsOneWidget);
    expect(scopeOf(t).progress.progress.records, isEmpty);
  });

  testWidgets('Replay the fall replays without changing the result', (t) async {
    phone(t);
    await buildWrong(t, 4);
    await pumpSeconds(t, 19);
    final title = t.widget<Text>(find.byKey(const ValueKey('result-title')));
    final before = title.data;
    await t.pump(const Duration(seconds: 2));
    final state = t.state<CollapseViewState>(find.byType(CollapseView));
    expect(state.controller.value, 1);
    await t.tap(find.text('Replay the fall'));
    await t.pump(const Duration(milliseconds: 100));
    expect(state.controller.value, lessThan(1));
    await t.pump(const Duration(seconds: 2));
    expect(
      t.widget<Text>(find.byKey(const ValueKey('result-title'))).data,
      before,
    );
    expect(scopeOf(t).progress.progress.records, isEmpty);
  });

  testWidgets('Build again gives a different tower on the same level', (
    t,
  ) async {
    phone(t);
    await buildWrong(t, 4);
    await pumpSeconds(t, 19);
    await t.tap(find.text('Build again'));
    await t.pump();
    expect(find.text('Level 4 of 12'), findsOneWidget);
    expect(find.text('Memorise the tower'), findsOneWidget);
    final fresh = t.widget<TowerView>(find.byType(TowerView)).placed;
    final old = generateTower(levels[3], 42).blocks;
    expect([for (final p in fresh) p.block], isNot(old));
    await pumpSeconds(t, 7);
    expect(find.text('Block 1 of 6'), findsOneWidget);
  });

  testWidgets('back during the hold leaves with no result', (t) async {
    phone(t);
    await pumpApp(t, home: const _Launcher());
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await pumpSeconds(t, 6);
    final ref = reference(1)..finishStudy();
    for (var row = 0; row < 3; row++) {
      await placeRight(t, ref, row);
    }
    await tapLock(t);
    await t.pump(const Duration(milliseconds: 200));
    expect(find.byType(HoldView), findsOneWidget);
    await t.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await t.pumpAndSettle();
    expect(find.byType(AttemptFlow), findsNothing);
    expect(find.text('open'), findsOneWidget);
    final scope = AppScope.of(t.element(find.text('open')));
    expect(scope.progress.progress.records, isEmpty);
  });

  testWidgets('back at about 7.9s of the hold records nothing', (t) async {
    phone(t);
    final store = CountingProgressStore(Progress.empty);
    await pumpApp(t, store: store, home: const _Launcher());
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await pumpSeconds(t, 6);
    final ref = reference(1)..finishStudy();
    for (var row = 0; row < 3; row++) {
      await placeRight(t, ref, row);
    }
    await tapLock(t);
    await pumpFor(t, 7.9);
    expect(find.byType(HoldView), findsOneWidget);
    await t.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await pumpSeconds(t, 1);
    await t.pumpAndSettle();
    expect(find.byType(AttemptFlow), findsNothing);
    final scope = AppScope.of(t.element(find.text('open')));
    expect(scope.progress.progress.records, isEmpty);
    expect(store.saves, 0);
  });

  testWidgets('a long pump gap advances the wind by one clamped step', (
    t,
  ) async {
    phone(t);
    await buildPerfect(t, 1);
    await t.pump(const Duration(milliseconds: 50));
    final sim = t.widget<HoldView>(find.byType(HoldView)).sim;
    final before = sim.elapsed;
    await t.pump(const Duration(seconds: 30));
    expect(sim.elapsed - before, lessThanOrEqualTo(0.0501));
    expect(sim.finished, isFalse);
    expect(find.byType(HoldView), findsOneWidget);
  });

  group('primary buttons are fully on screen without scrolling', () {
    Attempt locked() {
      final a = Attempt(level: levels[3], seed: 42)..finishStudy();
      for (final b in a.tower.blocks) {
        a.drop(b, 0);
      }
      a.lock();
      return a;
    }

    AttemptResult result(Attempt a, {required bool stood}) => AttemptResult(
      level: a.level,
      stood: stood,
      correct: 6,
      total: 6,
      heldSeconds: 18,
      points: 240,
      stars: 3,
      lockStability: 34,
      fellAtSeconds: stood ? 0 : 9,
      headline: 'Right blocks, wrong order',
      detail:
          '${explainFall(a.report, total: 6).detail} The wide yellow block '
          'sat too high, so the tower was top heavy.',
    );

    void expectOnScreen(WidgetTester t, Finder button, Size size) {
      final rect = t.getRect(button);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(size.height));
    }

    for (final size in const [Size(360, 568), Size(393, 735)]) {
      Future<void> show(WidgetTester t, Widget Function(Attempt) view) async {
        phone(t, size: size);
        final attempt = locked();
        await pumpApp(t, home: view(attempt));
        await t.pump(const Duration(milliseconds: 100));
        expect(t.takeException(), isNull);
      }

      testWidgets('hold brace button at ${size.width}x${size.height}', (t) async {
        await show(
          t,
          (a) => HoldView(attempt: a, sim: a.startHold(), onEnded: (_) {}),
        );
        expectOnScreen(t, find.widgetWithText(NeonButton, 'Brace it (1 left)'), size);
        expectOnScreen(t, find.text('STABILITY'), size);
      });

      testWidgets('stood button at ${size.width}x${size.height}', (t) async {
        await show(
          t,
          (a) => StoodView(
            attempt: a,
            result: result(a, stood: true),
            onNextLevel: () {},
            onBackToLevels: () {},
          ),
        );
        expectOnScreen(t, find.widgetWithText(NeonButton, 'Level 5 — hold for 22s'), size);
      });

      testWidgets('fell buttons at ${size.width}x${size.height}', (t) async {
        await show(
          t,
          (a) => FellView(
            attempt: a,
            result: result(a, stood: false),
            direction: 1,
            onBuildAgain: () {},
          ),
        );
        expectOnScreen(t, find.text('Build again'), size);
        expectOnScreen(t, find.text('Replay the fall'), size);
      });
    }
  });

  group('no overflow at 320x568, text scale 1.3, 10 blocks', () {
    Attempt locked() {
      final a = Attempt(level: levels[11], seed: 7)..finishStudy();
      for (final b in a.tower.blocks) {
        a.drop(b, 0);
      }
      a.lock();
      return a;
    }

    AttemptResult result(Attempt a, {required bool stood}) => AttemptResult(
      level: a.level,
      stood: stood,
      correct: 10,
      total: 10,
      heldSeconds: stood ? 40 : 21,
      points: stood ? 3234 : 0,
      stars: stood ? 3 : 0,
      lockStability: 34,
      fellAtSeconds: stood ? 0 : 21,
      headline: 'Right blocks, crooked stack, and then some',
      detail:
          'Every block matched and the stack was straight, but the wind '
          'was too strong this time. Every block matched and the stack '
          'was straight, but the wind was too strong this time.',
    );

    Future<void> show(WidgetTester t, Widget Function(Attempt) view) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final attempt = locked();
      await pumpApp(
        t,
        ads: FakeAds()..ready = true,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: view(attempt),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
    }

    testWidgets('wind ready', (t) async {
      await show(t, (a) => WindReadyView(attempt: a, onStart: () {}));
    });

    testWidgets('hold', (t) async {
      await show(
        t,
        (a) => HoldView(attempt: a, sim: a.startHold(), onEnded: (_) {}),
      );
    });

    testWidgets('stood', (t) async {
      await show(
        t,
        (a) => StoodView(
          attempt: a,
          result: result(a, stood: true),
          onNextLevel: () {},
          onBackToLevels: () {},
        ),
      );
    });

    testWidgets('fell', (t) async {
      await show(
        t,
        (a) => FellView(
          attempt: a,
          result: result(a, stood: false),
          direction: 1,
          onBuildAgain: () {},
        ),
      );
    });
  });
}

class _Launcher extends StatelessWidget {
  const _Launcher();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AttemptFlow(levelNumber: 1),
        ),
      ),
      child: const Text('open'),
    ),
  );
}
