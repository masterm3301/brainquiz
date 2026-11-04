import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart'
    show MaxAdContentRating;

/// Google's published test IDs only. No real IDs belong here.
class AdIds {
  const AdIds._();

  static const String rewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String rewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  /// Rewarded test unit for the current platform, or null if unsupported.
  static String? get rewarded {
    if (Platform.isAndroid) return rewardedAndroid;
    if (Platform.isIOS) return rewardedIos;
    return null;
  }
}

/// The single place to change ad content rating and personalization.
class AdPolicy {
  const AdPolicy._();

  static final String maxContentRating = MaxAdContentRating.t;
  static const bool nonPersonalizedAds = true;
}
