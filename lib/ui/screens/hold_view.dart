import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../game/attempt.dart';
import '../../game/hold_simulation.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/arena.dart';
import '../widgets/meter.dart';
import '../widgets/neon_button.dart';
import '../widgets/panel.dart';
import '../widgets/tower_view.dart';

/// Shared frame for the wind and result screens: the sheet's padding, with
/// a scroll fallback so large text on a short phone never overflows.
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children});

  final List<Widget> children;

  /// Below this height the screen scrolls instead of squeezing further.
  static const double minHeight = 820;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxHeight < 700;
          return SingleChildScrollView(
            child: SizedBox(
              height: math.max(c.maxHeight, minHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  compact ? 12 : 24,
                  24,
                  compact ? 12 : 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Screen 03: hands off. A [Ticker] feeds real frame deltas to the
/// simulation, which clamps them itself.
class HoldView extends StatefulWidget {
  const HoldView({
    super.key,
    required this.attempt,
    required this.sim,
    required this.onEnded,
  });

  final Attempt attempt;
  final HoldSimulation sim;

  /// Called once, when the tower falls or the hold runs out. The argument
  /// is the side it leaned to last: 1 right, -1 left.
  final ValueChanged<int> onEnded;

  @override
  State<HoldView> createState() => _HoldViewState();
}

class _HoldViewState extends State<HoldView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  int _direction = 1;

  HoldSimulation get _sim => widget.sim;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _sim.step(dt);
    if (_sim.leanDegrees.abs() > 0.01) _direction = _sim.leanDegrees.sign.toInt();
    if (_sim.fallen || _sim.finished) {
      _ticker.stop();
      if (_sim.fallen) HapticFeedback.mediumImpact();
      widget.onEnded(_direction);
    } else {
      setState(() {});
    }
  }

  void _brace() {
    if (_sim.fallen) return;
    if (_sim.brace()) {
      HapticFeedback.lightImpact();
      setState(() {});
    }
  }

  String get _braceLine {
    final freeNext = widget.attempt.adBraceEarned && _sim.bracesUsed == 0;
    if (freeNext) return 'Free brace from the ad. Use it to steady the tower.';
    final left = _sim.bracesLeft;
    final count = left == 1 ? 'One brace' : '$left braces';
    return '$count left. Use it to steady the tower — costs 40 points.';
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.attempt.level;
    final stability = _sim.stabilityPercent;
    final color = meterColor(stability);
    final lean = _sim.leanDegrees;
    final leanText = lean.abs().round() == 0
        ? '0°'
        : '${lean.abs().round()}° ${lean > 0 ? 'right' : 'left'}';
    final gust = _sim.gustIndex.clamp(1, level.gusts);
    final hasBrace = _sim.bracesLeft > 0;
    return ScreenBody(
      children: [
        Text(
          'Hands off — wind is on'.toUpperCase(),
          style: label(color: AppColors.green),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'It has to stand',
                style: nunito(28, weight: 900, letterSpacing: -0.4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_sim.secondsLeft}s',
              style: nunito(34, weight: 900, color: AppColors.green).copyWith(
                shadows: [
                  Shadow(
                    color: AppColors.green.withValues(alpha: 0.9),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        StatRow([
          ('Wind', 'Gust $gust of ${level.gusts}', AppColors.cyan),
          ('Lean', leanText, color),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Arena(
            wind: true,
            child: TowerView(
              placed: widget.attempt.placed,
              leanDegrees: lean,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Stability'.toUpperCase(), style: label()),
            const SizedBox(width: 10),
            Expanded(child: Meter(percent: stability)),
            const SizedBox(width: 10),
            Text(
              '$stability%',
              style: nunito(15, weight: 900, color: color),
            ),
          ],
        ),
        if (hasBrace) ...[
          const SizedBox(height: 12),
          Text(
            _braceLine,
            textAlign: TextAlign.center,
            style: nunito(
              15,
              weight: 700,
              color: AppColors.textTertiary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          NeonButton.outline(
            'Brace it (${_sim.bracesLeft} left)',
            onPressed: _sim.fallen ? null : _brace,
          ),
        ],
      ],
    );
  }
}
