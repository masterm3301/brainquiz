# Tower Build

A dark, neon, 2D memory game for Android and iOS, with two games picked from
the home screen. Each keeps its own levels and saved progress.

- **Memory Towers** (22 levels): towers of coloured cubes are shown with a
  countdown. Rebuild them by tapping colours, bottom to top, left tower first.
  Tap any placed cube to change it. Level 1 has 5 cubes, then +2 a level for 7
  levels, +5 for the next 7 and +7 for the last 7 (103 cubes). Three quarters
  right clears a level; every cube right earns 3 stars. No wind.
- **Wind Levels** (12 levels): a tower of odd-shaped blocks is shown for a few
  seconds. Rebuild it from memory by dragging blocks from the tray, lock it,
  and see whether it stands against the wind. Rewarded ads are the only ads,
  and both are optional: "See the tower again" on the build screen replays the
  tower, and an extra brace is offered before the wind starts.

Portrait only, dark only, no sound, no accounts, no backend. Progress is saved
on the device.

## Run

```bash
flutter pub get
flutter run -d <emulator or simulator id>
```

Run the app on an emulator or simulator only (Android `Pixel_3a_API_34`, or the
iOS Simulator).

## Test

```bash
flutter test
flutter analyze
```

To regenerate the launcher icon:

```bash
flutter test test/visual/render_icon_test.dart
dart run flutter_launcher_icons
```

## Before a store release

All ad IDs are Google's test IDs. They live in `lib/ads/ad_ids.dart`, the
Android manifest (`android/app/src/main/AndroidManifest.xml`), and
`ios/Runner/Info.plist`. Change these before release:

- The app ID: `com.otot.brainquiz` is a placeholder. It lives in
  `applicationId` and `namespace` in `android/app/build.gradle.kts`, and as the
  bundle ID in the Xcode project.
- Signing: the Android release build is signed with the debug keys. Set up a
  real release signing config before publishing.
- Replace every test ad ID with real ones, in all three places above.
- Recheck Google's and Apple's current rules for teen players (ad content
  rating, consent, and data handling), including whether Apple's App Tracking
  Transparency prompt is needed.
