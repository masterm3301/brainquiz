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
import '../widgets/ad_offer.dart';
import '../widgets/level_row.dart' show StarRow;
import 'levels_screen.dart' show BackLabel;
import 'memorise_view.dart' show StudyClockTicker;
import 'memory_levels_screen.dart';

/// Memory Towers: study the cubes, rebuild the colours, see the score.
/// All three phases share one arena, so the towers never jump between them.
/// Leaving mid-round records nothing.
///
/// Rewarded ads are optional help, offered only when one is loaded: a peek
/// at the tower while rebuilding, or another go at the same tower after a
/// miss. Either caps the round at [adHelpStars] stars.
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
  StudyClockTicker? _peekClock;
  bool _adShowing = false;
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

  MemoryRound _newRound(int number, {int? seed, bool adHelped = false}) {
    final round = MemoryRound(
      level: memoryLevels[number - 1],
      seed: seed ?? AppScope.of(context).newSeed(),
      adHelped: adHelped,
    );
    _stopPeek();
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
  /// With [seed], the same tower again.
  void _begin(int number, {int? seed, bool adHelped = false}) {
    final old = _round!;
    _waitingForRoute = false;
    setState(() => _round = _newRound(number, seed: seed, adHelped: adHelped));
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

  void _stopPeek() {
    _peekClock?.stop();
    _peekClock?.dispose();
    _peekClock = null;
  }

  /// Explains the offer, then plays the ad. True only if it was watched
  /// to the end.
  Future<bool> _watchAd(String title, String body) async {
    if (_adShowing) return false;
    final ok = await showAdOffer(context, title: title, body: body);
    if (!ok || !mounted) return false;
    setState(() => _adShowing = true);
    final earned = await AppScope.of(context).ads.show();
    if (!mounted) return false;
    setState(() => _adShowing = false);
    return earned;
  }

  Future<void> _peek() async {
    final round = _round!;
    if (!round.canPeek) return;
    final seconds = round.level.peekSeconds;
    final earned = await _watchAd(
      'Peek at the tower',
      'Watch a short ad to see the whole tower again for $seconds seconds. '
          'The cubes you placed stay put. This round can then earn at most '
          '$adHelpStars stars.',
    );
    if (!earned || !mounted || round != _round || !round.canPeek) return;
    round.startPeek();
    _stopPeek();
    // A ticker, not a timer: time away from the app does not use up the peek.
    _peekClock = StudyClockTicker(
      this,
      seconds: seconds,
      onTick: () => setState(() {}),
      onDone: round.endPeek,
    )..start();
  }

  Future<void> _retrySameTower() async {
    final round = _round!;
    final earned = await _watchAd(
      'Same tower again',
      'Watch a short ad to study and rebuild this exact tower again, '
          'instead of new colours. Clearing it earns at most '
          '$adHelpStars stars.',
    );
    if (!earned || !mounted || round != _round) return;
    _begin(round.level.number, seed: round.seed, adHelped: true);
  }

  void _check() {
    HapticFeedback.mediumImpact();
    _stopPeek();
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
    _stopPeek();
    _round?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = _round!;
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        round,
        scope.memoryProgress,
        scope.ads.isReady,
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
    final peekClock = _peekClock?.clock;
    final peeking = round.peeking && peekClock != null;

    final (title, trailing, bar, barColor) = switch (round.phase) {
      MemoryPhase.recall when peeking => (
        'Take a peek',
        '${peekClock.secondsLeft}',
        peekClock.fractionLeft,
        AppColors.green,
      ),
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
        result!.perfect
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
                      maxColumns: level.maxColumns,
                      cubes: round.phase == MemoryPhase.study || peeking
                          ? List<int?>.of(round.target)
                          : List<int?>.of(round.placed),
                      cursor: round.phase == MemoryPhase.recall && !peeking
                          ? round.cursor
                          : null,
                      answer: round.phase == MemoryPhase.result
                          ? round.target
                          : null,
                      onTapCube: round.phase == MemoryPhase.recall && !peeking
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
                round.level.maxColumns == 1
                    ? 'Read the tower from the bottom up. '
                          'Start early for bonus points.'
                    : 'Bottom to top, left tower first. '
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

  Widget _recallControls(MemoryRound round, double buttonHeight) {
    final busy = round.peeking || _adShowing;
    final offerPeek =
        !round.peekUsed &&
        (AppScope.of(context).ads.isReady.value || _adShowing);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: _Palette(
            colors: round.level.colors,
            onPick: busy ? null : _place,
          ),
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
                onPressed: round.canUndo && !busy ? round.undo : null,
              ),
            ),
            if (offerPeek) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _ActionButton(
                  'Peek',
                  key: const ValueKey('memory-peek'),
                  height: buttonHeight,
                  outline: true,
                  adBadge: true,
                  onPressed: busy ? null : _peek,
                ),
              ),
            ],
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _ActionButton(
                round.complete
                    ? 'Check'
                    : '${round.filled} of ${round.level.cubes}',
                key: const ValueKey('memory-check'),
                height: buttonHeight,
                onPressed: round.complete && !busy ? _check : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resultControls(MemoryResult result, double buttonHeight) {
    final number = result.level.number;
    final last = number >= memoryLevels.length;
    final need = rightNeeded(result.total, passPercent);
    final offerRetry =
        !result.passed &&
        (AppScope.of(context).ads.isReady.value || _adShowing);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              if (!offerRetry) ...[
                StarRow(stars: result.stars, size: 22),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  result.passed
                      ? result.perfect
                            ? result.stars == 3
                                  ? 'Every cube right.'
                                  : 'Every cube right. Ad help caps it at '
                                        '$adHelpStars stars.'
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
              if (offerRetry) ...[
                const SizedBox(width: 10),
                _ActionButton(
                  'Same tower',
                  key: const ValueKey('memory-retry-ad'),
                  height: 44,
                  outline: true,
                  adBadge: true,
                  fontSize: 15,
                  onPressed: _adShowing ? null : _retrySameTower,
                ),
              ],
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
                onPressed: _adShowing
                    ? null
                    : result.passed
                    ? () => _begin(number)
                    : _toLevels,
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
                onPressed: _adShowing
                    ? null
                    : !result.passed
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

  /// Null while picking is paused (a peek or an ad); the cubes fade.
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPick == null ? 0.35 : 1,
    child: Row(
      children: [
        for (var i = 0; i < colors; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              enabled: onPick != null,
              label: cubeColorNames[i],
              excludeSemantics: true,
              child: GestureDetector(
                key: ValueKey('palette-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: onPick == null ? null : () => onPick!(i),
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
    ),
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
    this.adBadge = false,
    this.fontSize = 18,
  });

  final String text;
  final double height;
  final VoidCallback? onPressed;
  final bool outline;

  /// Marks a button that plays a rewarded ad.
  final bool adBadge;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: adBadge ? '$text, watch an ad' : text,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    maxLines: 1,
                    style: nunito(
                      fontSize,
                      weight: 900,
                      color: outline ? AppColors.green : AppColors.onGreen,
                    ),
                  ),
                  if (adBadge) ...[const SizedBox(width: 6), const AdBadge()],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
