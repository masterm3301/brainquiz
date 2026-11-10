import 'package:flutter/material.dart';

import '../../game/levels.dart';
import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/level_row.dart';
import '../widgets/neon_button.dart';
import 'attempt_flow.dart';

/// Small "back" control in the sheet's caption style.
class BackLabel extends StatelessWidget {
  const BackLabel({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Back',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.maybePop(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('‹ BACK', style: label(size: 12)),
          ),
        ),
      );
}

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).progress;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final progress = controller.progress;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const Align(
                    alignment: Alignment.centerLeft, child: BackLabel()),
                const SizedBox(height: 4),
                Text('Wind Levels', style: nunito(28, weight: 900)),
                const SizedBox(height: 6),
                Text(
                  'Twelve levels. Rebuild the tower, then hold it through '
                  'the wind.',
                  style: nunito(14,
                      weight: 700, color: AppColors.textTertiary, height: 1.4),
                ),
                const SizedBox(height: 16),
                Text(
                  progressStatus(progress),
                  key: const ValueKey('wind-status'),
                  style: nunito(13,
                      weight: 900,
                      color: progress.hasPlayed
                          ? AppColors.textSecondary
                          : AppColors.label),
                ),
                const SizedBox(height: 10),
                NeonButton.primary(
                  playLabel(progress),
                  key: const ValueKey('wind-play'),
                  color: AppColors.cyan,
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => AttemptFlow(
                              levelNumber: progress.nextLevel))),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    border: Border.all(color: AppColors.rule),
                  ),
                  child: Column(
                    children: [
                      for (final level in levels)
                        LevelRow(
                          number: level.number,
                          detail: '${level.blocks} blocks · '
                              '${level.holdSeconds}s of wind',
                          record: progress.records[level.number],
                          unlocked: progress.isUnlocked(level.number),
                          current: level.number == progress.nextLevel &&
                              !progress.records.containsKey(level.number),
                          last: level.number == levels.length,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => AttemptFlow(
                                      levelNumber: level.number))),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
