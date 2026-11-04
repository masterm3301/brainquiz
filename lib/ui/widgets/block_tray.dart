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

  static Size tileSize(Block b) =>
      Size((b.width * 90).clamp(10, 40), (b.height * 0.45).clamp(10, 32));

  @override
  Widget build(BuildContext context) {
    final blocks = widget.blocks;
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
          key: ValueKey('tile-${start + i}'),
          block: shown[i],
          enabled: widget.enabled,
          feedbackSize: widget.feedbackSize ?? tileSize,
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

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.block,
    required this.enabled,
    required this.feedbackSize,
  });

  final Block block;
  final bool enabled;
  final Size Function(Block) feedbackSize;

  @override
  Widget build(BuildContext context) {
    final small = _BlockTrayState.tileSize(block);
    final held = feedbackSize(block);
    final tile = _Frame(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: BlockView(
            block: block,
            width: small.width,
            height: small.height,
          ),
        ),
      ),
    );
    return Draggable<Block>(
      data: block,
      maxSimultaneousDrags: enabled ? 1 : 0,
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
