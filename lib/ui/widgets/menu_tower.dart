import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/levels.dart';
import '../../memory/memory_levels.dart';
import '../../progress/progress.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';

/// A level tapped on a home tower.
typedef OpenLevel = void Function(int number);

const _gap = 3.0;

/// Room under the bottom block: the 3px floor and its 7px margin.
const _floorSpace = 10.0;

/// The "+N" count above the tower: 11px text and its margin.
const _countSpace = 21.0;

/// One block on a home tower, in tower coordinates (y grows down).
class _Placed {
  _Placed(this.number, this.rect, this.kind);

  final int number;
  final Rect rect;
  final _Kind kind;
}

enum _Kind { cleared, current, locked, more }

/// What the tower shows of a ladder: cleared levels up to the current one,
/// then a few locked ones, fitted to the height there is.
class _Ladder {
  _Ladder(this.progress);

  final Progress progress;

  int? get current => progress.allCleared ? null : progress.nextLevel;
  int get clearedTop => current == null ? progress.lastLevel : current! - 1;
  int get lockedCount => current == null ? 0 : progress.lastLevel - current!;
}

/// Lays blocks out from the floor up. [heightOf] gives each level's block
/// height. Returns the placed blocks and how many locked levels are hidden.
(List<_Placed>, int) _stack({
  required _Ladder ladder,
  required double height,
  required double Function(int number) heightOf,
  required double Function(int number) widthOf,
  required double centerX,
  required int maxLocked,
  required double currentMargin,
}) {
  final current = ladder.current;
  final cleared = ladder.clearedTop;

  double need(int shownCleared, int shownLocked, bool more) {
    var h = _floorSpace;
    if (more) h += 44 + _gap;
    for (var n = cleared - shownCleared + 1; n <= cleared; n++) {
      h += heightOf(n) + _gap;
    }
    if (current != null) h += heightOf(current) + _gap + currentMargin;
    for (var n = 1; n <= shownLocked; n++) {
      h += heightOf(current! + n) + _gap;
    }
    if (ladder.lockedCount > shownLocked) h += _countSpace;
    return h;
  }

  // Drop the higher locked blocks first (keeping one), then the lowest
  // cleared ones, which fold into a "+N" block on the floor.
  var locked = math.min(maxLocked, ladder.lockedCount);
  var shown = cleared;
  while (need(shown, locked, shown < cleared) > height) {
    if (locked > 1) {
      locked--;
    } else if (shown > 0) {
      shown--;
    } else if (locked > 0) {
      locked--;
    } else {
      break;
    }
  }
  final more = shown < cleared;

  final placed = <_Placed>[];
  var bottom = height - _floorSpace;
  Rect take(int n) {
    final h = heightOf(n);
    final w = widthOf(n);
    final r = Rect.fromLTWH(centerX - w / 2, bottom - h, w, h);
    bottom -= h + _gap;
    return r;
  }

  if (more) {
    final r = Rect.fromLTWH(centerX - 22, bottom - 44, 44, 44);
    bottom -= 44 + _gap;
    placed.add(_Placed(cleared - shown, r, _Kind.more));
  }
  for (var n = cleared - shown + 1; n <= cleared; n++) {
    placed.add(_Placed(n, take(n), _Kind.cleared));
  }
  if (current != null) {
    bottom -= currentMargin;
    placed.add(_Placed(current, take(current), _Kind.current));
    for (var n = 1; n <= locked; n++) {
      placed.add(_Placed(current + n, take(current + n), _Kind.locked));
    }
  }
  return (placed, ladder.lockedCount - locked);
}

double _textScale(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) / 14;

/// The Tower build tower: one cube per level, the next one hovering above
/// the stack with its card, and the title in the bottom corner.
class MemoryMenuTower extends StatelessWidget {
  const MemoryMenuTower({
    super.key,
    required this.progress,
    required this.accent,
    required this.compact,
    required this.onPlay,
    required this.onAllLevels,
  });

  final Progress progress;
  final Color accent;
  final bool compact;
  final OpenLevel onPlay;
  final VoidCallback onAllLevels;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scale = _textScale(context);
      final ladder = _Ladder(progress);
      final (placed, hidden) = _stack(
        ladder: ladder,
        height: c.maxHeight,
        heightOf: (_) => 44,
        widthOf: (_) => 44,
        centerX: 46,
        maxLocked: 3,
        currentMargin: 8,
      );
      final titleSize = compact ? 30.0 : 36.0;
      final titleHeight = (titleSize * 1.05 * 2 + 10 + 14 * 1.4 * 2) * scale;
      final titleTop = c.maxHeight - 26 - titleHeight;
      final anchor = placed.lastWhere(
        (p) => p.kind == _Kind.current,
        orElse: () => placed.lastWhere(
          (p) => p.kind == _Kind.cleared,
          orElse: () => placed.last,
        ),
      );
      final cardHeight = 94 * scale;
      final cardTop = _clampCard(
        anchor.rect.center.dy - cardHeight / 2,
        cardHeight,
        lowest: titleTop - 12,
      );
      final level = memoryLevels[anchor.number - 1];
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 120,
            right: 0,
            bottom: 26,
            child: _Title(
              ['Memory', 'Towers'],
              'Remember every cube. Rebuild the tower.',
              size: titleSize,
              maxWidth: 190,
            ),
          ),
          _floor(accent),
          if (hidden > 0) _count(hidden, placed, width: 44, left: 24),
          Positioned.fill(
            child: CustomPaint(
              painter: _ConnectorPainter(
                from: Offset(anchor.rect.right, anchor.rect.center.dy),
                to: Offset(84, cardTop + cardHeight / 2),
                color: accent,
              ),
            ),
          ),
          for (final p in placed)
            Positioned.fromRect(rect: p.rect, child: _cube(p, placed)),
          Positioned(
            left: 84,
            right: 0,
            top: cardTop,
            height: cardHeight,
            child: _NextCard(
              key: const ValueKey('memory-card'),
              accent: accent,
              heading: ladder.current == null
                  ? 'All ${progress.lastLevel} cleared'
                  : 'Next up · ${memoryStageName(level.number)}',
              title: 'Level ${level.number}',
              detail: Text(
                '${level.cubes} cubes · ${level.colors} colours',
                style: manrope(13, weight: 600, color: MenuColors.muted),
              ),
              onTap: onAllLevels,
            ),
          ),
        ],
      );
    },
  );

  Widget _cube(_Placed p, List<_Placed> all) {
    switch (p.kind) {
      case _Kind.more:
        return _MoreBlock(count: p.number, onTap: onAllLevels);
      case _Kind.locked:
        final k =
            p.number - all.firstWhere((q) => q.kind == _Kind.locked).number;
        return ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: MenuColors.white(const [0.24, 0.16, 0.1][k.clamp(0, 2)]),
                width: 1.5,
              ),
            ),
          ),
        );
      case _Kind.current:
      case _Kind.cleared:
        final current = p.kind == _Kind.current;
        final color = current ? accent : MenuColors.level(p.number);
        return _Tappable(
          key: ValueKey('memory-cube-${p.number}'),
          label: 'Level ${p.number}, ${current ? 'next up' : 'cleared'}',
          onTap: () => onPlay(p.number),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Solid even when current: Flutter paints a glow under the box.
              color: current ? AppColors.background : color,
              borderRadius: BorderRadius.circular(6),
              border: current ? Border.all(color: accent, width: 2) : null,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 20),
              ],
            ),
            child: _Number(p.number, size: current ? 14 : 13),
          ),
        );
    }
  }
}

/// The Wind tower: one odd-shaped block per level, swaying more the higher
/// it goes, with gusts blowing through and the title at the top.
class WindMenuTower extends StatelessWidget {
  const WindMenuTower({
    super.key,
    required this.progress,
    required this.accent,
    required this.compact,
    required this.onPlay,
    required this.onAllLevels,
  });

  final Progress progress;
  final Color accent;
  final bool compact;
  final OpenLevel onPlay;
  final VoidCallback onAllLevels;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scale = _textScale(context);
      final ladder = _Ladder(progress);
      final titleSize = compact ? 30.0 : 36.0;
      final titleBottom =
          8 + (titleSize * 1.05 * 2 + 10 + 14 * 1.4 * 2) * scale;
      final (placed, hidden) = _stack(
        ladder: ladder,
        height: c.maxHeight,
        heightOf: (n) => _windShape(n).size.height,
        widthOf: (n) => _windShape(n).size.width,
        centerX: 56,
        maxLocked: 5,
        currentMargin: 10,
      );
      final anchor = placed.lastWhere(
        (p) => p.kind == _Kind.current,
        orElse: () => placed.lastWhere(
          (p) => p.kind == _Kind.cleared,
          orElse: () => placed.last,
        ),
      );
      final cardHeight = 100 * scale;
      final cardTop = _clampCard(
        anchor.rect.center.dy - cardHeight / 2,
        cardHeight,
        highest: titleBottom + 12,
        lowest: c.maxHeight - _floorSpace,
      );
      final level = levels[anchor.number - 1];
      final (bars, wind) = windTier(level);
      final firstLocked = placed
          .where((p) => p.kind == _Kind.locked)
          .map((p) => p.number)
          .fold<int?>(null, (a, b) => a ?? b);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Gusts start under the title, and stop above the floor.
          Positioned(
            left: 0,
            top: titleBottom + 26,
            width: 350,
            height: (c.maxHeight - titleBottom - 46).clamp(0.0, 170.0),
            child: ClipRect(
              child: Opacity(
                opacity: 0.45,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxHeight: 170,
                  child: CustomPaint(
                    size: const Size(350, 170),
                    painter: _GustPainter(accent),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 128,
            right: 0,
            top: 8,
            child: _Title(
              ['Wind', 'Levels'],
              'Rebuild it from memory. Then let the wind test it.',
              size: titleSize,
              maxWidth: 200,
            ),
          ),
          _floor(accent),
          if (hidden > 0) _count(hidden, placed, width: 112, left: 0),
          Positioned.fill(
            child: CustomPaint(
              painter: _ConnectorPainter(
                from: Offset(anchor.rect.right + 4, anchor.rect.center.dy),
                to: Offset(128, cardTop + cardHeight / 2),
                color: accent,
              ),
            ),
          ),
          for (final p in placed)
            Positioned.fromRect(rect: p.rect, child: _block(p, firstLocked)),
          Positioned(
            left: 128,
            right: 0,
            top: cardTop,
            height: cardHeight,
            child: _NextCard(
              key: const ValueKey('wind-card'),
              accent: accent,
              heading: ladder.current == null
                  ? 'All ${progress.lastLevel} cleared'
                  : 'Next up · ${level.number} of ${progress.lastLevel}',
              title: 'Level ${level.number}',
              detail: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${level.blocks} blocks',
                      style: manrope(13, weight: 600, color: MenuColors.muted),
                    ),
                    Text(
                      '  ·  ',
                      style: manrope(13, weight: 600, color: MenuColors.muted),
                    ),
                    _WindBars(bars, accent),
                    const SizedBox(width: 8),
                    Text(
                      wind,
                      style: manrope(13, weight: 600, color: MenuColors.muted),
                    ),
                  ],
                ),
              ),
              onTap: onAllLevels,
            ),
          ),
        ],
      );
    },
  );

  Widget _block(_Placed p, int? firstLocked) {
    final shape = _windShape(p.number);
    switch (p.kind) {
      case _Kind.more:
        return _MoreBlock(count: p.number, onTap: onAllLevels);
      case _Kind.locked:
        // Higher blocks lean further, as if the wind already has them.
        final k = (p.number - firstLocked!).clamp(0, 4);
        const shift = [0.0, 2, 5, 8, 12];
        return ExcludeSemantics(
          child: Transform.translate(
            offset: Offset(shift[k].toDouble(), 0),
            child: Transform.rotate(
              angle: k * math.pi / 180,
              child: CustomPaint(
                painter: _ShapePainter(
                  shape,
                  stroke: MenuColors.white(0.26 - k * 0.04),
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ),
        );
      case _Kind.current:
        return _Tappable(
          key: ValueKey('wind-block-${p.number}'),
          label: 'Level ${p.number}, next up',
          onTap: () => onPlay(p.number),
          child: Transform.rotate(
            angle: -4 * math.pi / 180,
            child: CustomPaint(
              painter: _ShapePainter(
                shape,
                fill: accent.withValues(alpha: 0.12),
                stroke: accent,
                strokeWidth: 2,
                glow: accent.withValues(alpha: 0.6),
              ),
              child: Center(child: _Number(p.number, size: 14)),
            ),
          ),
        );
      case _Kind.cleared:
        final color = MenuColors.level(p.number);
        return _Tappable(
          key: ValueKey('wind-block-${p.number}'),
          label: 'Level ${p.number}, cleared',
          onTap: () => onPlay(p.number),
          child: CustomPaint(
            painter: _ShapePainter(
              shape,
              fill: color,
              glow: color.withValues(alpha: 0.6),
            ),
            child: Center(child: _Number(p.number, size: 13)),
          ),
        );
    }
  }
}

/// Wind strength as 1 to 3 bars and a word, from how many gusts blow.
(int, String) windTier(LevelConfig level) => level.gusts <= 2
    ? (1, 'Light wind')
    : level.gusts <= 4
    ? (2, 'Strong wind')
    : (3, 'Gale');

/// Keeps the card on screen and clear of the title.
double _clampCard(
  double top,
  double height, {
  double highest = 0,
  required double lowest,
}) {
  var t = top;
  if (t + height > lowest) t = lowest - height;
  if (t < highest) t = highest;
  return t;
}

Widget _floor(Color accent) => Positioned(
  left: 0,
  right: 0,
  bottom: 0,
  height: 3,
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: accent,
      borderRadius: BorderRadius.circular(2),
      boxShadow: [
        BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 16),
      ],
    ),
  ),
);

/// "+N" over the tower: locked levels the tower has no room to show.
Widget _count(
  int hidden,
  List<_Placed> placed, {
  required double width,
  required double left,
}) {
  final top = placed.map((p) => p.rect.top).reduce(math.min);
  return Positioned(
    left: left,
    width: width,
    top: top - _countSpace + 3,
    child: Text(
      '+$hidden',
      key: const ValueKey('menu-locked-count'),
      textAlign: TextAlign.center,
      style: manrope(11, weight: 700, color: MenuColors.faint),
    ),
  );
}

class _Tappable extends StatelessWidget {
  const _Tappable({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    ),
  );
}

class _Number extends StatelessWidget {
  const _Number(this.number, {required this.size});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    '$number',
    textScaler: TextScaler.noScaling,
    style: unbounded(size, color: MenuColors.text),
  );
}

/// Cleared levels the tower has no room for; opens the full list.
class _MoreBlock extends StatelessWidget {
  const _MoreBlock({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Tappable(
    key: const ValueKey('menu-more-cleared'),
    label: '$count more cleared levels. Open all levels',
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MenuColors.white(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MenuColors.white(0.14)),
      ),
      child: Text(
        '+$count',
        textScaler: TextScaler.noScaling,
        style: manrope(12, weight: 800, color: MenuColors.muted),
      ),
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(
    this.lines,
    this.tagline, {
    required this.size,
    required this.maxWidth,
  });

  final List<String> lines;
  final String tagline;
  final double size;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Semantics(
        header: true,
        child: Text(
          lines.join('\n'),
          textAlign: TextAlign.right,
          maxLines: 2,
          style: unbounded(size, weight: 800, letterSpacing: -1, height: 1.05),
        ),
      ),
      const SizedBox(height: 10),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(
          tagline,
          textAlign: TextAlign.right,
          style: manrope(14, weight: 500, color: MenuColors.muted, height: 1.4),
        ),
      ),
    ],
  );
}

/// The card beside the next level: stage, level number and what it holds.
/// Tapping it opens the full list of levels.
class _NextCard extends StatelessWidget {
  const _NextCard({
    super.key,
    required this.accent,
    required this.heading,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final Color accent;
  final String heading, title;
  final Widget detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$heading. $title. Open all levels',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        decoration: BoxDecoration(
          color: MenuColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MenuColors.white(0.12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: manrope(
                        11,
                        weight: 800,
                        color: accent,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(title, maxLines: 1, style: unbounded(20, height: 1.1)),
                    const SizedBox(height: 6),
                    detail,
                  ],
                ),
              ),
            ),
            CustomPaint(
              size: const Size(14, 14),
              painter: _ChevronPainter(MenuColors.white(0.3)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WindBars extends StatelessWidget {
  const _WindBars(this.lit, this.accent);

  final int lit;
  final Color accent;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Wind strength $lit of 3',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, h) in const [5.0, 8.0, 12.0].indexed) ...[
          if (i > 0) const SizedBox(width: 2),
          Container(
            width: 4,
            height: h,
            decoration: BoxDecoration(
              color: i < lit ? accent : MenuColors.white(0.2),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ],
    ),
  );
}

/// A line from a block to its card, with an elbow when the card had to
/// move off the block's height.
class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  final Offset from, to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final midX = (from.dx + to.dx) / 2;
    canvas.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(midX, from.dy)
        ..lineTo(midX, to.dy)
        ..lineTo(to.dx, to.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.from != from || old.to != to || old.color != color;
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.35, h * 0.2)
        ..lineTo(w * 0.7, h * 0.5)
        ..lineTo(w * 0.35, h * 0.8),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// Four gust streaks, two ending in a curl.
class _GustPainter extends CustomPainter {
  const _GustPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-10, 34)
        ..lineTo(176, 34)
        ..arcToPoint(
          const Offset(160, 18),
          radius: const Radius.circular(16),
          largeArc: true,
          clockwise: false,
        )
        ..moveTo(120, 78)
        ..lineTo(330, 78)
        ..moveTo(-10, 122)
        ..lineTo(236, 122)
        ..arcToPoint(
          const Offset(222, 108),
          radius: const Radius.circular(14),
          largeArc: true,
          clockwise: false,
        )
        ..moveTo(60, 156)
        ..lineTo(150, 156),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GustPainter old) => old.color != color;
}

/// A Wind block's outline, in its own box.
class _WindShape {
  const _WindShape(this.size, this.outline);

  final Size size;
  final Path Function(Size) outline;
}

Path _poly(List<double> xy) {
  final path = Path()..moveTo(xy[0], xy[1]);
  for (var i = 2; i < xy.length; i += 2) {
    path.lineTo(xy[i], xy[i + 1]);
  }
  return path..close();
}

Path _rounded(Size s) => Path()
  ..addRRect(
    RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(5)),
  );

/// Level 1 is a wide slab, 2 a trapezoid, and on up through a tall block,
/// an L, a parallelogram, a square and a hexagon, then round again.
final _windShapes = [
  _WindShape(const Size(96, 34), _rounded),
  _WindShape(const Size(72, 44), (_) => _poly([9, 1, 63, 1, 71, 43, 1, 43])),
  _WindShape(const Size(40, 52), _rounded),
  _WindShape(
    const Size(76, 44),
    (_) => _poly([1, 1, 30, 1, 30, 22, 75, 22, 75, 43, 1, 43]),
  ),
  _WindShape(const Size(64, 40), (_) => _poly([15, 1, 63, 1, 49, 39, 1, 39])),
  _WindShape(const Size(36, 36), _rounded),
  _WindShape(
    const Size(60, 40),
    (_) => _poly([10, 1, 50, 1, 59, 20, 50, 39, 10, 39, 1, 20]),
  ),
];

_WindShape _windShape(int number) =>
    _windShapes[(number - 1) % _windShapes.length];

class _ShapePainter extends CustomPainter {
  _ShapePainter(
    this.shape, {
    this.fill,
    this.stroke,
    this.strokeWidth = 0,
    this.glow,
  });

  final _WindShape shape;
  final Color? fill, stroke, glow;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.outline(size);
    if (glow != null) {
      // An outline glows from its stroke; a filled block from its body.
      final glowPaint = Paint()
        ..color = glow!
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      if (stroke != null) {
        glowPaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2;
      }
      canvas.drawPath(path, glowPaint);
      if (stroke != null) {
        canvas.drawPath(path, Paint()..color = AppColors.background);
      }
    }
    if (fill != null) canvas.drawPath(path, Paint()..color = fill!);
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape ||
      old.fill != fill ||
      old.stroke != stroke ||
      old.glow != glow;
}
