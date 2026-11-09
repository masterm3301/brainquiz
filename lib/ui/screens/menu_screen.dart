import 'package:flutter/material.dart';

import '../../game/block.dart';
import '../../game/levels.dart';
import '../../game/stability.dart';
import '../../memory/memory_levels.dart';
import '../../progress/progress.dart';
import '../../progress/progress_controller.dart';
import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/cube_tower.dart';
import '../widgets/tower_view.dart';
import 'attempt_flow.dart';
import 'how_to_play.dart';
import 'levels_screen.dart';
import 'memory_game_screen.dart';
import 'memory_levels_screen.dart';

const _decorTower = [
  PlacedBlock(
    Block(
      color: BlockColor.cyan,
      shape: BlockShape.rectangle,
      width: 0.74,
      height: 26,
    ),
    0,
  ),
  PlacedBlock(
    Block(
      color: BlockColor.green,
      shape: BlockShape.triangle,
      width: 0.82,
      height: 40,
    ),
    0,
  ),
  PlacedBlock(
    Block(
      color: BlockColor.yellow,
      shape: BlockShape.rectangle,
      width: 0.7,
      height: 44,
    ),
    0,
  ),
  PlacedBlock(
    Block(
      color: BlockColor.cyan,
      shape: BlockShape.square,
      width: 0.3,
      height: 30,
    ),
    0,
  ),
];

/// Cubes for the Memory Towers card, bottom to top, like a real stack.
const _decorCubes = <int?>[3, 2, 1, 3, 2, 1, 0, 0];

/// Home: pick a game. Each card resumes its own ladder in one tap.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final ads = scope.ads;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            scope.progress,
            scope.memoryProgress,
            ads.privacyOptionsRequired,
          ]),
          builder: (context, _) {
            final showPrivacy = ads.privacyOptionsRequired.value;
            final total =
                scope.progress.progress.totalPoints +
                scope.memoryProgress.progress.totalPoints;
            return LayoutBuilder(
              builder: (context, c) {
                final compact = c.maxHeight < 700;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, compact ? 10 : 16, 20, 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight - 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('TOTAL POINTS', style: label(size: 11)),
                                Text(
                                  formatPoints(total),
                                  style:
                                      nunito(
                                        16,
                                        weight: 900,
                                        color: AppColors.green,
                                      ).copyWith(
                                        shadows: [
                                          Shadow(
                                            color: AppColors.green.withValues(
                                              alpha: 0.7,
                                            ),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(height: compact ? 8 : 16),
                            Text(
                              'Tower Build',
                              style: nunito(compact ? 32 : 38, weight: 900),
                            ),
                            if (!compact)
                              Text(
                                'Two games. One memory.',
                                style: nunito(
                                  15,
                                  weight: 700,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            SizedBox(height: compact ? 12 : 20),
                            _ModeCard(
                              modeKey: 'memory',
                              tag: 'Memory · ${memoryLevels.length} levels',
                              title: 'Memory Towers',
                              blurb:
                                  'Remember the colour of every cube, '
                                  'then rebuild the tower.',
                              accent: AppColors.green,
                              controller: scope.memoryProgress,
                              art: const _MemoryArt(),
                              play: (n) => MemoryGameScreen(levelNumber: n),
                              levels: const MemoryLevelsScreen(),
                            ),
                            SizedBox(height: compact ? 10 : 14),
                            _ModeCard(
                              modeKey: 'wind',
                              tag: 'Wind · ${levels.length} levels',
                              title: 'Wind Levels',
                              blurb:
                                  'Rebuild odd-shaped blocks, then hold '
                                  'the tower through the wind.',
                              accent: AppColors.cyan,
                              controller: scope.progress,
                              art: const _WindArt(),
                              play: (n) => AttemptFlow(levelNumber: n),
                              levels: const LevelsScreen(),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PlainEntry(
                                'How to play',
                                onTap: () => showHowToPlay(context),
                              ),
                              if (showPrivacy) ...[
                                Text('·', style: label(size: 15)),
                                _PlainEntry(
                                  'Privacy options',
                                  onTap: ads.showPrivacyOptions,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// One game mode: art, name, progress, and Play/Continue plus Levels.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.modeKey,
    required this.tag,
    required this.title,
    required this.blurb,
    required this.accent,
    required this.controller,
    required this.art,
    required this.play,
    required this.levels,
  });

  final String modeKey;
  final String tag, title, blurb;
  final Color accent;
  final ProgressController controller;
  final Widget art;
  final Widget Function(int level) play;
  final Widget levels;

  @override
  Widget build(BuildContext context) {
    final progress = controller.progress;
    final next = progress.nextLevel;
    final playLabel = !progress.hasPlayed
        ? 'Play'
        : progress.allCleared
        ? 'Replay level $next'
        : 'Continue level $next';
    final cleared = progress.records.length;
    final status = !progress.hasPlayed
        ? 'Not started'
        : progress.allCleared
        ? 'All ${progress.lastLevel} cleared'
        : '$cleared of ${progress.lastLevel} cleared';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 74, height: 96, child: art),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag.toUpperCase(),
                      style: label(size: 11, color: accent),
                    ),
                    const SizedBox(height: 3),
                    Text(title, style: nunito(22, weight: 900)),
                    const SizedBox(height: 3),
                    Text(
                      blurb,
                      style: nunito(
                        13,
                        weight: 700,
                        color: AppColors.textTertiary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status,
                      key: ValueKey('$modeKey-status'),
                      style: nunito(
                        13,
                        weight: 900,
                        color: progress.hasPlayed
                            ? AppColors.textSecondary
                            : AppColors.label,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _CardButton(
                  playLabel,
                  key: ValueKey('$modeKey-play'),
                  color: accent,
                  filled: true,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => play(next))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _CardButton(
                  'Levels',
                  key: ValueKey('$modeKey-levels'),
                  color: accent,
                  filled: false,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => levels)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton(
    this.text, {
    super.key,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  final String text;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: text,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : null,
          border: filled ? null : Border.all(color: color, width: 2),
          boxShadow: filled
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 24)]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            style: nunito(
              16,
              weight: 900,
              color: filled ? AppColors.background : color,
            ),
          ),
        ),
      ),
    ),
  );
}

/// A small dark stage with a green glow, for the card art.
class _Stage extends StatelessWidget {
  const _Stage({required this.child, required this.glow});

  final Widget child;
  final Color glow;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, 0.8),
        radius: 1.2,
        colors: [glow, AppColors.background],
        stops: const [0, 0.8],
      ),
      border: Border.all(color: AppColors.rule),
    ),
    child: ClipRect(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
        child: child,
      ),
    ),
  );
}

class _MemoryArt extends StatelessWidget {
  const _MemoryArt();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: _Stage(
      glow: AppColors.arenaNormal,
      child: CubeTower(cubes: _decorCubes),
    ),
  );
}

class _WindArt extends StatelessWidget {
  const _WindArt();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: _Stage(
      glow: AppColors.arenaNormal,
      child: TowerView(placed: _decorTower),
    ),
  );
}

/// A quiet text link under the game cards.
class _PlainEntry extends StatelessWidget {
  const _PlainEntry(this.text, {required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Flexible(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: nunito(15, weight: 800, color: AppColors.textTertiary),
        ),
      ),
    ),
  );
}
