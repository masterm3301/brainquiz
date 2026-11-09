import '../game/attempt.dart';

/// Best result for one cleared level.
class LevelRecord {
  const LevelRecord({required this.stars, required this.bestPoints});

  final int stars, bestPoints;
}

/// What the player has cleared. Only levels that stood are stored.
class Progress {
  const Progress(this.records, {this.lastLevel = 12});

  final Map<int, LevelRecord> records;

  /// How many levels this game mode has.
  final int lastLevel;

  static const Progress empty = Progress({});

  int get totalPoints => records.values.fold(0, (sum, r) => sum + r.bestPoints);

  bool get hasPlayed => records.isNotEmpty;

  bool get allCleared =>
      List.generate(lastLevel, (i) => i + 1).every(records.containsKey);

  /// Lowest uncleared level, or the last level when all are cleared.
  int get nextLevel {
    for (var n = 1; n <= lastLevel; n++) {
      if (!records.containsKey(n)) return n;
    }
    return lastLevel;
  }

  bool isUnlocked(int number) =>
      number >= 1 && number <= lastLevel && number <= nextLevel;

  /// Returns this when the tower fell. Stars and points keep their own bests.
  Progress withResult(AttemptResult result) {
    if (!result.stood) return this;
    return withCleared(result.level.number,
        stars: result.stars, points: result.points);
  }

  /// Records a cleared level, keeping the best stars and best points.
  Progress withCleared(int number, {required int stars, required int points}) {
    final old = records[number];
    return Progress({
      ...records,
      number: LevelRecord(
        stars: old == null || stars > old.stars ? stars : old.stars,
        bestPoints:
            old == null || points > old.bestPoints ? points : old.bestPoints,
      ),
    }, lastLevel: lastLevel);
  }

  /// The same records for a mode with [lastLevel] levels.
  Progress withLastLevel(int lastLevel) =>
      lastLevel == this.lastLevel ? this : Progress(records, lastLevel: lastLevel);
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
