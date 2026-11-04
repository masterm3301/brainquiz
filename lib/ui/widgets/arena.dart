import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

enum ArenaMood { normal, stood, fell }

class Arena extends StatelessWidget {
  const Arena({
    super.key,
    required this.child,
    this.mood = ArenaMood.normal,
    this.showCentreLine = false,
    this.wind = false,
  });

  final Widget child;
  final ArenaMood mood;
  final bool showCentreLine;
  final bool wind;

  @override
  Widget build(BuildContext context) {
    final (glow, border) = switch (mood) {
      ArenaMood.normal => (AppColors.arenaNormal, AppColors.rule),
      ArenaMood.stood => (AppColors.arenaStood, AppColors.borderStood),
      ArenaMood.fell => (AppColors.arenaFell, AppColors.borderFell),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, 0.75),
          radius: 1.35,
          colors: [glow, AppColors.background],
          stops: const [0, 0.75],
        ),
        border: Border.all(color: border),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            if (wind) const Positioned.fill(child: CustomPaint(painter: _WindPainter())),
            if (showCentreLine)
              const Positioned.fill(
                  child: CustomPaint(painter: _CentreLinePainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _CentreLinePainter extends CustomPainter {
  const _CentreLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.text.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final x = size.width / 2;
    for (var y = 18.0; y < size.height - 30; y += 12) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 6), paint);
    }
  }

  @override
  bool shouldRepaint(_CentreLinePainter old) => false;
}

class _WindPainter extends CustomPainter {
  const _WindPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const streaks = [(0.10, 0.9, 0.35), (0.22, 0.7, 0.25), (0.34, 0.8, 0.2)];
    for (final (y, len, a) in streaks) {
      final left = size.width * (1 - len) / 2;
      final rect = Rect.fromLTWH(left, size.height * y, size.width * len, 1.5);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(colors: [
            AppColors.cyan.withValues(alpha: 0),
            AppColors.cyan.withValues(alpha: a),
            AppColors.cyan.withValues(alpha: 0),
          ]).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_WindPainter old) => false;
}
