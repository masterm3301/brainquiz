import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'rewarded_ads.dart';

/// Google Mobile Ads implementation (test IDs only). Consent never blocks the
/// game: every failure leaves [isReady] false and the game playable.
class AdMobRewardedAds implements RewardedAds {
  static const Duration _retryDelay = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _showWatchdog = Duration(seconds: 10);
  static const Duration _rewardGrace = Duration(seconds: 1);

  final ValueNotifier<bool> _ready = ValueNotifier<bool>(false);
  RewardedAd? _ad;
  bool _showing = false;
  bool _initialized = false;
  int _failedLoads = 0;
  Timer? _retryTimer;

  @override
  ValueListenable<bool> get isReady => _ready;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final consentUpdated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => consentUpdated.complete(),
        (error) => consentUpdated.completeError(error.message),
      );
      await consentUpdated.future;

      await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
    } catch (_) {
      // Consent failures fall through: a cached consent may still allow ads.
    }
    try {
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: AdPolicy.maxContentRating),
      );
      await MobileAds.instance.initialize();
      await _load();
    } catch (_) {
      _ready.value = false;
    }
  }

  Future<void> _load() async {
    final unitId = AdIds.rewarded;
    if (unitId == null) return;
    try {
      await RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(nonPersonalizedAds: AdPolicy.nonPersonalizedAds),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _failedLoads = 0;
            _ad = ad;
            _ready.value = true;
          },
          onAdFailedToLoad: (_) {
            _ad = null;
            _ready.value = false;
            _scheduleRetry();
          },
        ),
      );
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (++_failedLoads > _maxRetries) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () => unawaited(_load()));
  }

  @override
  Future<bool> show() async {
    final ad = _ad;
    if (ad == null || _showing) return false;
    _showing = true;
    _ad = null;
    _ready.value = false;

    final done = Completer<bool>();
    var rewarded = false;
    var dismissed = false;
    Timer? watchdog;
    Timer? grace;
    void finish() {
      if (done.isCompleted) return;
      watchdog?.cancel();
      grace?.cancel();
      try {
        ad.dispose();
      } catch (_) {}
      _showing = false;
      done.complete(rewarded);
      unawaited(_load());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) => watchdog?.cancel(),
      onAdDismissedFullScreenContent: (_) {
        dismissed = true;
        if (rewarded) {
          finish();
        } else {
          // The reward event can land just after dismissal.
          grace = Timer(_rewardGrace, finish);
        }
      },
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          rewarded = true;
          if (dismissed) finish();
        },
      );
      // Native show() can succeed without ever raising an event.
      if (!done.isCompleted && !dismissed) {
        watchdog = Timer(_showWatchdog, finish);
      }
    } catch (_) {
      finish();
    }
    return done.future;
  }
}
