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

class _Fall {
  _Fall(this.drift, this.spin, this.delay, this.rest);
  final double drift; // fraction of width
  final double spin; // radians at rest
  final double delay; // 0..0.3 of the timeline
  final double rest; // resting height above floor, px
}

class CollapseViewState extends State<CollapseView>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late List<_Fall> _falls = _plan();

  List<_Fall> _plan() {
    final rnd = math.Random(widget.seed);
    final n = widget.placed.length + 1; // pillar stays put
    return [
      for (var i = 0; i < n; i++)
        _Fall(
          widget.direction * (0.05 + rnd.nextDouble() * 0.3) * (1 + i * 0.12),
          (rnd.nextDouble() * 2 - 1) * 1.1,
          rnd.nextDouble() * 0.3 * (n - i) / n,
          rnd.nextDouble() * 10,
        ),
    ];
  }

  void replay() => controller.forward(from: 0);

  @override
  void didUpdateWidget(CollapseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed ||
        oldWidget.placed.length != widget.placed.length) {
      _falls = _plan();
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
      final blocks = [for (final p in widget.placed) p.block];
      final scale = TowerLayout.scaleFor(
          blocks, c.hasBoundedHeight ? c.maxHeight : double.infinity);
      final slots = TowerLayout.slots(widget.placed, width, scale);
      final height = c.hasBoundedHeight
          ? c.maxHeight
          : TowerLayout.naturalHeight(blocks) * scale;
      final floorBottom = TowerLayout.floorMargin * scale;
      final restBase = (TowerLayout.floorMargin + TowerLayout.floorHeight) * scale;

      return SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: width * 0.02,
                width: width * 0.96,
                bottom: floorBottom,
                height: TowerLayout.floorHeight * scale,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    boxShadow: [BoxShadow(color: Color(0xD9FF3B30), blurRadius: 30)],
                  ),
                ),
              ),
              for (var i = 0; i < slots.length; i++) _block(slots[i], i, width, restBase),
            ],
          ),
        ),
      );
    });
  }

  Widget _block(
      ({Block block, double left, double width, double base, double height}) s,
      int i,
      double arenaWidth,
      double restBase) {
    final f = _falls[i];
    if (i == 0) {
      // The pillar topples last and only tilts.
      final t = Curves.easeIn.transform(controller.value);
      return Positioned(
        left: s.left + f.drift * arenaWidth * t * 0.5,
        bottom: s.base,
        child: Transform.rotate(
          angle: widget.direction * 0.5 * t,
          alignment: Alignment.bottomCenter,
          child: BlockView(block: s.block, width: s.width, height: s.height),
        ),
      );
    }
    final raw = ((controller.value - f.delay) / (1 - 0.3)).clamp(0.0, 1.0);
    final fall = Curves.easeIn.transform(raw);
    final drift = Curves.easeOut.transform(raw);
    final rest = restBase + f.rest + (i % 2) * 2;
    final bottom = s.base + (rest - s.base) * fall;
    return Positioned(
      left: s.left + f.drift * arenaWidth * drift,
      bottom: bottom,
      child: Transform.rotate(
        angle: f.spin * drift,
        child: BlockView(block: s.block, width: s.width, height: s.height),
      ),
    );
  }
}
