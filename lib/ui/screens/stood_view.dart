import 'package:flutter/material.dart';

import '../../game/attempt.dart';
import '../../game/levels.dart';
import '../../progress/progress.dart' show formatPoints;
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/arena.dart';
import '../widgets/neon_button.dart';
import '../widgets/panel.dart';
import '../widgets/tower_view.dart';
import 'hold_view.dart' show ScreenBody;

/// Screen 04: the tower stood.
class StoodView extends StatelessWidget {
  const StoodView({
    super.key,
    required this.attempt,
    required this.result,
    required this.onNextLevel,
    required this.onBackToLevels,
  });

  final Attempt attempt;
  final AttemptResult result;
  final VoidCallback onNextLevel;
  final VoidCallback onBackToLevels;

  @override
  Widget build(BuildContext context) {
    final number = result.level.number;
    final last = number >= levels.length;
    return ScreenBody(
      children: [
        Text(
          'Held ${result.heldSeconds} seconds'.toUpperCase(),
          style: label(color: AppColors.green),
        ),
        const SizedBox(height: 6),
        Text(
          'Your tower stood',
          key: const ValueKey('result-title'),
          style: nunito(32, weight: 900, letterSpacing: -0.5).copyWith(
            shadows: [
              Shadow(
                color: AppColors.green.withValues(alpha: 0.35),
                blurRadius: 26,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Arena(
            mood: ArenaMood.stood,
            child: TowerView(placed: attempt.placed),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.rule),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Cell('Memory', '${result.correct} / ${result.total}', null),
                _Cell('Held', '${result.heldSeconds}s', null),
                _Cell(
                  'Points',
                  '+${formatPoints(result.points)}',
                  AppColors.green,
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why it held'.toUpperCase(),
                style: label(size: 11).copyWith(letterSpacing: 1.32),
              ),
              const SizedBox(height: 5),
              Text(
                result.detail,
                style: nunito(
                  15,
                  weight: 700,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        NeonButton.primary(
          last
              ? 'You cleared all ${levels.length}'
              : 'Level ${number + 1} — hold for ${levels[number].holdSeconds}s',
          onPressed: last ? onBackToLevels : onNextLevel,
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.title, this.value, this.color, {this.last = false});

  final String title, value;
  final Color? color;
  final bool last;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(right: BorderSide(color: AppColors.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: label(size: 11)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: nunito(22, weight: 900, color: color ?? AppColors.text)
                  .copyWith(
                    shadows: color == null
                        ? null
                        : [
                            Shadow(
                              color: color!.withValues(alpha: 0.8),
                              blurRadius: 14,
                            ),
                          ],
                  ),
            ),
          ),
        ],
      ),
    ),
  );
}
