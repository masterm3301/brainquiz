import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../game/block.dart';
import '../../game/stability.dart';
import '../theme/tokens.dart';
import 'block_view.dart';
import 'tower_view.dart';

/// Plays the tower falling over. Seeded, so [replay] repeats it exactly.
class CollapseView extends StatefulWidget {
  const CollapseView({
    super.key,
    required this.placed,
    required this.seed,
    required this.direction,
  });

  final List<PlacedBlock> placed;
  final int seed;

  /// 1 falls to the right, -1 to the left.
  final int direction;

  @override
  State<CollapseView> createState() => CollapseViewState();
}

/// Where one block starts, where it comes to rest, and how it spins.
/// Centres are measured from the arena's left edge and ground line (y up).
class BlockFall {
  const BlockFall({
    required this.block,
    required this.width,
    required this.height,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.angle,
    required this.delay,
  });

  final Block block;
  final double width, height;
  final double startX, startY, endX, endY;
  final double angle; // radians at rest
  final double delay; // 0..0.3 of the timeline

  /// Axis-aligned bounds of the block at rest, rotation included. `low`
  /// and `high` are heights above the ground line (y up).
  ({double left, double right, double low, double high}) get rest {
    final hx = _halfX(width, height, angle), hy = _halfY(width, height, angle);
    return (left: endX - hx, right: endX + hx, low: endY - hy, high: endY + hy);
  }
}

double _halfX(double w, double h, double a) =>
    (w / 2) * math.cos(a).abs() + (h / 2) * math.sin(a).abs();
double _halfY(double w, double h, double a) =>
    (w / 2) * math.sin(a).abs() + (h / 2) * math.cos(a).abs();

class CollapsePlan {
  const CollapsePlan({
    required this.scale,
    required this.height,
    required this.floorTop,
    required this.falls,
  });

  final double scale, height;

  /// Height of the floor's top edge above the ground line.
  final double floorTop;

  /// The pillar first, then the placed blocks bottom-up.
  final List<BlockFall> falls;
}

/// Pure and seeded: the same inputs always give the same scatter. Blocks
/// are spread along the floor, kept inside the arena, rest on the floor or
/// on whatever they overlap, and never pass through either.
CollapsePlan planCollapse({
  required List<PlacedBlock> placed,
  required int seed,
  required int direction,
  required double width,
  required double availableHeight,
}) {
  final blocks = [for (final p in placed) p.block];
  final scale = TowerLayout.scaleFor(blocks, availableHeight);
  final height = availableHeight.isFinite
      ? availableHeight
      : TowerLayout.naturalHeight(blocks) * scale;
  final slots = TowerLayout.slots(placed, width, scale);
  final floorTop = (TowerLayout.floorMargin + TowerLayout.floorHeight) * scale;
  final rnd = math.Random(seed);
  final n = slots.length;
  final m = n - 1;

  final angles = [
    for (var i = 0; i < n; i++)
      i == 0
          ? direction * 0.5
          // Wide blocks lie nearly flat; narrow ones tumble.
          : (rnd.nextDouble() * 2 - 1) *
                (0.9 - 0.78 * (slots[i].width / width).clamp(0.0, 1.0)),
  ];
  final delays = [
    for (var i = 0; i < n; i++)
      i == 0 ? 0.25 : rnd.nextDouble() * 0.3 * (n - i) / n,
  ];
  // Higher blocks land further the way the tower leaned.
  final keys = [for (var i = 1; i < n; i++) i / m + 0.7 * rnd.nextDouble()];
  final order = [for (var i = 1; i < n; i++) i]
    ..sort((a, b) => keys[a - 1].compareTo(keys[b - 1]));
  final targetX = List<double>.filled(n, 0);
  targetX[0] = slots[0].left + slots[0].width / 2 + direction * 0.06 * width;
  for (var k = 0; k < order.length; k++) {
    final x = width * (0.12 + 0.76 * (k + 0.5) / m);
    targetX[order[k]] = direction > 0 ? x : width - x;
  }

  // Rest bounds plus how much of their height is only tilt.
  final landed = <({double left, double right, double low, double high, double slack})>[];
  final falls = <BlockFall>[];
  for (var i = 0; i < n; i++) {
    final s = slots[i];
    final hx = _halfX(s.width, s.height, angles[i]);
    final hy = _halfY(s.width, s.height, angles[i]);
    final slackSelf = hy - s.height / 2;
    // Try the block's own slot and a row of other spots along the floor;
    // take the lowest landing, with a pull towards its own slot.
    final lo = math.min(hx, width / 2), hi = math.max(width - hx, width / 2);
    final candidates = [
      targetX[i].clamp(lo, hi).toDouble(),
      for (var k = 0; k <= 10; k++) lo + (hi - lo) * k / 10,
    ];
    var cx = candidates.first, cy = double.infinity, best = double.infinity;
    for (final x in candidates) {
      var y = floorTop + hy;
      for (final r in landed) {
        if (x - hx < r.right && x + hx > r.left) y = math.max(y, r.high - 0.6 * r.slack + hy - 0.6 * slackSelf);
      }
      final score = y + 0.12 * (x - targetX[i]).abs();
      if (score < best) {
        best = score;
        cx = x;
        cy = y;
      }
    }
    cy = math.max(floorTop + hy, math.min(cy, height - hy));
    final fall = BlockFall(
      block: s.block,
      width: s.width,
      height: s.height,
      startX: s.left + s.width / 2,
      startY: s.base + s.height / 2,
      endX: cx,
      endY: cy,
      angle: angles[i],
      delay: delays[i],
    );
    final rest = fall.rest;
    landed.add((
      left: rest.left,
      right: rest.right,
      low: rest.low,
      high: rest.high,
      slack: slackSelf,
    ));
    falls.add(fall);
  }
  return CollapsePlan(
    scale: scale,
    height: height,
    floorTop: floorTop,
    falls: falls,
  );
}

class CollapseViewState extends State<CollapseView>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  void replay() => controller.forward(from: 0);

  @override
  void didUpdateWidget(CollapseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed ||
        oldWidget.placed.length != widget.placed.length) {
      replay();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth;
      final plan = planCollapse(
        placed: widget.placed,
        seed: widget.seed,
        direction: widget.direction,
        width: width,
        availableHeight: c.hasBoundedHeight ? c.maxHeight : double.infinity,
      );
      final scale = plan.scale;

      return SizedBox(
        width: width,
        height: plan.height,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: width * 0.02,
                width: width * 0.96,
                bottom: TowerLayout.floorMargin * scale,
                height: TowerLayout.floorHeight * scale,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    boxShadow: [BoxShadow(color: Color(0xD9FF3B30), blurRadius: 30)],
                  ),
                ),
              ),
              for (final f in plan.falls) _block(f),
            ],
          ),
        ),
      );
    });
  }

  Widget _block(BlockFall f) {
    final raw = ((controller.value - f.delay) / 0.7).clamp(0.0, 1.0);
    final fall = Curves.easeIn.transform(raw);
    final drift = Curves.easeOut.transform(raw);
    final cx = f.startX + (f.endX - f.startX) * drift;
    final cy = f.startY + (f.endY - f.startY) * fall;
    return Positioned(
      left: cx - f.width / 2,
      bottom: cy - f.height / 2,
      child: Transform.rotate(
        angle: f.angle * drift,
        child: BlockView(block: f.block, width: f.width, height: f.height),
      ),
    );
  }
}
