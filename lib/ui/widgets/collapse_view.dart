import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../game/block.dart';
import '../../game/hold_simulation.dart' show maxLeanDegrees;
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

/// Seconds the whole collapse takes, bounce included.
const double collapseSeconds = 2.0;

/// How long the stack keeps leaning further before blocks slide off.
const double _toppleSeconds = 0.45;

/// Most the top block leans, in degrees, before the stack breaks up.
const double _maxToppleDegrees = 30;

/// Time for the landing: the slap flat and two hops.
const double _settleSeconds = 0.26;

/// One block's whole fall: leaning further with the stack, sliding off
/// and dropping under gravity, slapping flat on its rest spot and
/// bouncing. Centres are measured from the arena's left edge and ground
/// line (y up); angles are clockwise, as [Transform.rotate] draws them.
class BlockFall {
  const BlockFall({
    required this.block,
    required this.width,
    required this.height,
    required this.slotX,
    required this.base,
    required this.leanShare,
    required this.leanFrom,
    required this.leanTo,
    required this.endX,
    required this.endY,
    required this.angle,
    required this.detachAt,
    required this.landAt,
    required this.gravity,
    required this.bounce,
  });

  final Block block;
  final double width, height;

  /// Upright centre x and underside height in the tower.
  final double slotX, base;

  /// Share of the stack's lean this block takes (0 for the pillar, 1 for
  /// the top block), as on the hold screen.
  final double leanShare;

  /// The stack's lean in radians when it fell, and when it breaks up.
  final double leanFrom, leanTo;

  /// Rest pose. [angle] is radians at rest.
  final double endX, endY, angle;

  /// Seconds into the collapse the block leaves the stack, and lands.
  final double detachAt, landAt;

  /// Pixels per second squared, and the height of the first hop.
  final double gravity, bounce;

  bool get _isPillar => leanShare == 0;

  /// Axis-aligned bounds of the block at rest, rotation included. `low`
  /// and `high` are heights above the ground line (y up).
  ({double left, double right, double low, double high}) get rest {
    final hx = _halfX(width, height, angle), hy = _halfY(width, height, angle);
    return (left: endX - hx, right: endX + hx, low: endY - hy, high: endY + hy);
  }

  /// The stack's lean [t] seconds in, speeding up like anything tipping.
  double _lean(double t) {
    final u = t / _toppleSeconds;
    return leanFrom + (leanTo - leanFrom) * u * u;
  }

  double _leanRate(double t) =>
      2 * (leanTo - leanFrom) * t / (_toppleSeconds * _toppleSeconds);

  /// Centre and angle while still riding the stack; the same pose
  /// [TowerView] draws for that lean.
  ({double x, double y, double angle}) _riding(double t) {
    final a = _lean(t) * leanShare;
    return (x: slotX + base * math.sin(a), y: base + height / 2, angle: a);
  }

  /// Where and how fast it leaves the stack.
  ({double x, double y, double angle, double vx, double spin}) get _parting {
    final d = _riding(detachAt);
    final spin = _leanRate(detachAt) * leanShare;
    return (
      x: d.x,
      y: d.y,
      angle: d.angle,
      vx: base * math.cos(d.angle) * spin,
      spin: spin,
    );
  }

  /// The angle it hits the pile at: still spinning from the fall.
  double get impactAngle {
    final p = _parting;
    return p.angle + p.spin * (landAt - detachAt);
  }

  /// Pose [t] seconds into the collapse.
  ({double x, double y, double angle}) poseAt(double t) {
    if (_isPillar) return _pillarPose(t);
    if (t <= detachAt) return _riding(t);
    final p = _parting;
    final flight = landAt - detachAt;
    // Small corrections happen as it slaps down; a bigger turn (an
    // upside-down triangle righting itself) is spread over the flight.
    final hit = impactAngle;
    final slap = (angle - hit).clamp(-0.6, 0.6);
    final turn = angle - hit - slap;
    if (t < landAt) {
      // Free fall, bent just enough to finish exactly on the rest spot.
      final s = t - detachAt, q = (s / flight) * (s / flight);
      final freeX = p.x + p.vx * flight;
      final freeY = p.y - gravity * flight * flight / 2;
      return (
        x: p.x + p.vx * s + (endX - freeX) * q,
        y: p.y - gravity * s * s / 2 + (endY - freeY) * q,
        angle: p.angle + p.spin * s + turn * q,
      );
    }
    // One corner hits first, then it slaps down onto its rest angle.
    final s = t - landAt;
    final ease = Curves.easeOutCubic.transform((s / 0.12).clamp(0.0, 1.0));
    return (x: endX, y: endY + _hop(s), angle: hit + turn + slap * ease);
  }

  /// The pillar is the plinth: it stays where it stands.
  ({double x, double y, double angle}) _pillarPose(double t) =>
      (x: slotX, y: base + height / 2, angle: 0);

  /// A hop and a smaller one after landing.
  double _hop(double s) {
    const first = 0.16, second = 0.09;
    if (s < first) {
      final u = s / first;
      return bounce * 4 * u * (1 - u);
    }
    if (s < first + second) {
      final u = (s - first) / second;
      return bounce * 0.3 * 4 * u * (1 - u);
    }
    return 0;
  }
}

double _halfX(double w, double h, double a) =>
    (w / 2) * math.cos(a).abs() + (h / 2) * math.sin(a).abs();
double _halfY(double w, double h, double a) =>
    (w / 2) * math.sin(a).abs() + (h / 2) * math.cos(a).abs();

/// The rest angle with the same footprint as [tilt] (a half turn apart
/// for rectangles, a full turn for triangles) closest to [near], so a
/// block settles the way it was already turning. Inverted triangles come
/// to rest point up.
double _restAngle(Block b, double tilt, double near) {
  final triangle =
      b.shape == BlockShape.triangle || b.shape == BlockShape.invertedTriangle;
  final period = triangle ? 2 * math.pi : math.pi;
  final from = b.shape == BlockShape.invertedTriangle ? tilt + math.pi : tilt;
  return from + ((near - from) / period).round() * period;
}

/// Steepest a block may come to rest, in radians.
const double _maxRestTilt = 0.45;

/// A piece that has landed, for the ones that fall on it later.
class _Landed {
  const _Landed({
    required this.left,
    required this.right,
    required this.mid,
    required this.bottom,
    required this.thick,
    required this.high,
    required this.peaked,
    required this.landAt,
  });

  final double left, right, mid, thick, high, landAt;

  /// Its underside: height `a` at [mid], rising `k` per pixel to the right.
  final ({double a, double k}) bottom;
  final bool peaked;

  double topAt(double x) {
    final base = bottom.a + bottom.k * (x - mid);
    final half = (right - left) / 2;
    final up = peaked
        ? thick * (1 - ((x - mid).abs() / half).clamp(0.0, 1.0))
        : thick;
    return math.min(base + up, high);
  }
}

/// Where a plank of half width [half] centred on [x] comes to rest on
/// [surface]: on the upper hull edge of what is beneath that spans its
/// middle, tilted no more than [_maxRestTilt]. Returns its underside as a
/// height at [x] and a slope.
({double a, double k}) _settle(
  double x,
  double half,
  double Function(double) surface,
) {
  const samples = 16;
  final pts = [
    for (var j = 0; j <= samples; j++)
      (
        u: -half + 2 * half * j / samples,
        y: surface(x - half + 2 * half * j / samples),
      ),
  ];
  // Upper convex hull, left to right.
  final hull = <({double u, double y})>[];
  for (final p in pts) {
    while (hull.length >= 2) {
      final a = hull[hull.length - 2], b = hull.last;
      final cross = (b.u - a.u) * (p.y - a.y) - (b.y - a.y) * (p.u - a.u);
      if (cross >= 0) {
        hull.removeLast();
      } else {
        break;
      }
    }
    hull.add(p);
  }
  var k = 0.0;
  for (var j = 0; j + 1 < hull.length; j++) {
    if (hull[j].u <= 0 && hull[j + 1].u >= 0) {
      k = (hull[j + 1].y - hull[j].y) / (hull[j + 1].u - hull[j].u);
      break;
    }
  }
  final maxK = math.tan(_maxRestTilt);
  k = k.clamp(-maxK, maxK).toDouble();
  // Lowest line of that slope that clears everything beneath.
  var a = -double.infinity;
  for (final p in pts) {
    a = math.max(a, p.y - k * p.u);
  }
  return (a: a, k: k);
}

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

/// Pure and seeded: the same inputs always give the same fall. The stack
/// starts at the lean it fell at ([leanDegrees]), leans further, then
/// breaks up top first. Blocks are spread along the floor, higher ones
/// further the way it fell, kept inside the arena, rest on the floor or on
/// whatever landed before them, and never pass through either.
CollapsePlan planCollapse({
  required List<PlacedBlock> placed,
  required int seed,
  required int direction,
  required double width,
  required double availableHeight,
  double leanDegrees = maxLeanDegrees,
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
  final dir = direction >= 0 ? 1 : -1;

  // Lean further, but not so far the top swings out of the arena.
  final leanFrom = leanDegrees.abs() * math.pi / 180;
  final topBase = slots.last.base;
  final room = topBase <= 0 ? 1.0 : (0.46 * width / topBase).clamp(0.0, 1.0);
  final leanTo = math.max(
    leanFrom,
    math.min(_maxToppleDegrees * math.pi / 180, math.asin(room)),
  );
  final gravity = 5.5 * height;

  // The top slides off first, the bottom of the stack last.
  final detach = [
    for (var i = 0; i < n; i++)
      i == 0
          ? 0.0
          : _toppleSeconds * (0.7 + 0.3 * (1 - i / m)) +
                0.05 * rnd.nextDouble(),
  ];

  // Higher blocks land further the way the tower leaned.
  final keys = [for (var i = 1; i < n; i++) i / m + 0.5 * rnd.nextDouble()];
  final order = [for (var i = 1; i < n; i++) i]
    ..sort((a, b) => keys[a - 1].compareTo(keys[b - 1]));
  final targetX = List<double>.filled(n, 0);
  for (var k = 0; k < order.length; k++) {
    final x = width * (0.42 + 0.52 * (k + 0.5) / m);
    targetX[order[k]] = dir > 0 ? x : width - x;
  }

  final pillarX = slots[0].left + slots[0].width / 2;

  // The landed pieces' top surfaces: a sloped line for slabs, a tent for
  // triangles (they rest point up).
  final landed = <_Landed>[];
  double surface(double x) {
    var y = floorTop;
    for (final r in landed) {
      if (x > r.left && x < r.right) y = math.max(y, r.topAt(x));
    }
    return y;
  }

  final falls = <BlockFall>[];
  for (var i = 0; i < n; i++) {
    final s = slots[i];
    double cx, cy, tilt, footX;
    ({double a, double k}) bottom;
    if (i == 0) {
      // The pillar stays standing.
      tilt = 0;
      cx = footX = s.left + s.width / 2;
      cy = s.base + s.height / 2;
      bottom = (a: s.base, k: 0);
    } else {
      // Try its own spot and a row of others along the floor. At each, it
      // settles like a plank: on the stretch of what is below that spans
      // its middle. Take the lowest, with a pull towards its own spot.
      // Room for it tilted, the way it lands when tipping off something;
      // the final spot is clamped again for the tilt it actually takes.
      final hx =
          _halfX(s.width, s.height, _maxRestTilt) +
          s.height / 2 * math.sin(_maxRestTilt);
      final lo = math.min(hx, width / 2), hi = math.max(width - hx, width / 2);
      // Nothing lands far behind the plinth: the tower fell the other way.
      final back = pillarX - dir * 0.15 * width;
      final candidates = [
        targetX[i].clamp(lo, hi).toDouble(),
        for (var k = 0; k <= 12; k++) lo + (hi - lo) * k / 12,
      ].where((x) => dir * (x - back) >= 0).toList();
      if (candidates.isEmpty) {
        candidates.add(targetX[i].clamp(lo, hi).toDouble());
      }
      var best = double.infinity;
      cx = candidates.first;
      bottom = (a: floorTop, k: 0);
      for (final x in candidates) {
        final line = _settle(x, s.width / 2, surface);
        final score = line.a + 0.3 * (x - targetX[i]).abs();
        if (score < best) {
          best = score;
          cx = x;
          bottom = line;
        }
      }
      footX = cx;
      tilt = -math.atan(bottom.k);
      cy = bottom.a + s.height / 2 * math.cos(tilt);
      cx += s.height / 2 * math.sin(tilt);
      final hx2 = _halfX(s.width, s.height, tilt);
      final hy = _halfY(s.width, s.height, tilt);
      cx = math.max(hx2, math.min(cx, width - hx2));
      cy = math.max(floorTop + hy, math.min(cy, height - hy));
    }

    BlockFall make(double landAt, double angle) => BlockFall(
      block: s.block,
      width: s.width,
      height: s.height,
      slotX: s.left + s.width / 2,
      base: s.base,
      leanShare: i / math.max(m, 1),
      leanFrom: dir * leanFrom,
      leanTo: dir * leanTo,
      endX: cx,
      endY: cy,
      angle: angle,
      detachAt: detach[i],
      landAt: landAt,
      gravity: gravity,
      bounce: math.min(
        9 * scale,
        0.05 * math.max(s.base + s.height / 2 - cy, 0),
      ),
    );

    var fall = make(0, tilt);
    if (i > 0) {
      // A free drop from where it leaves the stack, but never landing
      // before whatever it comes to rest on.
      final rest = fall.rest;
      final drop = math.max(s.base + s.height / 2 - cy, 0.0);
      var landAt = detach[i] + math.max(math.sqrt(2 * drop / gravity), 0.16);
      for (final r in landed) {
        if (rest.left < r.right && rest.right > r.left) {
          landAt = math.max(landAt, r.landAt + 0.06);
        }
      }
      landAt = math.min(landAt, collapseSeconds - _settleSeconds);
      fall = make(landAt, tilt);
      fall = make(landAt, _restAngle(s.block, tilt, fall.impactAngle));
    }
    final rest = fall.rest;
    final cos = math.cos(tilt).abs();
    landed.add(
      _Landed(
        left: rest.left,
        right: rest.right,
        mid: footX,
        bottom: bottom,
        // Vertical thickness of the slab, so its top follows its slope.
        thick: s.height / math.max(cos, 0.2),
        high: rest.high,
        peaked:
            i > 0 &&
            (s.block.shape == BlockShape.triangle ||
                s.block.shape == BlockShape.invertedTriangle),
        landAt: fall.landAt,
      ),
    );
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
    duration: Duration(milliseconds: (collapseSeconds * 1000).round()),
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
    return LayoutBuilder(
      builder: (context, c) {
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
                      boxShadow: [
                        BoxShadow(color: Color(0xD9FF3B30), blurRadius: 30),
                      ],
                    ),
                  ),
                ),
                for (final f in plan.falls) _block(f),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _block(BlockFall f) {
    final p = f.poseAt(controller.value * collapseSeconds);
    return Positioned(
      left: p.x - f.width / 2,
      bottom: p.y - f.height / 2,
      child: Transform.rotate(
        angle: p.angle,
        child: BlockView(block: f.block, width: f.width, height: f.height),
      ),
    );
  }
}
