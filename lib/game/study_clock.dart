import 'hold_simulation.dart' show clampedDt;

/// Counts the study time down. Each step is clamped, so coming back from
/// the background cannot skip the player's look at the tower.
class StudyClock {
  StudyClock(this.seconds);

  final int seconds;
  double _elapsed = 0;

  void step(double dt) => _elapsed += clampedDt(dt);

  int get secondsLeft => (seconds - _elapsed).ceil().clamp(0, seconds);
  /// Full seconds still unused, rounding down.
  int get wholeSecondsLeft => (seconds - _elapsed).floor().clamp(0, seconds);
  double get fractionLeft => (1 - _elapsed / seconds).clamp(0.0, 1.0);
  bool get done => _elapsed >= seconds;
}
