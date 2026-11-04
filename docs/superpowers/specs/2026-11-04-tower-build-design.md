# Tower Build: design

Date: 2026-11-04
Status: waiting for owner approval

Visual source: `Brain Quiz game app – Tower Build.html` in the project root. It is a design sheet with no game logic. Open it in a browser and use section **1b, "neon arena"**. Section 1a is the rejected calm version, and only its idea of a 12-level ladder carries over.

## Intent

A single-player phone memory game. You study a glowing tower of odd-shaped blocks balanced on a red pillar, rebuild it from memory, then watch it try to survive the wind. Memory gets you the right blocks, and careful stacking keeps them up.

The owner's inspiration is a video by a famous YouTuber: a neon green floor in a dark arena, with a tower of wedges and upside-down triangles balanced on a red pillar. The block being placed glows white. This sets the mood, but the game must stand on its own.

## Decided by the owner

- **Version:** build 1b's look, building, and wind challenge, with progress through levels.
- **Appearance:** dark only. 2D, with the same glow and the same design as 1b. No 3D.
- **Fairness rule:** a perfect copy stacked straight always stands. Wrong blocks or crooked drops can bring the tower down.
- **Randomised:** towers are randomised.
- **Offline:** no backend and no rivals. Comparing with other players may come later, but none of it is built now.
- **New screens:** add a menu and a levels screen, in the same design. The sheet has neither.
- **Income:** AdMob rewarded ads, using the two placements below.
- **Audience:** ages 13 and up, mainly 13 to 17, with older players welcome. Not aimed at children under 13.

## Author's calls, for the owner to check

The owner hasn't explicitly agreed to these:

- Placed blocks can't be moved.
- A wrong colour counts as a wrong block, even when the shape is right.
- From level 3, two or more wrong blocks always fall, and one wrong block can still pass with 1 star.
- The red pillar is already placed and isn't counted as a block.
- The "Place here" marker hides the correct block's size, unlike the sheet.
- The 12-level table, star rules, and total points as the sum of each level's best.
- Failed attempts cost nothing, and every retry gets a new tower.
- The robot is left out.
- The app is named Tower Build, portrait only, on Android and iOS, with no sound in this version.
- The work ends at tested device builds with test ads, with no store submission.
- Progress is stored with `shared_preferences` instead of sqflite.
- Ads are capped at the Teen rating and non-personalized for everyone.

## Goals

- The full loop works: menu, levels, memorise, build, hold, result, next level.
- A fall feels earned, and the result screen says truthfully why it happened.
- The game looks like sheet 1b when placed beside it.

## Non-goals

- 3D or a 3D engine, and the robot from the video.
- Accounts, servers, online play, leaderboards, and sheet 1b's "Five platforms" screen.
- A light theme or theme toggle.
- 1a's supports and Peek button.

## Anti-goals

These would make it a failure even if it technically works:

- A perfect copy, stacked straight, falls.
- The player can beat a level by trial and error instead of memory.
- The result screen gives an explanation that doesn't match what happened.
- It passes as the video: no footage, name, or robot from it.

## Game loop

### 1. Memorise (sheet 1b, screen 01)

- A random tower is shown with a countdown number and shrinking bar.
- The header shows `Level 4 of 12` and total points, replacing the sheet's "Round 4 · Platform 3".
- The "Two things to remember" panel stays.

### 2. Build (screen 02)

- The tower disappears, leaving the red pillar on the neon floor. The pillar is already placed and isn't counted in `Block N of M`.
- There is no timer.
- The player drags each block from the tray onto the tower, bottom up. The next row height snaps automatically, but the horizontal position is where the player let go, so crooked drops are possible.
- The block being dragged glows white.
- The dashed centre line and "Place here" marker stay. The marker must not reveal the correct block's size or shape, so it differs from the sheet in that one way.
- The tray holds the real blocks plus decoys, in random order. Placed blocks leave the tray. The sheet's `+3` tile means the tray can hold more than fits on one screen.
- "Chance it stands" updates after every drop: a percentage, a bar, and one line of explanation. It is green at 70% or above, yellow from 40% to 69%, and red below 40%.
- **Placed blocks can't be moved.** Without this, the player could try blocks until the meter stops dropping.
- "Lock the tower" becomes active once every row is filled.
- An optional "See the tower again" rewarded ad is available here. See Rewarded ads.

### 3. Hold (screen 03)

- Hands off while wind gusts blow for the level's hold time.
- Shows the countdown, gust count, lean in degrees and direction, wind streaks, and a stability bar. Blocks tilt more the higher they are, as in the sheet.
- One "Brace it" per attempt: costs 40 points and visibly steadies the tower. An extra brace can be earned from a rewarded ad just before the wind starts, and it costs no points.
- If the lean passes the limit, the tower collapses in an animation and the round ends immediately.

### 4. Result

**It stood (screen 04):**
- Shows memory score (`6 / 6`), seconds held, points, a "Why it held" line, and a button to the next level.
- The tower must stand to unlock the next level.

**It fell (screen 05):**
- Shows the second it fell, a "What went wrong" line, stability at lock, "Replay the fall", and "Build again".
- The headline comes from the real cause: for example, "Right blocks, crooked stack" or "Two wrong blocks". The sheet's "Right blocks, wrong order" contradicts its own text ("Order was correct"), so don't copy it word for word.
- "Replay the fall" replays that collapse. "Build again" gives a new tower at the same level, starting from Memorise.

## Stability rules

Use a calculated stability model, not a rigid-body physics engine. A real simulation could topple a perfect tower through tiny numerical errors, which would break the fairness rule. Collapse can still be animated to look physical.

Stability falls because of:
- **Crooked drops:** distance from the block below. Small misses within a forgiving tolerance count as straight.
- **Balance:** the tower's centre of mass moving away from the pillar, and heavy wide blocks sitting too high.
- **Wrong blocks:** every wrong block costs stability, including one with the right shape but wrong colour. Otherwise colour would never matter.

Required results:
- A perfect copy stacked within tolerance stands at every level, every time, with no brace, for any wind.
- The meter never lies: a high reading must usually stand and a low reading must usually fall.
- From level 3 on, two or more wrong blocks always bring the tower down, in any wind and even with both braces. One wrong block may still stand, which earns 1 star. The meter must show red for a tower that can't stand.
- Levels 1 and 2 are gentle introductions, so this limit doesn't apply. A lucky guess can pass them.
- Test the limit across many seeds at each level from 3 to 12, the same way as the perfect-copy guarantee. Also test a simulated player placing blocks at random, to confirm retrying can't realistically clear those levels.
- Other numbers are the builder's to tune.

## Random towers

- Every attempt gets a new tower, including retries. The same tower never appears twice in a row.
- Generate towers from a seed so that tests and bugs can be reproduced.
- Blocks vary by colour (green, cyan, yellow), shape (rectangle, square, triangle, upside-down triangle or wedge), width, and height. Red is for the pillar and may also appear on decoys, as in the sheet's tray.
- A generated tower must meet the perfect-copy guarantee before it is shown.
- At higher levels, decoys should look closer to the real blocks.

## Levels

Twelve levels, playable in order. Starting values for the builder to tune:

| Level | Blocks | Study | Hold | Gusts | Decoys |
|---|---|---|---|---|---|
| 1 | 3 | 6s | 8s | 1 | 0 |
| 2 | 4 | 6s | 10s | 1 | 0 |
| 3 | 5 | 6s | 14s | 2 | 2 |
| 4 | 6 | 6s | 18s | 3 | 4 |
| 5 | 7 | 6s | 22s | 3 | 4 |
| 6 | 7 | 5s | 24s | 3 | 4 |
| 7 | 8 | 5s | 26s | 3 | 5 |
| 8 | 8 | 5s | 28s | 4 | 5 |
| 9 | 9 | 4s | 30s | 4 | 6 |
| 10 | 9 | 4s | 32s | 4 | 6 |
| 11 | 10 | 4s | 35s | 5 | 7 |
| 12 | 10 | 3s | 40s | 5 | 7 |

Wind strength also rises by level. Shapes can be introduced gradually, starting with rectangles and squares. The tower must be scaled to fit the arena at 10 blocks on small phones.

After level 12, the next-level button becomes a simple "You cleared all 12" state that returns to the levels screen.

## Scoring and progress

- A perfect level 4 is worth about +240, as on the sheet, and a brace costs 40. The builder sets the formula.
- Stars per level: 3 for every block correct with no brace and no second look, 2 for every block correct with a brace or second look, 1 for standing with any wrong blocks.
- Each level keeps its best points and best stars. Total points is the sum of the bests, so replaying can't farm points.
- A failed attempt saves nothing and loses nothing.
- Progress is saved on the device with `shared_preferences`, as versioned JSON, and survives closing the app. The data is only a dozen small records, so a database like sqflite would add setup and upgrade work with no benefit. Keep storage behind a small interface so it can be swapped if per-attempt history is ever needed.
- Keep result data simple and separate from the screens, so comparing with other players could be added later. Don't build anything for it now.

## Rewarded ads

Every ad is optional and chosen by the player. There are no banners, interstitials, or forced ads.

**Placements**
- **See the tower again:** on the Build screen, once per attempt. Shows the study tower for 3 seconds, then returns to the build unchanged. Limits that attempt to 2 stars.
- **Extra brace:** offered after "Lock the tower", before the wind starts, once per attempt. It costs no points. Using it limits that attempt to 2 stars.

**Rules**
- The game stays fully playable offline. If no ad is loaded, its button doesn't appear, and nothing else changes.
- The reward is given only when the ad reports that it was earned. Closing it early gives nothing.
- Ad buttons never appear during the wind.
- Ads can't override the stability rules.

**Setup**
- Use Google's official Mobile Ads plugin, with ads kept behind a small interface so game logic and tests don't depend on it.
- Use Google's test ad IDs in all builds for now. The real IDs are supplied at store release, from the owner's AdMob account.
- Don't mark the app as child-directed, because it isn't aimed at under-13s. Declare the 13+ audience in the store listings.
- Because most players are expected to be minors, cap ad content at the Teen rating and request non-personalized ads for everyone. This may earn somewhat less, but it avoids targeting teens. It should be one setting that's easy to change.
- Include the consent flow Google requires for regions such as the EU. Show Apple's tracking prompt only if non-personalized ads still require it.
- Recheck Google's and Apple's current rules for teen audiences before the store release.

## New screens

Same design language as 1b: near-black background, thin rules, square corners, heavy Nunito, small uppercase labels, glow on anything active.

**Menu**
- "Tower Build" title, a decorative glowing tower on a neon floor, and total points.
- Main button: `Continue level N`, or `Play` on first launch.
- `Levels` button.
- `How to play`, using 1a's three-step format updated for the 1b rules.

**Levels**
- A vertical list of all 12, in the style of 1a's ladder but dark.
- Each row shows the level number, block count, and stars or best points.
- The current level is highlighted in green, and locked levels are dimmed with no glow.
- Tapping an unlocked level starts it. Finished levels can be replayed.

## Design tokens from sheet 1b

| Use | Value |
|---|---|
| Background | `#05070d` |
| Panels | `#0a0f1c` |
| Rules and empty bars | `#12182a` |
| Tray borders | `#1a2236` |
| Dashed outlines and secondary button border | `#22304d` |
| Text, primary | `#eef3ff` |
| Text, secondary | `#c6cee6`, `#8a93b2` |
| Labels | `#6b7394` |
| Green, the main accent | `#22e06b`, with `#04210f` for text on it |
| Cyan | `#06b6d4` |
| Yellow | `#f5d90a` |
| Red | `#ff3b30` |
| Arena gradient: normal, stood, fell | `#0d2416`, `#133d22`, `#2a0d0c` |

Font weights are 700 to 900. The sheet is the reference for spacing and glow strength.

## Technical

- Flutter, in this existing project, which is currently the unmodified starter.
- Android and iOS, portrait only.
- Network access is used only by ads. No backend, analytics, or in-app purchases.
- Nunito is bundled with the app. The sheet only embeds web-font fragments, so use the proper font files and include the SIL Open Font License notice.
- The stability model, tower generator, and scoring are plain Dart with automated tests, including many seeds at every level proving the perfect-copy guarantee.
- The app icon and display name become Tower Build. The project folder and package stay `brainquiz`.
- The work ends at tested release builds running on Android and iOS devices, using test ads. Store submission is a separate later step and is required before the ads earn money. The app ID stays `com.example.brainquiz` until then, and must be replaced before the first Google Play upload.

## Left to the builder

- Code structure, state management, and how to draw the glow.
- The stability formula, tolerance, wind model, and scoring formula, within the required results above.
- Animation details, tray overflow behaviour, and leaving a level mid-attempt. Leaving counts as no result.
- Light haptic feedback on drops and collapse, using what Flutter already includes.

## Later, not now

- Comparing with other players.
- Sound effects and music.
