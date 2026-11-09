import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../progress/progress.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';

/// One row of a levels ladder: number, a detail line, and stars and best
/// points once cleared. The current level glows green; locked rows are
/// dimmed and ignore taps.
class LevelRow extends StatelessWidget {
  const LevelRow({
    super.key,
    required this.number,
    required this.detail,
    required this.record,
    required this.unlocked,
    required this.current,
    required this.last,
    required this.onTap,
  });

  final int number;
  final String detail;
  final LevelRecord? record;
  final bool unlocked;
  final bool current;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        nunito(
          18,
          weight: 900,
          color: current
              ? AppColors.green
              : unlocked
              ? AppColors.text
              : AppColors.label,
        ).copyWith(
          shadows: current
              ? [
                  Shadow(
                    color: AppColors.green.withValues(alpha: 0.7),
                    blurRadius: 14,
                  ),
                ]
              : null,
        );
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
                Text('Level $number', style: titleStyle),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: nunito(
                    13,
                    weight: 700,
                    color: unlocked ? AppColors.textTertiary : AppColors.label,
                  ),
                ),
              ],
            ),
          ),
          if (rec != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StarRow(stars: rec.stars),
                const SizedBox(height: 2),
                Text(
                  formatPoints(rec.bestPoints),
                  style: nunito(13, weight: 900, color: AppColors.green),
                ),
              ],
            )
          else if (current)
            Text('PLAY ›', style: label(size: 12, color: AppColors.green)),
        ],
      ),
    );
    if (!unlocked) return Opacity(opacity: 0.5, child: row);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}

/// Three stars, [stars] of them lit.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 16});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars of 3 stars',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(left: size / 8),
            child: CustomPaint(
              size: Size(size, size),
              painter: _StarPainter(
                i < stars ? AppColors.yellow : AppColors.trayBorder,
              ),
            ),
          ),
      ],
    ),
  );
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
