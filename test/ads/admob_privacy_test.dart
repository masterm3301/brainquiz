import 'package:brainquiz/ads/admob_rewarded_ads.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _umpChannel = MethodChannel('plugins.flutter.io/google_mobile_ads/ump');

class _FakeConsent implements ConsentInformation {
  PrivacyOptionsRequirementStatus status =
      PrivacyOptionsRequirementStatus.notRequired;
  bool statusThrows = false;
  bool updateFails = false;
  bool canRequest = false;
  int canRequestChecks = 0;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) {
    if (updateFails) {
      failureListener(FormError(errorCode: 1, message: 'offline'));
    } else {
      successListener();
    }
  }

  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async {
    if (statusThrows) throw PlatformException(code: '1');
    return status;
  }

  @override
  Future<bool> canRequestAds() async {
    canRequestChecks++;
    return canRequest;
  }

  @override
  Future<bool> isConsentFormAvailable() async => false;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.unknown;

  @override
  Future<void> reset() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final original = ConsentInformation.instance;
  late _FakeConsent consent;
  late List<String> calls;

  void onFormShown(Future<Object?> Function() respond) {
    messenger.setMockMethodCallHandler(_umpChannel, (call) {
      calls.add(call.method);
      return call.method == 'UserMessagingPlatform#showPrivacyOptionsForm'
          ? respond()
          : Future<Object?>.value();
    });
  }

  setUp(() {
    consent = _FakeConsent();
    calls = [];
    ConsentInformation.instance = consent;
    onFormShown(() async => null);
  });

  tearDown(() {
    ConsentInformation.instance = original;
    messenger.setMockMethodCallHandler(_umpChannel, null);
  });

  test('not required until initialize says so', () async {
    consent.status = PrivacyOptionsRequirementStatus.required;
    final ads = AdMobRewardedAds();
    expect(ads.privacyOptionsRequired.value, isFalse);
    await ads.initialize();
    expect(ads.privacyOptionsRequired.value, isTrue);
  });

  for (final status in [
    PrivacyOptionsRequirementStatus.notRequired,
    PrivacyOptionsRequirementStatus.unknown,
  ]) {
    test('status $status hides the entry', () async {
      consent.status = status;
      final ads = AdMobRewardedAds();
      await ads.initialize();
      expect(ads.privacyOptionsRequired.value, isFalse);
    });
  }

  test('a failed consent update still reads the cached status', () async {
    consent
      ..updateFails = true
      ..status = PrivacyOptionsRequirementStatus.required;
    final ads = AdMobRewardedAds();
    await ads.initialize();
    expect(ads.privacyOptionsRequired.value, isTrue);
  });

  test('a status error leaves the entry hidden and does not throw', () async {
    consent.statusThrows = true;
    final ads = AdMobRewardedAds();
    await ads.initialize();
    expect(ads.privacyOptionsRequired.value, isFalse);
  });

  test('showPrivacyOptions opens the form, then reads the status again',
      () async {
    final ads = AdMobRewardedAds();
    await ads.initialize();
    consent.status = PrivacyOptionsRequirementStatus.required;
    await ads.showPrivacyOptions();
    expect(calls, contains('UserMessagingPlatform#showPrivacyOptionsForm'));
    expect(ads.privacyOptionsRequired.value, isTrue);
  });

  test('ads get another chance to start after the form', () async {
    final ads = AdMobRewardedAds();
    await ads.initialize();
    final before = consent.canRequestChecks;
    await ads.showPrivacyOptions();
    expect(consent.canRequestChecks, before + 1);
  });

  test('showPrivacyOptions never throws on a platform error', () async {
    onFormShown(() async => throw PlatformException(code: '1', message: 'no'));
    final ads = AdMobRewardedAds();
    await expectLater(ads.showPrivacyOptions(), completes);
  });

  test('showPrivacyOptions never throws with no plugin at all', () async {
    messenger.setMockMethodCallHandler(_umpChannel, null);
    final ads = AdMobRewardedAds();
    await expectLater(ads.showPrivacyOptions(), completes);
  });

  test('showPrivacyOptions never throws when the status read fails', () async {
    consent.statusThrows = true;
    final ads = AdMobRewardedAds();
    await expectLater(ads.showPrivacyOptions(), completes);
  });
}
