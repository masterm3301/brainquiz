import 'package:flutter/widgets.dart';

import '../../game/block.dart';
import '../theme/tokens.dart';

Color blockColor(BlockColor c) => switch (c) {
      BlockColor.green => AppColors.green,
      BlockColor.cyan => AppColors.cyan,
      BlockColor.yellow => AppColors.yellow,
      BlockColor.red => AppColors.red,
    };

/// A flat, bright block with a soft coloured glow beneath it.
class BlockView extends StatelessWidget {
  const BlockView({
    super.key,
    required this.block,
    required this.width,
    required this.height,
    this.heldWhite = false,
  });

  final Block block;
  final double width;
  final double height;
  final bool heldWhite;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BlockPainter(block.shape, blockColor(block.color), heldWhite),
    );
  }
}

class _BlockPainter extends CustomPainter {
  _BlockPainter(this.shape, this.color, this.heldWhite);

  final BlockShape shape;
  final Color color;
  final bool heldWhite;

  Path _path(Size s) {
    switch (shape) {
      case BlockShape.triangle:
        return Path()
          ..moveTo(s.width / 2, 0)
          ..lineTo(s.width, s.height)
          ..lineTo(0, s.height)
          ..close();
      case BlockShape.invertedTriangle:
        return Path()
          ..moveTo(0, 0)
          ..lineTo(s.width, 0)
          ..lineTo(s.width / 2, s.height)
          ..close();
      case BlockShape.rectangle:
      case BlockShape.square:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              Offset.zero & s, const Radius.circular(3)));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    final glow = heldWhite ? AppColors.text : color;
    canvas.drawPath(
      path,
      Paint()
        ..color = glow.withValues(alpha: heldWhite ? 0.95 : 0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, heldWhite ? 18 : 13),
    );
    canvas.drawPath(
        path, Paint()..color = heldWhite ? AppColors.text : color);
  }

  @override
  bool shouldRepaint(_BlockPainter old) =>
      old.shape != shape || old.color != color || old.heldWhite != heldWhite;
}
