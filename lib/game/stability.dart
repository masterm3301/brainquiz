import 'block.dart';
import 'levels.dart';

/// Drops within this fraction of arena width snap to a neighbouring line.
const double dropTolerance = 0.035;

class PlacedBlock {
  const PlacedBlock(this.block, this.x);

  final Block block;

  /// Centre, as an arena-width fraction. 0 is the centre line.
  final double x;
}

enum Side { left, right }

class CrookedDrop {
  const CrookedDrop(this.row, this.side);

  /// 1-based, bottom block = 1.
  final int row;
  final Side side;
}

class StabilityReport {
  const StabilityReport({
    required this.score,
    required this.mustFall,
    required this.wrongRows,
    required this.crooked,
    required this.topHeavy,
    required this.meterLine,
  });

  final int score;
  final bool mustFall;
  final List<int> wrongRows;
  final List<CrookedDrop> crooked;
  final bool topHeavy;
  final String meterLine;

  int get wrongCount => wrongRows.length;
}

String meterLineFor(int score) {
  if (score >= 70) return 'Centre of mass still over the pillar.';
  if (score >= 40) return 'Getting shaky. Centre of mass is drifting.';
  return 'Too unstable to last in the wind.';
}

double snapDrop(double rawX, {required double belowX}) {
  if (rawX.abs() <= dropTolerance) return 0;
  if ((rawX - belowX).abs() <= dropTolerance) return belowX;
  return rawX;
}

bool touchesBelow(Block block, double x, PlacedBlock? below) {
  final belowX = below?.x ?? 0;
  final belowWidth = below?.block.width ?? pillar.width;
  return (x - belowX).abs() <= (block.width + belowWidth) / 2;
}

/// Mass-weighted vertical centre as a fraction of the stack height.
double _comY(List<Block> blocks) {
  if (blocks.isEmpty) return 0;
  var mass = 0.0, moment = 0.0, base = 0.0;
  for (final b in blocks) {
    mass += b.mass;
    moment += b.mass * (base + b.height / 2);
    base += b.height;
  }
  return moment / (mass * base);
}

StabilityReport assessStability({
  required List<Block> target,
  required List<PlacedBlock> placed,
  required LevelConfig level,
}) {
  final wrongRows = <int>[];
  final crooked = <CrookedDrop>[];
  var sumOffset = 0.0;
  var mass = 0.0, massX = 0.0;
  var prevX = 0.0;
  for (var i = 0; i < placed.length; i++) {
    final p = placed[i];
    if (p.block != target[i]) wrongRows.add(i + 1);
    final offset = p.x - prevX;
    if (offset.abs() > dropTolerance) {
      crooked.add(CrookedDrop(i + 1, offset < 0 ? Side.left : Side.right));
      sumOffset += offset.abs();
    }
    prevX = p.x;
    mass += p.block.mass;
    massX += p.block.mass * p.x;
  }

  final comX = mass == 0 ? 0.0 : massX / mass;
  final comY = _comY([for (final p in placed) p.block]);
  final targetComY = _comY(target.take(placed.length).toList());
  final rise = comY - targetComY;

  final wrongCost = (level.wrongLimitApplies ? 22 : 12) * wrongRows.length;
  var score = 100 -
      wrongCost -
      60 * sumOffset -
      200 * comX.abs() -
      150 * (rise > 0 ? rise : 0);
  final mustFall = level.wrongLimitApplies && wrongRows.length >= 2;
  if (mustFall && score > 35) score = 35;
  final finalScore = score.round().clamp(0, 100);

  return StabilityReport(
    score: finalScore,
    mustFall: mustFall,
    wrongRows: wrongRows,
    crooked: crooked,
    topHeavy: rise > 0.05,
    meterLine: meterLineFor(finalScore),
  );
}
