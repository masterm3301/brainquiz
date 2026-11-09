import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../memory/memory_levels.dart';
import '../../memory/memory_round.dart';
import '../../progress/progress.dart' show formatPoints;
import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/arena.dart';
import '../widgets/cube_tower.dart';
import '../widgets/level_row.dart' show StarRow;
import 'levels_screen.dart' show BackLabel;
import 'memorise_view.dart' show StudyClockTicker;
import 'memory_levels_screen.dart';

/// Memory Towers: study the cubes, rebuild the colours, see the score.
/// All three phases share one arena, so the towers never jump between them.
/// Leaving mid-round records nothing.
class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key, required this.levelNumber});

  final int levelNumber;

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with TickerProviderStateMixin {
  MemoryRound? _round;
  StudyClockTicker? _clock;
  bool _waitingForRoute = false;
  Animation<double>? _routeEntering;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_round != null) return;
    _round = _newRound(widget.levelNumber);
    // The first clock waits for the page transition, so all the study
    // time is spent with the tower fully on show.
    final route = ModalRoute.of(context);
    final enter = route?.animation;
    if (enter == null || (enter.isCompleted && !route!.offstage)) {
      _clock!.start();
    } else {
      _waitingForRoute = true;
      _routeEntering = enter..addStatusListener(_onRouteStatus);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (!status.isCompleted) return;
    _routeEntering?.removeStatusListener(_onRouteStatus);
    _routeEntering = null;
    if (_waitingForRoute) {
      _waitingForRoute = false;
      _clock?.start();
    }
  }

  MemoryRound _newRound(int number) {
    final round = MemoryRound(
      level: memoryLevels[number - 1],
      seed: AppScope.of(context).newSeed(),
    );
    _clock?.stop();
    _clock?.dispose();
    _clock = StudyClockTicker(
      this,
      seconds: round.level.studySeconds,
      onTick: () => setState(() {}),
      onDone: round.finishStudy,
    );
    return round;
  }

  /// A fresh round at [number]. The clock starts at once: no transition.
  void _begin(int number) {
    final old = _round!;
    _waitingForRoute = false;
    setState(() => _round = _newRound(number));
    _clock!.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _ready() {
    final clock = _clock!;
    clock.stop();
    _round!.finishStudy(secondsLeft: clock.clock.wholeSecondsLeft);
  }

  void _place(int color) {
    HapticFeedback.selectionClick();
    _round!.place(color);
  }

  void _check() {
    HapticFeedback.mediumImpact();
    final result = _round!.check();
    if (result.passed) {
      AppScope.of(context).memoryProgress.recordCleared(
        result.level.number,
        stars: result.stars,
        points: result.points,
      );
    }
  }

  void _toLevels() {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const MemoryLevelsScreen()),
    );
  }

  @override
  void dispose() {
    _routeEntering?.removeStatusListener(_onRouteStatus);
    _clock?.stop();
    _clock?.dispose();
    _round?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = _round!;
    return ListenableBuilder(
      listenable: Listenable.merge([
        round,
        AppScope.of(context).memoryProgress,
      ]),
      builder: (context, _) => _buildRound(context, round),
    );
  }

  Widget _buildRound(BuildContext context, MemoryRound round) {
    final level = round.level;
    final compact = MediaQuery.sizeOf(context).height < 700;
    final scale = MediaQuery.textScalerOf(context).scale(18) / 18;
    final buttonHeight = (34 + 20 * scale).roundToDouble();
    final total = AppScope.of(context).memoryProgress.progress.totalPoints;
    final result = round.result;

    final (title, trailing, bar, barColor) = switch (round.phase) {
      MemoryPhase.study => (
        'Remember the colours',
        '${_clock!.clock.secondsLeft}',
        _clock!.clock.fractionLeft,
        AppColors.green,
      ),
      MemoryPhase.recall => (
        'Rebuild the tower',
        '${round.filled}/${level.cubes}',
        round.filled / level.cubes,
        AppColors.cyan,
      ),
      MemoryPhase.result => (
        result!.stars == 3
            ? 'Perfect memory'
            : result.passed
            ? 'Level cleared'
            : 'Not quite',
        '${result.correct}/${result.total}',
        result.correct / result.total,
        result.passed ? AppColors.green : AppColors.red,
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            compact ? 8 : 16,
            20,
            compact ? 12 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const BackLabel(),
                  const SizedBox(width: 14),
                  Text(
                    'Level ${level.number} of ${memoryLevels.length}'
                        .toUpperCase(),
                    style: label(size: 13),
                  ),
                  const Spacer(),
                  Text(
                    formatPoints(total),
                    style: nunito(
                      15,
                      weight: 900,
                      color: AppColors.green,
                    ).copyWith(shadows: _glow(AppColors.green, 14)),
                  ),
                ],
              ),
              SizedBox(height: compact ? 6 : 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        key: const ValueKey('memory-title'),
                        maxLines: 1,
                        style: nunito(26, weight: 900, letterSpacing: -0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    trailing,
                    style: nunito(
                      28,
                      weight: 900,
                      color: barColor,
                    ).copyWith(shadows: _glow(barColor, 18)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Bar(fraction: bar, color: barColor),
              SizedBox(height: compact ? 10 : 16),
              Expanded(
                child: Arena(
                  mood: switch (result) {
                    null => ArenaMood.normal,
                    MemoryResult(passed: true) => ArenaMood.stood,
                    _ => ArenaMood.fell,
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: CubeTower(
                      cubes: switch (round.phase) {
                        MemoryPhase.study => List<int?>.of(round.target),
                        _ => List<int?>.of(round.placed),
                      },
                      cursor: round.phase == MemoryPhase.recall
                          ? round.cursor
                          : null,
                      answer: round.phase == MemoryPhase.result
                          ? round.target
                          : null,
                      onTapCube: round.phase == MemoryPhase.recall
                          ? round.select
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 10 : 16),
              SizedBox(
                height: 52 + 10 + buttonHeight,
                child: switch (round.phase) {
                  MemoryPhase.study => _studyControls(round, buttonHeight),
                  MemoryPhase.recall => _recallControls(round, buttonHeight),
                  MemoryPhase.result => _resultControls(result!, buttonHeight),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studyControls(MemoryRound round, double buttonHeight) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Bottom to top, left tower first. '
                'Start early for bonus points.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: nunito(
                  13,
                  weight: 700,
                  color: AppColors.textTertiary,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _Swatches(colors: round.level.colors),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _ActionButton(
        "I'm ready",
        key: const ValueKey('memory-ready'),
        height: buttonHeight,
        onPressed: _ready,
      ),
    ],
  );

  Widget _recallControls(MemoryRound round, double buttonHeight) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 52,
        child: _Palette(colors: round.level.colors, onPick: _place),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: _ActionButton(
              'Undo',
              key: const ValueKey('memory-undo'),
              height: buttonHeight,
              outline: true,
              onPressed: round.canUndo ? round.undo : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: _ActionButton(
              round.complete
                  ? 'Check'
                  : '${round.filled} of ${round.level.cubes}',
              key: const ValueKey('memory-check'),
              height: buttonHeight,
              onPressed: round.complete ? _check : null,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _resultControls(MemoryResult result, double buttonHeight) {
    final number = result.level.number;
    final last = number >= memoryLevels.length;
    final need = (result.total * passShare).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              StarRow(stars: result.stars, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  result.passed
                      ? result.stars == 3
                            ? 'Every cube right.'
                            : 'Wrong cubes show the right colour inside.'
                      : 'You need $need right to clear this level.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: nunito(
                    13,
                    weight: 700,
                    color: AppColors.textTertiary,
                    height: 1.3,
                  ),
                ),
              ),
              if (result.passed) ...[
                const SizedBox(width: 10),
                Text(
                  '+${formatPoints(result.points)}',
                  style: nunito(
                    20,
                    weight: 900,
                    color: AppColors.green,
                  ).copyWith(shadows: _glow(AppColors.green, 14)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _ActionButton(
                result.passed ? 'Again' : 'Levels',
                key: const ValueKey('memory-secondary'),
                height: buttonHeight,
                outline: true,
                onPressed: result.passed ? () => _begin(number) : _toLevels,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _ActionButton(
                !result.passed
                    ? 'Try again'
                    : last
                    ? 'All ${memoryLevels.length} cleared'
                    : 'Level ${number + 1}',
                key: const ValueKey('memory-primary'),
                height: buttonHeight,
                onPressed: !result.passed
                    ? () => _begin(number)
                    : last
                    ? _toLevels
                    : () => _begin(number + 1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

List<Shadow> _glow(Color color, double blur) => [
  Shadow(color: color.withValues(alpha: 0.8), blurRadius: blur),
];

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 5,
    color: AppColors.rule,
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: fraction.clamp(0.0, 1.0),
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.9), blurRadius: 14),
          ],
        ),
      ),
    ),
  );
}

/// The colours in play this level, as small chips.
class _Swatches extends StatelessWidget {
  const _Swatches({required this.colors});

  final int colors;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$colors colours',
    excludeSemantics: true,
    child: SizedBox(
      width: 4 * 14 + 3 * 4,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < colors; i++)
            Container(width: 14, height: 14, color: cubeColors[i]),
        ],
      ),
    ),
  );
}

/// One tappable cube per colour in play.
class _Palette extends StatelessWidget {
  const _Palette({required this.colors, required this.onPick});

  final int colors;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < colors; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            button: true,
            label: cubeColorNames[i],
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('palette-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(i),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cubeColors[i],
                      borderRadius: BorderRadius.circular(4),
                      border: Border(
                        top: BorderSide(
                          color: Color.lerp(
                            cubeColors[i],
                            AppColors.text,
                            0.4,
                          )!,
                          width: 5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cubeColors[i].withValues(alpha: 0.45),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

/// A fixed-height button, so the controls take the same room in every phase.
class _ActionButton extends StatelessWidget {
  const _ActionButton(
    this.text, {
    super.key,
    required this.height,
    required this.onPressed,
    this.outline = false,
  });

  final String text;
  final double height;
  final VoidCallback? onPressed;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: outline ? null : AppColors.green,
              border: outline
                  ? Border.all(color: AppColors.green, width: 2)
                  : null,
              boxShadow: outline || !enabled
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.45),
                        blurRadius: 26,
                      ),
                    ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                style: nunito(
                  18,
                  weight: 900,
                  color: outline ? AppColors.green : AppColors.onGreen,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
