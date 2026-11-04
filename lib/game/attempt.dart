import 'package:flutter/foundation.dart';

import 'block.dart';
import 'explanation.dart';
import 'hold_simulation.dart';
import 'levels.dart';
import 'scoring.dart';
import 'stability.dart';
import 'tower_generator.dart';

class AttemptResult {
  const AttemptResult({
    required this.level,
    required this.stood,
    required this.correct,
    required this.total,
    required this.heldSeconds,
    required this.points,
    required this.stars,
    required this.lockStability,
    required this.fellAtSeconds,
    required this.headline,
    required this.detail,
  });

  final LevelConfig level;
  final bool stood;
  final int correct, total, heldSeconds, points, stars;
  final int lockStability;

  /// 0 if it stood.
  final int fellAtSeconds;
  final String headline, detail;
}

enum AttemptPhase { memorise, build, windReady, hold, result }

enum DropOutcome { placed, returnedToTray }

/// One try at one level, from study to result.
class Attempt extends ChangeNotifier {
  Attempt({
    required LevelConfig level,
    required int seed,
    List<Block>? previous,
  }) : _level = level,
       _seed = seed,
       _tower = generateTower(level, seed, previous: previous) {
    _tray = [..._tower.tray];
    _report = _assess();
  }

  final LevelConfig _level;
  final int _seed;
  final GeneratedTower _tower;
  late final List<Block> _tray;
  final List<PlacedBlock> _placed = [];
  late StabilityReport _report;
  AttemptPhase _phase = AttemptPhase.memorise;
  bool _secondLookUsed = false;
  bool _adBraceEarned = false;
  int _lockStability = 0;
  AttemptResult? _result;

  LevelConfig get level => _level;
  GeneratedTower get tower => _tower;
  AttemptPhase get phase => _phase;
  List<Block> get tray => List.unmodifiable(_tray);
  List<PlacedBlock> get placed => List.unmodifiable(_placed);
  StabilityReport get report => _report;
  bool get canLock => _placed.length == _level.blocks;
  bool get secondLookUsed => _secondLookUsed;
  bool get adBraceEarned => _adBraceEarned;

  StabilityReport _assess() =>
      assessStability(target: _tower.blocks, placed: _placed, level: _level);

  void finishStudy() {
    if (_phase != AttemptPhase.memorise) return;
    _phase = AttemptPhase.build;
    notifyListeners();
  }

  DropOutcome drop(Block block, double rawX) {
    if (_phase != AttemptPhase.build || canLock) {
      return DropOutcome.returnedToTray;
    }
    final index = _tray.indexOf(block);
    if (index < 0) return DropOutcome.returnedToTray;
    final below = _placed.isEmpty ? null : _placed.last;
    final x = snapDrop(rawX, belowX: below?.x ?? 0);
    if (!touchesBelow(block, x, below)) return DropOutcome.returnedToTray;
    _tray.removeAt(index);
    _placed.add(PlacedBlock(block, x));
    _report = _assess();
    notifyListeners();
    return DropOutcome.placed;
  }

  bool earnSecondLook() {
    if (_secondLookUsed || _phase != AttemptPhase.build) return false;
    _secondLookUsed = true;
    notifyListeners();
    return true;
  }

  void lock() {
    if (_phase != AttemptPhase.build || !canLock) return;
    _lockStability = _report.score;
    _phase = AttemptPhase.windReady;
    notifyListeners();
  }

  bool earnAdBrace() {
    if (_adBraceEarned || _phase != AttemptPhase.windReady) return false;
    _adBraceEarned = true;
    notifyListeners();
    return true;
  }

  HoldSimulation startHold() {
    if (_phase != AttemptPhase.windReady) {
      throw StateError('startHold needs the windReady phase, not $_phase');
    }
    _phase = AttemptPhase.hold;
    notifyListeners();
    return HoldSimulation(
      level: _level,
      stabilityScore: _report.score,
      mustFall: _report.mustFall,
      seed: _seed,
      braces: _adBraceEarned ? 2 : 1,
    );
  }

  AttemptResult finish(HoldSimulation sim) {
    final done = _result;
    if (done != null) return done;
    if (_phase != AttemptPhase.hold) {
      throw StateError('finish needs the hold phase, not $_phase');
    }
    if (!sim.fallen && !sim.finished) {
      throw StateError('finish called before the hold ended');
    }
    final total = _level.blocks;
    final correct = total - _report.wrongCount;
    // The small bias absorbs float drift: 160 steps of 0.05 sum to 7.9999...
    final held = (sim.elapsed + 1e-6).floor();
    final stood = !sim.fallen;
    final paidBraces = (sim.bracesUsed - (_adBraceEarned ? 1 : 0)).clamp(
      0,
      sim.bracesUsed,
    );

    final ResultText text;
    if (stood) {
      text = ResultText(headline: 'It stood', detail: explainHold(_report));
    } else {
      text = explainFall(_report, total: total);
    }

    _result = AttemptResult(
      level: _level,
      stood: stood,
      correct: correct,
      total: total,
      heldSeconds: held,
      points: stood
          ? pointsFor(
              correct: correct,
              heldSeconds: held,
              paidBraces: paidBraces,
            )
          : 0,
      stars: stood
          ? starsFor(
              correct: correct,
              total: total,
              usedBrace: sim.bracesUsed > 0,
              usedSecondLook: _secondLookUsed,
            )
          : 0,
      lockStability: _lockStability,
      fellAtSeconds: stood ? 0 : (held < 1 ? 1 : held),
      headline: text.headline,
      detail: text.detail,
    );
    _phase = AttemptPhase.result;
    notifyListeners();
    return _result!;
  }
}
