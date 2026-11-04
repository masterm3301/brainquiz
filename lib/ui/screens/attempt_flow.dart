import 'package:flutter/material.dart';

import '../../game/attempt.dart';
import '../../game/levels.dart';
import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import 'build_view.dart';
import 'levels_screen.dart';
import 'memorise_view.dart';

/// One try at one level: holds the [Attempt] and shows the view for its
/// phase. Going back leaves without recording anything.
class AttemptFlow extends StatefulWidget {
  const AttemptFlow({super.key, required this.levelNumber});

  final int levelNumber;

  @override
  State<AttemptFlow> createState() => _AttemptFlowState();
}

class _AttemptFlowState extends State<AttemptFlow> {
  Attempt? _attempt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attempt ??= Attempt(
      level: levels[widget.levelNumber - 1],
      seed: AppScope.of(context).newSeed(),
    );
  }

  @override
  void dispose() {
    _attempt?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt!;
    return ListenableBuilder(
      listenable: attempt,
      builder: (context, _) => switch (attempt.phase) {
        AttemptPhase.memorise => MemoriseView(
          key: const ValueKey('memorise'),
          attempt: attempt,
          totalPoints: AppScope.of(context).progress.progress.totalPoints,
        ),
        AttemptPhase.build => BuildView(
          key: const ValueKey('build'),
          attempt: attempt,
        ),
        _ => _PhasePlaceholder(phase: attempt.phase),
      },
    );
  }
}

/// Stands in for the wind and result screens until they land.
class _PhasePlaceholder extends StatelessWidget {
  const _PhasePlaceholder({required this.phase});

  final AttemptPhase phase;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLabel(),
            const SizedBox(height: 16),
            Text(phase.name, style: nunito(28, weight: 900)),
          ],
        ),
      ),
    ),
  );
}
