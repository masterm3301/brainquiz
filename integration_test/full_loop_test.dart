import 'package:brainquiz/ads/rewarded_ads.dart';
import 'package:brainquiz/app.dart';
import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/game/tower_generator.dart';
import 'package:brainquiz/memory/memory_levels.dart';
import 'package:brainquiz/progress/progress_controller.dart';
import 'package:brainquiz/progress/progress_store.dart';
import 'package:brainquiz/ui/app_scope.dart';
import 'package:brainquiz/ui/screens/build_view.dart';
import 'package:brainquiz/ui/screens/menu_screen.dart';
import 'package:brainquiz/ui/widgets/arena.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _seed = 42;

/// Pumps real frames until [finder] matches.
Future<void> waitFor(
  WidgetTester t,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final watch = Stopwatch()..start();
  while (finder.evaluate().isEmpty) {
    if (watch.elapsed > timeout) {
      final shown = t
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .join(' | ');
      fail(
        'Waited $timeout for ${finder.describeMatch(Plurality.one)}. '
        'On screen: $shown',
      );
    }
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Drags [block] from the tray and lets go over the arena's centre line.
Future<void> place(WidgetTester t, Block block) async {
  final tile = find.byWidgetPredicate(
    (w) => w is Draggable<Block> && w.data == block,
  );
  final from = t.getCenter(tile);
  final to = t.getCenter(find.byType(Arena));
  final gesture = await t.startGesture(from);
  await t.pump(const Duration(milliseconds: 50));
  for (var step = 1; step <= 10; step++) {
    await gesture.moveTo(Offset.lerp(from, to, step / 10)!);
    await t.pump(const Duration(milliseconds: 30));
  }
  await gesture.up();
  await t.pump(const Duration(milliseconds: 100));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('level 1 plays from the menu to a saved win', (t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final progress = ProgressController(SharedPrefsProgressStore());
    await progress.load();
    await t.pumpWidget(
      AppScope(
        progress: progress,
        memoryProgress: ProgressController(
          SharedPrefsProgressStore.memory(memoryLevels.length),
          lastLevel: memoryLevels.length,
        ),
        ads: NoAds(),
        newSeed: () => _seed,
        child: const TowerBuildApp(home: MenuScreen()),
      ),
    );
    await t.pump();

    await t.tap(find.byKey(const ValueKey('mode-wind')));
    await waitFor(t, find.byKey(const ValueKey('wind-play')));
    await t.tap(find.byKey(const ValueKey('wind-play')));
    await waitFor(t, find.text('Memorise the tower'));
    expect(find.text('Level 1 of 12'), findsOneWidget);

    final level = levels.first;
    await waitFor(t, find.text('Block 1 of ${level.blocks}'));
    // The tray learns the held-block size one frame after the arena's layout.
    // Nobody can start a drag sooner than that, so neither does this test.
    await t.pump(const Duration(milliseconds: 200));

    final tower = generateTower(level, _seed);
    for (var row = 0; row < level.blocks; row++) {
      await place(t, tower.blocks[row]);
      final next = row + 1 == level.blocks
          ? 'All ${level.blocks} placed'
          : 'Block ${row + 2} of ${level.blocks}';
      await waitFor(t, find.text(next));
    }

    final attempt = t.widget<BuildView>(find.byType(BuildView)).attempt;
    expect(attempt.placed.map((p) => p.x), everyElement(0));
    expect(attempt.report.wrongRows, isEmpty);

    await t.tap(find.text('Lock the tower'));
    await waitFor(t, find.text('It has to stand'));

    await waitFor(t, find.text('Your tower stood'));

    final saved = await SharedPrefsProgressStore().load();
    expect(saved.records[1]?.stars, 3);
    expect(saved.totalPoints, greaterThan(0));
  });
}
