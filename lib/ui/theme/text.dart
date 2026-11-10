import 'package:flutter/painting.dart';

import 'tokens.dart';

/// Nunito at a variable-font weight (700 to 900 in practice).
TextStyle nunito(
  double size, {
  int weight = 800,
  Color color = AppColors.text,
  double? letterSpacing,
  double? height,
}) => _variable('Nunito', size, weight, color, letterSpacing, height);

/// Manrope, the home screen's body face.
TextStyle manrope(
  double size, {
  int weight = 700,
  Color color = AppColors.text,
  double? letterSpacing,
  double? height,
}) => _variable('Manrope', size, weight, color, letterSpacing, height);

/// Unbounded, the home screen's wide display face.
TextStyle unbounded(
  double size, {
  int weight = 700,
  Color color = AppColors.text,
  double? letterSpacing,
  double? height,
}) => _variable('Unbounded', size, weight, color, letterSpacing, height);

TextStyle _variable(
  String family,
  double size,
  int weight,
  Color color,
  double? letterSpacing,
  double? height,
) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)],
    fontVariations: [FontVariation('wght', weight.toDouble())],
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// Small caption style. Callers uppercase the string.
TextStyle label({double size = 12, Color color = AppColors.label}) =>
    nunito(size, weight: 900, color: color, letterSpacing: size * 0.1);
