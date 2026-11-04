import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/progress/progress_store.dart';
import 'package:brainquiz/ui/app_scope.dart';
import 'package:brainquiz/ui/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_ads.dart';
import '../support/flow_helpers.dart';
import '../support/pump_app.dart';

bool _noAdText() => find
    .textContaining(RegExp(r'\bad\b', caseSensitive: false))
    .evaluate()
    .isEmpty;

/// Plays level 1 from the menu to the stood screen. With [noAdText] set,
/// asserts that no ad text shows at any step.
Future<void> playLevelOneFromMenu(WidgetTester t, {bool noAdText = false}) async {
  void checkAds() {
    if (noAdText) expect(_noAdText(), isTrue);
  }

  checkAds();
  await t.tap(find.text('Play'));
  await t.pumpAndSettle(const Duration(milliseconds: 50));
  checkAds();
  await pumpSeconds(t, levels[0].studySeconds);
  checkAds();
  final ref = reference(1)..finishStudy();
  for (var row = 0; row < levels[0].blocks; row++) {
    await placeRight(t, ref, row);
  }
  checkAds();
  await tapLock(t);
  expect(find.text('It has to stand'), findsOneWidget);
  checkAds();
  await pumpSeconds(t, levels[0].holdSeconds + 1);
  expect(find.text('Your tower stood'), findsOneWidget);
  checkAds();
}

void main() {
  testWidgets(
    'new player clears level 1, closes the app, and continues on level 2',
    (t) async {
      phone(t);
      SharedPreferences.setMockInitialValues({});
      await pumpApp(t, store: SharedPrefsProgressStore(), ads: FakeAds());
      expect(find.text('Play'), findsOneWidget);

      await playLevelOneFromMenu(t);
      final total = AppScope.of(t.element(find.byType(Scaffold).first))
          .progress
          .progress
          .totalPoints;
      expect(total, greaterThan(0));

      await t.binding.handlePopRoute();
      await t.pumpAndSettle(const Duration(milliseconds: 50));
      expect(find.byType(MenuScreen), findsOneWidget);
      expect(find.text('Continue level 2'), findsOneWidget);
      expect(find.text(formatPoints(total)), findsOneWidget);

      // "Close the app": a new controller and store over the same saved data.
      await t.pumpWidget(const SizedBox());
      await pumpApp(t, store: SharedPrefsProgressStore(), ads: FakeAds());
      expect(find.text('Continue level 2'), findsOneWidget);
      expect(find.text(formatPoints(total)), findsOneWidget);
    },
  );

  testWidgets('the game plays start to finish with no ads available', (t) async {
    phone(t);
    SharedPreferences.setMockInitialValues({});
    await pumpApp(t, store: SharedPrefsProgressStore());
    await playLevelOneFromMenu(t, noAdText: true);
  });
}
