# Tower Build

A dark, neon, 2D memory game for Android and iOS. Home is Memory Towers: the
next level, one big Play button and the full ladder. Wind Levels is the
secondary game, behind a small button at the bottom of home. Each keeps its
own levels and saved progress.

- **Memory Towers** (33 levels): towers of coloured cubes are shown with a
  countdown. Rebuild them by tapping colours, bottom to top. Tap any placed
  cube to change it. Levels 1-12 are a single tower: 3 cubes, then +1 a level.
  After that it is +2 a level for 7 levels, +5 for 7 and +7 for the last 7
  (33 levels, up to 112 cubes in side-by-side towers). Three quarters right
  clears a level; every cube right earns 3 stars. No wind. Optional rewarded
  ads: "Peek" shows the tower again once per round while rebuilding, and
  "Same tower" retries the exact tower after a miss. Each explains itself
  before the ad plays and caps that round at 2 stars.
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

Android uses the live AdMob app (`ca-app-pub-9331906778457556~1593986873`,
in `android/app/src/main/AndroidManifest.xml`). Its rewarded unit
(`ca-app-pub-9331906778457556/3902575117`) is used only in release builds;
debug and profile builds load Google's test unit, so never tap real ads on
your own device. Both Memory Towers and Wind Levels share this one unit. The
unit choice lives in `lib/ads/ad_ids.dart`.

iOS still uses Google's test IDs everywhere (`lib/ads/ad_ids.dart` and
`ios/Runner/Info.plist`); add an iOS app in AdMob before an App Store release.

Also change these before release:

- The app ID: `com.otot.brainquiz` is a placeholder. It lives in
  `applicationId` and `namespace` in `android/app/build.gradle.kts`, and as the
  bundle ID in the Xcode project.
- Signing: the Android release build is signed with the debug keys. Set up a
  real release signing config before publishing.
- Replace every test ad ID with real ones, in all three places above.
- Recheck Google's and Apple's current rules for teen players (ad content
  rating, consent, and data handling), including whether Apple's App Tracking
  Transparency prompt is needed.
