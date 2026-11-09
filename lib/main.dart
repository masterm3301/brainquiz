import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads/admob_rewarded_ads.dart';
import 'ads/rewarded_ads.dart';
import 'app.dart';
import 'memory/memory_levels.dart';
import 'progress/progress_controller.dart';
import 'progress/progress_store.dart';
import 'ui/app_scope.dart';
import 'ui/screens/menu_screen.dart';
import 'ui/theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Nunito'], text);
  });
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  final progress = ProgressController(SharedPrefsProgressStore());
  final memoryProgress = ProgressController(
    SharedPrefsProgressStore.memory(memoryLevels.length),
    lastLevel: memoryLevels.length,
  );
  await Future.wait([progress.load(), memoryProgress.load()]);

  final onMobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  final RewardedAds ads = onMobile ? AdMobRewardedAds() : NoAds();
  // Deliberately not awaited: ads must never delay startup.
  ads.initialize();

  runApp(AppScope(
    progress: progress,
    memoryProgress: memoryProgress,
    ads: ads,
    newSeed: () => DateTime.now().microsecondsSinceEpoch,
    child: const TowerBuildApp(home: MenuScreen()),
  ));
}
