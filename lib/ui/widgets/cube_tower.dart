import 'package:flutter/widgets.dart';

import '../../memory/cube_layout.dart';
import '../theme/tokens.dart';

/// The Memory Towers palette, in the order levels unlock it.
const cubeColors = [
  AppColors.red,
  AppColors.green,
  AppColors.cubeBlue,
  AppColors.yellow,
  AppColors.cubePurple,
  AppColors.cubeOrange,
  AppColors.cubePink,
  AppColors.cyan,
];

const cubeColorNames = [
  'Red',
  'Green',
  'Blue',
  'Yellow',
  'Purple',
  'Orange',
  'Pink',
  'Cyan',
];

/// Room under the towers for the neon floor.
const double _floor = 14;

/// Towers of cubes standing on a neon floor. [cubes] holds a palette index
/// per slot, or null for an empty slot. The [cursor] slot glows white.
/// With [answer] set, every cube that differs from it is marked wrong and
/// shows the right colour inside.
class CubeTower extends StatefulWidget {
  const CubeTower({
    super.key,
    required this.cubes,
    this.cursor,
    this.answer,
    this.onTapCube,
  });

  final List<int?> cubes;
  final int? cursor;
  final List<int>? answer;
  final ValueChanged<int>? onTapCube;

  @override
  State<CubeTower> createState() => _CubeTowerState();
}

class _CubeTowerState extends State<CubeTower> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );
  int? _dropped;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(CubeTower old) {
    super.didUpdateWidget(old);
    _syncPulse();
    // Animate the one slot that just got a new colour.
    if (old.cubes.length == widget.cubes.length) {
      for (var i = 0; i < widget.cubes.length; i++) {
        if (widget.cubes[i] != null && old.cubes[i] != widget.cubes[i]) {
          _dropped = i;
          _drop.forward(from: 0);
          break;
        }
      }
    }
  }

  void _syncPulse() {
    if (widget.cursor != null && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (widget.cursor == null && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final layout = CubeLayout(
          widget.cubes.length,
          Size(c.maxWidth, c.maxHeight - _floor),
        );
        final placed = widget.cubes.where((x) => x != null).length;
        return Semantics(
          label: '${widget.cubes.length} cube tower, $placed placed',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.onTapCube == null
                ? null
                : (d) {
                    final i = layout.indexAt(d.localPosition);
                    if (i != null) widget.onTapCube!(i);
                  },
            child: CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: _CubePainter(
                layout: layout,
                cubes: widget.cubes,
                cursor: widget.cursor,
                answer: widget.answer,
                pulse: _pulse,
                drop: _drop,
                dropped: _dropped,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CubePainter extends CustomPainter {
  _CubePainter({
    required this.layout,
    required this.cubes,
    required this.cursor,
    required this.answer,
    required this.pulse,
    required this.drop,
    required this.dropped,
  }) : super(repaint: Listenable.merge([pulse, drop]));

  final CubeLayout layout;
  final List<int?> cubes;
  final int? cursor;
  final List<int>? answer;
  final Animation<double> pulse;
  final Animation<double> drop;
  final int? dropped;

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.columns == 0) return;
    _paintFloor(canvas);
    final cube = layout.cube;
    final radius = Radius.circular(cube * 0.08);
    final seam = (cube * 0.04).clamp(1.0, 2.5);

    for (var i = 0; i < cubes.length; i++) {
      var rect = layout.rectOf(i).deflate(seam / 2);
      final index = cubes[i];
      if (index == null) {
        _paintEmpty(canvas, rect, radius);
      } else {
        if (i == dropped && drop.value < 1) {
          final t = Curves.easeOutBack.transform(drop.value);
          rect = Rect.fromCenter(
            center: rect.center.translate(0, -cube * 0.6 * (1 - t)),
            width: rect.width * (0.7 + 0.3 * t),
            height: rect.height * (0.7 + 0.3 * t),
          );
        }
        final right = answer == null || answer![i] == index;
        _paintCube(canvas, rect, radius, cubeColors[index], dim: !right);
        if (!right) _paintMiss(canvas, rect, radius, cubeColors[answer![i]]);
      }
      if (i == cursor) _paintCursor(canvas, rect, radius);
    }
  }

  void _paintFloor(Canvas canvas) {
    final first = layout.rectOf(0);
    final last = layout.rectOf(cubes.length - 1);
    final left = first.left - layout.cube * 0.4;
    final right = last.right + layout.cube * 0.4;
    final y = layout.origin.dy + 3;
    final floor = Rect.fromLTRB(left, y, right, y + 3);
    canvas.drawRect(
      floor.inflate(4),
      Paint()
        ..color = AppColors.green.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRect(floor, Paint()..color = AppColors.green);
  }

  void _paintEmpty(Canvas canvas, Rect rect, Radius radius) {
    final r = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(r, Paint()..color = AppColors.cubeEmpty);
    canvas.drawRRect(
      r.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.dashed,
    );
  }

  void _paintCube(
    Canvas canvas,
    Rect rect,
    Radius radius,
    Color color, {
    bool dim = false,
  }) {
    final r = RRect.fromRectAndRadius(rect, radius);
    final alpha = dim ? 0.3 : 1.0;
    if (!dim) {
      canvas.drawRRect(
        r,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.width * 0.18),
      );
    }
    canvas.drawRRect(r, Paint()..color = color.withValues(alpha: alpha));
    // A lit top face and a shaded base, so each cube reads as a block.
    final top = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height * 0.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(top, topLeft: radius, topRight: radius),
      Paint()
        ..color = Color.lerp(
          color,
          AppColors.text,
          0.35,
        )!.withValues(alpha: alpha),
    );
    final base = Rect.fromLTWH(
      rect.left,
      rect.bottom - rect.height * 0.14,
      rect.width,
      rect.height * 0.14,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(base, bottomLeft: radius, bottomRight: radius),
      Paint()
        ..color = Color.lerp(
          color,
          AppColors.background,
          0.3,
        )!.withValues(alpha: alpha),
    );
  }

  /// A wrong cube: red frame, with the right colour as an inner square.
  void _paintMiss(Canvas canvas, Rect rect, Radius radius, Color right) {
    final inner = rect.deflate(rect.width * 0.27);
    canvas.drawRect(inner, Paint()..color = right);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius).deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (rect.width * 0.08).clamp(1.5, 3.0)
        ..color = AppColors.red,
    );
  }

  void _paintCursor(Canvas canvas, Rect rect, Radius radius) {
    final r = RRect.fromRectAndRadius(rect.inflate(1.5), radius);
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = AppColors.text.withValues(alpha: 0.25 + 0.45 * pulse.value)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.text,
    );
  }

  @override
  bool shouldRepaint(_CubePainter old) =>
      old.layout.cube != layout.cube ||
      old.layout.origin != layout.origin ||
      old.cursor != cursor ||
      old.answer != answer ||
      old.dropped != dropped ||
      !_sameCubes(old.cubes, cubes);

  static bool _sameCubes(List<int?> a, List<int?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
