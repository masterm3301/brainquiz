import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/levels.dart';
import '../../progress/progress.dart';
import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
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
                Text('Twelve levels', style: nunito(28, weight: 900)),
                const SizedBox(height: 6),
                Text(
                  'Taller towers, less time to study, stronger wind.',
                  style: nunito(14,
                      weight: 700, color: AppColors.textTertiary, height: 1.4),
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
                        _LevelRow(
                          level: level,
                          record: progress.records[level.number],
                          unlocked: progress.isUnlocked(level.number),
                          current: level.number == progress.nextLevel &&
                              !progress.records.containsKey(level.number),
                          last: level.number == levels.length,
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

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.record,
    required this.unlocked,
    required this.current,
    required this.last,
  });

  final LevelConfig level;
  final LevelRecord? record;
  final bool unlocked;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final titleStyle = nunito(18,
            weight: 900,
            color: current
                ? AppColors.green
                : unlocked
                    ? AppColors.text
                    : AppColors.label)
        .copyWith(
            shadows: current
                ? [
                    Shadow(
                        color: AppColors.green.withValues(alpha: 0.7),
                        blurRadius: 14)
                  ]
                : null);
    final rec = record;
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.rule)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Level ${level.number}', style: titleStyle),
                const SizedBox(height: 2),
                Text('${level.blocks} blocks',
                    style: nunito(13,
                        weight: 700,
                        color: unlocked
                            ? AppColors.textTertiary
                            : AppColors.label)),
              ],
            ),
          ),
          if (rec != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Semantics(
                  label: '${rec.stars} of 3 stars',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: CustomPaint(
                            size: const Size(16, 16),
                            painter: _StarPainter(i < rec.stars
                                ? AppColors.yellow
                                : AppColors.trayBorder),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(formatPoints(rec.bestPoints),
                    style: nunito(13, weight: 900, color: AppColors.green)),
              ],
            ),
        ],
      ),
    );
    if (!unlocked) return Opacity(opacity: 0.5, child: row);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => AttemptFlow(levelNumber: level.number))),
      child: row,
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * radius;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
