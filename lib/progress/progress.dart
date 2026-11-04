import '../game/attempt.dart';

const int _lastLevel = 12;

/// Best result for one cleared level.
class LevelRecord {
  const LevelRecord({required this.stars, required this.bestPoints});

  final int stars, bestPoints;
}

/// What the player has cleared. Only levels that stood are stored.
class Progress {
  const Progress(this.records);

  final Map<int, LevelRecord> records;

  static const Progress empty = Progress({});

  int get totalPoints => records.values.fold(0, (sum, r) => sum + r.bestPoints);

  bool get hasPlayed => records.isNotEmpty;

  bool get allCleared =>
      List.generate(_lastLevel, (i) => i + 1).every(records.containsKey);

  /// Lowest uncleared level, or the last level when all are cleared.
  int get nextLevel {
    for (var n = 1; n <= _lastLevel; n++) {
      if (!records.containsKey(n)) return n;
    }
    return _lastLevel;
  }

  bool isUnlocked(int number) =>
      number >= 1 && number <= _lastLevel && number <= nextLevel;

  /// Returns this when the tower fell. Stars and points keep their own bests.
  Progress withResult(AttemptResult result) {
    if (!result.stood) return this;
    final number = result.level.number;
    final old = records[number];
    final stars = old == null || result.stars > old.stars
        ? result.stars
        : old.stars;
    final points = old == null || result.points > old.bestPoints
        ? result.points
        : old.bestPoints;
    return Progress({
      ...records,
      number: LevelRecord(stars: stars, bestPoints: points),
    });
  }
}

/// 1240 -> '1,240'.
String formatPoints(int points) {
  final digits = points.abs().toString();
  final buffer = StringBuffer(points < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
