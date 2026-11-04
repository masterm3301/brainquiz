import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../game/block.dart';
import '../../game/stability.dart';
import '../theme/tokens.dart';
import 'block_view.dart';

/// A block's position, measured from the bottom-left of the tower area.
class TowerSlot {
  const TowerSlot(this.block, this.rect);
  final Block block;
  final Rect rect; // top is measured from the bottom edge: rect.bottom is the gap height above ground
}

/// Pure layout for the tower, shared by [TowerView] and the collapse.
abstract final class TowerLayout {
  static const double gap = 5;
  static const double floorHeight = 8;
  static const double floorMargin = 20;
  static const double emptyRowHeight = 40;

  /// Height at scale 1: margin, floor, pillar and blocks, with 5px gaps.
  static double naturalHeight(List<Block> blocks) {
    var h = floorMargin + floorHeight + pillar.height + gap;
    for (final b in blocks) {
      h += b.height + gap;
    }
    return h;
  }

  /// Uniform scale so the tower fits [availableHeight]. Never above 1.
  static double scaleFor(List<Block> blocks, double availableHeight) {
    final natural = naturalHeight(blocks);
    return natural <= availableHeight ? 1 : availableHeight / natural;
  }

  /// Slots for the pillar followed by [placed], bottom-up. Each rect is
  /// measured with y up from the ground line (rect.bottom = height of the
  /// block's underside above the ground), x from the arena's left edge.
  static List<({Block block, double left, double width, double base, double height})>
      slots(List<PlacedBlock> placed, double innerWidth, double scale) {
    final out = <({Block block, double left, double width, double base, double height})>[];
    var y = (floorMargin + floorHeight + gap) * scale;
    void add(Block b, double x) {
      final w = b.width * innerWidth;
      out.add((
        block: b,
        left: innerWidth / 2 + x * innerWidth - w / 2,
        width: w,
        base: y,
        height: b.height * scale,
      ));
      y += (b.height + gap) * scale;
    }

    add(pillar, 0);
    for (final p in placed) {
      add(p.block, p.x);
    }
    return out;
  }
}

class TowerView extends StatelessWidget {
  const TowerView({
    super.key,
    required this.placed,
    this.leanDegrees = 0,
    this.nextSlot,
    this.emptyRows = 0,
  });

  final List<PlacedBlock> placed;
  final double leanDegrees;
  final Widget? nextSlot;
  final int emptyRows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final blocks = [for (final p in placed) p.block];
      final extra = emptyRows * TowerLayout.emptyRowHeight;
      final avail = c.hasBoundedHeight ? c.maxHeight - extra : double.infinity;
      final scale = TowerLayout.scaleFor(blocks, avail);
      final width = c.maxWidth;
      final slots = TowerLayout.slots(placed, width, scale);
      final height = c.hasBoundedHeight
          ? c.maxHeight
          : TowerLayout.naturalHeight(blocks) * scale + extra;
      final top = slots.last.base + slots.last.height + TowerLayout.gap * scale;

      return SizedBox(
        width: width,
        height: height,
        child: Transform.rotate(
          angle: leanDegrees * math.pi / 180,
          alignment: Alignment.bottomCenter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: width * 0.02,
                width: width * 0.96,
                bottom: TowerLayout.floorMargin * scale,
                height: TowerLayout.floorHeight * scale,
                child: const _Floor(),
              ),
              for (final s in slots)
                Positioned(
                  left: s.left,
                  bottom: s.base,
                  child: BlockView(
                      block: s.block, width: s.width, height: s.height),
                ),
              if (nextSlot != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: top,
                  child: Center(child: nextSlot),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _Floor extends StatelessWidget {
  const _Floor();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.green,
          boxShadow: [
            BoxShadow(color: Color(0xF222E06B), blurRadius: 30),
          ],
        ),
      );
}
