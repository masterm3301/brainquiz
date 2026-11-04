import 'package:flutter/material.dart';

import 'ui/theme/tokens.dart';

class TowerBuildApp extends StatelessWidget {
  const TowerBuildApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Build',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.background,
        fontFamily: 'Nunito',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.green,
          onPrimary: AppColors.onGreen,
          surface: AppColors.panel,
          onSurface: AppColors.text,
          error: AppColors.red,
        ),
        textTheme: Typography.whiteMountainView.apply(
          fontFamily: 'Nunito',
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: AppColors.transparent,
      ),
      home: home,
    );
  }
}
