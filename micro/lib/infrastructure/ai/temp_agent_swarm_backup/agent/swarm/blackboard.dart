import 'dart:convert';
import 'package:micro/infrastructure/serialization/toon_encoder.dart';

/// Entry in the blackboard with metadata
class BlackboardEntry {
  final String key;
  final dynamic value;
  final String author; // Which specialist wrote this
  final DateTime timestamp;
  final double confidence; // 0.0 - 1.0
  final int version;
  final List<String> supportingStepIds;

  BlackboardEntry({
    required this.key,
    required this.value,
    required this.author,
    required this.timestamp,
    this.confidence = 1.0,
    required this.version,
    this.supportingStepIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'author': author,
        'timestamp': timestamp.toIso8601String(),
        'confidence': confidence,
        'version': version,
        'supportingStepIds': supportingStepIds,
      };

  @override
  String toString() => 'BlackboardEntry($key=$value by $author @v$version)';
}

/// Shared memory store for multi-specialist coordination
/// Supports version tracking, delta updates, and conflict detection
class Blackboard {
  final Map<String, List<BlackboardEntry>> _history = {};
  int _globalVersion = 0;

  /// Write a fact to the blackboard
  void put(
    String key,
    dynamic value, {
    required String author,
    double confidence = 1.0,
    List<String> supportingStepIds = const [],
  }) {
    _globalVersion++;

    final entry = BlackboardEntry(
      key: key,
      value: value,
      author: author,
      timestamp: DateTime.now(),
      confidence: confidence,
      version: _globalVersion,
      supportingStepIds: supportingStepIds,
    );

    _history.putIfAbsent(key, () => []).add(entry);
  }

  /// Get latest value for a key
  dynamic get(String key) {
    final entries = _history[key];
    if (entries == null || entries.isEmpty) return null;
    return entries.last.value;
  }

  /// Get latest entry with metadata
  BlackboardEntry? getEntry(String key) {
    final entries = _history[key];
    if (entries == null || entries.isEmpty) return null;
    return entries.last;
  }

  /// Get all versions of a key (for conflict detection)
  List<BlackboardEntry> getHistory(String key) {
    return _history[key] ?? [];
  }

  /// Get all current facts (latest version of each key)
  Map<String, dynamic> getAllFacts() {
    final facts = <String, dynamic>{};
    for (final key in _history.keys) {
      facts[key] = get(key);
    }
    return facts;
  }

  /// Get entries added since a specific version (for delta updates)
  List<BlackboardEntry> getDelta(int sinceVersion) {
    final delta = <BlackboardEntry>[];
    for (final entries in _history.values) {
      delta.addAll(entries.where((e) => e.version > sinceVersion));
    }
    delta.sort((a, b) => a.version.compareTo(b.version));
    return delta;
  }

  /// Serialize to TOON format (compact for LLM input)
  String toTOON({int? sinceVersion}) {
    final entries =
        sinceVersion == null ? _getAllLatestEntries() : getDelta(sinceVersion);

    if (entries.isEmpty) return 'blackboard[0]:';

    // Convert to tabular format
    final data = entries
        .map((e) => {
              'key': e.key,
              'value': e.value,
              'author': e.author,
              'confidence': e.confidence,
            })
        .toList();

    return toonEncode({'blackboard': data});
  }

  /// Serialize to JSON (for LLM output or storage)
  String toJSON({int? sinceVersion}) {
    final entries =
        sinceVersion == null ? _getAllLatestEntries() : getDelta(sinceVersion);

    final data = entries.map((e) => e.toJson()).toList();
    return jsonEncode({'blackboard': data});
  }

  /// Detect conflicts (multiple specialists wrote different values for same key)
  List<String> detectConflicts() {
    final conflicts = <String>[];
    for (final key in _history.keys) {
      final versions = _history[key]!;
      if (versions.length > 1) {
        // Check if different authors provided different values
        final uniqueValues = versions.map((e) => jsonEncode(e.value)).toSet();
        if (uniqueValues.length > 1) {
          conflicts.add(key);
        }
      }
    }
    return conflicts;
  }

  /// Resolve conflict by selecting highest confidence entry
  void resolveConflict(String key) {
    final entries = _history[key];
    if (entries == null || entries.length <= 1) return;

    // Keep only highest confidence entry
    final best = entries.reduce((a, b) => a.confidence > b.confidence ? a : b);
    _history[key] = [best];
  }

  List<BlackboardEntry> _getAllLatestEntries() {
    return _history.keys.map((key) => getEntry(key)!).toList();
  }

  int get version => _globalVersion;
  int get factCount => _history.keys.length;

  void clear() {
    _history.clear();
    _globalVersion = 0;
  }

  @override
  String toString() {
    final facts = getAllFacts();
    return 'Blackboard(v$_globalVersion, ${facts.length} facts: ${facts.keys.join(', ')})';
  }
}
