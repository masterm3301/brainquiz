import 'dart:io';

import 'package:brainquiz/ads/ad_ids.dart';
import 'package:brainquiz/ui/screens/about_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Play and AdMob requirements for a 13+ app that shows rewarded ads.
void main() {
  test('ads are capped at teen content and non-personalized', () {
    expect(AdPolicy.maxContentRating, MaxAdContentRating.t);
    expect(AdPolicy.nonPersonalizedAds, isTrue);
  });

  test('the app is not tagged as child directed (13+ audience)', () {
    final code = File('lib/ads/admob_rewarded_ads.dart').readAsStringSync();
    expect(code, isNot(contains('tagForChildDirectedTreatment')));
    expect(code, isNot(contains('tagForUnderAgeOfConsent')));
  });

  test('the manifest declares the advertising ID permission', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('com.google.android.gms.permission.AD_ID'));
    expect(manifest, isNot(contains('tools:node="remove"')));
  });

  test('a privacy policy link is set before release', () {
    expect(privacyPolicyUrl, startsWith('https://'),
        reason: 'Fill in privacyPolicyUrl in lib/ui/screens/about_screen.dart');
  });
}
