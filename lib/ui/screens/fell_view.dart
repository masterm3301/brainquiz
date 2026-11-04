import 'package:flutter/material.dart';

import '../../game/attempt.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/arena.dart';
import '../widgets/collapse_view.dart';
import '../widgets/meter.dart';
import '../widgets/panel.dart';
import 'hold_view.dart' show ScreenBody;

/// Screen 05: the tower fell, and why.
class FellView extends StatefulWidget {
  const FellView({
    super.key,
    required this.attempt,
    required this.result,
    required this.direction,
    required this.onBuildAgain,
  });

  final Attempt attempt;
  final AttemptResult result;

  /// The side the tower leaned to when it fell: 1 right, -1 left.
  final int direction;
  final VoidCallback onBuildAgain;

  @override
  State<FellView> createState() => _FellViewState();
}

class _FellViewState extends State<FellView> {
  final _collapse = GlobalKey<CollapseViewState>();

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return ScreenBody(
      children: [
        Text(
          'Fell at ${result.fellAtSeconds} of ${result.level.holdSeconds} seconds'
              .toUpperCase(),
          style: label(color: AppColors.red),
        ),
        const SizedBox(height: 6),
        Text(
          result.headline,
          key: const ValueKey('result-title'),
          style: nunito(32, weight: 900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Arena(
            mood: ArenaMood.fell,
            child: CollapseView(
              key: _collapse,
              placed: widget.attempt.placed,
              seed: result.level.number * 1000 + result.fellAtSeconds,
              direction: widget.direction,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What went wrong'.toUpperCase(),
                style: label(size: 11).copyWith(letterSpacing: 1.32),
              ),
              const SizedBox(height: 10),
              Text(
                result.detail,
                style: nunito(
                  15,
                  weight: 700,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('At lock', style: nunito(12, weight: 900, color: AppColors.label)),
                  const SizedBox(width: 10),
                  Expanded(child: Meter(percent: result.lockStability)),
                  const SizedBox(width: 10),
                  Text(
                    '${result.lockStability}%',
                    style: nunito(
                      14,
                      weight: 900,
                      color: meterColor(result.lockStability),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _SheetButton(
                'Replay the fall',
                onPressed: () => _collapse.currentState?.replay(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SheetButton(
                'Build again',
                primary: true,
                onPressed: widget.onBuildAgain,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The sheet's two 16px buttons for this screen.
class _SheetButton extends StatelessWidget {
  const _SheetButton(this.text, {required this.onPressed, this.primary = false});

  final String text;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: text,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? AppColors.green : null,
          border: primary ? null : Border.all(color: AppColors.dashed, width: 1.5),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.4),
                    blurRadius: 26,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: nunito(
            16,
            weight: 900,
            color: primary ? AppColors.onGreen : AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}
