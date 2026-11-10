import 'package:flutter/widgets.dart';

import '../theme/text.dart';
import '../theme/tokens.dart';
import 'ad_offer.dart';

/// Line icons for [GameButton], drawn on a 24 unit grid.
enum GameIcon { undo, eye, retry, grid }

/// The round's buttons, in the home screen's style: a soft green primary
/// in the display face, and dark rounded secondaries with a line icon.
class GameButton extends StatelessWidget {
  const GameButton.primary(
    this.text, {
    super.key,
    required this.height,
    required this.onPressed,
    this.semanticLabel,
  }) : _primary = true,
       icon = null,
       adBadge = false;

  const GameButton.secondary(
    this.text, {
    super.key,
    required this.height,
    required this.onPressed,
    this.icon,
    this.adBadge = false,
    this.semanticLabel,
  }) : _primary = false;

  /// An icon-only secondary, as wide as it is tall.
  const GameButton.icon(
    GameIcon this.icon, {
    super.key,
    required this.height,
    required this.onPressed,
    required String this.semanticLabel,
  }) : text = null,
       _primary = false,
       adBadge = false;

  final String? text;
  final GameIcon? icon;
  final double height;
  final VoidCallback? onPressed;

  /// Marks a button that plays a rewarded ad.
  final bool adBadge;
  final String? semanticLabel;
  final bool _primary;

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final name = semanticLabel ?? text ?? '';
    return Semantics(
      button: true,
      enabled: enabled,
      label: adBadge ? '$name, watch an ad' : name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: _primary ? _buildPrimary(enabled) : _buildSecondary(enabled),
      ),
    );
  }

  Widget _buildPrimary(bool enabled) {
    const accent = MenuColors.action;
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        // Disabled stays a dim green, not a faded one.
        color: enabled ? accent : MenuColors.actionDisabled,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: enabled
            ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 24)]
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text!,
          maxLines: 1,
          style: unbounded(
            17,
            color: enabled ? MenuColors.onAccent : MenuColors.faint,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondary(bool enabled) {
    final iconSize = text == null ? 24.0 : 18.0;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        height: height,
        width: text == null ? height : null,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: text == null ? 0 : 12),
        decoration: BoxDecoration(
          color: MenuColors.white(0.06),
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: MenuColors.white(0.1)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                SizedBox.square(
                  dimension: iconSize,
                  child: CustomPaint(
                    painter: _GameIconPainter(icon!, MenuColors.icon),
                  ),
                ),
              if (icon != null && text != null) const SizedBox(width: 8),
              if (text != null)
                Text(
                  text!,
                  maxLines: 1,
                  style: manrope(15, weight: 800, color: MenuColors.text),
                ),
              if (adBadge) ...[const SizedBox(width: 8), const AdBadge()],
            ],
          ),
        ),
      ),
    );
  }
}

class _GameIconPainter extends CustomPainter {
  const _GameIconPainter(this.icon, this.color);

  final GameIcon icon;
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
      case GameIcon.undo:
        canvas.drawPath(
          Path()
            ..moveTo(9, 5)
            ..lineTo(4, 10)
            ..lineTo(9, 15)
            ..moveTo(4, 10)
            ..lineTo(14.5, 10)
            ..arcToPoint(
              const Offset(14.5, 20),
              radius: const Radius.circular(5),
            )
            ..lineTo(11, 20),
          stroke,
        );
      case GameIcon.eye:
        canvas.drawPath(
          Path()
            ..moveTo(2, 12)
            ..quadraticBezierTo(12, -1, 22, 12)
            ..quadraticBezierTo(12, 25, 2, 12)
            ..close(),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 12), 3, stroke);
      case GameIcon.retry:
        canvas.drawPath(
          Path()
            ..moveTo(20, 12)
            ..arcToPoint(
              const Offset(17.7, 6.3),
              radius: const Radius.circular(8),
              largeArc: true,
            )
            ..moveTo(18.5, 2.5)
            ..lineTo(18.5, 7)
            ..lineTo(14, 7),
          stroke,
        );
      case GameIcon.grid:
        for (final (x, y) in const [
          (4.0, 4.0),
          (13.0, 4.0),
          (4.0, 13.0),
          (13.0, 13.0),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, 7, 7),
              const Radius.circular(1.5),
            ),
            stroke,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_GameIconPainter old) =>
      old.icon != icon || old.color != color;
}
