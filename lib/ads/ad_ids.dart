import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kReleaseMode, visibleForTesting;
import 'package:google_mobile_ads/google_mobile_ads.dart'
    show MaxAdContentRating;

/// Rewarded ad units. Release builds on Android use the live AdMob unit;
/// every other build uses Google's published test units, so development
/// never shows (or clicks) real ads on the AdMob account.
///
/// The Android AdMob app ID lives in android/app/src/main/AndroidManifest.xml.
/// iOS has no AdMob app yet, so it stays on test IDs in every build.
class AdIds {
  const AdIds._();

  /// Live "reward" unit in AdMob app ca-app-pub-9331906778457556~1593986873.
  static const String rewardedAndroidLive =
      'ca-app-pub-9331906778457556/3902575117';

  static const String rewardedAndroidTest =
      'ca-app-pub-3940256099942544/5224354917';
  static const String rewardedIosTest =
      'ca-app-pub-3940256099942544/1712485313';

  /// Rewarded unit for this platform and build, or null if unsupported.
  static String? get rewarded => rewardedFor(
    android: Platform.isAndroid,
    ios: Platform.isIOS,
    release: kReleaseMode,
  );

  @visibleForTesting
  static String? rewardedFor({
    required bool android,
    required bool ios,
    required bool release,
  }) {
    if (android) return release ? rewardedAndroidLive : rewardedAndroidTest;
    if (ios) return rewardedIosTest;
    return null;
  }
}

/// The single place to change ad content rating and personalization.
///
/// The Play target audience is 13 and over, so the app is not child
/// directed: requests set no child-directed or under-age-of-consent tag
/// (setting either would wrongly limit ads for an adult audience). Ads are
/// capped at teen content to suit the youngest players in that audience,
/// and stay non-personalized; Google's UMP form still handles consent where
/// the law requires it.
class AdPolicy {
  const AdPolicy._();

  static final String maxContentRating = MaxAdContentRating.t;
  static const bool nonPersonalizedAds = true;
}
