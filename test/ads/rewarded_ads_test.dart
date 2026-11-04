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

  test('FakeAds completes with the given outcome', () async {
    final ads = FakeAds()..ready = true;
    expect(ads.isReady.value, isTrue);

    final first = ads.show();
    expect(ads.showCount, 1);
    ads.complete(false);
    expect(await first, isFalse);

    final second = ads.show();
    expect(ads.showCount, 2);
    ads.complete(true);
    expect(await second, isTrue);
  });
}
