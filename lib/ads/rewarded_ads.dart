import 'package:flutter/foundation.dart';

/// Rewarded ads behind a small interface so game logic and tests never
/// depend on the ad SDK.
abstract class RewardedAds {
  /// True only while an ad is loaded and can be shown.
  ValueListenable<bool> get isReady;

  /// Prepares ads. Must never throw; any failure leaves [isReady] false.
  Future<void> initialize();

  /// Shows an ad. Completes true only if the reward was earned; false for
  /// anything else (nothing loaded, show failed, dismissed early).
  Future<bool> show();

  /// True when the player must be offered a way to change their ad consent.
  ValueListenable<bool> get privacyOptionsRequired;

  /// Shows the form for changing ad consent. Must never throw.
  Future<void> showPrivacyOptions();
}

/// Used on unsupported platforms: never ready, never rewards.
class NoAds implements RewardedAds {
  final ValueNotifier<bool> _ready = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _privacyOptionsRequired = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get isReady => _ready;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> show() async => false;

  @override
  ValueListenable<bool> get privacyOptionsRequired => _privacyOptionsRequired;

  @override
  Future<void> showPrivacyOptions() async {}
}
