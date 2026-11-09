import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'progress.dart';

abstract class ProgressStore {
  Future<Progress> load();
  Future<void> save(Progress progress);
}

/// Keeps progress as one JSON string:
/// `{"version":1,"levels":{"1":{"stars":3,"points":120}}}`.
class SharedPrefsProgressStore implements ProgressStore {
  /// Wind Levels progress, under its original key.
  SharedPrefsProgressStore() : key = windKey, lastLevel = 12;

  /// Memory Towers progress.
  SharedPrefsProgressStore.memory(this.lastLevel) : key = memoryKey;

  static const windKey = 'tower_build.progress';
  static const memoryKey = 'tower_build.memory_progress';
  static const _version = 1;

  final String key;
  final int lastLevel;

  @override
  Future<Progress> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.get(key);
      if (raw is! String) return Progress(const {}, lastLevel: lastLevel);
      return _decode(raw) ?? Progress(const {}, lastLevel: lastLevel);
    } catch (_) {
      return Progress(const {}, lastLevel: lastLevel);
    }
  }

  @override
  Future<void> save(Progress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, _encode(progress));
  }

  String _encode(Progress progress) => jsonEncode({
    'version': _version,
    'levels': {
      for (final e in progress.records.entries)
        '${e.key}': {'stars': e.value.stars, 'points': e.value.bestPoints},
    },
  });

  /// Null when the data is corrupt, from the future, or out of range.
  Progress? _decode(String raw) {
    final Object? data;
    try {
      data = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (data is! Map || data['version'] != _version) return null;
    final levels = data['levels'];
    if (levels is! Map) return null;
    final records = <int, LevelRecord>{};
    for (final entry in levels.entries) {
      final number = int.tryParse('${entry.key}');
      final value = entry.value;
      if (number == null || number < 1 || number > lastLevel) return null;
      if (value is! Map) return null;
      final stars = value['stars'];
      final points = value['points'];
      if (stars is! int || stars < 0 || stars > 3) return null;
      if (points is! int || points < 0) return null;
      records[number] = LevelRecord(stars: stars, bestPoints: points);
    }
    return Progress(records, lastLevel: lastLevel);
  }
}
