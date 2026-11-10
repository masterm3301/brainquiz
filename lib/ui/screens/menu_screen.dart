import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../progress/progress.dart';
import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/menu_tower.dart';
import 'about_screen.dart';
import 'attempt_flow.dart';
import 'levels_screen.dart';
import 'memory_game_screen.dart';
import 'memory_levels_screen.dart';

/// The two games home can show.
enum MenuMode { memory, wind }

/// Home: the score, a switch between Tower build and Wind, that game's
/// tower of levels with the next one picked out, and one big Play.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  MenuMode _mode = MenuMode.memory;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final wind = _mode == MenuMode.wind;
    final accent = wind ? MenuColors.windAccent : MenuColors.memoryAccent;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: accent),
        duration: const Duration(milliseconds: 300),
        builder: (context, color, _) => ListenableBuilder(
          listenable: Listenable.merge([scope.progress, scope.memoryProgress]),
          builder: (context, _) => _body(
            context,
            color ?? accent,
            memory: scope.memoryProgress.progress,
            wind: scope.progress.progress,
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    Color accent, {
    required Progress memory,
    required Progress wind,
  }) {
    final isWind = _mode == MenuMode.wind;
    final progress = isWind ? wind : memory;
    final stars = [
      memory,
      wind,
    ].expand((p) => p.records.values).fold(0, (n, r) => n + r.stars);
    final maxStars = (memory.lastLevel + wind.lastLevel) * 3;
    final playing = progress.nextLevel;
    return CustomPaint(
      painter: _BackdropPainter(
        accent,
        topInset: MediaQuery.paddingOf(context).top,
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final compact = c.maxHeight < 700;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, compact ? 8 : 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hud(
                    stars: stars,
                    maxStars: maxStars,
                    points: memory.totalPoints + wind.totalPoints,
                    onHelp: () =>
                        _open(context, const AboutScreen(rulesOpen: true)),
                    onSettings: () => _open(context, const AboutScreen()),
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  _ModeSwitch(
                    mode: _mode,
                    memory: memory,
                    wind: wind,
                    onChanged: (mode) => setState(() => _mode = mode),
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isWind
                          ? WindMenuTower(
                              key: const ValueKey('wind-tower'),
                              progress: wind,
                              accent: accent,
                              compact: compact,
                              onPlay: (n) => _playWind(context, n),
                              onAllLevels: () =>
                                  _open(context, const LevelsScreen()),
                            )
                          : MemoryMenuTower(
                              key: const ValueKey('memory-tower'),
                              progress: memory,
                              accent: accent,
                              compact: compact,
                              onPlay: (n) => _playMemory(context, n),
                              onAllLevels: () =>
                                  _open(context, const MemoryLevelsScreen()),
                            ),
                    ),
                  ),
                  if (isWind) ...[
                    SizedBox(height: compact ? 8 : 14),
                    _HowWindPlays(accent: accent, compact: compact),
                  ],
                  SizedBox(height: compact ? 10 : 14),
                  _PlayButton(
                    progress.allCleared
                        ? 'Replay level $playing'
                        : 'Play level $playing',
                    key: ValueKey(isWind ? 'wind-play' : 'memory-play'),
                    accent: accent,
                    onTap: () => isWind
                        ? _playWind(context, playing)
                        : _playMemory(context, playing),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void _playMemory(BuildContext context, int n) =>
    _open(context, MemoryGameScreen(levelNumber: n));

void _playWind(BuildContext context, int n) =>
    _open(context, AttemptFlow(levelNumber: n));

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

/// Stars and points from both games, with How to play and Settings.
class _Hud extends StatelessWidget {
  const _Hud({
    required this.stars,
    required this.maxStars,
    required this.points,
    required this.onHelp,
    required this.onSettings,
  });

  final int stars, maxStars, points;
  final VoidCallback onHelp, onSettings;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(width: 4),
      Expanded(
        child: Semantics(
          label: '$stars of $maxStars stars, ${formatPoints(points)} points',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                CustomPaint(
                  size: const Size(16, 16),
                  painter: _IconPainter(_Icon.star, MenuColors.star),
                ),
                const SizedBox(width: 6),
                Text(
                  '$stars/$maxStars',
                  key: const ValueKey('menu-stars'),
                  style: _hudNumber,
                ),
                const SizedBox(width: 16),
                Text(
                  formatPoints(points),
                  key: const ValueKey('menu-points'),
                  style: _hudNumber,
                ),
                Text(
                  ' pts',
                  style: manrope(12, weight: 800, color: MenuColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
      _IconButton(
        _Icon.help,
        key: const ValueKey('menu-help'),
        label: 'How to play',
        onTap: onHelp,
      ),
      _IconButton(
        _Icon.settings,
        key: const ValueKey('about'),
        label: 'Settings and about',
        onTap: onSettings,
      ),
    ],
  );
}

final _hudNumber = manrope(
  14,
  weight: 800,
).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

class _IconButton extends StatelessWidget {
  const _IconButton(
    this.icon, {
    super.key,
    required this.label,
    required this.onTap,
  });

  final _Icon icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: CustomPaint(
              size: const Size(22, 22),
              painter: _IconPainter(icon, MenuColors.icon),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Tower build or Wind, each with its cleared count.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.mode,
    required this.memory,
    required this.wind,
    required this.onChanged,
  });

  final MenuMode mode;
  final Progress memory, wind;
  final ValueChanged<MenuMode> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: MenuColors.white(0.05),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Stack(
      children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: mode == MenuMode.memory
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            child: Padding(
              padding: EdgeInsets.only(
                left: mode == MenuMode.wind ? 2 : 0,
                right: mode == MenuMode.memory ? 2 : 0,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: MenuColors.white(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            _segment(MenuMode.memory, 'Tower build', memory),
            const SizedBox(width: 4),
            _segment(MenuMode.wind, 'Wind', wind),
          ],
        ),
      ],
    ),
  );

  Widget _segment(MenuMode m, String name, Progress progress) {
    final on = m == mode;
    final count = '${progress.records.length}/${progress.lastLevel}';
    return Expanded(
      child: Semantics(
        button: true,
        selected: on,
        label: '$name, $count cleared',
        excludeSemantics: true,
        child: GestureDetector(
          key: ValueKey('mode-${m.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(m),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  text: '$name ',
                  children: [
                    TextSpan(
                      text: count,
                      style: manrope(14, weight: 600, color: MenuColors.muted)
                          .copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ],
                ),
                maxLines: 1,
                style: manrope(
                  14,
                  weight: 800,
                  color: on ? MenuColors.text : MenuColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wind's three steps: memorise, rebuild, lock it.
class _HowWindPlays extends StatelessWidget {
  const _HowWindPlays({required this.accent, required this.compact});

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: compact ? 62 : 72,
    child: Row(
      children: [
        for (final (i, (icon, name, detail)) in const [
          (_Icon.eye, 'Memorise', 'a few seconds'),
          (_Icon.move, 'Rebuild', 'from the tray'),
          (_Icon.lock, 'Lock it', 'then the wind'),
        ].indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: MenuColors.white(0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: const Size(18, 18),
                        painter: _IconPainter(icon, accent),
                      ),
                      const SizedBox(height: 4),
                      Text(name, style: manrope(13, weight: 800)),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: manrope(
                          11,
                          weight: 600,
                          color: MenuColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _PlayButton extends StatelessWidget {
  const _PlayButton(
    this.text, {
    super.key,
    required this.accent,
    required this.onTap,
  });

  final String text;
  final Color accent;
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
        height: 60,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 28),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            style: unbounded(16, color: MenuColors.onAccent),
          ),
        ),
      ),
    ),
  );
}

/// The arena light and a perspective floor grid fading out from its middle,
/// both in the mode's colour. Laid out on the 390 by 844 design frame.
class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.accent, {required this.topInset});

  final Color accent;
  final double topInset;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 390;
    final cx = size.width / 2;
    final horizon = topInset + 250 * s;

    // Haze: an ellipse 510 by 420 centred on the horizon.
    canvas.save();
    canvas.translate(cx, horizon);
    canvas.scale(1, 210 / 255);
    final r = 255 * s;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    canvas.restore();

    // Floor: a 790 by 260 plane, tipped back 64 degrees under a 340px
    // perspective from its top edge, lines every 56px.
    const w = 790.0, h = 260.0, p = 340.0, step = 56.0;
    final sin = math.sin(64 * math.pi / 180);
    final cos = math.cos(64 * math.pi / 180);
    Offset project(double x, double d) {
      final k = p / (p - d * sin);
      return Offset(cx + (x - w / 2) * k * s, horizon + d * cos * k * s);
    }

    double fade(double x, double d) {
      final dx = (x - w / 2) / (w / 2), dy = (d - h / 2) / (h / 2);
      final t = math.sqrt(dx * dx + dy * dy);
      return t <= 0.2 ? 1 : (t >= 1 ? 0 : 1 - (t - 0.2) / 0.8);
    }

    final paint = Paint()
      ..strokeWidth = 1.5 * s
      ..style = PaintingStyle.stroke;
    void line(Offset Function(double t) at, double Function(double t) alpha) {
      const pieces = 24;
      for (var i = 0; i < pieces; i++) {
        final a = alpha((i + 0.5) / pieces);
        if (a <= 0) continue;
        paint.color = accent.withValues(alpha: 0.34 * a);
        canvas.drawLine(at(i / pieces), at((i + 1) / pieces), paint);
      }
    }

    for (var x = 0.0; x <= w; x += step) {
      line((t) => project(x, t * h), (t) => fade(x, t * h));
    }
    for (var d = 0.0; d <= h; d += step) {
      line((t) => project(t * w, d), (t) => fade(t * w, d));
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.accent != accent || old.topInset != topInset;
}

enum _Icon { star, help, settings, eye, move, lock }

/// The design's line icons, drawn on a 24 unit grid.
class _IconPainter extends CustomPainter {
  const _IconPainter(this.icon, this.color);

  final _Icon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (icon) {
      case _Icon.star:
        canvas.drawPath(
          Path()
            ..moveTo(12, 2.5)
            ..lineTo(14.9, 8.6)
            ..lineTo(21.5, 9.5)
            ..lineTo(16.7, 14.1)
            ..lineTo(17.9, 20.7)
            ..lineTo(12, 17.5)
            ..lineTo(6.1, 20.7)
            ..lineTo(7.3, 14.1)
            ..lineTo(2.5, 9.5)
            ..lineTo(9.1, 8.6)
            ..close(),
          Paint()..color = color,
        );
      case _Icon.help:
        canvas.drawCircle(const Offset(12, 12), 9, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(9.6, 9.3)
            ..arcToPoint(
              const Offset(13.2, 11.6),
              radius: const Radius.circular(2.5),
              largeArc: true,
            )
            ..cubicTo(12.4, 12, 12, 12.6, 12, 13.5),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 17), 1.1, Paint()..color = color);
      case _Icon.settings:
        canvas.drawLine(const Offset(4, 7), const Offset(14, 7), stroke);
        canvas.drawLine(const Offset(18, 7), const Offset(20, 7), stroke);
        canvas.drawCircle(const Offset(16, 7), 2, stroke);
        canvas.drawLine(const Offset(4, 17), const Offset(6, 17), stroke);
        canvas.drawLine(const Offset(10, 17), const Offset(20, 17), stroke);
        canvas.drawCircle(const Offset(8, 17), 2, stroke);
      case _Icon.eye:
        canvas.drawPath(
          Path()
            ..moveTo(2, 12)
            ..quadraticBezierTo(12, -1, 22, 12)
            ..quadraticBezierTo(12, 25, 2, 12)
            ..close(),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 12), 3, stroke);
      case _Icon.move:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(12, 21)
            ..moveTo(3, 12)
            ..lineTo(21, 12)
            ..moveTo(9, 6)
            ..lineTo(12, 3)
            ..lineTo(15, 6)
            ..moveTo(9, 18)
            ..lineTo(12, 21)
            ..lineTo(15, 18)
            ..moveTo(6, 9)
            ..lineTo(3, 12)
            ..lineTo(6, 15)
            ..moveTo(18, 9)
            ..lineTo(21, 12)
            ..lineTo(18, 15),
          stroke,
        );
      case _Icon.lock:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 11, 14, 10),
            const Radius.circular(2),
          ),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 11)
            ..lineTo(8, 7)
            ..arcToPoint(const Offset(16, 7), radius: const Radius.circular(4))
            ..lineTo(16, 11),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color;
}
