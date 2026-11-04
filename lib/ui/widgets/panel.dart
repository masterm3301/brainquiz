import 'package:flutter/widgets.dart';

import '../theme/text.dart';
import '../theme/tokens.dart';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.rule),
        ),
        child: child,
      );
}

/// A row of small labelled stats, each in its own bordered cell.
class StatRow extends StatelessWidget {
  const StatRow(this.stats, {super.key});

  final List<(String label, String value, Color? color)> stats;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.rule),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stats[i].$1.toUpperCase(),
                        style: label(size: 11)),
                    const SizedBox(height: 3),
                    Text(stats[i].$2,
                        style: nunito(18,
                            weight: 900,
                            color: stats[i].$3 ?? AppColors.text)),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
}
