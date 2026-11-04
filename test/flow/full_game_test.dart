import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/ui/app_scope.dart';
import 'package:brainquiz/ui/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ads.dart';
import '../support/flow_helpers.dart';
import '../support/pump_app.dart';

Future<void> playLevelOneFromMenu(WidgetTester t) async {
  await t.tap(find.text('Play'));
  await t.pumpAndSettle(const Duration(milliseconds: 50));
  await pumpSeconds(t, levels[0].studySeconds);
  final ref = reference(1)..finishStudy();
  for (var row = 0; row < levels[0].blocks; row++) {
    await placeRight(t, ref, row);
  }
  await tapLock(t);
  await pumpSeconds(t, levels[0].holdSeconds + 1);
  expect(find.text('Your tower stood'), findsOneWidget);
}

void main() {
  testWidgets(
    'new player clears level 1, closes the app, and continues on level 2',
    (t) async {
      phone(t);
      final store = MemoryProgressStore(Progress.empty);
      final ads = FakeAds(); // never ready
      await pumpApp(t, store: store, ads: ads);
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

      // "Close the app": a new controller over the same saved store.
      await t.pumpWidget(const SizedBox());
      await pumpApp(t, store: store, ads: FakeAds());
      expect(find.text('Continue level 2'), findsOneWidget);
      expect(find.text(formatPoints(total)), findsOneWidget);
    },
  );

  testWidgets('the game plays start to finish with ads unavailable', (t) async {
    phone(t);
    await pumpApp(t);
    bool noAdText() =>
        find.textContaining(RegExp(r'\bad\b', caseSensitive: false))
            .evaluate()
            .isEmpty;
    expect(noAdText(), isTrue);
    await t.tap(find.text('Play'));
    await t.pumpAndSettle(const Duration(milliseconds: 50));
    expect(noAdText(), isTrue);
    await pumpSeconds(t, levels[0].studySeconds);
    expect(noAdText(), isTrue);
    final ref = reference(1)..finishStudy();
    for (var row = 0; row < levels[0].blocks; row++) {
      await placeRight(t, ref, row);
    }
    expect(noAdText(), isTrue);
    await tapLock(t);
    expect(find.text('It has to stand'), findsOneWidget);
    expect(noAdText(), isTrue);
    await pumpSeconds(t, levels[0].holdSeconds + 1);
    expect(find.text('Your tower stood'), findsOneWidget);
    expect(noAdText(), isTrue);
  });
}
