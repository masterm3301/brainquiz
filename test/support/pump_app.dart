import 'package:brainquiz/ads/rewarded_ads.dart';
import 'package:brainquiz/app.dart';
import 'package:brainquiz/progress/progress.dart';
import 'package:brainquiz/progress/progress_controller.dart';
import 'package:brainquiz/progress/progress_store.dart';
import 'package:brainquiz/ui/app_scope.dart';
import 'package:brainquiz/ui/screens/menu_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'load_font.dart';

class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore(this.progress);
  Progress progress;

  @override
  Future<Progress> load() async => progress;

  @override
  Future<void> save(Progress progress) async => this.progress = progress;
}

/// Pumps the whole app inside an [AppScope] with an in-memory store.
Future<void> pumpApp(
  WidgetTester t, {
  Progress progress = Progress.empty,
  RewardedAds? ads,
  int Function()? newSeed,
  Widget? home,
}) async {
  await loadNunito();
  final controller = ProgressController(MemoryProgressStore(progress));
  await controller.load();
  await t.pumpWidget(AppScope(
    progress: controller,
    ads: ads ?? NoAds(),
    newSeed: newSeed ?? () => 42,
    child: TowerBuildApp(home: home ?? const MenuScreen()),
  ));
}
