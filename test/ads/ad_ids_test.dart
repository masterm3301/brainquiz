import 'package:brainquiz/ads/ad_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android release builds use the live rewarded unit', () {
    expect(AdIds.rewardedFor(android: true, ios: false, release: true),
        'ca-app-pub-9331906778457556/3902575117');
  });

  test('debug and profile builds never use the live unit', () {
    expect(AdIds.rewardedFor(android: true, ios: false, release: false),
        AdIds.rewardedAndroidTest);
    expect(AdIds.rewardedAndroidTest, startsWith('ca-app-pub-3940256099942544/'));
  });

  test('iOS stays on test ads; other platforms get none', () {
    expect(AdIds.rewardedFor(android: false, ios: true, release: true),
        AdIds.rewardedIosTest);
    expect(AdIds.rewardedFor(android: false, ios: false, release: true),
        isNull);
  });
}
