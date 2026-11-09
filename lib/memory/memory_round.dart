import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'memory_levels.dart';

enum MemoryPhase { study, recall, result }

/// Share of cubes that must be right to clear a level.
const double passShare = 0.75;

/// The outcome of one round.
class MemoryResult {
  const MemoryResult({
    required this.level,
    required this.correct,
    required this.total,
    required this.secondsSaved,
  });

  final MemoryLevel level;
  final int correct, total;

  /// Whole study seconds left when the player said they were ready.
  final int secondsSaved;

  bool get passed => correct >= (total * passShare).ceil();

  /// 3 for every cube right, 2 for 90% or more, 1 for a pass, 0 for a miss.
  int get stars {
    if (!passed) return 0;
    if (correct == total) return 3;
    return correct >= (total * 0.9).ceil() ? 2 : 1;
  }

  /// 10 per right cube, plus 3 per study second saved. Nothing for a miss.
  int get points => passed ? 10 * correct + 3 * secondsSaved : 0;
}

/// One try at one Memory Towers level. Cubes are colour indexes into the
/// level's palette, listed bottom to top, column by column.
class MemoryRound extends ChangeNotifier {
  MemoryRound({required this.level, required int seed})
    : target = _generate(level, seed),
      placed = List<int?>.filled(level.cubes, null);

  final MemoryLevel level;
  final List<int> target;
  final List<int?> placed;

  MemoryPhase _phase = MemoryPhase.study;
  MemoryPhase get phase => _phase;

  int _cursor = 0;

  /// The slot the next colour goes into.
  int get cursor => _cursor;

  final List<({int index, int? before, int cursor})> _history = [];
  bool get canUndo => _phase == MemoryPhase.recall && _history.isNotEmpty;

  int _secondsSaved = 0;
  MemoryResult? _result;
  MemoryResult? get result => _result;

  int get filled => placed.where((c) => c != null).length;
  bool get complete => filled == placed.length;

  /// Random colours, never more than three of one colour in a row, so the
  /// tower reads as a pattern and not as a block of paint.
  static List<int> _generate(MemoryLevel level, int seed) {
    final random = math.Random(seed);
    final cubes = <int>[];
    while (cubes.length < level.cubes) {
      final c = random.nextInt(level.colors);
      final n = cubes.length;
      if (n >= 3 &&
          cubes[n - 1] == c &&
          cubes[n - 2] == c &&
          cubes[n - 3] == c) {
        continue;
      }
      cubes.add(c);
    }
    return cubes;
  }

  /// Ends the study time. [secondsLeft] is unused time, which earns points.
  void finishStudy({int secondsLeft = 0}) {
    if (_phase != MemoryPhase.study) return;
    _secondsSaved = secondsLeft;
    _phase = MemoryPhase.recall;
    notifyListeners();
  }

  /// Moves the cursor to a cube already placed, so it can be recoloured,
  /// or to the next free slot.
  void select(int index) {
    if (_phase != MemoryPhase.recall) return;
    if (index < 0 || index >= placed.length) return;
    if (placed[index] == null && index != _firstEmpty) return;
    _cursor = index;
    notifyListeners();
  }

  /// Puts [color] in the cursor's slot, then moves to the next free slot.
  void place(int color) {
    if (_phase != MemoryPhase.recall) return;
    if (color < 0 || color >= level.colors || placed[_cursor] == color) return;
    _history.add((index: _cursor, before: placed[_cursor], cursor: _cursor));
    placed[_cursor] = color;
    _cursor = _firstEmpty ?? _cursor;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    final last = _history.removeLast();
    placed[last.index] = last.before;
    _cursor = last.cursor;
    notifyListeners();
  }

  int? get _firstEmpty {
    final i = placed.indexOf(null);
    return i < 0 ? null : i;
  }

  MemoryResult check() {
    if (_result case final result?) return result;
    assert(complete, 'check() before every slot is filled');
    var correct = 0;
    for (var i = 0; i < target.length; i++) {
      if (placed[i] == target[i]) correct++;
    }
    final result = MemoryResult(
      level: level,
      correct: correct,
      total: target.length,
      secondsSaved: _secondsSaved,
    );
    _result = result;
    _phase = MemoryPhase.result;
    notifyListeners();
    return result;
  }
}
