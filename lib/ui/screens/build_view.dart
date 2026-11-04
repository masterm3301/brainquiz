import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../game/attempt.dart';
import '../../game/block.dart';
import '../../game/stability.dart';
import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/arena.dart';
import '../widgets/block_tray.dart';
import '../widgets/meter.dart';
import '../widgets/neon_button.dart';
import '../widgets/tower_view.dart';
import 'levels_screen.dart' show BackLabel;

/// How long the second look keeps the study tower on show.
const Duration secondLookDuration = Duration(seconds: 3);

/// Screen 02: drag blocks from the tray onto the tower.
class BuildView extends StatefulWidget {
  const BuildView({super.key, required this.attempt});

  final Attempt attempt;

  @override
  State<BuildView> createState() => _BuildViewState();
}

class _BuildViewState extends State<BuildView> {
  final _towerKey = GlobalKey();
  bool _adShowing = false;
  bool _peeking = false;
  Timer? _peekTimer;

  // Measured while building, read when a block is held or dropped.
  double _scale = 1;
  double _innerWidth = 0;

  Attempt get _attempt => widget.attempt;

  @override
  void dispose() {
    _peekTimer?.cancel();
    super.dispose();
  }

  /// The tray's held-block size depends on the arena, which is laid out
  /// after the tray is built, so a change takes one more frame to reach it.
  void _measure(double innerWidth, double scale) {
    if (innerWidth == _innerWidth && scale == _scale) return;
    _innerWidth = innerWidth;
    _scale = scale;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Size _heldSize(Block b) => Size(b.width * _innerWidth, b.height * _scale);

  void _onDrop(DragTargetDetails<Block> d) {
    final box = _towerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final held = _heldSize(d.data);
    final centre = d.offset + Offset(held.width / 2, held.height / 2);
    final local = box.globalToLocal(centre);
    final x = (local.dx - box.size.width / 2) / box.size.width;
    if (_attempt.drop(d.data, x) == DropOutcome.placed) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _secondLook() async {
    if (_adShowing || _peeking || _attempt.secondLookUsed) return;
    setState(() => _adShowing = true);
    final earned = await AppScope.of(context).ads.show();
    if (!mounted) return;
    setState(() => _adShowing = false);
    if (earned && _attempt.earnSecondLook()) {
      setState(() => _peeking = true);
      _peekTimer = Timer(secondLookDuration, () {
        if (mounted) setState(() => _peeking = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ads = AppScope.of(context).ads;
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _attempt,
          builder: (context, _) {
            final total = _attempt.level.blocks;
            final placedCount = _attempt.placed.length;
            final report = _attempt.report;
            final full = _attempt.canLock;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                compact ? 12 : 24,
                24,
                compact ? 12 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const BackLabel(),
                      const SizedBox(width: 14),
                      Flexible(
                        child: Text(
                          full
                              ? 'All $total placed'
                              : 'Block ${placedCount + 1} of $total',
                          style: nunito(20, weight: 900),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 12),
                      Text('No timer', style: label(size: 13)),
                    ],
                  ),
                  SizedBox(height: compact ? 6 : 18),
                  _MeterPanel(
                    score: report.score,
                    line: report.meterLine,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 6 : 16),
                  Expanded(child: _arena(full)),
                  SizedBox(height: compact ? 6 : 16),
                  Text('Block tray'.toUpperCase(), style: label()),
                  const SizedBox(height: 8),
                  BlockTray(
                    blocks: _attempt.tray,
                    enabled: !_peeking && !_adShowing,
                    feedbackSize: _heldSize,
                    tileAspect: compact ? 2.6 : 1,
                  ),
                  SizedBox(height: compact ? 6 : 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: ads.isReady,
                    builder: (context, ready, _) {
                      final offerLook =
                          (ready || _adShowing) && !_attempt.secondLookUsed;
                      final canLock = full && !_peeking && !_adShowing;
                      final lock = NeonButton.primary(
                        offerLook ? 'Lock' : 'Lock the tower',
                        onPressed: canLock ? _attempt.lock : null,
                      );
                      if (!offerLook) return lock;
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Stack(
                                children: [
                                  NeonButton.outline(
                                    'See the tower again',
                                    onPressed: _adShowing || _peeking
                                        ? null
                                        : _secondLook,
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 6,
                                    child: IgnorePointer(
                                      child: Text(
                                        'Ad'.toUpperCase(),
                                        style: label(size: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(flex: 2, child: lock),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _arena(bool full) {
    return DragTarget<Block>(
      onWillAcceptWithDetails: (_) => !_peeking,
      onAcceptWithDetails: _onDrop,
      builder: (context, candidate, rejected) => Arena(
        showCentreLine: true,
        child: SizedBox.expand(
          key: _towerKey,
          child: LayoutBuilder(
            builder: (context, c) {
              final shown = _peeking
                  ? [for (final b in _attempt.tower.blocks) PlacedBlock(b, 0)]
                  : _attempt.placed;
              final withSlot = !_peeking && !full;
              final scale = TowerLayout.scaleFor(
                [for (final p in shown) p.block],
                c.maxHeight,
                withNextSlot: withSlot,
              );
              _measure(c.maxWidth, scale);
              return TowerView(
                key: _peeking ? const ValueKey('peek-tower') : null,
                placed: shown,
                nextSlot: withSlot
                    ? _PlaceHere(
                        key: const ValueKey('place-here'),
                        width: c.maxWidth * 0.58,
                        height: TowerLayout.nextSlotHeight * scale,
                      )
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MeterPanel extends StatelessWidget {
  const _MeterPanel({
    required this.score,
    required this.line,
    required this.compact,
  });

  final int score;
  final String line;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = meterColor(score);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 6 : 14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Chance it stands'.toUpperCase(),
                  style: label(size: 11),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$score%',
                style: nunito(22, weight: 900, color: color).copyWith(
                  shadows: [
                    Shadow(
                      color: color.withValues(alpha: 0.85),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 10),
          Meter(percent: score),
          SizedBox(height: compact ? 6 : 10),
          Text(
            line,
            style: nunito(14, weight: 700, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// The dashed "Place here" box above the tower. Always the same size.
class _PlaceHere extends StatelessWidget {
  const _PlaceHere({super.key, required this.width, required this.height});

  final double width, height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: CustomPaint(
      painter: _DashedBoxPainter(),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Place here'.toUpperCase(),
            style: label(color: AppColors.green),
          ),
        ),
      ),
    ),
  );
}

class _DashedBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..color = AppColors.green.withValues(alpha: 0.07),
    );
    final paint = Paint()
      ..color = AppColors.green.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRect(rect.deflate(0.75));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, (d + 5).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBoxPainter old) => false;
}
