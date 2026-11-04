import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Green at 70 and above, yellow 40 to 69, red below 40.
Color meterColor(int percent) => percent >= 70
    ? AppColors.green
    : percent >= 40
        ? AppColors.yellow
        : AppColors.red;

class Meter extends StatelessWidget {
  const Meter({super.key, required this.percent, this.height = 8});

  final int percent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = meterColor(percent);
    return Container(
      height: height,
      color: AppColors.rule,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: percent.clamp(0, 100) / 100,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.9), blurRadius: 16),
            ],
          ),
        ),
      ),
    );
  }
}
