import 'package:brainquiz/ads/rewarded_ads.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ads.dart';

void main() {
  test('NoAds is never ready and never rewards', () async {
    final ads = NoAds();
    await ads.initialize();
    expect(ads.isReady.value, isFalse);
    expect(await ads.show(), isFalse);
  });

  test('NoAds never requires privacy options, and showing them is safe',
      () async {
    final ads = NoAds();
    expect(ads.privacyOptionsRequired.value, isFalse);
    await ads.showPrivacyOptions();
    expect(ads.privacyOptionsRequired.value, isFalse);
  });

  test('FakeAds completes with the given outcome', () async {
    final ads = FakeAds()..ready = true;
    expect(ads.isReady.value, isTrue);

    final first = ads.show();
    expect(ads.showCount, 1);
    ads.complete(false);
    expect(await first, isFalse);

    ads.ready = true;
    final second = ads.show();
    expect(ads.showCount, 2);
    ads.complete(true);
    expect(await second, isTrue);
  });

  test('FakeAds show returns false at once when not ready', () async {
    final ads = FakeAds();
    expect(await ads.show(), isFalse);
    expect(ads.showCount, 0);
  });

  test('FakeAds is not ready while showing and rejects a second show',
      () async {
    final ads = FakeAds()..ready = true;
    final first = ads.show();
    expect(ads.isReady.value, isFalse);
    ads.ready = true;
    expect(await ads.show(), isFalse);
    expect(ads.showCount, 1);
    ads.complete(true);
    expect(await first, isTrue);
  });
}
