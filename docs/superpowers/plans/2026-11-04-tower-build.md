# Tower Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Flutter starter into Tower Build, a dark-only 2D neon memory game with 12 levels, a wind challenge, saved progress, and optional rewarded ads.

**Architecture:** Game rules are plain Dart in `lib/game/`, with no Flutter widgets and with seeded randomness, so the fairness guarantees can be tested across many seeds. Progress and ads sit behind small interfaces in `lib/progress/` and `lib/ads/`. Screens in `lib/ui/` use `ChangeNotifier` and plain `Navigator`, with no state-management package.

**Tech Stack:** Flutter 3.44 / Dart 3.12, `shared_preferences` ^2.5.6, `google_mobile_ads` ^9.2.0, `flutter_launcher_icons` ^0.14.4 (dev), bundled Nunito variable font.

**Spec:** `docs/superpowers/specs/2026-11-04-tower-build-design.md`
**Visual reference:** `docs/design-reference/tower-build-sheet-1b.html`, screens 01 to 05. Read its inline styles for sizes, spacing, and glow. Screen 06 is out of scope.

## Global Constraints

- Dark only: no light theme, no theme toggle. Portrait only. Android and iOS.
- 2D, drawn in Flutter. No 3D, no game or physics engine, no robot, no footage or name from the inspiration video.
- No backend, accounts, analytics, or in-app purchases. Network is used only by ads.
- Rewarded ads only: no banners, interstitials, or forced ads. Ad buttons never appear during the wind.
- All ad IDs are Google's test IDs. No real IDs and no store submission in this work.
- Display name is `Tower Build`. Folder, package, and app ID stay `brainquiz` / `com.example.brainquiz`.
- No sound.
- Work happens on the `tower-build` branch. Each task ends with its tests and `flutter analyze` passing, then a commit. Never push.
- Never use Chrome or `flutter run -d chrome`, including headless. Run the app only on emulators: Android `Pixel_3a_API_34` and the iOS Simulator.
- Every colour comes from `lib/ui/theme/tokens.dart`. Corners are square, or 3px at most on blocks. Text is Nunito at weight 700 to 900, apart from body copy as shown in the sheet.

## Review Focus

Each has a test in the owning task.

1. A block released outside the arena, or not touching the block below, returns to the tray and isn't placed (Task 11).
2. The app going to the background during Memorise or Hold doesn't skip study time or jump the wind forward (Tasks 5 and 11).
3. Saved progress that is corrupt or from an unknown version gives an empty start, not a crash (Task 7).
4. An ad closed early, unavailable, or double-tapped gives no reward and leaves the game playable (Tasks 8, 11, and 12).
5. A 10-block tower on a 320×568 phone with text scale 1.3 renders with no overflow on every game screen (Tasks 11 and 12).

---

### Task 1: Project foundation

**Files:**
- Modify: `pubspec.yaml`, `lib/main.dart`, `analysis_options.yaml` (only if needed), `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`, `ios/Runner/Info.plist`, `ios/Runner/Base.lproj/LaunchScreen.storyboard`, `android/app/src/main/res/drawable/launch_background.xml`, `android/app/src/main/res/drawable-v21/launch_background.xml`
- Create: `assets/fonts/Nunito-Variable.ttf`, `assets/fonts/OFL.txt`, `lib/app.dart`, `lib/ui/theme/tokens.dart`, `lib/ui/theme/text.dart`
- Replace: `test/widget_test.dart` with `test/app_test.dart`

**Interfaces:**
- Produces: `class AppColors` with static `Color` constants; `TextStyle nunito(double size, {int weight = 800, Color color = AppColors.text, double? letterSpacing, double? height})`; `TextStyle label({double size = 12, Color color = AppColors.label})`; `class TowerBuildApp extends StatelessWidget` with `Widget home` parameter.

- [ ] **Step 1: Add dependencies and the font**

Run: `flutter pub add shared_preferences google_mobile_ads && flutter pub add --dev flutter_launcher_icons`

Download the font and licence:
```bash
mkdir -p assets/fonts
curl -sL 'https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/Nunito%5Bwght%5D.ttf' -o assets/fonts/Nunito-Variable.ttf
curl -sL 'https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/OFL.txt' -o assets/fonts/OFL.txt
```
Declare family `Nunito` and asset `assets/fonts/` in `pubspec.yaml`. Register `OFL.txt` with `LicenseRegistry` in `main()`.

- [ ] **Step 2: Write the failing test** in `test/app_test.dart`

```dart
testWidgets('app is dark only and uses Nunito', (tester) async {
  await tester.pumpWidget(const TowerBuildApp(home: SizedBox()));
  final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(app.themeMode, ThemeMode.dark);
  expect(app.theme, isNull);
  expect(app.darkTheme!.brightness, Brightness.dark);
  expect(app.darkTheme!.scaffoldBackgroundColor, const Color(0xFF05070D));
  expect(app.title, 'Tower Build');
  expect(app.debugShowCheckedModeBanner, isFalse);
});

test('nunito sets the variable font weight', () {
  final s = nunito(18, weight: 900);
  expect(s.fontFamily, 'Nunito');
  expect(s.fontVariations, [const FontVariation('wght', 900)]);
  expect(s.fontWeight, FontWeight.w900);
});
```

- [ ] **Step 3: Run it and confirm it fails**

Run: `flutter test test/app_test.dart`
Expected: FAIL because `TowerBuildApp` and `nunito` aren't defined.

- [ ] **Step 4: Implement tokens, text helpers, and the app shell**

`AppColors` names and values (from the spec): `background 0xFF05070D`, `panel 0xFF0A0F1C`, `rule 0xFF12182A`, `trayBorder 0xFF1A2236`, `dashed 0xFF22304D`, `text 0xFFEEF3FF`, `textSecondary 0xFFC6CEE6`, `textTertiary 0xFF8A93B2`, `label 0xFF6B7394`, `green 0xFF22E06B`, `onGreen 0xFF04210F`, `cyan 0xFF06B6D4`, `yellow 0xFFF5D90A`, `red 0xFFFF3B30`, `arenaNormal 0xFF0D2416`, `arenaStood 0xFF133D22`, `arenaFell 0xFF2A0D0C`, `borderStood 0xFF1C3A28`, `borderFell 0xFF2A1A1C`.

`label()` is uppercase-ready: weight 900 with letter spacing `0.1 * size`. Callers uppercase the string.

`main()` must: call `WidgetsFlutterBinding.ensureInitialized()`, lock to `portraitUp`, set light status-bar icons on a transparent bar, and run `TowerBuildApp(home: SizedBox())` for now.

- [ ] **Step 5: Apply native settings**

- Android manifest: `android:label="Tower Build"`, activity `android:screenOrientation="portrait"`.
- `android/app/build.gradle.kts`: `minSdk = 24`, which `google_mobile_ads` requires.
- `Info.plist`: `CFBundleDisplayName` = `Tower Build`; `UISupportedInterfaceOrientations` contains only `UIInterfaceOrientationPortrait`; add `UIRequiresFullScreen` = true.
- Launch screens on both platforms use background `#05070d`, so no white flash appears.

- [ ] **Step 6: Run tests and analysis**

Run: `flutter test && flutter analyze`
Expected: all pass, no issues. `test/widget_test.dart` is gone.

---

### Task 2: Blocks and levels

**Files:**
- Create: `lib/game/block.dart`, `lib/game/levels.dart`
- Test: `test/game/levels_test.dart`, `test/game/block_test.dart`

**Interfaces:**
- Produces:
```dart
enum BlockColor { green, cyan, yellow, red }
enum BlockShape { rectangle, square, triangle, invertedTriangle }
class Block { // const, value equality on all four fields
  final BlockColor color; final BlockShape shape;
  final double width;  // fraction of arena width
  final double height; // logical pixels at scale 1
  double get mass;     // width * height, halved for both triangles
}
const Block pillar; // red rectangle, width 0.18, height 70
class LevelConfig {
  final int number, blocks, studySeconds, holdSeconds, gusts, decoys, colorCount;
  final List<BlockShape> shapes;
  double get windStrength; // 0.8 + (number - 1) * 0.2 / 11
  bool get wrongLimitApplies; // number >= 3
}
final List<LevelConfig> levels; // index 0 is level 1
```

- [ ] **Step 1: Write the failing tests**

```dart
test('level table matches the spec', () {
  const table = [ // blocks, study, hold, gusts, decoys
    [3,6,8,1,0],[4,6,10,1,0],[5,6,14,2,2],[6,6,18,3,4],[7,6,22,3,4],[7,5,24,3,4],
    [8,5,26,3,5],[8,5,28,4,5],[9,4,30,4,6],[9,4,32,4,6],[10,4,35,5,7],[10,3,40,5,7],
  ];
  expect(levels, hasLength(12));
  for (var i = 0; i < 12; i++) {
    final l = levels[i];
    expect([l.blocks,l.studySeconds,l.holdSeconds,l.gusts,l.decoys], table[i]);
    expect(l.number, i + 1);
  }
});

test('wind and shape progression', () {
  expect(levels.first.windStrength, closeTo(0.8, 1e-9));
  expect(levels.last.windStrength, closeTo(1.0, 1e-9));
  expect(levels[1].wrongLimitApplies, isFalse);
  expect(levels[2].wrongLimitApplies, isTrue);
  expect(levels[1].shapes, [BlockShape.rectangle, BlockShape.square]);
  expect(levels[2].shapes, contains(BlockShape.triangle));
  expect(levels[3].shapes, isNot(contains(BlockShape.invertedTriangle)));
  expect(levels[4].shapes, contains(BlockShape.invertedTriangle));
  expect(levels[1].colorCount, 2);
  expect(levels[2].colorCount, 3);
});

test('block equality and triangle mass', () {
  const a = Block(color: BlockColor.green, shape: BlockShape.rectangle, width: .5, height: 40);
  const b = Block(color: BlockColor.green, shape: BlockShape.rectangle, width: .5, height: 40);
  const t = Block(color: BlockColor.green, shape: BlockShape.triangle, width: .5, height: 40);
  expect(a, b);
  expect(a.hashCode, b.hashCode);
  expect(t.mass, a.mass / 2);
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/game/`
Expected: FAIL because the types aren't defined.

- [ ] **Step 3: Implement** `block.dart` and `levels.dart` to those interfaces.

- [ ] **Step 4: Run and confirm passing**

Run: `flutter test test/game/ && flutter analyze`
Expected: PASS, no issues.

---

### Task 3: Stability model

**Files:**
- Create: `lib/game/stability.dart`
- Test: `test/game/stability_test.dart`

**Interfaces:**
- Consumes: `Block`, `pillar`, `LevelConfig`.
- Produces:
```dart
const double dropTolerance = 0.035;
class PlacedBlock { final Block block; final double x; } // x: centre, arena-width fraction, 0 = centre line
enum Side { left, right }
class CrookedDrop { final int row; final Side side; } // row is 1-based, bottom block = 1
class StabilityReport {
  final int score; final bool mustFall; final List<int> wrongRows;
  final List<CrookedDrop> crooked; final bool topHeavy; final String meterLine;
  int get wrongCount; // wrongRows.length
}
double snapDrop(double rawX, {required double belowX});
bool touchesBelow(Block block, double x, PlacedBlock? below); // null below = pillar at x 0
StabilityReport assessStability({required List<Block> target, required List<PlacedBlock> placed, required LevelConfig level});
```

- [ ] **Step 1: Write the failing tests**

```dart
// Helpers: blockOf(color, width, height), level3 = levels[2], level2 = levels[1].
// target: rectangles of width .9, .7, .5 with heights 44, 34, 26.
test('a straight perfect copy scores 100 at every prefix', () {
  for (var n = 0; n <= target.length; n++) {
    final r = assessStability(target: target, placed: straight(target.take(n)), level: level3);
    expect(r.score, 100);
    expect(r.mustFall, isFalse);
  }
});
test('snapDrop snaps to the centre line, then to the block below', () {
  expect(snapDrop(0.03, belowX: 0), 0);
  expect(snapDrop(0.05, belowX: 0), 0.05);
  expect(snapDrop(0.31, belowX: 0.3), 0.3);
  expect(snapDrop(0.02, belowX: 0.3), 0);
});
test('wrong colour alone is a wrong block', () {
  final r = assessStability(target: target, placed: straight([recolour(target[0]), target[1], target[2]]), level: level3);
  expect(r.wrongRows, [1]);
  expect(r.score, 78);
  expect(r.mustFall, isFalse);
});
test('two wrong blocks must fall from level 3, not on level 2', () {
  final placed = straight([recolour(target[0]), recolour(target[1]), target[2]]);
  final l3 = assessStability(target: target, placed: placed, level: level3);
  expect(l3.mustFall, isTrue);
  expect(l3.score, lessThanOrEqualTo(35));
  expect(assessStability(target: target, placed: placed, level: level2).mustFall, isFalse);
});
test('a crooked drop lowers the score and records row and side', () {
  final placed = [PlacedBlock(target[0], 0), PlacedBlock(target[1], -0.12), PlacedBlock(target[2], -0.12)];
  final r = assessStability(target: target, placed: placed, level: level3);
  expect(r.wrongRows, isEmpty);
  expect(r.score, lessThan(100));
  expect(r.crooked.single.row, 2);
  expect(r.crooked.single.side, Side.left);
});
test('wide block too high is top heavy', () {
  final r = assessStability(target: target, placed: straight(target.reversed), level: level3);
  expect(r.topHeavy, isTrue);
});
test('touchesBelow needs real overlap', () {
  expect(touchesBelow(target[1], 0.4, null), isTrue);   // half widths .35 + .09 >= .4
  expect(touchesBelow(target[1], 0.5, null), isFalse);
  expect(touchesBelow(target[2], 0.0, PlacedBlock(target[0], 0)), isTrue);
});
test('meter line follows the score', () {
  expect(perfectReport.meterLine, 'Centre of mass still over the pillar.');
  expect(reportWithScore(55).meterLine, 'Getting shaky. Centre of mass is drifting.');
  expect(reportWithScore(20).meterLine, 'Too unstable to last in the wind.');
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/game/stability_test.dart`
Expected: FAIL because the file doesn't exist.

- [ ] **Step 3: Implement using this formula**

`snapDrop`: return 0 if `|rawX| <= dropTolerance`; otherwise `belowX` if `|rawX - belowX| <= dropTolerance`; otherwise `rawX`.

`assessStability` compares `placed` to the same-length prefix of `target`:
```
wrongRows = rows where placed block != target block
crooked   = rows where |x[i] - x[i-1]| > dropTolerance (x[-1] = 0, the pillar)
sumOffset = sum of |x[i] - x[i-1]| over crooked rows
comX      = sum(mass * x) / sum(mass)
comY      = sum(mass * rowCentreY) / (sum(mass) * totalHeight), using placed blocks' own heights
targetComY= the same for the target prefix
topHeavy  = comY - targetComY > 0.05
wrongCost = (level.wrongLimitApplies ? 22 : 12) * wrongCount
score     = 100 - wrongCost - 60*sumOffset - 200*|comX| - 150*max(0, comY - targetComY)
mustFall  = level.wrongLimitApplies && wrongCount >= 2
if mustFall: score = min(score, 35)
score     = round and clamp to 0..100
```
`meterLine`: score >= 70 gives the first line in the test, 40 to 69 the second, below 40 the third. Expose a testable way to get the line from a score (`meterLineFor(int score)`), and use that for `reportWithScore` in the test.

The constants may be tuned only if every test here and in Task 5 still passes.

- [ ] **Step 4: Run and confirm passing**

Run: `flutter test test/game/stability_test.dart && flutter analyze`
Expected: PASS, no issues.

---

### Task 4: Random tower generator

**Files:**
- Create: `lib/game/tower_generator.dart`
- Test: `test/game/tower_generator_test.dart`

**Interfaces:**
- Consumes: `Block`, `LevelConfig`.
- Produces:
```dart
class GeneratedTower {
  final int seed;
  final List<Block> blocks; // bottom first, pillar not included
  final List<Block> tray;   // real blocks + decoys, shuffled
}
GeneratedTower generateTower(LevelConfig level, int seed, {List<Block>? previous});
```

- [ ] **Step 1: Write the failing tests**

Each runs over 200 seeds at all 12 levels:

```dart
test('sizes: blocks and tray match the level', () { /* blocks.length == level.blocks; tray.length == blocks + decoys */ });
test('same seed gives the same tower', () { /* deep equal blocks and tray */ });
test('never repeats the previous tower', () {
  for (final level in levels) {
    var previous = <Block>[];
    for (var seed = 0; seed < 200; seed++) {
      final t = generateTower(level, seed, previous: previous);
      expect(listEquals(t.blocks, previous), isFalse);
      previous = t.blocks;
    }
  }
});
test('every tray block is distinct, so a choice is never ambiguous', () { /* tray.toSet().length == tray.length */ });
test('tray contains every tower block', () { /* tray.toSet() contains all blocks */ });
test('uses only the level shapes and colour count', () { /* shapes subset; distinct non-red tower colours <= colorCount */ });
test('tower blocks are never red; only decoys may be', () {});
test('towers taper: the bottom block is at least as wide as the top', () {});
test('from level 7, decoys differ from some real block in exactly one attribute', () {
  // Compare color, shape, and size (width+height as one attribute).
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/game/tower_generator_test.dart`
Expected: FAIL because the file doesn't exist.

- [ ] **Step 3: Implement** `generateTower`

Use only `Random(seed)`. If the result equals `previous`, retry with a derived seed until it differs, keeping `seed` in the result as the one that produced it.

- Rectangle and triangle widths come from `[.30, .42, .54, .66, .78, .90]`, and heights from `[26, 34, 44]`.
- Squares use widths `[.16, .22, .28]` with height `width * 340`.
- For taper, the row's ideal width step falls linearly from the widest step at the bottom to the narrowest at the top, with ±1 step of jitter. Bottom width must be at least top width.
- Choose colours from the first `colorCount` of `[green, cyan, yellow]`.
- Below level 7, a decoy is a random distinct block, and a quarter of them are red.
- From level 7, a decoy copies a random real block and changes exactly one attribute: colour, shape, or size by at least two width steps. Shape changes stay among rectangle and the two triangles, so a copied square changes only colour or size.

- [ ] **Step 4: Run and confirm passing**

Run: `flutter test test/game/tower_generator_test.dart && flutter analyze`
Expected: PASS, no issues.

---

### Task 5: Wind simulation and fairness guarantees

**Files:**
- Create: `lib/game/hold_simulation.dart`
- Test: `test/game/hold_simulation_test.dart`, `test/game/fairness_test.dart`

**Interfaces:**
- Consumes: `LevelConfig`, `assessStability`, `generateTower`, `PlacedBlock`.
- Produces:
```dart
const double maxLeanDegrees = 12;
double clampedDt(double dt); // max 1/20 s, shared with the study clock
class Gust { final double start, duration, amplitude; final int direction; } // direction -1 or 1
List<Gust> scheduleGusts(LevelConfig level, Random random);
class HoldSimulation {
  HoldSimulation({required LevelConfig level, required int stabilityScore, required bool mustFall, required int seed, required int braces});
  void step(double dt);        // applies clampedDt
  bool brace();                // false if none are left or the round is over
  double get leanDegrees;      // signed, positive = right
  double get elapsed;
  int get secondsLeft;
  bool get fallen; bool get finished;
  int get gustIndex;           // 1-based for "Gust 2 of 3"; 0 before the first
  int get stabilityPercent;    // round((1 - |lean| / maxLeanDegrees) * 100), clamped 0..100
  int get bracesLeft; int get bracesUsed;
  bool get windActive;
}
```

- [ ] **Step 1: Write the failing simulation tests**

```dart
// run(sim) steps at 1/60 until fallen or finished.
test('finishes exactly at the hold time when it stands', () {
  final s = HoldSimulation(level: levels[3], stabilityScore: 100, mustFall: false, seed: 1, braces: 0);
  run(s);
  expect(s.fallen, isFalse);
  expect(s.finished, isTrue);
  expect(s.elapsed, closeTo(18, 0.05));
});
test('gusts fit inside the hold, one per slot, at least 2.5s long', () {
  // for all levels and seeds: count == level.gusts, start >= 0,
  // start + duration <= holdSeconds, duration >= 2.5, amplitude in 0.8..1.0
});
test('a huge dt cannot skip time, as when returning from background', () {
  final s = HoldSimulation(level: levels[3], stabilityScore: 100, mustFall: false, seed: 1, braces: 0);
  s.step(60);
  expect(s.elapsed, closeTo(0.05, 1e-9));
});
test('brace halves the lean and is limited', () {
  // At a moment with |lean| > 1: value after brace() == before / 2.
  // With braces: 1, second brace() returns false.
});
```

- [ ] **Step 2: Write the failing fairness tests** in `fairness_test.dart`

Each uses 300 seeds per level:
```dart
test('a perfect copy never falls, at any level, with no brace', () { /* score from assessStability on a straight copy; fallen == false */ });
test('any tower scoring 70 or more never falls', () { /* score 70..100 */ });
test('a score below 40 falls at least 90% of the time', () { /* score 0..39, no braces */ });
test('from level 3, two wrong blocks always fall, with any brace timing', () {
  // braces: 2, used at: never; first gust start; both in the last gust;
  // one at each of the last two gusts' starts. fallen must be true.
});
test('from level 3, a player with no memory clears at most 2%', () {
  // Fill rows with random tray picks, stacked straight, using assessStability
  // and HoldSimulation with braces: 2 used at the last gust.
});
```

- [ ] **Step 3: Run and confirm failure**

Run: `flutter test test/game/hold_simulation_test.dart test/game/fairness_test.dart`
Expected: FAIL because the file doesn't exist.

- [ ] **Step 4: Implement `hold_simulation.dart`**

Split the hold into `gusts` equal slots. In each slot, use `duration = min(slot * 0.7, 5)`, a random start within the slot, `amplitude` in 0.8 to 1.0, and a random direction.

Each step:
```
f       = 1 - score / 100
target  = in a gust ? direction * amplitude * level.windStrength * (4 + 26 * f) : 0
if mustFall: target *= 3
if braced:   target *= 0.5       // for 4 s after a brace; does not stack, a new brace restarts the 4 s
lean   += (target - lean) * (1 - exp(-dt / 0.8))
fallen  = |lean| > maxLeanDegrees
```
This first-order response can't overshoot, so a perfect copy never leans past 4°. That is what makes the fairness rule hold for any wind.

- [ ] **Step 5: Run and confirm passing**

Run: `flutter test test/game/ && flutter analyze`
Expected: PASS, no issues.

---

### Task 6: Attempt, scoring, and result explanations

**Files:**
- Create: `lib/game/scoring.dart`, `lib/game/explanation.dart`, `lib/game/attempt.dart`
- Test: `test/game/scoring_test.dart`, `test/game/explanation_test.dart`, `test/game/attempt_test.dart`

**Interfaces:**
- Consumes: Tasks 2 to 5.
- Produces:
```dart
int pointsFor({required int correct, required int heldSeconds, required int paidBraces}); // 30*correct + round(heldSeconds*10/3) - 40*paidBraces, min 0
int starsFor({required int correct, required int total, required bool usedBrace, required bool usedSecondLook});
class ResultText { final String headline; final String detail; }
ResultText explainFall(StabilityReport report, {required int total});
String explainHold(StabilityReport report);
class AttemptResult {
  final LevelConfig level; final bool stood; final int correct, total, heldSeconds, points, stars;
  final int lockStability; final int fellAtSeconds; // 0 if it stood
  final String headline, detail;
}
enum AttemptPhase { memorise, build, windReady, hold, result }
enum DropOutcome { placed, returnedToTray }
class Attempt extends ChangeNotifier {
  Attempt({required LevelConfig level, required int seed, List<Block>? previous});
  LevelConfig get level; GeneratedTower get tower; AttemptPhase get phase;
  List<Block> get tray;         // what's left, in stable order
  List<PlacedBlock> get placed;
  StabilityReport get report;
  bool get canLock;             // every row is filled
  bool get secondLookUsed; bool get adBraceEarned;
  void finishStudy();           // memorise -> build
  DropOutcome drop(Block block, double rawX);
  bool earnSecondLook();        // false if already used or not in build
  void lock();                  // build -> windReady; ignored unless canLock
  bool earnAdBrace();           // false if already earned or not in windReady
  HoldSimulation startHold();   // windReady -> hold
  AttemptResult finish(HoldSimulation sim); // hold -> result; a second call returns the same result
}
```

- [ ] **Step 1: Write the failing tests**

```dart
test('a perfect level 4 is worth 240, a paid brace costs 40', () {
  expect(pointsFor(correct: 6, heldSeconds: 18, paidBraces: 0), 240);
  expect(pointsFor(correct: 6, heldSeconds: 18, paidBraces: 1), 200);
  expect(pointsFor(correct: 0, heldSeconds: 0, paidBraces: 2), 0);
});
test('stars', () {
  expect(starsFor(correct: 6, total: 6, usedBrace: false, usedSecondLook: false), 3);
  expect(starsFor(correct: 6, total: 6, usedBrace: true, usedSecondLook: false), 2);
  expect(starsFor(correct: 6, total: 6, usedBrace: false, usedSecondLook: true), 2);
  expect(starsFor(correct: 5, total: 6, usedBrace: false, usedSecondLook: false), 1);
});
test('fall text matches the true cause', () {
  // crooked only, row 3 left:
  //   headline 'Right blocks, crooked stack'; detail contains 'third' and 'left'.
  // two wrong, rows 2 and 4, straight:
  //   headline 'Two wrong blocks'; detail contains '2' and '4'; no 'crooked'.
  // one wrong + crooked: headline 'One wrong block, crooked stack'.
  // no wrong, not crooked, topHeavy impossible; right blocks & straight falls only via
  //   low wind luck: headline 'It couldn't hold', and the text never claims a wrong block.
});
test('hold text matches the true cause', () {
  // perfect: 'Every block matched and the stack stayed over the pillar.'
  // one wrong: mentions one wrong block and that the stack stayed balanced.
});
test('drop rules', () {
  // Off-tower drop returns returnedToTray; tray and placed are unchanged.
  // A valid drop removes that block from tray and adds it to placed.
  // A drop within tolerance snaps to x == 0.
  // Placed blocks can't be removed: Attempt exposes no such method.
});
test('flow and limits', () {
  // lock() ignored until every row is filled.
  // earnSecondLook() true once, then false. earnAdBrace() only in windReady, once.
  // startHold gives braces 1 without ad, 2 with ad.
  // finish(): ad brace is spent first, so one brace used with ad earned => paidBraces 0;
  //   usedBrace is still true, so stars <= 2.
  // finish() on a fallen sim gives points 0, stars 0, fellAtSeconds from elapsed.
  // A second finish() returns the identical result.
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/game/`
Expected: FAIL because the new files don't exist.

- [ ] **Step 3: Implement** all three files.

Headlines and details are generated only from `StabilityReport`, so they can't contradict what happened. Don't use the sheet's "Right blocks, wrong order". Order words: `first` to `tenth`. Number words for wrong counts in headlines: `One`, `Two`, then digits are fine in details.

- [ ] **Step 4: Run and confirm passing**

Run: `flutter test test/game/ && flutter analyze`
Expected: PASS, no issues.

---

### Task 7: Saved progress

**Files:**
- Create: `lib/progress/progress.dart`, `lib/progress/progress_store.dart`, `lib/progress/progress_controller.dart`
- Test: `test/progress/progress_test.dart`

**Interfaces:**
- Consumes: `AttemptResult`.
- Produces:
```dart
class LevelRecord { final int stars, bestPoints; }
class Progress {
  const Progress(this.records); // Map<int, LevelRecord>, only cleared levels
  static const empty;
  int get totalPoints; bool get hasPlayed; bool get allCleared;
  int get nextLevel;        // lowest uncleared, or 12 when all cleared
  bool isUnlocked(int number);
  Progress withResult(AttemptResult result); // returns this if !stood
}
abstract class ProgressStore { Future<Progress> load(); Future<void> save(Progress progress); }
class SharedPrefsProgressStore implements ProgressStore {} // key 'tower_build.progress'
class ProgressController extends ChangeNotifier {
  ProgressController(ProgressStore store);
  Progress get progress; Future<void> load(); Future<void> record(AttemptResult result);
}
String formatPoints(int points); // 1240 -> '1,240'
```

- [ ] **Step 1: Write the failing tests**

```dart
test('keeps best stars and best points separately', () {
  // 3 stars 100 pts, then 2 stars 200 pts => stars 3, bestPoints 200.
});
test('total is the sum of bests, so replaying cannot farm', () {
  // Record the same result twice => total unchanged.
});
test('a fall saves nothing and loses nothing', () {});
test('unlocks only the next level', () {
  // Empty: 1 unlocked, 2 locked. After clearing 1: 2 unlocked, 3 locked, nextLevel 2.
});
test('survives a store round trip', () async {
  SharedPreferences.setMockInitialValues({});
  // save then load through a new store instance: equal values.
});
test('corrupt or future data starts empty and does not throw', () async {
  for (final bad in ['not json', '{"version":99,"levels":{}}', '{"version":1,"levels":{"x":1}}', '[]']) {
    SharedPreferences.setMockInitialValues({'tower_build.progress': bad});
    expect((await SharedPrefsProgressStore().load()).records, isEmpty);
  }
});
test('formatPoints', () { expect(formatPoints(1240), '1,240'); expect(formatPoints(12), '12'); expect(formatPoints(1000000), '1,000,000'); });
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/progress/`
Expected: FAIL because the files don't exist.

- [ ] **Step 3: Implement**

The stored value is a JSON string: `{"version":1,"levels":{"1":{"stars":3,"points":120}}}`.

- [ ] **Step 4: Run and confirm passing**

Run: `flutter test test/progress/ && flutter analyze`
Expected: PASS, no issues.

---

### Task 8: Rewarded ads

**Files:**
- Create: `lib/ads/rewarded_ads.dart`, `lib/ads/admob_rewarded_ads.dart`, `lib/ads/ad_ids.dart`, `test/support/fake_ads.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`
- Test: `test/ads/rewarded_ads_test.dart`

**Interfaces:**
- Produces:
```dart
abstract class RewardedAds {
  ValueListenable<bool> get isReady;
  Future<void> initialize();  // must never throw
  Future<bool> show();        // true only if the reward was earned; false for anything else
}
class NoAds implements RewardedAds {}  // never ready; used on unsupported platforms
class AdMobRewardedAds implements RewardedAds {}
// test/support/fake_ads.dart:
class FakeAds implements RewardedAds { // settable ready flag; counts show() calls; completes show() via complete(bool) }
```

- [ ] **Step 1: Write the failing tests**

```dart
test('NoAds is never ready and never rewards', () async {
  final ads = NoAds();
  await ads.initialize();
  expect(ads.isReady.value, isFalse);
  expect(await ads.show(), isFalse);
});
test('FakeAds completes with the given outcome', () async { /* show counts; complete(false) => false */ });
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/ads/`
Expected: FAIL because the files don't exist.

- [ ] **Step 3: Implement `rewarded_ads.dart`, `ad_ids.dart`, and `fake_ads.dart`**

`ad_ids.dart`, Google's published test IDs:
- Rewarded unit, Android: `ca-app-pub-3940256099942544/5224354917`
- Rewarded unit, iOS: `ca-app-pub-3940256099942544/1712485313`

- [ ] **Step 4: Implement `AdMobRewardedAds`**

`initialize()` in this order, catching all errors:
1. `ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(), onSuccess, onFailure)`.
2. On success, `ConsentForm.loadAndShowConsentFormIfRequired(...)`.
3. If `await ConsentInformation.instance.canRequestAds()` is true: `MobileAds.instance.updateRequestConfiguration(RequestConfiguration(maxAdContentRating: MaxAdContentRating.t))`, then `MobileAds.instance.initialize()`, then load an ad.

Loading uses `RewardedAd.load(adUnitId: ..., request: const AdRequest(nonPersonalizedAds: true), rewardedAdLoadCallback: ...)`. Don't set any child-directed tag. `isReady` is true only with a loaded ad.

`show()`:
- Returns false at once if nothing is loaded or a show is in progress.
- Sets `isReady` to false, sets `fullScreenContentCallback`, and calls `ad.show(onUserEarnedReward: ...)`.
- Completes only on dismiss or failed-to-show, with whether the reward fired.
- Disposes the ad and loads the next one.
- On load failure, retries after 30 seconds, at most 3 times in a row.

- [ ] **Step 5: Add native configuration**

Google's test app IDs:
- Android manifest, inside `<application>`: `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/>`
- `Info.plist`: `GADApplicationIdentifier` = `ca-app-pub-3940256099942544~1458002511`, and `SKAdNetworkItems` with `cstr6suwn9.skadnetwork`.

Don't add `NSUserTrackingUsageDescription` or request Apple's tracking prompt: ads are non-personalized and the app doesn't track. The spec's recheck of this before store release stays open and belongs to the release step.

- [ ] **Step 6: Run and confirm passing**

Run: `flutter test test/ads/ && flutter analyze`
Expected: PASS, no issues.

---

### Task 9: Neon widgets

**Files:**
- Create: `lib/ui/widgets/block_view.dart`, `lib/ui/widgets/tower_view.dart`, `lib/ui/widgets/arena.dart`, `lib/ui/widgets/neon_button.dart`, `lib/ui/widgets/panel.dart`, `lib/ui/widgets/meter.dart`, `lib/ui/widgets/collapse_view.dart`
- Test: `test/ui/widgets_test.dart`, `test/visual/widgets_visual_test.dart`, `test/support/load_font.dart`

**Interfaces:**
- Consumes: `Block`, `pillar`, `PlacedBlock`, tokens.
- Produces:
```dart
Color blockColor(BlockColor c);
Color meterColor(int percent); // green >= 70, yellow 40..69, red below 40
class BlockView extends StatelessWidget { const BlockView({required Block block, required double width, required double height, bool heldWhite = false}); }
class TowerLayout { // pure, testable
  static double scaleFor(List<Block> blocks, double availableHeight); // never above 1; includes pillar, floor, 5px gaps
}
class TowerView extends StatelessWidget { const TowerView({required List<PlacedBlock> placed, double leanDegrees = 0, Widget? nextSlot, int emptyRows = 0}); }
enum ArenaMood { normal, stood, fell }
class Arena extends StatelessWidget { const Arena({required Widget child, ArenaMood mood = ArenaMood.normal, bool showCentreLine = false, bool wind = false}); }
class NeonButton extends StatelessWidget { const NeonButton.primary(String label, {VoidCallback? onPressed}); const NeonButton.outline(String label, {VoidCallback? onPressed, Color? color}); }
class Panel extends StatelessWidget { const Panel({required Widget child}); }
class StatRow extends StatelessWidget { const StatRow(List<(String label, String value, Color? color)> stats); }
class Meter extends StatelessWidget { const Meter({required int percent, double height = 8}); }
class CollapseView extends StatefulWidget { const CollapseView({required List<PlacedBlock> placed, required int seed, required int direction, Key? key}); } // state exposes replay()
Future<void> loadNunito(); // test/support/load_font.dart
```

- [ ] **Step 1: Write the failing tests**

```dart
test('meter colours use the spec bands', () {
  expect(meterColor(70), AppColors.green);
  expect(meterColor(69), AppColors.yellow);
  expect(meterColor(40), AppColors.yellow);
  expect(meterColor(39), AppColors.red);
});
test('ten blocks scale to fit, and small towers are not enlarged', () {
  expect(TowerLayout.scaleFor(tallTower10, 240), lessThan(1));
  expect(TowerLayout.scaleFor(smallTower3, 600), 1);
});
testWidgets('a disabled NeonButton does not fire', (t) async { /* onPressed null; tap; nothing */ });
testWidgets('every shape paints without error', (t) async { /* pump BlockView for all shapes */ });
testWidgets('replay restarts the collapse', (t) async { /* controller value resets toward 0 after replay() */ });
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/ui/`
Expected: FAIL because the files don't exist.

- [ ] **Step 3: Implement**

- `BlockView` is a `CustomPainter`: a shape path with a 3px corner on rectangles, and a matching `polygon(50% 0, 100% 100%, 0 100%)` or its inverse on triangles. Under the shape, paint the same path in the block colour at alpha 0.7 with `MaskFilter.blur(BlurStyle.normal, 13)`, matching the sheet's 26px shadow. With `heldWhite`, the fill is white with a brighter glow, as in the owner's picture.
- `Arena` has a `RadialGradient` from the mood colour to `AppColors.background`, a 1px border (`rule`, `borderStood`, or `borderFell`), the glowing floor line, and optional dashed centre line and cyan wind streaks.
- `CollapseView` runs a 1.4-second seeded animation: blocks gain horizontal drift in the fall direction, rotate, and drop to the floor, ending in a scatter like sheet screen 05. It's random only through `Random(seed)`, so `replay()` looks identical.

- [ ] **Step 4: Add a visual check**

`widgets_visual_test.dart` calls `loadNunito()` and renders a tower with all four shapes and all four colours in an `Arena`, sized 380×600, using `matchesGoldenFile('goldens/widgets.png')`.

Run: `flutter test --update-goldens test/visual/widgets_visual_test.dart`

Open `test/visual/goldens/widgets.png` and compare it with sheet screen 01. Block glow, floor glow, and background must look like the sheet.

- [ ] **Step 5: Run and confirm passing**

Run: `flutter test && flutter analyze`
Expected: PASS, no issues.

---

### Task 10: Menu, levels, and how to play

**Files:**
- Create: `lib/ui/app_scope.dart`, `lib/ui/screens/menu_screen.dart`, `lib/ui/screens/levels_screen.dart`, `lib/ui/screens/how_to_play.dart`, `lib/ui/screens/attempt_flow.dart` (placeholder body until Task 11)
- Modify: `lib/main.dart`
- Test: `test/ui/menu_levels_test.dart`, `test/support/pump_app.dart`

**Interfaces:**
- Consumes: `ProgressController`, `Progress`, `levels`, `RewardedAds`, `TowerBuildApp`.
- Produces:
```dart
class AppScope extends InheritedWidget { final ProgressController progress; final RewardedAds ads; final int Function() newSeed; static AppScope of(BuildContext c); } // newSeed is clock-based in main(), fixed in tests
class MenuScreen extends StatelessWidget {}
class LevelsScreen extends StatelessWidget {}
class AttemptFlow extends StatefulWidget { const AttemptFlow({required int levelNumber}); }
Future<void> pumpApp(WidgetTester t, {Progress progress, RewardedAds? ads, int Function()? newSeed, Widget? home});
```

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('first launch shows Play', ...);            // 'Tower Build', 'Play', 'Levels', 'How to play'; no 'Continue'
testWidgets('returning player sees Continue level N and total', ...); // 3 cleared => 'Continue level 4' and formatted total
testWidgets('after all 12, Continue is replaced', ...); // 'Replay level 12'
testWidgets('Play opens level 1', ...);
testWidgets('levels list shows all 12 with block counts', ...); // scrollable, finds '3 blocks' and '10 blocks'
testWidgets('locked levels ignore taps', ...);          // tap level 5 at empty progress => still on LevelsScreen
testWidgets('unlocked and cleared levels open', ...);   // cleared level can be replayed
testWidgets('cleared levels show stars and best points', ...);
testWidgets('how to play shows the three 1b rules', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/ui/menu_levels_test.dart`
Expected: FAIL because the screens don't exist.

- [ ] **Step 3: Implement**

**Menu:** background `AppColors.background`. Label row with total points in glowing green, as in the sheet's header. `Tower Build` at 40/900. A decorative fixed tower in an `Arena`. Primary button `Play`, `Continue level N`, or `Replay level 12`. Outline button `Levels`. Plain text button `How to play`.

**Levels:** title `Twelve levels`, subtitle `Taller towers, less time to study, stronger wind.`. A list panel with 1px rules. Each row has the number, `N blocks`, and stars plus best points if cleared. The current level uses green text with a soft glow, and locked rows use `label` colour at reduced opacity with no glow.

**How to play:** a dark panel in a bottom sheet with exactly these three numbered lines:
1. `Study the tower before the countdown ends.`
2. `Rebuild it from the bottom up. Placed blocks stay put, so drop them straight.`
3. `Lock it and hold through the wind. Wrong blocks and crooked drops can bring it down.`

**`main.dart`:** create `SharedPrefsProgressStore` and `ProgressController`, await `load()`, use `AdMobRewardedAds` on Android and iOS and `NoAds` elsewhere, wrap the app in `AppScope` with `MenuScreen` as home, and call `ads.initialize()` without awaiting it so ads never delay startup.

- [ ] **Step 4: Run and confirm passing**

Run: `flutter test && flutter analyze`
Expected: PASS, no issues.

---

### Task 11: Memorise and Build screens

**Files:**
- Create: `lib/game/study_clock.dart`, `lib/ui/screens/memorise_view.dart`, `lib/ui/screens/build_view.dart`, `lib/ui/widgets/block_tray.dart`
- Modify: `lib/ui/screens/attempt_flow.dart`
- Test: `test/game/study_clock_test.dart`, `test/ui/memorise_build_test.dart`

**Interfaces:**
- Consumes: `Attempt`, `TowerView`, `Arena`, `Meter`, `BlockView`, `RewardedAds`, `clampedDt`.
- Produces:
```dart
class StudyClock { StudyClock(int seconds); void step(double dt); int get secondsLeft; double get fractionLeft; bool get done; }
class MemoriseView extends StatefulWidget { const MemoriseView({required Attempt attempt, required int totalPoints}); }
class BuildView extends StatefulWidget { const BuildView({required Attempt attempt}); }
class BlockTray extends StatefulWidget { const BlockTray({required List<Block> blocks}); } // Draggable<Block> tiles
```
`AttemptFlow` holds the `Attempt`, gets each seed from `AppScope.of(context).newSeed()`, and switches views by phase. System back returns to the previous screen and records nothing.

- [ ] **Step 1: Write the failing tests**

```dart
test('a study clock cannot jump when the app returns from background', () {
  final c = StudyClock(6);
  c.step(120);
  expect(c.done, isFalse);
  expect(c.fractionLeft, closeTo(1 - .05 / 6, 1e-9));
});
testWidgets('memorise shows the tower and then hides it', ...);
// Level header 'Level 1 of 12', 'Memorise the tower', 'Two things to remember',
// exact sheet copy; countdown; after 6s it moves to 'Block 1 of 3' and 'No timer'.
testWidgets('dropping on the centre line places a block', ...);
// tester.timedDrag from tray to arena centre => 'Block 2 of 3'; tray has one less.
testWidgets('dropping outside the arena returns the block', ...);
testWidgets('dropping with no contact below returns the block', ...);
testWidgets('the meter drops after a wrong block and stays at 100 after a right one', ...);
testWidgets('only one block can be dragged at a time', ...); // maxSimultaneousDrags: 1
testWidgets('Lock is disabled until every row is filled', ...);
testWidgets('the Place here marker has the same width whichever block is next', ...);
testWidgets('the tray pages when it is too large', ...); // 11 blocks: 7 tiles + '+4'; tapping shows the rest
testWidgets('second look: no button when no ad is ready', ...); // FakeAds ready false
testWidgets('second look: earned shows the tower for 3s, then back unchanged', ...);
testWidgets('second look: closed early gives nothing and may be retried', ...); // complete(false)
testWidgets('second look: a double tap shows only one ad', ...); // show count == 1
testWidgets('second look: only once per attempt', ...);
testWidgets('no overflow at 320x568, text scale 1.3, 10 blocks', ...);
// tester.view sizes; for memorise and build: tester.takeException() is null.
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/game/study_clock_test.dart test/ui/memorise_build_test.dart`
Expected: FAIL because the views don't exist.

- [ ] **Step 3: Implement `StudyClock` and `MemoriseView`** to match sheet screen 01, replacing the header with `Level N of 12` and total points. Drive it from a `Ticker`, passing the delta between ticks to `step`.

- [ ] **Step 4: Implement `BuildView` and `BlockTray`** to match sheet screen 02, with these differences from the sheet:

- The pillar and floor are always visible. `Block N of M` counts rows above the pillar, and becomes `All M placed` when full.
- The "Place here" marker is always 58% of arena width and 40 tall, so it reveals nothing. Empty rows above it are not shown, for the same reason.
- The tray has 8 tiles per page in a 4-column grid. If more remain, tile 8 shows `+N`, and tapping it moves to the next page.
- Use `Draggable<Block>` with `maxSimultaneousDrags: 1`. The feedback is the block at tower scale with `heldWhite: true`. Use a `DragTarget` over the arena, and calculate the block's centre as a fraction of arena width from `onAcceptWithDetails`, using the arena's `RenderBox`. Call `attempt.drop`. A rejected drop leaves the block in the tray.
- When the ad is ready and unused, show an outline button `See the tower again` beside a shortened `Lock the tower`, with a small `Ad` label. When it isn't, `Lock the tower` is full width as in the sheet.
- While an ad is showing, the button is disabled. If `ads.show()` returns true, call `attempt.earnSecondLook()` and show the study tower for 3 seconds over the arena, with dragging disabled. Then return with the build unchanged.
- Use `HapticFeedback.lightImpact()` on a successful drop.

- [ ] **Step 5: Run and confirm passing**

Run: `flutter test && flutter analyze`
Expected: PASS, no issues.

---

### Task 12: Wind-ready, Hold, and Result screens

**Files:**
- Create: `lib/ui/screens/wind_ready_view.dart`, `lib/ui/screens/hold_view.dart`, `lib/ui/screens/stood_view.dart`, `lib/ui/screens/fell_view.dart`
- Modify: `lib/ui/screens/attempt_flow.dart`
- Test: `test/ui/hold_results_test.dart`, `test/visual/screens_visual_test.dart`

**Interfaces:**
- Consumes: `Attempt`, `HoldSimulation`, `AttemptResult`, `ProgressController.record`, `CollapseView`, `RewardedAds`, `levels`.
- Produces: `WindReadyView`, `HoldView`, `StoodView`, and `FellView`, each constructed with the `Attempt` (and `AttemptResult` where needed) plus callbacks from `AttemptFlow`: `onNextLevel`, `onBuildAgain`, `onBackToLevels`.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('no ad ready: Lock goes straight to the wind', ...);       // 'It has to stand'
testWidgets('ad ready: offer shown before the wind', ...);             // 'Watch ad for an extra brace', 'Start the wind'
testWidgets('earned ad gives 2 braces; closed early gives 1', ...);    // 'Brace it (2 left)' / 'Brace it (1 left)'
testWidgets('a double tap shows only one extra-brace ad', ...);
testWidgets('no ad button appears during the wind', ...);              // FakeAds ready true: no 'Watch ad' in HoldView
testWidgets('hold shows the sheet stats', ...);                        // 'Hands off — wind is on', 'Stability', 'Lean', 'Gust n of N'
testWidgets('a perfect copy reaches the stood screen and records it', ...);
// 'Your tower stood', 'Held 8 seconds', '3 / 3', points, 'Why it held'; progress updated once.
testWidgets('stood button names the next level and hold', ...);        // 'Level 2 — hold for 10s'
testWidgets('clearing level 12 shows the final state', ...);           // 'You cleared all 12' returns to levels
testWidgets('a fall shows the true reason and records nothing', ...);  // 'Fell at', headline from attempt, 'At lock', progress unchanged
testWidgets('Replay the fall replays without changing the result', ...);
testWidgets('Build again gives a different tower on the same level', ...); // memorise phase; blocks differ; level same
testWidgets('no overflow at 320x568, text scale 1.3, 10 blocks', ...); // for all four views
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/ui/hold_results_test.dart`
Expected: FAIL because the views don't exist.

- [ ] **Step 3: Implement all four views**

- `WindReadyView` appears only when an ad is ready. It shows the finished tower and the two buttons. If the ad isn't ready, `AttemptFlow` goes directly to the hold.
- `HoldView` matches sheet screen 03 and is driven by a `Ticker` calling `sim.step`. Draw lean per block as the sheet does: rotation rises with row height, up to `leanDegrees` at the top, with a matching sideways shift. Show lean as `4° right`. The brace text is `One brace left. Use it to steady the tower — costs 40 points.`, or a no-cost line when the next brace is the free ad one. The brace button is hidden at 0 braces. Use `HapticFeedback.mediumImpact()` on collapse.
- `StoodView` matches sheet screen 04, and `FellView` matches screen 05 with its top line `Fell at X of Y seconds` and `CollapseView`. `Replay the fall` calls `replay()`. Both use `AttemptResult` text only.
- `AttemptFlow` calls `progress.record(result)` exactly once, on a stood result, and passes the current tower as `previous` when building a new `Attempt`, so a retry can't repeat it.

- [ ] **Step 4: Add the screen-by-screen visual check**

`screens_visual_test.dart` calls `loadNunito()` and renders at 428×908, fixed seed: menu, levels, memorise, build mid-way, hold, stood, fell.

Run: `flutter test --update-goldens test/visual/screens_visual_test.dart`

Open each PNG in `test/visual/goldens/` and compare it with the matching screen in `docs/design-reference/tower-build-sheet-1b.html`. Fix any difference in colour, spacing, type, or glow before moving on.

- [ ] **Step 5: Run and confirm passing**

Run: `flutter test && flutter analyze`
Expected: PASS, no issues.

---

### Task 13: App icon, full playthrough, and release builds

**Files:**
- Create: `test/visual/render_icon_test.dart`, `assets/icon/icon.png` (generated), `test/flow/full_game_test.dart`
- Modify: `pubspec.yaml` (launcher icons config), `README.md`

- [ ] **Step 1: Write the end-to-end test**

```dart
testWidgets('new player clears level 1, closes the app, and continues on level 2', (t) async {
  // In-memory SharedPreferences mock, fixed seed, FakeAds not ready.
  // Menu > Play > wait for study > drag the correct tower blocks > Lock >
  // run the wind to the end > stood screen > back to menu.
  // Rebuild the app from a new ProgressController and store:
  // menu shows 'Continue level 2' and the same total.
});
testWidgets('the game plays start to finish with ads unavailable', (t) async {
  // NoAds: no ad text appears on any screen.
});
```

- [ ] **Step 2: Run and confirm it passes, or fix what it exposes**

Run: `flutter test test/flow/`
Expected: PASS. Any failure here is a real integration bug: fix it in the owning file.

- [ ] **Step 3: Generate the icon**

`render_icon_test.dart` uses `PictureRecorder` to paint a 1024×1024 opaque icon: `AppColors.background`, floor line, red pillar, and three glowing blocks. It writes `assets/icon/icon.png`.

Configure `flutter_launcher_icons` for Android and iOS with `remove_alpha_ios: true`, then run:
```bash
flutter test test/visual/render_icon_test.dart
dart run flutter_launcher_icons
```
Expected: the icon files are regenerated. Open `assets/icon/icon.png` and confirm it reads clearly at a small size.

- [ ] **Step 4: Replace the README** with a short description, how to run it, how to run tests, the note that all ad IDs in `lib/ads/ad_ids.dart`, the Android manifest, and `Info.plist` are test IDs, and what must change before store release: app ID, real ad IDs, and a recheck of Google's and Apple's rules for teen players, including whether Apple's tracking prompt is needed.

- [ ] **Step 5: Run the final checks**

```bash
flutter test
flutter analyze
flutter build apk --release
flutter build ios --release --no-codesign
```
Expected: all tests pass and analysis is clean. Both builds succeed.

If a build is blocked by this machine's setup, record the exact error. A known candidate from `flutter doctor` is CocoaPods 1.15.0, which is below the recommended 1.16.2. Don't change global tools without the owner's approval.

- [ ] **Step 6: Run on the emulators**

Run `flutter emulators --launch Pixel_3a_API_34`, wait for it to boot, then `flutter run -d <emulator id>`. Repeat on the iOS Simulator with `flutter emulators --launch apple_ios_simulator`. If the tool refuses release mode on an emulator, use profile or debug mode there, and say which mode was used. Check:
- The launch screen has no white flash, and the name and icon are correct.
- The EU consent form doesn't block play if it appears.
- Drag and drop works, and a full level plays through. Use `adb` or `xcrun simctl` screenshots to compare screens with the sheet.
- Both test ads appear and reward correctly, closing one early gives no reward, and with the emulator's network off the ad buttons disappear and the game stays playable.
- Closing and reopening keeps progress.

If an emulator can't run, stop and report that check as not verified. Never fall back to Chrome.
