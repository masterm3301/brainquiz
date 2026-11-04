import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../game/block.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import 'block_view.dart';

/// Tiles per page. With more blocks than this, the last tile pages.
const int trayTilesPerPage = 8;

/// The blocks still to place, as draggable tiles in a four-column grid.
class BlockTray extends StatefulWidget {
  const BlockTray({
    super.key,
    required this.blocks,
    this.enabled = true,
    this.feedbackSize,
    this.tileAspect = 1,
  });

  final List<Block> blocks;

  /// False stops drags, as while the tower is on show again.
  final bool enabled;

  /// Size of the block while held. Defaults to the tile's own drawing.
  final Size Function(Block block)? feedbackSize;

  final double tileAspect;

  @override
  State<BlockTray> createState() => _BlockTrayState();
}

class _BlockTrayState extends State<BlockTray> {
  int _page = 0;

  /// The tile being dragged. Every other tile is locked while it is set, so
  /// a second finger cannot hold a second block.
  Key? _activeKey;

  /// Stable per block (not per position), counting equal blocks apart.
  static Key _keyFor(List<Block> blocks, int index) {
    var n = 0;
    for (var j = 0; j < index; j++) {
      if (blocks[j] == blocks[index]) n++;
    }
    return ValueKey((blocks[index], n));
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.blocks;
    if (_activeKey != null &&
        !List.generate(
          blocks.length,
          (i) => _keyFor(blocks, i),
        ).contains(_activeKey)) {
      _activeKey = null;
    }
    final paged = blocks.length > trayTilesPerPage;
    const perPage = trayTilesPerPage - 1;
    final pages = paged ? (blocks.length / perPage).ceil() : 1;
    final page = _page.clamp(0, pages - 1);
    final start = paged ? page * perPage : 0;
    final shown = paged
        ? blocks.sublist(start, (start + perPage).clamp(0, blocks.length))
        : blocks;
    final tiles = <Widget>[
      for (var i = 0; i < shown.length; i++)
        _Tile(
          key: _keyFor(blocks, start + i),
          block: shown[i],
          enabled:
              widget.enabled &&
              (_activeKey == null || _activeKey == _keyFor(blocks, start + i)),
          canStart: (k) =>
              widget.enabled && (_activeKey == null || _activeKey == k),
          onDragStarted: (k) {
            // Set at once, not after a rebuild: a second finger can land
            // before the next frame.
            _activeKey = k;
            setState(() {});
          },
          onDragEnd: () {
            if (_activeKey != null) setState(() => _activeKey = null);
          },
          feedbackSize: widget.feedbackSize ?? _defaultHeld,
        ),
      if (paged)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _page = (page + 1) % pages),
          child: _Frame(
            child: Text(
              '+${blocks.length - shown.length}',
              style: nunito(13, weight: 900, color: AppColors.label),
            ),
          ),
        ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final w = (c.maxWidth - gap * 3) / 4;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles)
              SizedBox(width: w, height: w / widget.tileAspect, child: t),
          ],
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.panel,
      border: Border.all(color: AppColors.trayBorder),
    ),
    child: child,
  );
}

/// Arena width at which a square block is square (see the generator).
const double _referenceArenaWidth = 340;
const double _tallestBlock = 95;

/// One scale for every block, so relative widths and proportions survive:
/// the widest block (.90) fills [inner]'s width and the tallest fits its
/// height.
@visibleForTesting
Size trayDrawSize(Block b, Size inner) {
  final k = math.min(
    inner.width / (0.9 * _referenceArenaWidth),
    inner.height / _tallestBlock,
  );
  return Size(b.width * _referenceArenaWidth * k, b.height * k);
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.block,
    required this.enabled,
    required this.feedbackSize,
    required this.canStart,
    required this.onDragStarted,
    required this.onDragEnd,
  });

  final Block block;
  final bool enabled;
  final Size Function(Block) feedbackSize;
  final bool Function(Key?) canStart;
  final void Function(Key?) onDragStarted;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final held = feedbackSize(block);
    final tile = _Frame(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: LayoutBuilder(
          builder: (context, c) {
            final small = trayDrawSize(block, c.biggest);
            return Center(
              child: BlockView(
                block: block,
                width: small.width,
                height: small.height,
              ),
            );
          },
        ),
      ),
    );
    return Draggable<Block>(
      data: block,
      maxSimultaneousDrags: enabled ? 1 : 0,
      allowedButtonsFilter: (_) => canStart(key),
      onDragStarted: () => onDragStarted(key),
      onDragEnd: (_) => onDragEnd(),
      dragAnchorStrategy: (draggable, context, position) =>
          Offset(held.width / 2, held.height / 2),
      feedback: BlockView(
        block: block,
        width: held.width,
        height: held.height,
        heldWhite: true,
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: tile),
      child: tile,
    );
  }
}

/// Held size when the owner gives none: a quarter of the natural size.
Size _defaultHeld(Block b) =>
    Size(b.width * _referenceArenaWidth * 0.25, b.height * 0.25);
