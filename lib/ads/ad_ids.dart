import 'dart:io' show Platform;

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
