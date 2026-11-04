import 'package:flutter/foundation.dart';

import '../game/attempt.dart';
import 'progress.dart';
import 'progress_store.dart';

class ProgressController extends ChangeNotifier {
  ProgressController(this._store);

  final ProgressStore _store;
  Progress _progress = Progress.empty;

  Progress get progress => _progress;

  Future<void> load() async {
    _progress = await _store.load();
    notifyListeners();
  }

  /// Updates memory first, so a failed save never loses the result on screen.
  Future<void> record(AttemptResult result) async {
    final next = _progress.withResult(result);
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
