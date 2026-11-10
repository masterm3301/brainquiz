import 'dart:math' as math;
import 'dart:ui';

/// Where each cube sits: towers side by side, each filled bottom to top,
/// left tower first. The column count is the one giving the largest cubes
/// that fit [area], never more than [maxColumns].
class CubeLayout {
  CubeLayout._(this.cube, this.gap, this.columnHeights, this.origin);

  factory CubeLayout(
    int count,
    Size area, {
    double columnGap = 0.22,
    double maxCube = 72,
    int? maxColumns,
  }) {
    if (count <= 0 || area.isEmpty) {
      return CubeLayout._(0, 0, const [], Offset.zero);
    }
    var bestSize = 0.0;
    var bestColumns = 1;
    for (var columns = 1; columns <= (maxColumns ?? count); columns++) {
      final rows = (count / columns).ceil();
      // Gaps between towers are a share of the cube, so solve for both.
      final byWidth = area.width / (columns + (columns - 1) * columnGap);
      // Capped first, so a short tower keeps one column at full size.
      final size = math.min(math.min(byWidth, area.height / rows), maxCube);
      if (size > bestSize + 0.01) {
        bestSize = size;
        bestColumns = columns;
      }
    }
    final cube = bestSize.floorToDouble();
    final base = count ~/ bestColumns;
    final extra = count % bestColumns;
    final heights = [
      for (var c = 0; c < bestColumns; c++) base + (c < extra ? 1 : 0),
    ];
    final gap = (cube * columnGap).floorToDouble();
    final width = bestColumns * cube + (bestColumns - 1) * gap;
    final origin = Offset((area.width - width) / 2, area.height);
    return CubeLayout._(cube, gap, heights, origin);
  }

  /// Side of one cube, in pixels.
  final double cube;
  final double gap;

  /// How many cubes each tower holds, left to right.
  final List<int> columnHeights;

  /// Bottom-left corner of the first tower.
  final Offset origin;

  int get columns => columnHeights.length;

  /// The square cube [index] occupies.
  Rect rectOf(int index) {
    var i = index;
    for (var c = 0; c < columnHeights.length; c++) {
      if (i < columnHeights[c]) {
        final left = origin.dx + c * (cube + gap);
        final bottom = origin.dy - i * cube;
        return Rect.fromLTRB(left, bottom - cube, left + cube, bottom);
      }
      i -= columnHeights[c];
    }
    throw RangeError.index(index, columnHeights, 'index');
  }

  /// The cube under [point], or null.
  int? indexAt(Offset point) {
    var index = 0;
    for (var c = 0; c < columnHeights.length; c++) {
      final left = origin.dx + c * (cube + gap);
      if (point.dx >= left - gap / 2 && point.dx < left + cube + gap / 2) {
        final row = ((origin.dy - point.dy) / cube).floor();
        if (row < 0 || row >= columnHeights[c]) return null;
        return index + row;
      }
      index += columnHeights[c];
    }
    return null;
  }
}
