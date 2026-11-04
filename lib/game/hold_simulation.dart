import 'dart:math';

import 'levels.dart';

/// The tower falls once it leans further than this many degrees.
const double maxLeanDegrees = 12;

const double _maxDt = 1 / 20;
const double _responseSeconds = 0.8;
const double _braceSeconds = 4;

/// Longest time step any clock may take, so a return from background
/// cannot skip the hold or the study timer.
double clampedDt(double dt) => dt.clamp(0.0, _maxDt).toDouble();

class Gust {
  const Gust({
    required this.start,
    required this.duration,
    required this.amplitude,
    required this.direction,
  });

  final double start;
  final double duration;
  final double amplitude;

  /// -1 pushes left, 1 pushes right.
  final int direction;

  double get end => start + duration;
}

/// One gust per equal slot of the hold, fully inside its slot.
List<Gust> scheduleGusts(LevelConfig level, Random random) {
  final slot = level.holdSeconds / level.gusts;
  final duration = min(slot * 0.7, 5.0);
  return [
    for (var i = 0; i < level.gusts; i++)
      Gust(
        start: i * slot + random.nextDouble() * (slot - duration),
        duration: duration,
        amplitude: 0.8 + random.nextDouble() * 0.2,
        direction: random.nextBool() ? 1 : -1,
      ),
  ];
}

class HoldSimulation {
  HoldSimulation({
    required this.level,
    required this.stabilityScore,
    required this.mustFall,
    required this.seed,
    required int braces,
  }) : _bracesLeft = braces,
       _gusts = scheduleGusts(level, Random(seed));

  final LevelConfig level;
  final int stabilityScore;
  final bool mustFall;
  final int seed;

  final List<Gust> _gusts;
  int _bracesLeft;
  int _bracesUsed = 0;
  double _lean = 0;
  double _elapsed = 0;
  double _braceUntil = -1;
  bool _fallen = false;

  double get leanDegrees => _lean;
  double get elapsed => _elapsed;
  int get secondsLeft => max(0, (level.holdSeconds - _elapsed).ceil());
  bool get fallen => _fallen;
  bool get finished => !_fallen && _elapsed >= level.holdSeconds - 1e-9;
  bool get _over => _fallen || finished;

  int get gustIndex => _gusts.where((g) => g.start <= _elapsed).length;

  int get stabilityPercent =>
      ((1 - _lean.abs() / maxLeanDegrees) * 100).round().clamp(0, 100);

  int get bracesLeft => _bracesLeft;
  int get bracesUsed => _bracesUsed;

  bool get windActive => _activeGust != null;

  Gust? get _activeGust {
    for (final g in _gusts) {
      if (_elapsed >= g.start && _elapsed < g.end) return g;
    }
    return null;
  }

  void step(double dt) {
    if (_over) return;
    final d = clampedDt(dt);
    final gust = _activeGust;
    final f = 1 - stabilityScore / 100;
    var target = gust == null
        ? 0.0
        : gust.direction * gust.amplitude * level.windStrength * (4 + 26 * f);
    if (mustFall) target *= 3;
    if (_elapsed < _braceUntil) target *= 0.5;
    _lean += (target - _lean) * (1 - exp(-d / _responseSeconds));
    _elapsed += d;
    if (_lean.abs() > maxLeanDegrees) _fallen = true;
  }

  bool brace() {
    if (_bracesLeft <= 0 || _over) return false;
    _bracesLeft--;
    _bracesUsed++;
    _lean /= 2;
    _braceUntil = _elapsed + _braceSeconds;
    return true;
  }
}
