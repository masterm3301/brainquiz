import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

import '../../game/attempt.dart';
import '../../game/stability.dart';
import '../../game/study_clock.dart';
import '../../progress/progress.dart' show formatPoints;
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/arena.dart';
import '../widgets/panel.dart';
import '../widgets/tower_view.dart';
import 'levels_screen.dart' show BackLabel;

/// Screen 01: the tower is on show until the study clock runs out.
class MemoriseView extends StatefulWidget {
  const MemoriseView({
    super.key,
    required this.attempt,
    required this.totalPoints,
  });

  final Attempt attempt;
  final int totalPoints;

  @override
  State<MemoriseView> createState() => _MemoriseViewState();
}

class _MemoriseViewState extends State<MemoriseView>
    with SingleTickerProviderStateMixin {
  late final StudyClockTicker _clock;

  @override
  void initState() {
    super.initState();
    _clock = StudyClockTicker(
      this,
      seconds: widget.attempt.level.studySeconds,
      onTick: () => setState(() {}),
      onDone: widget.attempt.finishStudy,
    )..start();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.attempt.level;
    final clock = _clock.clock;
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            compact ? 12 : 24,
            24,
            compact ? 12 : 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const BackLabel(),
                  const SizedBox(width: 14),
                  Text('Level ${level.number} of 12', style: label(size: 13)),
                  const Spacer(),
                  Text(
                    formatPoints(widget.totalPoints),
                    style: nunito(15, weight: 900, color: AppColors.green)
                        .copyWith(
                          shadows: [
                            Shadow(
                              color: AppColors.green.withValues(alpha: 0.8),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 12 : 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Memorise the tower',
                      style: nunito(28, weight: 900, letterSpacing: -0.4),
                    ),
                  ),
                  Text(
                    '${clock.secondsLeft}',
                    style: nunito(30, weight: 900, color: AppColors.green)
                        .copyWith(
                          shadows: [
                            Shadow(
                              color: AppColors.green.withValues(alpha: 0.9),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 5,
                color: AppColors.rule,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clock.fractionLeft,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.9),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 12 : 24),
              Expanded(
                child: Arena(
                  child: TowerView(
                    placed: [
                      for (final b in widget.attempt.tower.blocks)
                        PlacedBlock(b, 0),
                    ],
                  ),
                ),
              ),
              SizedBox(height: compact ? 12 : 22),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Two things to remember'.toUpperCase(),
                      style: label(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The order of the blocks, and that heavy wide pieces '
                      'belong near the bottom.',
                      style: nunito(
                        16,
                        weight: 700,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feeds a [StudyClock] from a [Ticker], one frame delta at a time.
class StudyClockTicker {
  StudyClockTicker(
    TickerProvider vsync, {
    required int seconds,
    required this.onTick,
    required this.onDone,
  }) : clock = StudyClock(seconds) {
    _ticker = vsync.createTicker(_tick);
  }

  final StudyClock clock;
  final VoidCallback onTick;
  final VoidCallback onDone;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  void start() => _ticker.start();

  void _tick(Duration elapsed) {
    clock.step((elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    if (clock.done) {
      _ticker.stop();
      onDone();
    } else {
      onTick();
    }
  }

  void dispose() => _ticker.dispose();
}
