import 'package:flutter/material.dart';

import '../../memory/memory_levels.dart';
import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/level_row.dart';
import 'levels_screen.dart' show BackLabel;
import 'memory_game_screen.dart';


class MemoryLevelsScreen extends StatelessWidget {
  const MemoryLevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).memoryProgress;
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
                  alignment: Alignment.centerLeft,
                  child: BackLabel(),
                ),
                const SizedBox(height: 4),
                Text('Memory Towers', style: nunito(28, weight: 900)),
                const SizedBox(height: 6),
                Text(
                  '${memoryLevels.length} levels. More cubes and more colours '
                  'each time. No wind, just memory.',
                  style: nunito(
                    14,
                    weight: 700,
                    color: AppColors.textTertiary,
                    height: 1.4,
                  ),
                ),
                for (final (name, step, first, last) in memoryStageTable) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text(name.toUpperCase(), style: label(size: 12)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.toUpperCase(),
                          textAlign: TextAlign.right,
                          style: label(size: 11, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      border: Border.all(color: AppColors.rule),
                    ),
                    child: Column(
                      children: [
                        for (final level in memoryLevels.sublist(
                          first - 1,
                          last,
                        ))
                          LevelRow(
                            number: level.number,
                            detail:
                                '${level.cubes} cubes · '
                                '${level.colors} colours · '
                                '${level.studySeconds}s',
                            record: progress.records[level.number],
                            unlocked: progress.isUnlocked(level.number),
                            current:
                                level.number == progress.nextLevel &&
                                !progress.records.containsKey(level.number),
                            last: level.number == last,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    MemoryGameScreen(levelNumber: level.number),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
