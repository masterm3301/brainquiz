import 'package:flutter/foundation.dart';

import '../game/attempt.dart';
import 'progress.dart';
import 'progress_store.dart';

class ProgressController extends ChangeNotifier {
  ProgressController(this._store, {this.lastLevel = 12})
    : _progress = Progress(const {}, lastLevel: lastLevel);

  final ProgressStore _store;

  /// How many levels the mode this controller tracks has.
  final int lastLevel;
  Progress _progress;

  Progress get progress => _progress;

  Future<void> load() async {
    _progress = (await _store.load()).withLastLevel(lastLevel);
    notifyListeners();
  }

  /// Updates memory first, so a failed save never loses the result on screen.
  Future<void> record(AttemptResult result) =>
      _commit(_progress.withResult(result));

  /// Records a cleared level of a mode that is not built on [AttemptResult].
  Future<void> recordCleared(int number,
          {required int stars, required int points}) =>
      _commit(_progress.withCleared(number, stars: stars, points: points));

  /// Wipes every record: stars, points and unlocks back to a new player.
  Future<void> reset() => _commit(Progress(const {}, lastLevel: lastLevel));

  Future<void> _commit(Progress next) async {
    if (identical(next, _progress)) return;
    _progress = next;
    notifyListeners();
    try {
      await _store.save(next);
    } catch (error, stack) {
      debugPrint('Could not save progress: $error\n$stack');
    }
  }
}
