import 'dart:ui';

/// Every colour in the app. Nothing else defines a colour.
abstract final class AppColors {
  static const background = Color(0xFF05070D);
  static const panel = Color(0xFF0A0F1C);
  static const rule = Color(0xFF12182A);
  static const trayBorder = Color(0xFF1A2236);
  static const dashed = Color(0xFF22304D);
  static const text = Color(0xFFEEF3FF);
  static const textSecondary = Color(0xFFC6CEE6);
  static const textTertiary = Color(0xFF8A93B2);
  static const label = Color(0xFF6B7394);
  static const green = Color(0xFF22E06B);
  static const onGreen = Color(0xFF04210F);
  static const cyan = Color(0xFF06B6D4);
  static const yellow = Color(0xFFF5D90A);
  static const red = Color(0xFFFF3B30);
  static const arenaNormal = Color(0xFF0D2416);
  static const arenaStood = Color(0xFF133D22);
  static const arenaFell = Color(0xFF2A0D0C);
  static const borderStood = Color(0xFF1C3A28);
  static const borderFell = Color(0xFF2A1A1C);
  static const transparent = Color(0x00000000);

  // Memory Towers cubes, in the order levels unlock them.
  static const cubeBlue = Color(0xFF3B82F6);
  static const cubePurple = Color(0xFFA855F7);
  static const cubeOrange = Color(0xFFFF8A1F);
  static const cubePink = Color(0xFFFF4FA3);
  static const cubeEmpty = Color(0xFF0E1424);
}

/// The home screen's palette, from the menu design.
abstract final class MenuColors {
  static const text = Color(0xFFF4F7FB);
  static const muted = Color(0xFF9AA6B8);
  static const faint = Color(0xFF8A96A8);
  static const icon = Color(0xFFC9D2DF);
  static const star = Color(0xFFFFD23F);
  static const onAccent = Color(0xFF212121);
  static const card = Color(0xE60D121C);
  static const memoryAccent = Color(0xFF2BE07A);
  static const windAccent = Color(0xFF5CC8FF);

  /// White at [alpha], for outlines and glass fills.
  static Color white(double alpha) => const Color(0xFFFFFFFF).withValues(alpha: alpha);

  /// One colour per cleared level, repeating up the tower.
  static const levels = [
    Color(0xFF3D8BFF),
    Color(0xFFFF4D5E),
    Color(0xFFFFD23F),
    Color(0xFF2BE07A),
    Color(0xFFB26BFF),
  ];

  static Color level(int number) => levels[(number - 1) % levels.length];
}
