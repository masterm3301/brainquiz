import 'package:flutter/widgets.dart';

import '../ads/rewarded_ads.dart';
import '../progress/progress_controller.dart';

/// App-wide services. [newSeed] is clock-based in `main()` and fixed in tests.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.progress,
    required this.ads,
    required this.newSeed,
    required super.child,
  });

  final ProgressController progress;
  final RewardedAds ads;
  final int Function() newSeed;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      progress != old.progress || ads != old.ads || newSeed != old.newSeed;
}
