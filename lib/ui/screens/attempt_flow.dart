import 'package:flutter/material.dart';

import '../../game/attempt.dart';
import '../../game/hold_simulation.dart';
import '../../game/levels.dart';
import '../app_scope.dart';
import '../theme/tokens.dart';
import 'build_view.dart';
import 'fell_view.dart';
import 'hold_view.dart';
import 'levels_screen.dart';
import 'memorise_view.dart';
import 'stood_view.dart';
import 'wind_ready_view.dart';

/// One try at one level: holds the [Attempt] and shows the view for its
/// phase. Going back leaves without recording anything. A stood result is
/// recorded exactly once.
class AttemptFlow extends StatefulWidget {
  const AttemptFlow({super.key, required this.levelNumber});

  final int levelNumber;

  @override
  State<AttemptFlow> createState() => _AttemptFlowState();
}

class _AttemptFlowState extends State<AttemptFlow> {
  Attempt? _attempt;
  late int _levelNumber = widget.levelNumber;

  // Per attempt; cleared by [_begin].
  HoldSimulation? _sim;
  AttemptResult? _result;
  int _direction = 1;

  /// Decided once, when the lock happens: is an ad ready to offer?
  bool? _offerAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attempt ??= Attempt(
      level: levels[_levelNumber - 1],
      seed: AppScope.of(context).newSeed(),
    );
  }

  @override
  void dispose() {
    _attempt?.dispose();
    super.dispose();
  }

  /// Starts a fresh attempt. The old one is disposed after the frame, once
  /// nothing listens to it any more; its hold view and ticker go with it.
  void _begin(int levelNumber) {
    final old = _attempt!;
    final previous = levelNumber == _levelNumber ? old.tower.blocks : null;
    final next = Attempt(
      level: levels[levelNumber - 1],
      seed: AppScope.of(context).newSeed(),
      previous: previous,
    );
    setState(() {
      _levelNumber = levelNumber;
      _attempt = next;
      _sim = null;
      _result = null;
      _offerAd = null;
      _direction = 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _startHold() {
    final attempt = _attempt!;
    if (_sim != null || attempt.phase != AttemptPhase.windReady) return;
    setState(() => _sim = attempt.startHold());
  }

  void _onHoldEnded(int direction) {
    final attempt = _attempt!;
    if (_result != null) return;
    final result = attempt.finish(_sim!);
    _direction = direction;
    _result = result;
    if (result.stood) AppScope.of(context).progress.record(result);
    setState(() {});
  }

  void _backToLevels() {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const LevelsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt!;
    return ListenableBuilder(
      listenable: attempt,
      builder: (context, _) => switch (attempt.phase) {
        AttemptPhase.memorise => MemoriseView(
          key: ValueKey(attempt),
          attempt: attempt,
          totalPoints: AppScope.of(context).progress.progress.totalPoints,
        ),
        AttemptPhase.build => BuildView(key: ValueKey(attempt), attempt: attempt),
        AttemptPhase.windReady => _windReady(attempt),
        AttemptPhase.hold => HoldView(
          key: ValueKey(attempt),
          attempt: attempt,
          sim: _sim!,
          onEnded: _onHoldEnded,
        ),
        AttemptPhase.result => _resultView(attempt),
      },
    );
  }

  Widget _windReady(Attempt attempt) {
    _offerAd ??= AppScope.of(context).ads.isReady.value;
    if (_offerAd!) {
      return WindReadyView(
        key: ValueKey(attempt),
        attempt: attempt,
        onStart: _startHold,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(attempt, _attempt)) _startHold();
    });
    return const Scaffold(backgroundColor: AppColors.background);
  }

  Widget _resultView(Attempt attempt) {
    final result = _result;
    if (result == null) {
      return const Scaffold(backgroundColor: AppColors.background);
    }
    if (result.stood) {
      return StoodView(
        key: ValueKey(attempt),
        attempt: attempt,
        result: result,
        onNextLevel: () => _begin(result.level.number + 1),
        onBackToLevels: _backToLevels,
      );
    }
    return FellView(
      key: ValueKey(attempt),
      attempt: attempt,
      result: result,
      direction: _direction,
      onBuildAgain: () => _begin(result.level.number),
    );
  }
}
