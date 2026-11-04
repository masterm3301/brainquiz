import 'dart:async';

import 'package:brainquiz/ads/rewarded_ads.dart';
import 'package:flutter/foundation.dart';

/// Test double: settable ready flag, counts show() calls, and completes
/// each show() on demand via [complete].
class FakeAds implements RewardedAds {
  final ValueNotifier<bool> _ready = ValueNotifier<bool>(false);
  Completer<bool>? _pending;
  final ValueNotifier<bool> _privacyRequired = ValueNotifier<bool>(false);
  int showCount = 0;
  int privacyShowCount = 0;

  bool get ready => _ready.value;
  set ready(bool value) => _ready.value = value;

  set privacyRequired(bool value) => _privacyRequired.value = value;

  @override
  ValueListenable<bool> get isReady => _ready;

  @override
  ValueListenable<bool> get privacyOptionsRequired => _privacyRequired;

  @override
  Future<void> showPrivacyOptions() async => privacyShowCount++;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> show() {
    if (!ready || _pending != null) return Future.value(false);
    showCount++;
    ready = false;
    final pending = Completer<bool>();
    _pending = pending;
    return pending.future;
  }

  /// Completes the in-progress show() with [rewarded].
  void complete(bool rewarded) {
    _pending?.complete(rewarded);
    _pending = null;
  }
}
