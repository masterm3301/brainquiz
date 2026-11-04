import 'package:flutter/material.dart';

import '../../game/block.dart';
import '../../game/stability.dart';
import '../../progress/progress.dart';
import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/arena.dart';
import '../widgets/neon_button.dart';
import '../widgets/tower_view.dart';
import 'attempt_flow.dart';
import 'how_to_play.dart';
import 'levels_screen.dart';

const _decorTower = [
  PlacedBlock(
      Block(color: BlockColor.cyan, shape: BlockShape.rectangle, width: 0.74, height: 26),
      0),
  PlacedBlock(
      Block(color: BlockColor.green, shape: BlockShape.triangle, width: 0.82, height: 40),
      0),
  PlacedBlock(
      Block(color: BlockColor.yellow, shape: BlockShape.rectangle, width: 0.7, height: 44),
      0),
  PlacedBlock(
      Block(color: BlockColor.cyan, shape: BlockShape.square, width: 0.3, height: 30),
      0),
  PlacedBlock(
      Block(color: BlockColor.green, shape: BlockShape.rectangle, width: 0.5, height: 30),
      0),
];

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

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
            final next = progress.nextLevel;
            final buttonLabel = !progress.hasPlayed
                ? 'Play'
                : progress.allCleared
                    ? 'Replay level $next'
                    : 'Continue level $next';
            return LayoutBuilder(builder: (context, c) {
              final arenaHeight = (c.maxHeight - 340).clamp(160.0, 520.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL POINTS', style: label(size: 11)),
                              Text(formatPoints(progress.totalPoints),
                                  style: nunito(16,
                                          weight: 900, color: AppColors.green)
                                      .copyWith(shadows: [
                                    Shadow(
                                        color: AppColors.green
                                            .withValues(alpha: 0.7),
                                        blurRadius: 12)
                                  ])),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text('Tower Build', style: nunito(40, weight: 900)),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: arenaHeight,
                            child: const Arena(
                              child: TowerView(placed: _decorTower),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          NeonButton.primary(
                            buttonLabel,
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) =>
                                        AttemptFlow(levelNumber: next))),
                          ),
                          const SizedBox(height: 10),
                          NeonButton.outline(
                            'Levels',
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const LevelsScreen())),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => showHowToPlay(context),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('How to play',
                                    style: nunito(15,
                                        weight: 800,
                                        color: AppColors.textTertiary)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}
